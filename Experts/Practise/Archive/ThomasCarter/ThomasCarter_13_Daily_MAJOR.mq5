//+------------------------------------------------------------------+
//|                                  ThomasCarter_13_Daily_MAJOR.mq5 |
//|                                    Copyright 2021, Michael Enudi |
//|                                             okmich2002@yahoo.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2021, Michael Enudi"
#property link      "okmich2002@yahoo.com"
#property version   "1.00"

#include <Okmich\Expert\SingleExpert.mqh>
#include <Okmich\Indicators\MovingAverage.mqh>
#include <Okmich\Indicators\RSI.mqh>
#include <Okmich\Indicators\StochasticOscillator.mqh>
#include <Indicators\Trend.mqh>

//--- input parameters
const ulong EXPERT_MAGIC = 987650013;
//+------------------------------------------------------------------+
//| Input parameters                                                 |
//+------------------------------------------------------------------+
input group "********* Strategy settings *********";
input ENUM_TIMEFRAMES InpTimeframe = PERIOD_D1;             //Timeframe
input ENUM_LONG_SHORT_FLAG InpLongShortFlag = LONG_SHORT;   //Long/Short Flag

input group "********* Strategy settings *********";
input int             InpMaPeriod          = 150;                 //MA Period
input ENUM_MA_TYPE InpMaMethod = MA_SMA; // MA Method
input int      InpRSIParam=3;
input int      InpRSIOBParam=80;
input int      InpRSIOSParam=20;

input int      InpStochKParam=8;
input int      InpStochDParam=3;
input int      InpStochSlowingParam=3;
input int      InpStochOBParam=70;
input int      InpStochOSParam=30;

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

   //--- indicator settings
   int               mMaPeriod, mRsiPeriod;
   ENUM_MA_TYPE      mMaMethod;
   int               mStochKPeriod, mStochDPeriod, mStochSmoothingPeriod;

   //--- indicators
   CMa               *mMa;
   CRsi              *mRsi;
   CStochastic       *mStochastic;
   //--- indicator buffer
   double            m_CloseBuffer[];

protected:
   virtual Entry     FindEntry(const double ask, const double bid);

public:
                     CStrategyImpl(string symbol, ENUM_TIMEFRAMES period, int InptVolMultiple,
                 int InptMaPeriod, ENUM_MA_TYPE InptMaMethod, int InptRsiPeriod,
                 int InptStochKPeriod=8, int InptStochDPeriod=3, int InptStochSmoothing=3,
                 double InptRrRatio = 3): CStrategy(symbol, period)
     {
      mLotSize = InptVolMultiple*SymbolInfoDouble(_Symbol, SYMBOL_VOLUME_MIN);

      mMaPeriod = InptMaPeriod;
      mMaMethod = InptMaMethod;

      mRsiPeriod = InptRsiPeriod;

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
//--- mMa
   mMa = new CMa(mSymbol, mTimeframe, mMaPeriod, mMaMethod, PRICE_CLOSE);
//--- mRsi
   mRsi = new CRsi(mSymbol, mTimeframe, mRsiPeriod, InpRSIOBParam, InpRSIOSParam);
//--- mStochastic
   mStochastic = new CStochastic(mSymbol, mTimeframe, mStochKPeriod,
                                 mStochDPeriod, mStochSmoothingPeriod,STO_LOWHIGH, MODE_SMA,
                                 InpStochOBParam, InpStochOSParam);

//--- price buffers
   ArraySetAsSeries(m_CloseBuffer, true);

   return mRsi.Init() && mStochastic.Init() && mMa.Init();
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void CStrategyImpl::Release(void)
  {
   mMa.Release();
   delete mMa;
   mRsi.Release();
   delete mRsi;
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
      //-- mMa
      mMa.Refresh();
      //-- mRsi
      mRsi.Refresh();
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

// the expert to run our strategy
CSingleExpert singleExpert(EXPERT_MAGIC, "");
//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+
int OnInit()
  {
   CStrategy *strategy = new CStrategyImpl(_Symbol, InpTimeframe, InpLotSizeMultiple,
                                 InpMaPeriod, InpMaMethod, InpRSIParam,
                                InpStochKParam, InpStochDParam, InpStochSlowingParam);
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
