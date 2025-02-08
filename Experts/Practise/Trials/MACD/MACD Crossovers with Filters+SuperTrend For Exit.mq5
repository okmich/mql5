//+------------------------------------------------------------------+
//|             MACD Crossovers with Filters+SuperTrend For Exit.mq5 |
//|                                    Copyright 2024, Michael Enudi |
//|                                             okmich2002@yahoo.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2024, Michael Enudi"
#property link      "okmich2002@yahoo.com"
#property version   "1.00"

#include <Okmich\Expert\SingleExpert.mqh>
#include <Okmich\Indicators\KeltnerChannel.mqh>
#include <Okmich\Indicators\macd.mqh>
#include <Okmich\Indicators\supertrend.mqh>

//+------------------------------------------------------------------+
//| Input parameters                                                 |
//+------------------------------------------------------------------+
input group "********* Strategy settings *********";
input ENUM_TIMEFRAMES InpTimeframe = PERIOD_CURRENT;             //Timeframe
input ENUM_LONG_SHORT_FLAG InpLongShortFlag = LONG_SHORT;   //Long/Short Flag

input group "********* Long Strategy settings *********";
input ENUM_KTC_FILTER InpLongHowToFilter = KTC_FILTER_ABOVE_BELOW_BAND; //Filter strategy
input int      InpLongKcPeriod=48;
input double   InpLongKcAtrMultiplier=0.5;
input ENUM_MA_TYPE      InpLongKcMaMethod=MA_TYPE_EMA;
input ENUM_MACD_Strategies InpLongHowToTrigger = MACD_ZeroLineCrossover; //Long Entry MACD Signal Type
input int      InpLongFastMaPeriod=12;
input int      InpLongSlowMaPeriod=26;
input int      InpLongSignalPeriod=9;

input group "********* Short Strategy settings *********";
input ENUM_KTC_FILTER InpShortHowToFilter = KTC_FILTER_ABOVE_BELOW_BAND; //Short Filter strategy
input int      InpShortKcPeriod=48;
input double   InpShortKcAtrMultiplier=0.5;
input ENUM_MA_TYPE      InpShortKcMaMethod=MA_TYPE_EMA;
input ENUM_MACD_Strategies InpShortHowToTrigger = MACD_ZeroLineCrossover; //Short Entry MACD Signal Type
input int      InpShortFastMaPeriod=12;
input int      InpShortSlowMaPeriod=26;
input int      InpShortSignalPeriod=9;

input group "********* Volume setting **********";
input int InpLotSizeMultiple = 1;                     //Multiple of minimum lot size

input group "********* Exit setting **********";
input int InpATRPeriod = 60;                          // ATR Period (Required)
input int InpSuperTrendAtrMultiple = 2;               //SuperTrend Exit Multiple

input group "********* Filter settings **********";
input bool InpUseAtrFilter = false;                     //Use Atr filter
input double InpAtrPercentileFilter = 0.5;              //Atr Filter Percentile
input bool InpUseVolumeFilter = false;                  //Use Volume filter
input double InpVolumePercentileFilter = 0.5;           //Volume Filter Percentile

