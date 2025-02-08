//+------------------------------------------------------------------+
//|                                                     MACD+ADX.mq5 |
//|                                    Copyright 2024, Michael Enudi |
//|                                             okmich2002@yahoo.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2024, Michael Enudi"
#property link      "okmich2002@yahoo.com"
#property version   "1.00"

#include <Okmich\Expert\SingleExpert.mqh>
#include <Okmich\Indicators\adxwilder.mqh>
#include <Okmich\Indicators\atr.mqh>
#include <Okmich\Indicators\macd.mqh>

//+------------------------------------------------------------------+
//| Input parameters                                                 |
//+------------------------------------------------------------------+
input group "********* Strategy settings *********";
input ENUM_TIMEFRAMES InpTimeframe = PERIOD_CURRENT;             //Timeframe
input ENUM_LONG_SHORT_FLAG InpLongShortFlag = LONG_SHORT;   //Long/Short Flag
input int      InpADXPeriod=14;
input int      InpDMIPeriod=14;
input int      InpADXTrendLevel=20;

input group "********* Long Strategy settings *********";
input ENUM_MACD_Strategies InpLongMacdFilterType = MACD_ZeroLineCrossover; //Long trigger type
input int      InpLongFastMaPeriod=12;
input int      InpLongSlowMaPeriod=26;
input int      InpLongSignalPeriod=9;

input group "********* Short Strategy settings *********";
input ENUM_MACD_Strategies InpShortMacdFilterType = MACD_ZeroLineCrossover; //Short trigger type
input int      InpShortFastMaPeriod=12;
input int      InpShortSlowMaPeriod=26;
input int      InpShortSignalPeriod=9;

input group "********* Volume setting **********";
input bool InpUseAtrFilterFlag = false;               //Use ATR for filter
input int InpAtrSmoothingPeriod = 10;                 //ATR Signal Period
input int InpLotSizeMultiple = 1;                     //Multiple of minimum lot size

input group "********* Position management settings *********";
input ENUM_POSITION_MANAGEMENT InpPostManagmentType = POSITION_MGT_FLEX_ATR_MULTIPLES;  // Type of Position Management Algorithm
input int InpATRPeriod =90;                          // ATR Period (Required)
input double InpStopLossPoints = -1;                  // Stop loss distance in points
input double InpBreakEvenPoints = -1;                 // Points to Break-even
input double InpTrailingOrTpPoints = -1;              // Trailing/Take profit points
input double InpMaxLossAmount = 100.00;               // Maximum allowable loss in dollars
input bool InpScratchBreakEvenFlag = true;            // Enable break-even with scratch profit
input double InpStopLossMultiple = 2;                 // ATR multiple for stop loss
input double InpBreakEvenMultiple = 2.5;              // ATR multiple for break-even
input double InpTrailingOrTpMultiple = 2.5;           // ATR multiple for Maximum floating/Take profit

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
   CADXWilder        *m_CiAdx;
   CAtr              *m_CiAtr;
   CMacd             *m_Macds[2];
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
//--- m_CiAdx
   m_CiAdx = new CADXWilder(mSymbol, mTimeframe, InpDMIPeriod,InpADXPeriod, InpADXTrendLevel);
//--- m_Macds
   m_Macds[0] = new CMacd(mSymbol, mTimeframe, InpLongFastMaPeriod, InpLongSlowMaPeriod, InpLongSignalPeriod);
   m_Macds[1] = new CMacd(mSymbol, mTimeframe, InpShortFastMaPeriod, InpShortSlowMaPeriod, InpShortSignalPeriod);
   bool macdInited = m_Macds[0].Init() && m_Macds[1].Init();
//--- m_CiAtr
   bool atrInited = false;
   if(InpUseAtrFilterFlag)
     {
      m_CiAtr = CAtr(mSymbol, mTimeframe, InpATRPeriod, InpAtrSmoothingPeriod+2);
      atrInited = m_CiAtr.Init();
     }
   else
     {
      atrInited=true;
     }

   return m_CiAdx.Init() && macdInited && atrInited;
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void CStrategyImpl::Release(void)
  {
   m_CiAdx.Release();
   delete m_CiAdx;
   for(int i = 0; i < 2; i++)
     {
      m_Macds[i].Release();
      delete m_Macds[i];
     }
   if(InpUseAtrFilterFlag)
     {
      m_CiAtr.Release();
      delete m_CiAtr;
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

   bool atrSignalValid = false;
   if(InpUseAtrFilterFlag)
     {
      double atrSignalValue = m_CiAtr.CalculateMAofATR(InpAtrSmoothingPeriod, mRefShift);
      bool atrSignalValid = m_CiAtr.GetData(mRefShift) >= atrSignalValue;
     }
   else
     {
      atrSignalValid = true;
     }

//--- implement entry logic
   if(SupportLongEntries(InpLongShortFlag) && atrSignalValid)
     {
      ENUM_ENTRY_SIGNAL macdTrigger = m_Macds[0].TradeSignal(InpLongMacdFilterType);
      int dmiPlusDominance = m_CiAdx.Dominance(mRefShift);
      if(macdTrigger == ENTRY_SIGNAL_BUY && dmiPlusDominance == 1)
        {
         entry.signal = macdTrigger;
         entry.price = ask;
         return entry;
        }
     }

   if(SupportShortEntries(InpLongShortFlag) && atrSignalValid)
     {
      ENUM_ENTRY_SIGNAL macdTrigger = m_Macds[1].TradeSignal(InpShortMacdFilterType);
      int dmiNegDominance = m_CiAdx.Dominance(mRefShift);
      if(macdTrigger == ENTRY_SIGNAL_SELL && dmiNegDominance == -1)
        {
         entry.signal = macdTrigger;
         entry.price = bid;
         return entry;
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
   ENUM_ENTRY_SIGNAL signal = ENTRY_SIGNAL_NONE;
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void CStrategyImpl::Refresh(void)
  {
   if(IsNewBar())
     {
      int barsToCopy = 10;
      m_CiAdx.Refresh(mRefShift);
      m_CiAtr.Refresh(mRefShift);
      for(int i = 0; i < 2; i++)
         m_Macds[i].Refresh(mRefShift);
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
