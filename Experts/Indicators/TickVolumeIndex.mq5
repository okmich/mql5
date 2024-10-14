//+------------------------------------------------------------------+
//|                                                     FilterEA.mq5 |
//|                                    Copyright 2021, Michael Enudi |
//|                                             okmich2002@yahoo.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2021, Michael Enudi"
#property link      "okmich2002@yahoo.com"
#property version   "1.00"

#include <Okmich\Expert\SingleExpert.mqh>
#include <Okmich\Indicators\TickVolumeMomentumIndex.mqh>

//--- input parameters
input group "********* Strategy settings *********";
input ENUM_TIMEFRAMES InpTimeframe = PERIOD_H1;             //Timeframe
input ENUM_LONG_SHORT_FLAG InpLongShortFlag = LONG_SHORT;   //Long/Short Flag

input group "********* Indicator settings *********";
input ENUM_TVI_Strategies InpHowTo = TVI_AboveBelowSignal;
input int    InpTviPeriod = 13;
input int    InpTviSmooth1 = 25;
input int    InpTviSmooth2 = 5;
input int    InpTviSignal = 5;
input ulong    ExpertMagic           = 980023;              //Expert MagicNumbers

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
class CFilter : public CStrategy
  {
private :
   //--- indicator values
   ENUM_ENTRY_SIGNAL signal;
   double            mCloseShift1, mMaShift1;
   //--- indicator settings
   int               mTviPeriod, mTviSmooth1, mTviSmooth2, mTviSignalPeriod;

   //--- indicators
   CTvi              *mTvi;
   //--- indicator buffer
   //-- others


public:
                     CFilter(string symbol, ENUM_TIMEFRAMES period,
           int InptTviPeriod=13, int InptTviSmooth1=25,
           int InptTviSmooth2=2,  int InptTviSignal=5): CStrategy(symbol, period)
     {
      mTviPeriod = InptTviPeriod;
      mTviSmooth1 = InptTviSmooth1;
      mTviSmooth2 = InptTviSmooth2;
      mTviSignalPeriod = InptTviSignal;

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
bool CFilter::Init(ulong magic)
  {
   CStrategy::Init(magic);
//--- mTvi
   mTvi = new CTvi(mSymbol, mTimeframe, mTviPeriod, mTviSmooth1, mTviSignalPeriod);

   return mTvi.Init();
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void CFilter::Release(void)
  {
   mTvi.Release();
   delete mTvi;
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void CFilter::CheckAndSetExitSignal(CPositionInfo &positionInfo, Position &position)
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
void CFilter::Refresh(void)
  {
   if(IsNewBar())
     {
      //--- mTvi
      mTvi.Refresh();
      signal = mTvi.TradeFilter(InpHowTo);
      mEntrySignal = SupportShortEntries(InpLongShortFlag) && signal == ENTRY_SIGNAL_SELL ? signal :
                     SupportLongEntries(InpLongShortFlag) && signal == ENTRY_SIGNAL_BUY ? signal : ENTRY_SIGNAL_NONE;
     }
  }

// the expert to run our strategy
CSingleExpert singleExpert(ExpertMagic, "Tick Volume Indicator");

//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+
int OnInit()
  {
   CFilter *strategy = new CFilter(_Symbol, InpTimeframe, InpTviPeriod, InpTviSmooth1, InpTviSmooth2,
                                   InpTviSignal);

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
