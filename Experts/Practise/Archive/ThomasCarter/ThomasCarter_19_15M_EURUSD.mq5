//+------------------------------------------------------------------+
//|                                   ThomasCarter_19_15M_EURUSD.mq5 |
//|                                    Copyright 2021, Michael Enudi |
//|                                             okmich2002@yahoo.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2021, Michael Enudi"
#property link      "okmich2002@yahoo.com"
#property version   "1.00"

#include <Okmich\Expert\SingleExpert.mqh>
#include <Okmich\Indicators\MovingAverage.mqh>
#include <Okmich\Indicators\SchaffTrendCycle.mqh>
#include <Okmich\Indicators\StochasticOscillator.mqh>

//--- input parameters
const ulong EXPERT_MAGIC = 987650019;
//+------------------------------------------------------------------+
//| Input parameters                                                 |
//+------------------------------------------------------------------+
input group "********* Strategy settings *********";
input ENUM_TIMEFRAMES InpTimeframe = PERIOD_H4;             //Timeframe
input ENUM_LONG_SHORT_FLAG InpLongShortFlag = LONG_SHORT;   //Long/Short Flag

input group "********* Strategy settings *********";
input int      InpMaPeriod          = 100;                        //MA Period
input ENUM_MA_TYPE      InpEmaMethod=MA_SMA;                   //SMoothing method

input int    InpStcPeriod = 14;                      //Schaff Trend Cycle period
input int    InpFastEmaPeriod = 14;                  //Schaff Trend Cycle Fast Ma period
input int    InpSlowEmaPeriod = 14;                  //Schaff Trend Cycle Slow Ma period
input int    InpSmoothPeriod = 14;                   //Schaff Trend Cycle Smoothing period

input int      InpStochKParam=21;
input int      InpStochDParam=9;
input int      InpStochSlowingParam=9;
input int      InpStochOBParam=80;
input int      InpStochOSParam=20;

input group "********* Volume setting **********";
input int InpLotSizeMultiple = 1;                     //Multiple of minimum lot size

input group "********* Position management settings *********";
input ENUM_POSITION_MANAGEMENT InpPostManagmentType = POSITION_MGT_FIXED_ATR_MULTIPLES;  // Type of Position Management Algorithm
input int InpATRPeriod = 14;                          // ATR Period
input double InpStopLossPoints = -1;                  // Stop loss distance in points
input double InpBreakEvenPoints = -1;                 // Points to Break-even
input double InpTrailingOrTpPoints = -1;              // Trailing/Take profit points
input double InpMaxLossAmount = 100.00;               // Maximum allowable loss in dollars
input bool InpScratchBreakEvenFlag = true;            // Enable break-even with scratch profit
input double InpStopLossMultiple = 2;                 // ATR multiple for stop loss
input double InpBreakEvenMultiple = 1;                // ATR multiple for break-even
input double InpTrailingOrTpMultiple = 2;             // ATR multiple for Maximum floating/Take profit


