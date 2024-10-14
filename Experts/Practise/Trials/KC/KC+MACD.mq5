//+------------------------------------------------------------------+
//|                                                      KC+MACD.mq5 |
//|                                    Copyright 2024, Michael Enudi |
//|                                             okmich2002@yahoo.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2024, Michael Enudi"
#property link      "okmich2002@yahoo.com"
#property version   "1.00"

#include <Okmich\Expert\SingleExpert.mqh>
#include <Okmich\Indicators\KeltnerChannel.mqh>
#include <Okmich\Indicators\macd.mqh>

//+------------------------------------------------------------------+
//| Input parameters                                                 |
//+------------------------------------------------------------------+
input group "********* Strategy settings *********";
input ENUM_TIMEFRAMES InpTimeframe = PERIOD_CURRENT;             //Timeframe
input ENUM_LONG_SHORT_FLAG InpLongShortFlag = LONG_SHORT;   //Long/Short Flag

input group "********* Long Strategy settings *********";
input ENUM_KTC_FILTER InpLongHowToFilter = KTC_FILTER_ABOVE_BELOW_BAND; //Filter strategy
input int      InpLongKcPeriod=20;
input double   InpLongKcAtrMultiplier=2.0;
input ENUM_MA_TYPE      InpLongKcMaMethod=MA_TYPE_EMA;
input ENUM_MACD_Strategies InpLongHowToTrigger = MACD_ZeroLineCrossover; //Long Entry MACD Signal Type
input int      InpLongFastMaPeriod=12;
input int      InpLongSlowMaPeriod=26;
input int      InpLongSignalPeriod=9;

input double   InpLongTpAtrMultiples=2.25;
input double   InpLongSlAtrMultiples=3.75;

input group "********* Short Strategy settings *********";
input ENUM_KTC_FILTER InpShortHowToFilter = KTC_FILTER_ABOVE_BELOW_BAND; //Short Filter strategy
input int      InpShortKcPeriod=20;
input double   InpShortKcAtrMultiplier=2.0;
input ENUM_MA_TYPE      InpShortKcMaMethod=MA_TYPE_EMA;
input ENUM_MACD_Strategies InpShortHowToTrigger = MACD_ZeroLineCrossover; //Short Entry MACD Signal Type
input int      InpShortFastMaPeriod=12;
input int      InpShortSlowMaPeriod=26;
input int      InpShortSignalPeriod=9;

input double   InpShortTpAtrMultiples=3.5;
input double   InpShortSlAtrMultiples=4.75;

input group "********* Volume setting **********";
input int InpLotSizeMultiple = 1;                     //Multiple of minimum lot size

input ulong    ExpertMagic           = 980023;              //Expert MagicNumbers

const int ATR_PERIOD = 60;
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
   CMacd              *m_Macds[2];
   //-- others

protected:
   virtual Entry     FindEntry(const double ask, const double bid);

public:
                     CStrategyImpl(string symbol, ENUM_TIMEFRAMES period,
                 int InptLotSizeMultiple): CStrategy(symbol, period)
     {
      mLotSize = InptLotSizeMultiple * SymbolInfoDouble(mSymbol, SYMBOL_VOLUME_MIN);

      CAtrFixedPositionManager *posManager = new CAtrFixedPositionManager(
         symbol, InpTimeframe,
         ATR_PERIOD, InpLongSlAtrMultiples, 1000, InpLongTpAtrMultiples,1000,
         false, false, 100);
      SetPositionManager(posManager);
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

   return kcInited && maInited;
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
   if(SupportLongEntries(InpLongShortFlag))
     {
      ENUM_ENTRY_SIGNAL ktcSignal = m_KetChanls[0].TradeFilter(InpLongHowToFilter);
      ENUM_ENTRY_SIGNAL filterSignal = m_Macds[0].TradeSignal(InpLongHowToTrigger);

      if(filterSignal == ktcSignal && ktcSignal == ENTRY_SIGNAL_BUY)
        {
         entry.signal = ktcSignal;
         entry.price = ask;

         CAtrFixedPositionManager *posManager = mPositionManager;
         posManager.SetStopLossMultiple(InpLongSlAtrMultiples);
         posManager.SetTakeProfitMultiple(InpLongTpAtrMultiples);
        }
     }

   if(SupportShortEntries(InpLongShortFlag))
     {
      ENUM_ENTRY_SIGNAL ktcSignal = m_KetChanls[1].TradeFilter(InpShortHowToFilter);
      ENUM_ENTRY_SIGNAL filterSignal = m_Macds[1].TradeSignal(InpShortHowToTrigger);

      if(filterSignal == ktcSignal && ktcSignal == ENTRY_SIGNAL_SELL)
        {
         entry.signal = ktcSignal;
         entry.price = bid;

         CAtrFixedPositionManager *posManager = mPositionManager;
         posManager.SetStopLossMultiple(InpShortSlAtrMultiples);
         posManager.SetTakeProfitMultiple(InpShortTpAtrMultiples);
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
//TODO:
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
     }
  }

// the expert to run our strategy
CSingleExpert singleExpert(ExpertMagic, "...");

//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+
int OnInit()
  {
//--- set up Trading Strategy Implementaion
   CStrategyImpl *strategy = new CStrategyImpl(_Symbol, InpTimeframe, InpLotSizeMultiple);
//CPositionManager *positionManager = CreatPositionManager(_Symbol, InpTimeframe,
//                                    InpPostManagmentType,
//                                    InpKcPeriod, InpStopLossPoints, InpBreakEvenPoints, InpTrailingOrTpPoints,
//                                    InpMaxLossAmount, InpScratchBreakEvenFlag, false, 5,
//                                    InpStopLossMultiple, InpTrailingOrTpMultiple, InpTrailingOrTpMultiple);
//strategy.SetPositionManager(positionManager);
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
