//+------------------------------------------------------------------+
//|                                                      Impulse.mq5 |
//|                                                    Michael Enudi |
//|                                             okmich2002@yahoo.com |
//+------------------------------------------------------------------+
#property copyright "Michael Enudi"
#property link      "okmich2002@yahoo.com"
#property version   "1.00"

#include <Okmich\Expert\SingleExpert.mqh>
#include <Okmich\Indicators\CongestionIndex.mqh>


//--- input parameters
input ENUM_CGSIDX_Strategies InpHowTo= CGSIDX_SignalCrossover;           
input int      InpPeriod=28;                             //Period
input ENUM_APPLIED_PRICE    InpAppliedPrice  = PRICE_CLOSE; 
input int      InpSmoothingPeriod=10;
input int      InpSignalPeriod=10; 

input ulong    ExpertMagic           = 980023;              //Expert MagicNumbers

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
class CStrategryImpl : public CStrategy
  {
private :
   //--- indicator values
   //--- indicator settings
   int                m_Period, m_SmoothingPeriod, m_SignalPeriod;
   ENUM_APPLIED_PRICE m_AppliedPrice;
   //--- indicators
   CCongestionIndex   *m_CongIndex;
   //--- indicator buffer
   //-- others


public:
                     CStrategryImpl(string symbol, ENUM_TIMEFRAMES period,
                  int InputPeriod, ENUM_APPLIED_PRICE InputAppPrice,
                  int InputSmoothingPeriod, int InputSignalPeriod): CStrategy(symbol, period)
     {
      m_Period = InputPeriod;
      m_AppliedPrice = InputAppPrice;
      m_SmoothingPeriod = InputSmoothingPeriod;
      m_SignalPeriod = InputSignalPeriod;

      mLotSize = SymbolInfoDouble(_Symbol, SYMBOL_VOLUME_MIN);
     };

   virtual bool      Init(ulong magic);
   virtual void      Refresh();
   virtual void      CheckAndSetExitSignal(CPositionInfo &positionInfo, Position &position);
   virtual void      Release();
  };

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
bool CStrategryImpl::Init(ulong magic)
  {
   CStrategy::Init(magic);
//--- m_CongIndex
   m_CongIndex = new CCongestionIndex(mSymbol, mTimeframe, m_Period, m_AppliedPrice, m_SmoothingPeriod, m_SignalPeriod);
   return m_CongIndex.Init();
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void CStrategryImpl::Release(void)
  {
   m_CongIndex.Release();
   delete m_CongIndex;
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void CStrategryImpl::CheckAndSetExitSignal(CPositionInfo &positionInfo, Position &position)
  {
   ENUM_POSITION_TYPE posType = positionInfo.PositionType();
   if(posType == POSITION_TYPE_BUY && mEntrySignal == ENTRY_SIGNAL_SELL)
      position.signal = EXIT_SIGNAL_EXIT;
   else
      if(posType == POSITION_TYPE_SELL && mEntrySignal == ENTRY_SIGNAL_BUY)
         position.signal = EXIT_SIGNAL_EXIT;
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void CStrategryImpl::Refresh(void)
  {
   if(IsNewBar())
     {
      bool refreshed = m_CongIndex.Refresh();
      //--- take values from indicator
      mEntrySignal = m_CongIndex.TradeSignal(InpHowTo);
     }
  }

// the expert to run our strategy
CSingleExpert singleExpert(ExpertMagic, 10);
//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+
int OnInit()
  {
   CStrategryImpl *strategy =
      new CStrategryImpl(_Symbol, _Period, InpPeriod, InpAppliedPrice, InpSmoothingPeriod, InpSignalPeriod);
//set position management
   strategy.SetPositionManager(new CNoPositionManager(_Symbol, _Period));

//set strategy on expert
   singleExpert.SetStrategyImpl(strategy);

   if(singleExpert.OnInitHandler())
      return INIT_SUCCEEDED ;
   else
      return INIT_FAILED;
  }

//+------------------------------------------------------------------+
//| Expert deinitialization function                                 |
//+------------------------------------------------------------------+
void OnDeinit(const int reason)
  {
   singleExpert.OnDeinitHandler();
  }

//+------------------------------------------------------------------+
//| Expert tick function                                             |
//+------------------------------------------------------------------+
void OnTick()
  {
//---
   singleExpert.OnTickHandler();
  }
//+------------------------------------------------------------------+
