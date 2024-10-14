//+------------------------------------------------------------------+
//|                                MovingAverageRsiDslFilter.mq5.mq5 |
//|                                    Copyright 2021, Michael Enudi |
//|                                             okmich2002@yahoo.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2021, Michael Enudi"
#property link      "okmich2002@yahoo.com"
#property version   "1.00"

#include <Okmich\Expert\SingleExpert.mqh>
#include <Okmich\Indicators\DslRsiofAverage.mqh>

input group "********* Strategy settings *********";
input ENUM_TIMEFRAMES InpTimeframe = PERIOD_H1;             //Timeframe
input ENUM_LONG_SHORT_FLAG InpLongShortFlag = LONG_SHORT;   //Long/Short Flag


input group "********* Indicator settings *********";
input ENUM_RSIMA_Strategies  InpHowSignal = RSIMA_AboveBelowMidLevelFilter;                    //Signal Type
input int    InpRsiPeriod = 14;                          //RSI period
input int    InpMaPeriod  = 32;                          //Moving average period
input int    InpDslSignalPeriod  = 9;                    //DSL Signal period
input bool   InpUseFloatingLevels  = true;               //Use floating levels
input ENUM_MA_METHOD    InpSmoothingMethod  = MODE_EMA;  //Smoothing Method
input double    InpOverboughtLevel = 80.00;              //OB level
input double    InpOversoldLevel = 20.00;                //OS level

input int   InpLotSizeMultiple = 1;                      //Lot size multiple
input ulong    ExpertMagic = 980023;                     //Expert MagicNumbers


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
class CFilter : public CStrategy
  {
private :
   //--- indicator values
   ENUM_ENTRY_SIGNAL signal;
   //--- indicator settings
   int                m_RsiPeriod, m_MaPeriod, m_DslSignalPeriod;
   ENUM_MA_METHOD     m_SmoothingMethod;
   bool               m_FloatingLevels;
   //--- indicators
   CDslRsiOfAverage   *mMaRSI;
   //--- indicator buffer
   double            m_CloseBuffer[];
   //-- others


public:
                     CFilter(string symbol, ENUM_TIMEFRAMES period, int InptRsiPeriod=14,
           int InptMaPeriod=32, ENUM_MA_METHOD InptSmoothMethod = MODE_EMA,
           int InptDslSignal = 9, bool useFloatinglevels=true): CStrategy(symbol, period)
     {
      m_RsiPeriod = InptRsiPeriod;
      m_MaPeriod = InptMaPeriod;
      m_SmoothingMethod = InptSmoothMethod;
      m_DslSignalPeriod = InptDslSignal;
      m_FloatingLevels = useFloatinglevels;

      mLotSize = InpLotSizeMultiple * SymbolInfoDouble(_Symbol, SYMBOL_VOLUME_MIN);
     };

   virtual bool      Init(ulong magic);

   virtual void      Refresh();
   virtual void      CheckAndSetExitSignal(CPositionInfo &positionInfo, Position &position);
   virtual void      Release();
  };

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
bool CFilter::Init(ulong magic)
  {
   CStrategy::Init(magic);
//--- mMaRSI
   mMaRSI = new CDslRsiOfAverage(mSymbol, mTimeframe, m_RsiPeriod, m_MaPeriod, m_SmoothingMethod,PRICE_CLOSE,
                                 m_DslSignalPeriod, m_FloatingLevels, InpOverboughtLevel, InpOversoldLevel);
   return mMaRSI.Init();
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void CFilter::Release(void)
  {
   mMaRSI.Release();
   delete mMaRSI;
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void CFilter::CheckAndSetExitSignal(CPositionInfo &positionInfo, Position &position)
  {
   ENUM_POSITION_TYPE posType = positionInfo.PositionType();
   if(posType == POSITION_TYPE_BUY && signal != ENTRY_SIGNAL_BUY)
     {
      position.signal = EXIT_SIGNAL_EXIT;
     }
   else
      if(posType == POSITION_TYPE_SELL && signal != ENTRY_SIGNAL_SELL)
        {
         position.signal = EXIT_SIGNAL_EXIT;
        }
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void CFilter::Refresh(void)
  {
   if(IsNewBar())
     {
      //-- mMaRSI
      bool bool1 = mMaRSI.Refresh(mRefShift);
      signal = mMaRSI.TradeSignal(InpHowSignal);
      mEntrySignal = SupportShortEntries(InpLongShortFlag) && signal == ENTRY_SIGNAL_SELL ? signal :
                     SupportLongEntries(InpLongShortFlag) && signal == ENTRY_SIGNAL_BUY ? signal : ENTRY_SIGNAL_NONE;
     }
  }

// the expert to run our strategy
CSingleExpert singleExpert(ExpertMagic, "DSL_RSI_OF_MA");

//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+
int OnInit()
  {
   CFilter *strategy = new CFilter(_Symbol, InpTimeframe, InpRsiPeriod, InpMaPeriod, InpSmoothingMethod,
                                   InpDslSignalPeriod, InpUseFloatingLevels);
//set position management
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