input group "********* Others *********";
input double InpMaxLossAmount = 40.00;               // Maximum allowable loss in dollars
input double InpStopLossMultiple = 2;                 // ATR multiple for stop loss
input ulong    ExpertMagic           = 980023;         //Expert MagicNumbers

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
class CStrategyImpl : public CStrategy
  {
private :
   //--- indicator values
   //--- indicator settings
   //--- indicators
   CKeltnerChannel   *m_KetChanls[2];
   CMacd             *m_Macds[2];
   CAtrReader        *mCAtrReader;
   CSuperTrend       *mCSuperTrend;
   //-- others
   bool              AtrFilter();
   bool              VolumeFilter();

protected:
   virtual Entry     FindEntry(const double ask, const double bid);

public:
                     CStrategyImpl(string symbol, ENUM_TIMEFRAMES period,
                 int InptLotSizeMultiple): CStrategy(symbol, period)
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
//--- m_KetChanls
   m_KetChanls[0] = new CKeltnerChannel(mSymbol, mTimeframe, InpLongKcPeriod, InpLongKcMaMethod,
                                        InpLongKcAtrMultiplier, PRICE_CLOSE);
   m_KetChanls[1] = new CKeltnerChannel(mSymbol, mTimeframe, InpShortKcPeriod, InpShortKcMaMethod,
                                        InpShortKcAtrMultiplier, PRICE_CLOSE);
   bool kcInited = m_KetChanls[0].Init() && m_KetChanls[1].Init();
//--- m_Macds
   m_Macds[0] = new CMacd(mSymbol, mTimeframe, InpLongFastMaPeriod, InpLongSlowMaPeriod, InpLongSignalPeriod);
   m_Macds[1] = new CMacd(mSymbol, mTimeframe, InpShortFastMaPeriod, InpShortSlowMaPeriod, InpShortSignalPeriod);
   bool maInited = m_Macds[0].Init() && m_Macds[1].Init();

   mCAtrReader = new CAtrReader(mSymbol, mTimeframe, InpATRPeriod);
   mCSuperTrend = new CSuperTrend(mSymbol, mTimeframe, InpATRPeriod, InpSuperTrendAtrMultiple, 4);

   return kcInited && maInited && mCSuperTrend.Init();
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void CStrategyImpl::Release(void)
  {
   for(int i = 0; i < 2; i++)
     {
      m_KetChanls[i].Release();
      m_Macds[i].Release();

      delete m_KetChanls[i];
      delete m_Macds[i];
     }
   mCSuperTrend.Release();
   delete mCSuperTrend;

   delete mCAtrReader;
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
Entry CStrategyImpl::FindEntry(const double ask, const double bid)
  {
   Entry entry = noEntry();
   if(!mIsNewBar)
      return entry;

//--- Try extra trade filters
   bool volumeFilter = InpUseVolumeFilter ? VolumeFilter() : true;
   bool atrFilter = InpUseAtrFilter ? AtrFilter() : true;

//--- implement entry logic
   if(SupportLongEntries(InpLongShortFlag) && volumeFilter && atrFilter)
     {
      ENUM_ENTRY_SIGNAL ktcSignal = m_KetChanls[0].TradeFilter(InpLongHowToFilter);
      ENUM_ENTRY_SIGNAL macdSignal = m_Macds[0].TradeSignal(InpLongHowToTrigger);
      if(macdSignal == ktcSignal && ktcSignal == ENTRY_SIGNAL_BUY)
        {
         entry.signal = ktcSignal;
         entry.price = ask;
         entry.sl = bid - (InpStopLossMultiple * mCAtrReader.atr(mRefShift));
        }
     }

   if(SupportShortEntries(InpLongShortFlag) && volumeFilter && atrFilter)
     {
      ENUM_ENTRY_SIGNAL ktcSignal = m_KetChanls[1].TradeFilter(InpShortHowToFilter);
      ENUM_ENTRY_SIGNAL macdSignal = m_Macds[1].TradeSignal(InpShortHowToTrigger);

      if(macdSignal == ktcSignal && ktcSignal == ENTRY_SIGNAL_SELL)
        {
         entry.signal = ktcSignal;
         entry.price = bid;
         entry.sl = ask + (InpStopLossMultiple * mCAtrReader.atr(mRefShift));
        }
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
   ENUM_POSITION_TYPE posType = positionInfo.PositionType();
   ENUM_ENTRY_SIGNAL superTrendState = ENTRY_SIGNAL_NONE;
   double ask = SymbolInfoDouble(mSymbol, SYMBOL_ASK);
   double bid = SymbolInfoDouble(mSymbol, SYMBOL_BID);
   double spread = ask - bid;
   double profit = positionInfo.Profit();
   bool inProfit = profit > (2 * spread);
   double st1 = mCSuperTrend.GetData(mRefShift), st2 = mCSuperTrend.GetData(mRefShift+1);
   superTrendState = mCSuperTrend.TradeSignal();

   if(posType == POSITION_TYPE_BUY)
     {
      if(superTrendState == ENTRY_SIGNAL_SELL && inProfit)
        {
         position.signal = EXIT_SIGNAL_EXIT;
        }
     }
   else
      if(posType == POSITION_TYPE_SELL)
        {
         if(superTrendState == ENTRY_SIGNAL_BUY && inProfit)
           {
            position.signal = EXIT_SIGNAL_EXIT;
           }
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

      for(int i = 0; i < 2; i++)
        {
         m_KetChanls[i].Refresh(mRefShift);
         m_Macds[i].Refresh(mRefShift);
        }
      mCSuperTrend.Refresh(mRefShift);
     }
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
bool CStrategyImpl::AtrFilter(void)
  {
   ENUM_HIGHLOW level = mCAtrReader.classifyATR();
   return InpUseAtrFilter && level == HIGHLOW_HIGH;
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
bool CStrategyImpl::VolumeFilter(void)
  {
   return IsVolumeAbovePriorPercentile(mSymbol, mTimeframe, mRefShift, 100, InpVolumePercentileFilter);
  }

// the expert to run our strategy
CSingleExpert singleExpert(ExpertMagic, "MACD Crossovers with Filters+SuperTrend For Exit");

//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+
int OnInit()
  {
//--- set up Trading Strategy Implementaion
   CStrategyImpl *strategy = new CStrategyImpl(_Symbol, InpTimeframe, InpLotSizeMultiple);
   CPositionManager *positionManager = new CMaxLossAmountPositionManager(_Symbol, InpTimeframe, InpMaxLossAmount);
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
