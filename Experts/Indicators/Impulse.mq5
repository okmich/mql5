//+------------------------------------------------------------------+
//|                                                      Impulse.mq5 |
//|                                                    Michael Enudi |
//|                                             okmich2002@yahoo.com |
//+------------------------------------------------------------------+
#property copyright "Michael Enudi"
#property link      "okmich2002@yahoo.com"
#property version   "1.00"

#include <Okmich\Expert\SingleExpert.mqh>
#include <Okmich\Indicators\Impulse.mqh>


//--- input parameters
input int      InpPeriod=14;                             //Period
input ENUM_MA_METHOD    InpSmoothingMethod  = MODE_SMA;  //Smoothing Method

input ulong    ExpertMagic           = 980023;              //Expert MagicNumbers

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
class CStrategryImpl : public CStrategy
  {
private :
   //--- indicator values
   //--- indicator settings
   int               mPeriod;
   ENUM_MA_METHOD    mSmoothingMethod;
   //--- indicators
   CImpulse         *m_Impulse;
   //--- indicator buffer
   //-- others


public:
                     CStrategryImpl(string symbol, ENUM_TIMEFRAMES period, int InptPeriod, ENUM_MA_METHOD InptSmoothingMethod): CStrategy(symbol, period)
     {
      mPeriod = InptPeriod;
      mSmoothingMethod = InptSmoothingMethod;

      mLotSize = 1*SymbolInfoDouble(_Symbol, SYMBOL_VOLUME_MIN);
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
//--- m_Impulse
   m_Impulse = new CImpulse(mSymbol, mTimeframe, mPeriod, mSmoothingMethod);
   return m_Impulse.Init();
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void CStrategryImpl::Release(void)
  {
   m_Impulse.Release();
   delete m_Impulse;
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
      bool refreshed = m_Impulse.Refresh();
      //--- take values from indicator
      mEntrySignal = m_Impulse.TradeSignal();
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
      new CStrategryImpl(_Symbol, _Period, InpPeriod, InpSmoothingMethod);
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
