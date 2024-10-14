//+------------------------------------------------------------------+
//|                                  ThomasCarter_07_Daily_MAJOR.mq5 |
//|                                    Copyright 2021, Michael Enudi |
//|                                             okmich2002@yahoo.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2021, Michael Enudi"
#property link      "okmich2002@yahoo.com"
#property version   "1.00"

#include <Okmich\Expert\SingleExpert.mqh>
#include <Okmich\Indicators\DoubleMovingAverages.mqh>
#include <Okmich\Indicators\StochasticOscillator.mqh>

//--- input parameters
const ulong EXPERT_MAGIC = 98765007;
//+------------------------------------------------------------------+
//| Input parameters                                                 |
//+------------------------------------------------------------------+
input group "********* Strategy settings *********";
input ENUM_TIMEFRAMES InpTimeframe = PERIOD_D1;            //Timeframe
input ENUM_LONG_SHORT_FLAG InpLongShortFlag = LONG_SHORT;   //Long/Short Flag

input group "********* Strategy settings *********";

input int      InpShortEmaParam=2;
input int      InpLongEmaParam=5;
input ENUM_MA_TYPE      InpEmaMethod=MA_EMA;

input int      InpStochKParam=5;
input int      InpStochDParam=3;
input int      InpStochSlowingParam=3;
input int      InpStochOBParam=80;
input int      InpStochOSParam=20;

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
input double InpTrailingOrTpMultiple = 4;             // ATR multiple for Maximum floating/Take profit

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
class CStrategyImpl : public CStrategy
  {
private :
   //--- indicator values
   double            mCloseShift1, mFastEMaShift1, mSlowEMaShift1, mStochShift1;

   //--- indicator settings
   int               mFastEmaPeriod, mSlowEmaPeriod;
   int               mStochKPeriod, mStochDPeriod, mStochSmoothingPeriod;
   ENUM_MA_TYPE    mMaMethod;

   //--- indicators
   CDoubleMovingAverages *m_DblMa;
   CStochastic       *mStochastic;
   //--- indicator buffer
   double            m_CloseBuffer[];

public:
                     CStrategyImpl(string symbol, ENUM_TIMEFRAMES period,
                 int InptShortMaPeriod,int InptLongMaPeriod, ENUM_MA_TYPE InptMaMethod,
                 int InptStochKPeriod=5, int InptStochDPeriod=3, int InptStochSmoothing=3): CStrategy(symbol, period)
     {
      mFastEmaPeriod = InptShortMaPeriod;
      mSlowEmaPeriod = InptLongMaPeriod;
      mMaMethod = InptMaMethod;

      mStochKPeriod = InptStochKPeriod;
      mStochDPeriod = InptStochDPeriod;
      mStochSmoothingPeriod = InptStochSmoothing;
     };

   virtual bool      Init(ulong magic);
   virtual Entry     FindEntry(const double ask, const double bid);
   virtual void      Refresh();
   virtual void      CheckAndSetExitSignal(CPositionInfo &positionInfo, Position &position);
   virtual void      Release();
  };

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
bool CStrategyImpl::Init(ulong magic)
  {
//--- m_DblMa
   m_DblMa = new CDoubleMovingAverages(mSymbol, mTimeframe, mFastEmaPeriod, mSlowEmaPeriod, mMaMethod);
//--- mStochastic
   mStochastic = new CStochastic(mSymbol, mTimeframe, mStochKPeriod,
                                 mStochDPeriod, mStochSmoothingPeriod,STO_LOWHIGH,MODE_SMA,
                                 80, 20);

//--- price buffers
   ArraySetAsSeries(m_CloseBuffer, true);

   return mStochastic.Init() && m_DblMa.Init();
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void CStrategyImpl::Release(void)
  {
   mStochastic.Release();
   m_DblMa.Release();
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
      //-- m_DblMa
      m_DblMa.Refresh();
      //-- mStochastic
      mStochastic.Refresh();

      //--- price buffers
      int closeBarsCopied = CopyClose(mSymbol, mTimeframe, 0, barsToCopy, m_CloseBuffer);
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

//   if(mCloseShift1 > mCloseShift1)
//     {
//      bool goLong  = false;
//      ////check macd
//      //if(mMacdShift1 > mMacdSignalShift1)
//      //   return createEntryObject(mSymbol, ask, bid, _Point, mTargetProfit, 0*mTargetProfit, 2, ENTRY_SIGNAL_BUY);
//      //else
//      //   return entry;
//
//     }
//   else
//      if(mCloseShift1 < mCloseShift1)
//        {
//         ////check macd
//         //bool goShort  = false;
//         //if(mMacdShift1 < mMacdSignalShift1)
//         //   return createEntryObject(mSymbol, ask, bid, _Point, mTargetProfit, 0*mTargetProfit, 2, ENTRY_SIGNAL_SELL);
//         //else
//         //   return entry;
//        }

   return entry;
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void CStrategyImpl::CheckAndSetExitSignal(CPositionInfo &positionInfo, Position &position)
  {
   if(!mIsNewBar)
      return;

   ENUM_POSITION_TYPE postType = positionInfo.PositionType();

//if(postType == POSITION_TYPE_SELL)
//  {
//   //bullish macd
//   if(mMacdShift1 > mMacdSignalShift1)
//      position.signal = EXIT_SIGNAL_EXIT;
//  }
//else
//   if(postType == POSITION_TYPE_BUY)
//      //bullish macd
//      if(mMacdShift1 < mMacdSignalShift1)
//         position.signal = EXIT_SIGNAL_EXIT;
  }
//+------------------------------------------------------------------+


// the expert to run our strategy
CSingleExpert singleExpert(EXPERT_MAGIC, "");

//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+
int OnInit()
  {
   CPositionManager *mPositionManager = CreatPositionManager(_Symbol, InpTimeframe,
                                        InpPostManagmentType,
                                        InpATRPeriod, InpStopLossPoints, InpBreakEvenPoints, InpTrailingOrTpPoints,
                                        InpMaxLossAmount, InpScratchBreakEvenFlag, false, 5,
                                        InpStopLossMultiple, InpBreakEvenMultiple, InpTrailingOrTpMultiple);

   CStrategyImpl *strategy = new CStrategyImpl(_Symbol, InpTimeframe,
         InpShortEmaParam,InpLongEmaParam, InpEmaMethod,
         InpStochKParam, InpStochDParam, InpStochSlowingParam);
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