//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
class CStrategyImpl : public CStrategy
  {
private :
   //--- indicator values
   double            mCloseShift1;

   //--- indicator settings
   ENUM_MA_TYPE      mMaMethod;
   int               mMaPeriod;
   int               mStochKPeriod, mStochDPeriod, mStochSmoothingPeriod;
   int               mStcPeriod, mStcFastEmaPeriod, mStcSlowEmaPeriod, mStcSmoothingPeriod;

   //--- indicators
   CMa               *m_Ma;
   CSchaffTrendCycle *mStc;
   CStochastic       *mStochastic;
   //--- indicator buffer
   double            m_CloseBuffer[];

protected:
   virtual Entry     FindEntry(const double ask, const double bid);

public:
                     CStrategyImpl(string symbol, ENUM_TIMEFRAMES period, int InptVolMultiple,
                 int InptMaPeriod, ENUM_MA_TYPE InptMaMethod,
                 int InptStochKPeriod=8, int InptStochDPeriod=3, int InptStochSmoothing=3,
                 int InptStcPeriod=32, int InptStcFastEma=23, int InptStcSlowEma=50, int InptStcSmoothing=3): CStrategy(symbol, period)
     {
      mLotSize = InptVolMultiple*SymbolInfoDouble(_Symbol, SYMBOL_VOLUME_MIN);

      mMaPeriod = InptMaPeriod;
      mMaMethod = InptMaMethod;

      mStcPeriod = InptStcPeriod;
      mStcFastEmaPeriod = InptStcFastEma;
      mStcSlowEmaPeriod = InptStcSlowEma;
      mStcSmoothingPeriod = InptStcSmoothing;

      mStochKPeriod = InptStochKPeriod;
      mStochDPeriod = InptStochDPeriod;
      mStochSmoothingPeriod = InptStochSmoothing;
     };

   virtual bool      Init(ulong magic);
   virtual void      CheckAndSetExitSignal(CPositionInfo &positionInfo, Position &position);
   virtual void      Refresh();
   virtual void      Release();
  };

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
bool CStrategyImpl::Init(ulong magic)
  {
//--- m_Ma
   m_Ma = new CMa(mSymbol, mTimeframe, mMaPeriod, mMaMethod, PRICE_CLOSE);
//--- mStochastic
   mStochastic = new CStochastic(mSymbol, mTimeframe, mStochKPeriod,
                                 mStochDPeriod, mStochSmoothingPeriod,STO_LOWHIGH,MODE_SMA,
                                 80, 20);
//--- mStc
   mStc = new CSchaffTrendCycle(mSymbol, mTimeframe, mStcPeriod, mStcFastEmaPeriod,
                                mStcSlowEmaPeriod, mStcSmoothingPeriod);
//--- price buffers
   ArraySetAsSeries(m_CloseBuffer, true);

   return mStc.Init() && mStochastic.Init() && m_Ma.Init();
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void CStrategyImpl::Release(void)
  {
   m_Ma.Release();
   delete m_Ma;
   mStc.Release();
   delete mStc;
   mStochastic.Release();
   delete mStochastic;
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void CStrategyImpl::Refresh(void)
  {
   int barsToCopy = 4;
//--- Check for new bar
   if(IsNewBar())
     {
      //-- m_Ma
      m_Ma.Refresh();
      //-- mStc
      mStc.Refresh();
      //-- mStochastic
      mStochastic.Refresh();
     }
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
Entry CStrategyImpl::FindEntry(const double ask, const double bid)
  {
   Entry entry = noEntry();

   if(!mIsNewBar)
      return entry;

   return entry;
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void CStrategyImpl::CheckAndSetExitSignal(CPositionInfo &positionInfo,Position &position)
  {
   if(!mIsNewBar)
      return;

   ENUM_POSITION_TYPE postType = positionInfo.PositionType();
  }

// the expert to run our strategy
CSingleExpert singleExpert(EXPERT_MAGIC, "");

//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+
int OnInit()
  {
   CStrategy *strategy = new CStrategyImpl(_Symbol, InpTimeframe, InpLotSizeMultiple, InpMaPeriod, InpEmaMethod,
                                InpStochKParam, InpStochDParam, InpStochSlowingParam,
                                InpStcPeriod, InpFastEmaPeriod, InpSlowEmaPeriod, InpSlowEmaPeriod);
   CPositionManager *mPositionManager = CreatPositionManager(_Symbol, InpTimeframe,
                                        InpPostManagmentType,
                                        InpATRPeriod, InpStopLossPoints, InpBreakEvenPoints, InpTrailingOrTpPoints,
                                        InpMaxLossAmount, InpScratchBreakEvenFlag, false, 5,
                                        InpStopLossMultiple, InpBreakEvenMultiple, InpTrailingOrTpMultiple);
   strategy.SetPositionManager(mPositionManager);

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
   singleExpert.OnTickHandler();
  }
//+------------------------------------------------------------------+
