//+------------------------------------------------------------------+
//|                                    Price Momentum Oscillator.mq5 |
//|                                    Copyright 2021, Michael Enudi |
//|                                             okmich2002@yahoo.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2021, Michael Enudi"
#property link      "okmich2002@yahoo.com"
#property version   "1.00"

#include <Okmich\Expert\SingleExpert.mqh>
#include <Okmich\Indicators\PriceMomentumOscillator.mqh>

//--- input parameters
input group "********* Strategy settings *********";
input ENUM_TIMEFRAMES InpTimeframe = PERIOD_H1;             //Timeframe
input ENUM_LONG_SHORT_FLAG InpLongShortFlag = LONG_SHORT;   //Long/Short Flag

input group "********* Indicator settings *********";
input ENUM_PMO_Strategies    InpStrategy = PMO_Strategies_Crossover;
input int    InpPeriod = 35;
input int    InpPeriod2 = 20;
input int    InpSignalPeriod = 10;
input int    InpSlopePeriod = 3;
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
class CStrategyImpl : public CStrategy
  {
private :
   //--- indicator values
   ENUM_ENTRY_SIGNAL signal;
   //--- indicator settings
   int               mPeriod, mPeriod2, mSignalPeriod, mSlopePeriod;
   //--- indicators
   CPriceMomentumOscillator            *mPmo;
   //--- indicator buffer
   //-- others


public:
                     CStrategyImpl(string symbol, ENUM_TIMEFRAMES period,
                 int InptPeriod=35, int InptPeriod2=20,
                 int InptSignal=10,  int InptSlopePeriod=3): CStrategy(symbol, period)
     {
      mPeriod = InptPeriod;
      mPeriod2 = InptPeriod2;
      mSignalPeriod = InptSignal;
      mSlopePeriod = InptSlopePeriod;

      mLotSize = InpLotSizeMultiple*SymbolInfoDouble(_Symbol, SYMBOL_VOLUME_MIN);
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
//--- mPmo
   mPmo = new CPriceMomentumOscillator(mSymbol, mTimeframe, mPeriod, mPeriod2,
                                       mSignalPeriod, mSlopePeriod);
   return mPmo.Init();
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void CStrategyImpl::Release(void)
  {
   mPmo.Release();
   delete mPmo;
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
      //--- mPmo
      mPmo.Refresh(mRefShift);
      signal = mPmo.TradeSignal(InpStrategy);
      mEntrySignal = SupportShortEntries(InpLongShortFlag) && signal == ENTRY_SIGNAL_SELL ? signal :
                     SupportLongEntries(InpLongShortFlag) && signal == ENTRY_SIGNAL_BUY ? signal : ENTRY_SIGNAL_NONE;
     }
  }

// the expert to run our strategy
CSingleExpert singleExpert(ExpertMagic, "Price Momentum Oscillator");

//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+
int OnInit()
  {
   CStrategyImpl *strategy =
      new CStrategyImpl(_Symbol, InpTimeframe, InpPeriod, InpPeriod2, InpSignalPeriod, InpSlopePeriod);

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
