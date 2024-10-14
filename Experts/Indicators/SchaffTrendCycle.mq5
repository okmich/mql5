//+------------------------------------------------------------------+
//|                                                     FilterEA.mq5 |
//|                                    Copyright 2021, Michael Enudi |
//|                                             okmich2002@yahoo.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2021, Michael Enudi"
#property link      "okmich2002@yahoo.com"
#property version   "1.00"

#include <Okmich\Expert\SingleExpert.mqh>
#include <Okmich\Indicators\SchaffTrendCycle.mqh>

input ENUM_STC_Strategies    InpEntryStrategyOption = STC_CrossesMidLevels; //STC Entry logic type
input int    InpStcPeriod = 20;                      //Schaff Trend Cycle period
input int    InpFastEmaPeriod = 23;                  //Fast Ma period
input int    InpSlowEmaPeriod = 50;                  //Slow Ma period
input int    InpSmoothPeriod = 3;                   //Smoothing period
input int    InpObLevel     = 80;                   //Overbought Level
input ulong  ExpertMagic = 980023;                  //Expert MagicNumbers


//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
class CStrategyImpl : public CStrategy
  {
private :
   //--- indicator values
   //--- indicator settings
   int                m_Period, m_FastEmaPeriod, m_SlowEmaPeriod, m_SmoothingPeriod, m_ObLevel;
   //--- indicators
   CSchaffTrendCycle *mStc;
   //--- indicator buffer
   //-- others


public:
                     CStrategyImpl(string symbol, ENUM_TIMEFRAMES timeFrame, int InptPeriod=32,
                 int InptFastEma=23,int InptSlowEma=50,int InptSmoothing=3, int InptObLevel = 80): CStrategy(symbol, timeFrame)
     {
      m_Period = InptPeriod;
      m_FastEmaPeriod = InptFastEma;
      m_SlowEmaPeriod = InptSlowEma;
      m_SmoothingPeriod = InptSmoothing;
      m_ObLevel = InptObLevel;

      mLotSize = 2*SymbolInfoDouble(_Symbol, SYMBOL_VOLUME_MIN);
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
//--- mStc
   mStc = new CSchaffTrendCycle(mSymbol, mTimeframe, m_Period, m_FastEmaPeriod, m_SlowEmaPeriod, m_SmoothingPeriod, m_ObLevel);
   return mStc.Init();
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void CStrategyImpl::Release(void)
  {
   mStc.Release();
   delete mStc;
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void CStrategyImpl::CheckAndSetExitSignal(CPositionInfo &positionInfo, Position &position)
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
void CStrategyImpl::Refresh(void)
  {
   if(IsNewBar())
     {
      //-- mStc
      bool bool1 = mStc.Refresh();
      mEntrySignal = mStc.TradeSignal(InpEntryStrategyOption);
     }
  }

// the expert to run our strategy
CSingleExpert singleExpert(ExpertMagic, 10);

//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+
int OnInit()
  {
//--- set up Position manager Implementaion
   CPositionManager *positionManager = new CNoPositionManager(_Symbol, _Period);
//--- set up Trading Strategy Implementaion
   CStrategyImpl *strategy = new CStrategyImpl(_Symbol, _Period, InpStcPeriod,
         InpFastEmaPeriod, InpSlowEmaPeriod, InpSmoothPeriod, InpObLevel);
   strategy.SetPositionManager(positionManager);
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
