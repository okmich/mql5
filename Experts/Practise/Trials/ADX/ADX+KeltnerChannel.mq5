//+------------------------------------------------------------------+
//|                                          ADX+Keltner Channel.mq5 |
//|                                    Copyright 2024, Michael Enudi |
//|                                             okmich2002@yahoo.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2024, Michael Enudi"
#property link      "okmich2002@yahoo.com"
#property version   "1.00"

#include <Okmich\Expert\SingleExpert.mqh>
#include <Okmich\Indicators\KeltnerChannel.mqh>
#include <Okmich\Indicators\ADXWilder.mqh>

//+------------------------------------------------------------------+
//| Input parameters                                                 |
//+------------------------------------------------------------------+
input group "********* Strategy settings *********";
input ENUM_TIMEFRAMES InpTimeframe = PERIOD_M5;             //Timeframe
input ENUM_LONG_SHORT_FLAG InpLongShortFlag = LONG_SHORT;   //Long/Short Flag

input group "********* Long Strategy settings *********";
input int      InpLongKcPeriod=20;
input double   InpLongKcAtrMultiplier=1.0;
input ENUM_MA_TYPE      InpLongKcMaMethod=MA_TYPE_EMA;
input int InpLongDMIPeriod = 13;
input int InpLongADXPeriod = 8;
input int InpLongADXLevel = 23;

input group "********* Short Strategy settings *********";
input int      InpShortKcPeriod=20;
input double   InpShortKcAtrMultiplier=1.0;
input ENUM_MA_TYPE      InpShortKcMaMethod=MA_TYPE_EMA;
input int InpShortDMIPeriod = 13;
input int InpShortADXPeriod = 13;
input int InpShortADXLevel = 23;

input group "********* Volume setting **********";
input int InpLotSizeMultiple = 1;                     //Multiple of minimum lot size

input group "********* Position management settings *********";
input ENUM_POSITION_MANAGEMENT InpPostManagmentType = POSITION_MGT_FLEX_ATR_MULTIPLES;  // Type of Position Management Algorithm
input int InpATRPeriod = 60;                          // ATR Period (Required)
input double InpStopLossPoints = -1;                  // Stop loss distance in points
input double InpBreakEvenPoints = -1;                 // Points to Break-even
input double InpTrailingOrTpPoints = -1;              // Trailing/Take profit points
input double InpMaxLossAmount = 100.00;               // Maximum allowable loss in dollars
input bool InpScratchBreakEvenFlag = true;            // Enable break-even with scratch profit
input double InpStopLossMultiple = 2.5;               // ATR multiple for stop loss
input double InpBreakEvenMultiple = 10;               // ATR multiple for break-even
input double InpTrailingOrTpMultiple = 10;            // ATR multiple for Maximum floating/Take profit

input group "********* Other settings *********";
input ulong    ExpertMagic           = 980023;              //Expert MagicNumbers

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
   CADXWilder         *m_AdxWilder;
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
//--- m_AdxWilder
   m_AdxWilder = new CADXWilder(mSymbol, mTimeframe, InpLongDMIPeriod, InpLongADXPeriod, InpLongADXLevel, 15);

   return kcInited && m_AdxWilder.Init();
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

   m_AdxWilder.Release();
   delete m_AdxWilder;
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
Entry CStrategyImpl::FindEntry(const double ask, const double bid)
  {
   Entry entry = noEntry();
   if(!mIsNewBar)
      return entry;

   ENUM_ENTRY_SIGNAL dmiSignal = ENTRY_SIGNAL_NONE;
//--- implement entry logic
   if(SupportLongEntries(InpLongShortFlag))
     {
      ENUM_ENTRY_SIGNAL ktcFilter = m_KetChanls[0].TradeFilter(KTC_FILTER_ABOVE_BELOW_BAND);
      dmiSignal = m_AdxWilder.DominantCrossOverWithRisingDX();

      if(ktcFilter == dmiSignal && dmiSignal == ENTRY_SIGNAL_BUY)
        {
         entry.signal = dmiSignal;
         entry.price = ask;
        }
     }

   if(SupportShortEntries(InpLongShortFlag))
     {
      ENUM_ENTRY_SIGNAL ktcFilter = m_KetChanls[1].TradeFilter(KTC_FILTER_ABOVE_BELOW_BAND);
      dmiSignal = m_AdxWilder.DominantCrossOverWithRisingDX();

      if(ktcFilter == dmiSignal && dmiSignal == ENTRY_SIGNAL_SELL)
        {
         entry.signal = dmiSignal;
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
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void CStrategyImpl::Refresh(void)
  {
   if(IsNewBar())
     {
      for(int i = 0; i < 2; i++)
        {
         m_KetChanls[i].Refresh(mRefShift);
        }
     }
   m_AdxWilder.Refresh(mRefShift);
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
