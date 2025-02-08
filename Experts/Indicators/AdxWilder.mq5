//+------------------------------------------------------------------+
//|                                                     FilterEA.mq5 |
//|                                    Copyright 2021, Michael Enudi |
//|                                             okmich2002@yahoo.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2021, Michael Enudi"
#property link      "okmich2002@yahoo.com"
#property version   "1.00"

#include <Okmich\Expert\SingleExpert.mqh>
#include <Okmich\Indicators\ADXWilder.mqh>

input ulong    ExpertMagic           = 980023;              //Expert MagicNumbers

//+------------------------------------------------------------------+
//| Input parameters                                                 |
//+------------------------------------------------------------------+
input group "********* Strategy settings *********";
input ENUM_TIMEFRAMES InpTimeframe = PERIOD_H1;             //Timeframe
input ENUM_LONG_SHORT_FLAG InpLongShortFlag = LONG_SHORT;   //Long/Short Flag
input bool InpUseExitFlag = true; //Use exit flag

input group "********* Strategy settings *********";
input int InpDMIPeriod = 13;
input int InpADXPeriod = 8;
input double InpSignificantSlope = 15;
input double InpAdxTrendThreshold = 25;

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
   ENUM_ENTRY_SIGNAL adxSignal;
   //--- indicator values
   bool              mIsTrending;
   double            mAdxDominance;
   //--- indicator settings
   int                mDmiPeriod, mAdxPeriod;
   double             mSignfSlope, mTrendIndx;

   //--- indicators
   CADXWilder        *mAdxWilder;
   //--- indicator buffer
   double            m_CloseBuffer[];
   //-- others

protected:
   virtual Entry     FindEntry(const double ask, const double bid);

public:
                     CStrategyImpl(string symbol, ENUM_TIMEFRAMES period, int InputDmiPeriod=13,
                 int InputAdxPeriod=8, double significantSlope=15, double trendThreshold=25): CStrategy(symbol, period)
     {
      mDmiPeriod = InputDmiPeriod;
      mAdxPeriod = InputAdxPeriod;
      mSignfSlope = significantSlope;
      mTrendIndx = trendThreshold;

      mLotSize = SymbolInfoDouble(symbol, SYMBOL_VOLUME_MIN);
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
//--- price buffers
   ArraySetAsSeries(m_CloseBuffer, true);
//--- mAdxWilder
   mAdxWilder = new CADXWilder(mSymbol, mTimeframe, mDmiPeriod, mAdxPeriod, mTrendIndx, mSignfSlope);

   return mAdxWilder.Init();
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void CStrategyImpl::Release(void)
  {
   mAdxWilder.Release();
   delete mAdxWilder;
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
Entry CStrategyImpl::FindEntry(const double ask, const double bid)
  {
   Entry entry = noEntry();

   if(!mIsNewBar)
      return entry;

//signal logic
   if(SupportLongEntries(InpLongShortFlag) && adxSignal == ENTRY_SIGNAL_BUY)
     {
      entry.signal = ENTRY_SIGNAL_BUY;
      entry.price = ask;
     }
   else
      if(SupportShortEntries(InpLongShortFlag) && adxSignal == ENTRY_SIGNAL_SELL)
        {
         entry.signal = ENTRY_SIGNAL_SELL;
         entry.price = bid;
        }

   if(entry.signal != ENTRY_SIGNAL_NONE)
     {
      entry.sym = mSymbol;
      entry.magic = _expertMagic;
      entry.vol = mLotSize;
     }

   return entry;
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void CStrategyImpl::CheckAndSetExitSignal(CPositionInfo &positionInfo, Position &position)
  {
   if(InpUseExitFlag)
     {
      ENUM_POSITION_TYPE posType = positionInfo.PositionType();
      if(posType == POSITION_TYPE_BUY && adxSignal == ENTRY_SIGNAL_SELL)
         position.signal = EXIT_SIGNAL_EXIT;
      else
         if(posType == POSITION_TYPE_SELL && adxSignal == ENTRY_SIGNAL_BUY)
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
      int barsToCopy = 10;
      //--- price buffers
      int closeBarsCopied = CopyClose(mSymbol, mTimeframe, 0, barsToCopy, m_CloseBuffer);

      mAdxWilder.Refresh();
      adxSignal = mAdxWilder.DominantCrossOverWithRisingDX();
     }
  }

// the expert to run our strategy
CSingleExpert singleExpert(ExpertMagic, "ADXW");

//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+
int OnInit()
  {
//--- set up Trading Strategy Implementaion
   CStrategyImpl *strategy = new CStrategyImpl(_Symbol, InpTimeframe, InpDMIPeriod, InpADXPeriod, InpSignificantSlope, InpAdxTrendThreshold);
   CPositionManager *positionManager = CreatPositionManager(_Symbol, InpTimeframe,
                                       InpPostManagmentType,
                                       InpATRPeriod, InpStopLossPoints, InpBreakEvenPoints, InpTrailingOrTpPoints,
                                       InpMaxLossAmount, InpScratchBreakEvenFlag, false, 5,
                                       InpStopLossMultiple, InpBreakEvenMultiple, InpTrailingOrTpMultiple);
   strategy.SetPositionManager(positionManager);
   singleExpert.SetStrategyImpl(strategy);

   if(singleExpert.OnInitHandler())
      return INIT_SUCCEEDED;
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
