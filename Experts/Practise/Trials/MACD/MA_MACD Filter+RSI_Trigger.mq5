//+------------------------------------------------------------------+
//|                                                     MACD+RSI.mq5 |
//|                                    Copyright 2024, Michael Enudi |
//|                                             okmich2002@yahoo.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2024, Michael Enudi"
#property link      "okmich2002@yahoo.com"
#property version   "1.00"

#include <Okmich\Expert\SingleExpert.mqh>
#include <Okmich\Indicators\KeltnerChannel.mqh>
#include <Okmich\Indicators\macd.mqh>
#include <Okmich\Indicators\rsi.mqh>

//+------------------------------------------------------------------+
//| Input parameters                                                 |
//+------------------------------------------------------------------+
input group "********* Strategy settings *********";
input ENUM_TIMEFRAMES InpTimeframe = PERIOD_CURRENT;             //Timeframe
input ENUM_LONG_SHORT_FLAG InpLongShortFlag = LONG_SHORT;   //Long/Short Flag

input group "********* General Strategy settings *********";
input ENUM_MACD_Strategies InpMACDHowToEnter = MACD_ZeroLineCrossover; //MACD Signal
input int      InpFastMaPeriod=12;
input int      InpSlowMaPeriod=26;
input int      InpSignalPeriod=9;

input ENUM_RSI_Strategies InpRsiHowToEnter = RSI_EnterOsOBLevels; //Entry Signal
input int         InpRsiPeriod=12;

input group "********* Long Strategy settings *********";
input ENUM_KTC_FILTER InpLongKcHowToFilter = KTC_FILTER_ABOVE_BELOW_BAND; //Filter strategy
input ENUM_MA_TYPE      InpLongKcMaMethod=MA_TYPE_EMA;
input int      InpLongKcPeriod=32;
input double   InpLongKcAtrMultiplier=1.0;

input double      InpLongRsiOBLevel=80;
input double      InpLongRsiOSLevel=20;

input group "********* Short Strategy settings *********";
input ENUM_KTC_FILTER InpShortKcHowToFilter = KTC_FILTER_ABOVE_BELOW_BAND; //Filter strategy
input ENUM_MA_TYPE      InpShortKcMaMethod=MA_TYPE_EMA;
input int      InpShortKcPeriod=32;
input double   InpShortKcAtrMultiplier=1.0;

input double      InpShortRsiOBLevel=80;
input double      InpShortRsiOSLevel=20;

input group "********* Volume setting **********";
input int InpLotSizeMultiple = 1;                     //Multiple of minimum lot size

input group "********* Position management settings *********";
input ENUM_POSITION_MANAGEMENT InpPostManagmentType = POSITION_MGT_FIXED_SL_TRAIL_TP_ATR;  // Type of Position Management Algorithm
input int InpATRPeriod = 60;                          // ATR Period (Required)
input double InpStopLossPoints = -1;                  // Stop loss distance in points
input double InpBreakEvenPoints = -1;                 // Points to Break-even
input double InpTrailingOrTpPoints = -1;              // Trailing/Take profit points
input double InpMaxLossAmount = 100.00;               // Maximum allowable loss in dollars
input bool InpScratchBreakEvenFlag = true;            // Enable break-even with scratch profit
input double InpStopLossMultiple = 3.0;               // ATR multiple for stop loss
input double InpBreakEvenMultiple = -1;               // ATR multiple for break-even
input double InpTrailingOrTpMultiple = 2.0;           // ATR multiple for Maximum floating/Take profit

input group "********* Other settings **********";
input ulong    ExpertMagic           = 4523485723;              //Expert MagicNumbers

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
   CRsi              *m_Rsi;
   CMacd             *m_Macd;
   //-- others

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
//--- m_Rsi
   m_Rsi = new CRsi(mSymbol, mTimeframe, InpRsiPeriod);
//--- m_Macd
   m_Macd = new CMacd(mSymbol, mTimeframe, InpFastMaPeriod, InpSlowMaPeriod, InpSignalPeriod);

   return kcInited && m_Rsi.Init() && m_Macd.Init();
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void CStrategyImpl::Release(void)
  {
   for(int i = 0; i < 2; i++)
     {
      m_KetChanls[i].Release();
      delete m_KetChanls[i];
     }

   m_Macd.Release();
   delete m_Macd;

   m_Rsi.Release();
   delete m_Rsi;
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
Entry CStrategyImpl::FindEntry(const double ask, const double bid)
  {
   Entry entry = noEntry();
   if(!mIsNewBar)
      return entry;

   ENUM_ENTRY_SIGNAL rsiSignal = m_Rsi.TradeSignal(InpRsiHowToEnter);
   ENUM_ENTRY_SIGNAL macdFilter = m_Macd.TradeFilter(InpMACDHowToEnter);

//--- implement entry logic
   if(SupportLongEntries(InpLongShortFlag))
     {
      ENUM_ENTRY_SIGNAL maFilter = m_KetChanls[0].TradeFilter(InpLongKcHowToFilter);
      if(maFilter == macdFilter && macdFilter == rsiSignal && rsiSignal == ENTRY_SIGNAL_BUY)
        {
         entry.signal = rsiSignal;
         entry.price = ask;
        }
     }

   if(SupportShortEntries(InpLongShortFlag))
     {
      ENUM_ENTRY_SIGNAL maFilter = m_KetChanls[0].TradeFilter(InpShortKcHowToFilter);
      if(maFilter == macdFilter && macdFilter == rsiSignal && rsiSignal == ENTRY_SIGNAL_SELL)
        {
         entry.signal = rsiSignal;
         entry.price = bid;
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
   ENUM_ENTRY_SIGNAL filterSignalValid = m_Macd.TradeFilter(InpMACDHowToEnter);
   if(posType == POSITION_TYPE_BUY)
     {
      if(filterSignalValid == ENTRY_SIGNAL_SELL)
        {
         position.signal = EXIT_SIGNAL_EXIT;
        }
     }
   else
      if(posType == POSITION_TYPE_SELL)
        {
         if(filterSignalValid == ENTRY_SIGNAL_BUY)
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

      m_Macd.Refresh(mRefShift);
      m_Rsi.Refresh(mRefShift);
      for(int i = 0; i < 2; i++)
        {
         m_KetChanls[i].Refresh(mRefShift);
        }
     }
  }

// the expert to run our strategy
CSingleExpert singleExpert(ExpertMagic, "KC & MACD & RSI");

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
