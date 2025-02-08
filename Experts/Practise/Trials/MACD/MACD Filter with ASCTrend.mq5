//+------------------------------------------------------------------+
//|                                    MACD Filter with ASCTrend.mq5 |
//|                                    Copyright 2025, Michael Enudi |
//|                                             okmich2002@yahoo.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2025, Michael Enudi"
#property link      "okmich2002@yahoo.com"
#property version   "1.00"

#include <Okmich\Expert\SingleExpert.mqh>
#include <Okmich\Indicators\AscTrend.mqh>
#include <Okmich\Indicators\macd.mqh>

//+------------------------------------------------------------------+
//| Input parameters                                                 |
//+------------------------------------------------------------------+
input group "********* Strategy settings *********";
input ENUM_TIMEFRAMES InpTimeframe = PERIOD_CURRENT;             //Timeframe
input ENUM_LONG_SHORT_FLAG InpLongShortFlag = LONG_SHORT;   //Long/Short Flag
input int      InpAscTendRisk=3;

input ENUM_MACD_Strategies InpMacdFilterType = MACD_ZeroLineCrossover; //Long trigger type
input int      InpFastMaPeriod=12;
input int      InpSlowMaPeriod=26;
input int      InpSignalPeriod=9;

input group "********* Volume setting **********";
input int InpLotSizeMultiple = 1;                     //Multiple of minimum lot size

input group "********* Position management settings *********";
input ENUM_POSITION_MANAGEMENT InpPostManagmentType = POSITION_MGT_FIXED_SL_TRAIL_TP_ATR;  // Type of Position Management Algorithm
input int InpATRPeriod = 90;                          // ATR Period (Required)
input double InpStopLossPoints = -1;                  // Stop loss distance in points
input double InpBreakEvenPoints = -1;                 // Points to Break-even
input double InpTrailingOrTpPoints = -1;              // Trailing/Take profit points
input double InpMaxLossAmount = 100.00;               // Maximum allowable loss in dollars
input bool InpScratchBreakEvenFlag = true;            // Enable break-even with scratch profit
input double InpStopLossMultiple = 2;                 // ATR multiple for stop loss
input double InpBreakEvenMultiple = 4.5;              // ATR multiple for break-even
input double InpTrailingOrTpMultiple = 4.5;           // ATR multiple for Maximum floating/Take profit

input group "********* Other settings *********";
input ulong    ExpertMagic           = 24238472942;         //Expert MagicNumbers

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
class CStrategyImpl : public CStrategy
  {
private :
   //--- indicator values
   ENUM_ENTRY_SIGNAL ascTrendSignal;
   //--- indicator settings
   //--- indicators
   CAscTrend         *m_AscTrend;
   CMacd             *m_Macd;
   //-- others

protected:
   virtual Entry     FindEntry(const double ask, const double bid);

public:
                     CStrategyImpl(string symbol, ENUM_TIMEFRAMES period, int InptLotSizeMultiple): CStrategy(symbol, period)
     {
      mLotSize = InptLotSizeMultiple * SymbolInfoDouble(mSymbol, SYMBOL_VOLUME_MIN);
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
//--- m_AscTrend
   m_AscTrend = new CAscTrend(mSymbol, mTimeframe, InpAscTendRisk);
//--- m_Macd
   m_Macd = new CMacd(mSymbol, mTimeframe, InpFastMaPeriod, InpSlowMaPeriod, InpSignalPeriod);

   return m_AscTrend.Init() && m_Macd.Init();
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void CStrategyImpl::Release(void)
  {
   m_AscTrend.Release();
   m_Macd.Release();
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
Entry CStrategyImpl::FindEntry(const double ask, const double bid)
  {
   Entry entry = noEntry();
   if(!mIsNewBar)
      return entry;

   ENUM_ENTRY_SIGNAL macdFilter = m_Macd.TradeFilter(InpMacdFilterType);

//--- implement entry logic
   if(SupportLongEntries(InpLongShortFlag) && macdFilter == ENTRY_SIGNAL_BUY &&
      ascTrendSignal == ENTRY_SIGNAL_BUY)
     {
      entry.signal = macdFilter;
      entry.price = ask;
      return entry;
     }

   if(SupportShortEntries(InpLongShortFlag) && macdFilter == ENTRY_SIGNAL_SELL &&
      ascTrendSignal == ENTRY_SIGNAL_SELL)
     {
      entry.signal = macdFilter;
      entry.price = bid;
      return entry;
     }

   return entry;
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void CStrategyImpl::CheckAndSetExitSignal(CPositionInfo &positionInfo, Position &position)
  {
   ENUM_POSITION_TYPE posType = positionInfo.PositionType();
   ENUM_ENTRY_SIGNAL signal = ENTRY_SIGNAL_NONE;
   double ask = SymbolInfoDouble(_Symbol, SYMBOL_ASK);
   double bid = SymbolInfoDouble(_Symbol, SYMBOL_BID);
   double spread = (ask - bid) / OnePoint();
   bool inProfit = positionInfo.Profit() > (2 * spread);

   if(posType == POSITION_TYPE_BUY && inProfit && ascTrendSignal == ENTRY_SIGNAL_SELL)
     {
      position.signal = EXIT_SIGNAL_EXIT;
     }
   else
      if(posType == POSITION_TYPE_SELL && inProfit && ascTrendSignal == ENTRY_SIGNAL_BUY)
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
      m_AscTrend.Refresh(mRefShift);
      m_Macd.Refresh(mRefShift);

      ascTrendSignal = m_AscTrend.TradeSignal();
     }
  }

// the expert to run our strategy
CSingleExpert singleExpert(ExpertMagic, "MACD & ADX & ATR");

//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+
int OnInit()
  {
//--- set up Trading Strategy Implementaion
   CStrategyImpl *strategy = new CStrategyImpl(_Symbol, InpTimeframe, InpLotSizeMultiple);
   CPositionManager *positionManager = CreatPositionManager(_Symbol, InpTimeframe,
                                       InpPostManagmentType, InpATRPeriod,
                                       InpStopLossPoints, InpBreakEvenPoints, InpTrailingOrTpPoints,
                                       InpMaxLossAmount, InpScratchBreakEvenFlag, false, 5,
                                       InpStopLossMultiple, InpTrailingOrTpMultiple, InpTrailingOrTpMultiple);
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
