//+------------------------------------------------------------------+
//|                                         BearBullPowerBalance.mq5 |
//|                                    Copyright 2022, Michael Enudi |
//|                                             okmich2002@yahoo.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2022, Michael Enudi"
#property link      "okmich2002@yahoo.com"
#property version   "1.00"

#include <Okmich\Expert\SingleExpert.mqh>
#include <Okmich\Indicators\BearBullPower.mqh>

//--- input parameters
input group "********* Trading strategy settings *********";
input int      InpPeriod=20;
input ENUM_MA_METHOD      InpMethod= MODE_EMA; 
input int      InpSmoothingPeriod=20;
input ENUM_MA_METHOD      InpSmoothingMethod= MODE_EMA;

input group "********* Other Settings *********";
input ulong    ExpertMagic             = 777776;      //Expert MagicNumber

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
class CStrategyImpl : public CStrategy
  {
private :
   //--- indicator values

   //--- indicator settings
   int                m_Period, m_SmoothingPeriod;
   ENUM_MA_METHOD     m_Method, m_SmoothingMethod;
   //--- indicators
   CBearBullBalance   *m_BBB;
   //--- indicator buffer

   //-- others
   double            m_CloseBuffer[];

public:
                     CStrategyImpl(string symbol, ENUM_TIMEFRAMES period,
                    int InputPeriod, ENUM_MA_METHOD InputMethod,
                    int InputSmoothingPeriod, ENUM_MA_METHOD InputSmoothingMethod): CStrategy(symbol, period)
     {
      m_Period = InputPeriod;
      m_Method = InputMethod;
      m_SmoothingPeriod = InputSmoothingPeriod;
      m_SmoothingMethod = InputSmoothingMethod;

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
bool CStrategyImpl::Init(ulong magic)
  {
   CStrategy::Init(magic);
//--- price buffers
   ArraySetAsSeries(m_CloseBuffer, true);
//--- m_BBB
   m_BBB = new CBearBullBalance(mSymbol, mTimeframe, m_Period, m_Method, m_SmoothingPeriod, m_SmoothingMethod);

   return m_BBB.Init();
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void CStrategyImpl::Release(void)
  {
   m_BBB.Release();
   delete m_BBB;
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void CStrategyImpl::CheckAndSetExitSignal(CPositionInfo &positionInfo, Position &position)
  {
   ENUM_POSITION_TYPE posType = positionInfo.PositionType();
   double profit = positionInfo.Profit();
   double openPrice = positionInfo.PriceOpen();
   double currentPrice = positionInfo.PriceCurrent();

   if(posType == POSITION_TYPE_BUY && mEntrySignal == ENTRY_SIGNAL_SELL)
      position.signal = EXIT_SIGNAL_EXIT;
   else
      if(posType == POSITION_TYPE_SELL && mEntrySignal == ENTRY_SIGNAL_BUY)
         position.signal = EXIT_SIGNAL_EXIT;
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void CStrategyImpl::Refresh(void)
  {
   if(IsNewBar())
     {
      CopyClose(mSymbol, mTimeframe, 0, 8, m_CloseBuffer);
      m_BBB.Refresh();
      //--- signal logic
      mEntrySignal = m_BBB.TradeSignal();
     }
  }

// the expert to run our strategy
CSingleExpert singleExpert(ExpertMagic, 10);
//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+
int OnInit()
  {
   CStrategyImpl *strategy =
      new CStrategyImpl(_Symbol, _Period,
                        InpPeriod, InpMethod, InpSmoothingPeriod, InpSmoothingMethod);
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
