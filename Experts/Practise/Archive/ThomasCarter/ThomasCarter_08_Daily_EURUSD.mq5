//+------------------------------------------------------------------+
//|                                 ThomasCarter_08_Daily_EURUSD.mq5 |
//|                                    Copyright 2021, Michael Enudi |
//|                                             okmich2002@yahoo.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2021, Michael Enudi"
#property link      "okmich2002@yahoo.com"
#property version   "1.00"

#include <Okmich\Expert\SingleExpert.mqh>
#include <Okmich\Indicators\ADXWilder.mqh>
#include <Okmich\Indicators\DoubleMovingAverages.mqh>

//--- input parameters
const ulong EXPERT_MAGIC = 98765008;
//+------------------------------------------------------------------+
//| Input parameters                                                 |
//+------------------------------------------------------------------+
input group "********* Strategy settings *********";
input ENUM_TIMEFRAMES InpTimeframe = PERIOD_D1;             //Timeframe
input ENUM_LONG_SHORT_FLAG InpLongShortFlag = LONG_SHORT;   //Long/Short Flag

input group "********* Strategy settings *********";
input int      InpShortMaPeriod      = 4;                 //Short MA Period
input int      InpLongMaPeriod       = 11;                 //Long MA Period
input ENUM_MA_TYPE   InpMaType       = MA_EMA;            //MA Method

input int      InpDmiPeriod          = 14;                 //DMI Period
input int      InpAdxPeriod          = 14;                 //ADX Period
input double   InpSignfSlope         = 2.0;                //ADX Significant Slope
input double   InpTrendLevel         = 25;                 //Trend Level
input double   InpRangeLevel         = 20;                 //Range Level

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
   int               mDmiPeriod, mADXPeriod;
   double            mAdxTrendThreshold, mAdxSignSlope;
   int               mFastEmaPeriod, mSlowEmaPeriod;
   ENUM_MA_TYPE      mMaType;

   //--- indicators
   CADXWilder        *m_Adx;
   CDoubleMovingAverages *m_DblMa;
   //--- indicator buffer
   double            m_CloseBuffer[];

protected:
   virtual Entry     FindEntry(const double ask, const double bid);

public:
                     CStrategyImpl(string symbol, ENUM_TIMEFRAMES period,
                 int InptShortMa, int InptLongMa, ENUM_MA_TYPE InptMaMethod,
                 int InptDmiPeriod=14, int InptAdxPeriod=14, double InptAdxSlopeLevel=2.0,
                 double InptTrendThresh=25.0): CStrategy(symbol, period)
     {
      mFastEmaPeriod = InptShortMa;
      mSlowEmaPeriod = InptLongMa;
      mMaType = InptMaMethod;

      mADXPeriod = InptAdxPeriod;
      mDmiPeriod = InptDmiPeriod;
      mAdxSignSlope = InptAdxSlopeLevel;
      mAdxTrendThreshold = InptTrendThresh;
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
//--- m_DblMa
   m_DblMa = new CDoubleMovingAverages(mSymbol, mTimeframe, mFastEmaPeriod, mSlowEmaPeriod, mMaType);
//--- m_Adx
   m_Adx = new CADXWilder(mSymbol, mTimeframe, mDmiPeriod, mADXPeriod, mAdxSignSlope, mAdxTrendThreshold);

//--- price buffers
   ArraySetAsSeries(m_CloseBuffer, true);

   return m_Adx.Init() && m_DblMa.Init();
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void CStrategyImpl::Release(void)
  {
   m_DblMa.Release();
   delete m_DblMa;
   m_Adx.Release();
   delete m_Adx;
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
      //-- m_Adx
      m_Adx.Refresh();

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
void CStrategyImpl::CheckAndSetExitSignal(CPositionInfo &positionInfo,Position &position)
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
   CStrategy *strategy = new CStrategyImpl(_Symbol, InpTimeframe,
                                           InpShortMaPeriod, InpLongMaPeriod, InpMaType,
                                           InpDmiPeriod, InpAdxPeriod, InpSignfSlope);
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
