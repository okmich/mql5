//+------------------------------------------------------------------+
//|                                ThomasCarter_14_4HDaily_MAJOR.mq5 |
//|                                    Copyright 2021, Michael Enudi |
//|                                             okmich2002@yahoo.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2021, Michael Enudi"
#property link      "okmich2002@yahoo.com"
#property version   "1.00"

#include <Okmich\Expert\SingleExpert.mqh>
#include <Okmich\Indicators\DoubleMovingAverages.mqh>
#include <Okmich\Indicators\Macd.mqh>

//--- input parameters
const ulong EXPERT_MAGIC = 987650014;
//+------------------------------------------------------------------+
//| Input parameters                                                 |
//+------------------------------------------------------------------+
input group "********* Strategy settings *********";
input ENUM_TIMEFRAMES InpTimeframe = PERIOD_H4;             //Timeframe
input ENUM_LONG_SHORT_FLAG InpLongShortFlag = LONG_SHORT;   //Long/Short Flag

input group "********* Strategy settings *********";
input int      InpFFastEmaParam=7;
input int      InpFastEmaParam=21;
input int      InpMidEmaParam=84;
input int      InpSlowEmaParam=336;
input ENUM_MA_TYPE      InpEmaMethod=MA_SMA;

input int      InpFastMACDParam=12;
input int      InpSlowMACDParam=26;
input int      InpSignalMACDParam=9;

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
   ENUM_MA_TYPE      mMaMethod;
   int               mFFastMaPeriod, mFastMaPeriod, mMidMaPeriod, mSlowMaPeriod;
   int               m_MacdShortEmaPeriod, m_MacdLongEmaPeriod, m_MacdSignalPeriod;

   //--- indicators
   CMacd                 *m_Macd;
   CDoubleMovingAverages *m_FastDblMa;
   CDoubleMovingAverages *m_SlowDblMa;
   //--- indicator buffer
   double            m_CloseBuffer[];

protected:
   virtual Entry     FindEntry(const double ask, const double bid);

public:
                     CStrategyImpl(string symbol, ENUM_TIMEFRAMES period, int InptVolMultiple,
                 int InptMa1, int InptMa2, int InptMa3, int InptMa4, ENUM_MA_TYPE InptMaMethod,
                 int InptMacdShort, int InptMacdLong, int InptMacdSignal): CStrategy(symbol, period)
     {
      mLotSize = InptVolMultiple*SymbolInfoDouble(_Symbol, SYMBOL_VOLUME_MIN);

      mMaMethod = InptMaMethod;
      
      mFFastMaPeriod = InptMa1;
      mFastMaPeriod = InptMa2;
      mMidMaPeriod = InptMa3;
      mSlowMaPeriod = InptMa4;

      m_MacdShortEmaPeriod = InptMacdShort;
      m_MacdLongEmaPeriod = InptMacdLong;
      m_MacdSignalPeriod = InptMacdSignal;
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
   m_FastDblMa = new CDoubleMovingAverages(mSymbol, mTimeframe, mFFastMaPeriod, mFastMaPeriod, mMaMethod);
   m_SlowDblMa = new CDoubleMovingAverages(mSymbol, mTimeframe, mMidMaPeriod, mSlowMaPeriod, mMaMethod);
//--- m_Macd
   m_Macd = new CMacd(mSymbol, mTimeframe, m_MacdShortEmaPeriod, m_MacdLongEmaPeriod, m_MacdSignalPeriod);

//--- price buffers
   ArraySetAsSeries(m_CloseBuffer, true);

   return m_FastDblMa.Init() && m_SlowDblMa.Init() && m_Macd.Init();
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void CStrategyImpl::Release(void)
  {
   m_FastDblMa.Release();
   delete m_FastDblMa;
   m_SlowDblMa.Release();
   delete m_SlowDblMa;
   m_Macd.Release();
   delete m_Macd;
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
      m_FastDblMa.Refresh();
      m_SlowDblMa.Refresh();
      //-- m_Macd
      m_Macd.Refresh();
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
//      //if(m_MacdShift1 > m_MacdSignalShift1)
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
//         //if(m_MacdShift1 < m_MacdSignalShift1)
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

// the expert to run our strategy
CSingleExpert singleExpert(EXPERT_MAGIC, "");

//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+
int OnInit()
  {
   CStrategy *strategy = new CStrategyImpl(_Symbol, InpTimeframe, InpLotSizeMultiple,
                                           InpFFastEmaParam, InpFastEmaParam, InpMidEmaParam, InpSlowEmaParam, InpEmaMethod,
                                           InpFastMACDParam, InpSlowMACDParam, InpSignalMACDParam);
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
