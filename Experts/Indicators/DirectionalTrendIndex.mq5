//+------------------------------------------------------------------+
//|                                                     FilterEA.mq5 |
//|                                    Copyright 2021, Michael Enudi |
//|                                             okmich2002@yahoo.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2021, Michael Enudi"
#property link      "okmich2002@yahoo.com"
#property version   "1.00"

#include <Okmich\Expert\SingleExpert.mqh>
#include <Okmich\Indicators\DirectionalTrendIndex.mqh>

//--- input parameters
input group "********* Strategy settings *********";
input ENUM_TIMEFRAMES InpTimeframe = PERIOD_H1;             //Timeframe
input ENUM_LONG_SHORT_FLAG InpLongShortFlag = LONG_SHORT;   //Long/Short Flag

input group "********* Indicator settings *********";
input ENUM_DTI_Strategies InpHowTo = DTI_DirectionAboveBelowZero; //Entry strategy
input int  InpDtiPeriod = 20;    //DTI Period
input int  InpDtiSmoothing = 20; //DTI Smoothing
input bool InpDSLAnchor = true;
input int  InpDtiSignal = 9;
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
   //--- indicator settings
   int               mDtiPeriod, mDtiSmoothing, mDtiSignal;
   bool              mDtiDslAnchor;

   //--- indicators
   CDti              *mDti;
   //--- indicator buffer
   double            m_CloseBuffer[];
   //-- others


public:
                     CFilter(string symbol, ENUM_TIMEFRAMES period,
           int InptDti, int InptDtiSmoothing, int InptDtiSignal,
           bool InptUseAnchor): CStrategy(symbol, period)
     {
      mDtiPeriod = InptDti;
      mDtiSmoothing = InptDtiSmoothing;
      mDtiSignal = InptDtiSignal;
      mDtiDslAnchor = InptUseAnchor;

      mLotSize = 1*SymbolInfoDouble(_Symbol, SYMBOL_VOLUME_MIN);
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
//--- price buffers
   ArraySetAsSeries(m_CloseBuffer, true);
   mDti = new CDti(mSymbol, mTimeframe, mDtiPeriod, mDtiSmoothing, mDtiSignal, mDtiDslAnchor, 6);

   return mDti.Init();
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void CFilter::Release(void)
  {
   mDti.Release();
   delete mDti;
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void CFilter::Refresh(void)
  {
   if(IsNewBar())
     {
      mDti.Refresh(mRefShift);
      signal = mDti.TradeFilter(InpHowTo);
      mEntrySignal = SupportShortEntries(InpLongShortFlag) && signal == ENTRY_SIGNAL_SELL ? signal :
                     SupportLongEntries(InpLongShortFlag) && signal == ENTRY_SIGNAL_BUY ? signal : ENTRY_SIGNAL_NONE;
     }
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void CFilter::CheckAndSetExitSignal(CPositionInfo &positionInfo, Position &position)
  {
   ENUM_POSITION_TYPE posType = positionInfo.PositionType();
//check for exits and modifications
   if(posType == POSITION_TYPE_BUY && signal == ENTRY_SIGNAL_SELL)
      position.signal = EXIT_SIGNAL_EXIT;

//check for exits and modifications
   if(posType == POSITION_TYPE_SELL && signal == ENTRY_SIGNAL_BUY)
      position.signal = EXIT_SIGNAL_EXIT;
  }

// the expert to run our strategy
CSingleExpert singleExpert(ExpertMagic, "DirectionalTrendIndex");

//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+
int OnInit()
  {
   CFilter *strategy = new CFilter(_Symbol, InpTimeframe, InpDtiPeriod, InpDtiSmoothing, InpDtiSignal,
                                   InpDSLAnchor);

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
