//+------------------------------------------------------------------+
//|                SingleExpert_With_DayTimeRangesFilter_Example.mq5 |
//|                                    Copyright 2024, Michael Enudi |
//|                                             okmich2002@yahoo.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2024, Michael Enudi"
#property link      "okmich2002@yahoo.com"
#property version   "1.00"

//--- includes directives here
#include <Okmich\Expert\SingleExpert.mqh>
#include <Okmich\Indicators\Macd.mqh>

//--- input EXPERT_MAGIC
const ulong EXPERT_MAGIC = 1000000000;

//+------------------------------------------------------------------+
//| Input parameters                                                 |
//+------------------------------------------------------------------+
input group "********* Strategy settings *********";
input ENUM_TIMEFRAMES InpTimeframe = PERIOD_H1;             //Timeframe
input ENUM_LONG_SHORT_FLAG InpLongShortFlag = LONG;   //Long/Short Flag

input group "********* Trading Times settings *********";
input string InpTradableDayRange = "MON-FRI";
input string InpTradableTimeRange = "1000-1459,1700-2159";

input group "********* Long Strategy settings *********";
input ENUM_MACD_Strategies InpBuySuperTrendStrategy = MACD_ZeroLineCrossover; //Buy StochRSI Entry Strategy
input int         InpBuyMacdFastEmaPeriod=5;
input int         InpBuyMacdSlowEmaPeriod=12;
input int         InpBuyMacdSignalPeriod=3;

input group "********* Short Strategy settings *********";
input ENUM_MACD_Strategies InpSellSuperTrendStrategy = MACD_ZeroLineCrossover; //Sell StochRSI Entry Strategy
input int         InpSellMacdFastEmaPeriod=12;
input int         InpSellMacdSlowEmaPeriod=5;
input int         InpSellMacdSignalPeriod=3;

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
   CMacd    *m_Macd[2];
   CTimeFilter       *mTimeFilter;
   //--- indicator buffer

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
   virtual void      CloseAllPosition();
  };

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
bool CStrategyImpl::Init(ulong magic)
  {
   CStrategy::Init(magic);
//--- m_Macd
   m_Macd[0] = new CMacd(mSymbol, mTimeframe, InpBuyMacdFastEmaPeriod, InpBuyMacdSlowEmaPeriod, InpBuyMacdSignalPeriod);
   m_Macd[1] = new CMacd(mSymbol, mTimeframe, InpSellMacdFastEmaPeriod, InpSellMacdSlowEmaPeriod, InpSellMacdSignalPeriod);
   bool macdOk = m_Macd[0].Init() && m_Macd[1].Init();
   mTimeFilter = new CDayTimeRangesTimeFilter(InpTradableDayRange, InpTradableTimeRange);

   return macdOk && mTimeFilter.Init();
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void CStrategyImpl::Release(void)
  {
//--- release indicators
   for(int i = 0; i< 2; i++)
     {
      m_Macd[i].Release();
      delete m_Macd[i];
     }
   delete mTimeFilter;

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
      for(int i = 0; i< 2; i++)
        {
         //-- m_Macd
         m_Macd[i].Refresh(mRefShift);
        }
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

   entry.magic = EXPERT_MAGIC;
   entry.vol = mLotSize;
   entry.sym = mSymbol;

//--- implement entry logic
   ENUM_ENTRY_SIGNAL signal = m_Macd[0].TradeSignal(InpBuySuperTrendStrategy);
   if(SupportLongEntries(InpLongShortFlag) && signal == ENTRY_SIGNAL_BUY)
     {
      entry.signal = signal;
      entry.price = ask;

      return entry;
     }

   signal = m_Macd[0].TradeSignal(InpSellSuperTrendStrategy);;
   if(SupportShortEntries(InpLongShortFlag) && signal == ENTRY_SIGNAL_SELL)
     {
      entry.signal = signal;
      entry.price = bid;

      return entry;
     }

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
      ENUM_ENTRY_SIGNAL signal = m_Macd[1].TradeSignal(InpSellSuperTrendStrategy);
      if(signal == ENTRY_SIGNAL_BUY)
         position.signal = EXIT_SIGNAL_EXIT;

      return;
     }
   else
      if(postType == POSITION_TYPE_BUY)
        {
         //--- implement exit logic for long positions
         ENUM_ENTRY_SIGNAL signal = m_Macd[0].TradeSignal(InpSellSuperTrendStrategy);

         if(signal == ENTRY_SIGNAL_SELL)
            position.signal = EXIT_SIGNAL_EXIT;
        }
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void CStrategyImpl::CloseAllPosition(void)
  {
   CPositionInfo positionInfo;
   int positionCount = PositionsTotal();
   for(int i = positionCount - 1; i >= 0; i--)
     {
      positionInfo.SelectByIndex(i);
      //get properties of the open trade and symbol
      if(positionInfo.Symbol() == mSymbol &&  positionInfo.Magic() == EXPERT_MAGIC)
        {
         //call the PositionClose of CTrade
         mPositionManager.ClosePosition(mCTradeHandle, positionInfo.Ticket());
        }
     }
  }


// the expert to run our strategy
CSingleExpert singleExpert(EXPERT_MAGIC, "Name of strategy here");

//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+
int OnInit()
  {
   CStrategy *strategy = new CStrategyImpl(_Symbol, InpTimeframe, InpLotSizeMultiple);
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
