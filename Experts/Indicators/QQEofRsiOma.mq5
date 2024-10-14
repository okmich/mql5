//+------------------------------------------------------------------+
//|                                                  QQEofRsiOma.mq5 |
//|                                    Copyright 2022, Michael Enudi |
//|                                             okmich2002@yahoo.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2022, Michael Enudi"
#property link      "okmich2002@yahoo.com"
#property version   "1.00"

#include <Okmich\Expert\SingleExpert.mqh>
#include <Okmich\Indicators\QQEofRsiOma.mqh>

//--- input parameters
input group "********* Setting **********";
input ENUM_TIMEFRAMES InpTimeframe = PERIOD_H1;             //Timeframe
input ENUM_LONG_SHORT_FLAG InpLongShortFlag = LONG;   //Long/Short Flag

input group "********* Indicator settings *********";
input ENUM_QQEofRsiOma_Strategies InpSignalType = QQERsiOma_FastSlowCrossover; //Entry logic type
input int      InpRsiPeriod=14;
input int      InpAvgPeriod=32;
input ENUM_MA_METHOD      InpAvgMethod=MODE_EMA;
input int      InpSmoothingFactor=5;
input double   InpFastPeriod=2.618;
input double   InpSlowPeriod=4.236;

input group "********* Trade Size settings *********";
input int   InpTradeVolMultiple = 1;               // Minimum Lot size multiple

input group "********* Other Settings *********";
input ulong    ExpertMagic           = 980023;              //Expert MagicNumbers


input group "********* Position management settings *********";
input ENUM_POSITION_MANAGEMENT InpPostManagmentType = POSITION_MGT_NONE;  // Type of Position Management Algorithm
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
   ENUM_ENTRY_SIGNAL signal;
   //--- indicator settings
   int               mRsiPeriod, mAvgPeriod, mSmoothingFactor;
   ENUM_MA_METHOD    mAvgMethod;
   double            mFastPeriod, mSlowPeriod;
   //--- indicators
   CQQERsiOma        *m_QqeRsiOma;
   //--- indicator buffer
   //-- others

public:
                     CStrategyImpl(string symbol, ENUM_TIMEFRAMES period,
                 int InptRsiPeriod, int InptAvgPeriod, int InptSmoothFactor,
                 ENUM_MA_METHOD InptAvgMethod, double InptFastPeriod, double InptSlowPeriod): CStrategy(symbol, period)
     {
      mRsiPeriod = InptRsiPeriod;
      mAvgPeriod = InptAvgPeriod;
      mAvgMethod = InptAvgMethod;
      mSmoothingFactor = InptSmoothFactor;
      mFastPeriod = InptFastPeriod;
      mSlowPeriod = InptSlowPeriod;

      mLotSize = InpTradeVolMultiple*SymbolInfoDouble(_Symbol, SYMBOL_VOLUME_MIN);
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
//--- m_QqeRsiOma
   m_QqeRsiOma = new CQQERsiOma(mSymbol, mTimeframe, mRsiPeriod, mAvgPeriod, mAvgMethod,
                                mSmoothingFactor, mFastPeriod, mSlowPeriod);
   return m_QqeRsiOma.Init();
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void CStrategyImpl::Release(void)
  {
   m_QqeRsiOma.Release();
   delete m_QqeRsiOma;
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void CStrategyImpl::CheckAndSetExitSignal(CPositionInfo &positionInfo, Position &position)
  {
   ENUM_POSITION_TYPE posType = positionInfo.PositionType();
   if(posType == POSITION_TYPE_BUY && signal == ENTRY_SIGNAL_SELL)
     {
      position.signal = EXIT_SIGNAL_EXIT;
     }
   else
      if(posType == POSITION_TYPE_SELL && signal == ENTRY_SIGNAL_BUY)
        {
         position.signal = EXIT_SIGNAL_EXIT;
        }
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void CStrategyImpl::Refresh(void)
  {
   if(IsNewBar())
     {
      m_QqeRsiOma.Refresh();

      //--- take values from indicator
      signal = m_QqeRsiOma.TradeSignal(InpSignalType);
      mEntrySignal = SupportShortEntries(InpLongShortFlag) && signal == ENTRY_SIGNAL_SELL ? signal :
                     SupportLongEntries(InpLongShortFlag) && signal == ENTRY_SIGNAL_BUY ? signal : ENTRY_SIGNAL_NONE;
     }
  }

// the expert to run our strategy
CSingleExpert singleExpert(ExpertMagic, "QQEofRSIOma");

//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+
int OnInit()
  {
   CStrategyImpl *strategy =
      new CStrategyImpl(_Symbol, InpTimeframe, InpRsiPeriod, InpAvgPeriod, InpSmoothingFactor, InpAvgMethod,
                        InpFastPeriod, InpSlowPeriod);

   CPositionManager *mPositionManager = CreatPositionManager(_Symbol, InpTimeframe,
                                        InpPostManagmentType,
                                        InpATRPeriod, InpStopLossPoints, InpBreakEvenPoints, InpTrailingOrTpPoints,
                                        InpMaxLossAmount, InpScratchBreakEvenFlag, false, 5,
                                        InpStopLossMultiple, InpBreakEvenMultiple, InpTrailingOrTpMultiple);
   strategy.SetPositionManager(mPositionManager);

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
