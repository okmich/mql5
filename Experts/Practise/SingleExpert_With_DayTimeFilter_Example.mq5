//+------------------------------------------------------------------+
//|                      SingleExpert_With_DayTimeFilter_Example.mq5 |
//|                                    Copyright 2024, Michael Enudi |
//|                                             okmich2002@yahoo.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2024, Michael Enudi"
#property link      "okmich2002@yahoo.com"
#property version   "1.00"

//--- includes directives here
#include <Okmich\Expert\SingleExpert.mqh>

//--- input EXPERT_MAGIC
const ulong EXPERT_MAGIC = 1000000000;

//+------------------------------------------------------------------+
//| Input parameters                                                 |
//+------------------------------------------------------------------+
input group "********* Strategy settings *********";
input ENUM_TIMEFRAMES InpTimeframe = PERIOD_H1;             //Timeframe
input ENUM_LONG_SHORT_FLAG InpLongShortFlag = LONG_SHORT;   //Long/Short Flag

input group "********* Trading Times settings *********";
input string InpTradableDayRange = "SUN-SAT";
input string InpTradableTimeRange = "0000-2359";

input group "********* Long Strategy settings *********";

input group "********* Short Strategy settings *********";

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

   //--- indicators

   //--- indicator buffer
   double            m_CloseBuffer[];

protected:
   virtual Entry     FindEntry(const double ask, const double bid);

public:
                     CStrategyImpl(string symbol, ENUM_TIMEFRAMES period, int InptVolMultiple): CStrategy(symbol, period)
     {
      mLotSize = InptVolMultiple*SymbolInfoDouble(_Symbol, SYMBOL_VOLUME_MIN);
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
   CStrategy::Init(magic);
//--- initialize indicators

//--- price buffers
   ArraySetAsSeries(m_CloseBuffer, true);

   return true;
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void CStrategyImpl::Release(void)
  {
//--- release indicators

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
      //-- refresh indicators


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

//--- implement entry logic

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

   if(postType == POSITION_TYPE_SELL)
     {
      //--- implement exit logic for short positions

     }
   else
      if(postType == POSITION_TYPE_BUY)
        {
         //--- implement exit logic for long positions

        }
  }


// the expert to run our strategy
CSingleExpert singleExpert(EXPERT_MAGIC, "Name of strategy here");

//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+
int OnInit()
  {
   CStrategy *strategy = new CStrategyImpl(_Symbol, _Period, InpLotSizeMultiple);
   CPositionManager *mPositionManager = CreatPositionManager(_Symbol, InpTimeframe,
                                        InpPostManagmentType,
                                        InpATRPeriod, InpStopLossPoints, InpBreakEvenPoints, InpTrailingOrTpPoints,
                                        InpMaxLossAmount, InpScratchBreakEvenFlag, false, 5,
                                        InpStopLossMultiple, InpBreakEvenMultiple, InpTrailingOrTpMultiple);
   CTimeFilter *mTimeFilter = new CDayTimeRangesTimeFilter(InpTradableDayRange, InpTradableTimeRange);
   strategy.SetPositionManager(mPositionManager);

   singleExpert.SetTimeFilter(mTimeFilter);
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
