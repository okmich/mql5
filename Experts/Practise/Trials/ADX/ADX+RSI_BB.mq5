//+------------------------------------------------------------------+
//|                                   ADX+DonchainChannel_Filter.mq5 |
//|                                    Copyright 2024, Michael Enudi |
//|                                             okmich2002@yahoo.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2024, Michael Enudi"
#property link      "okmich2002@yahoo.com"
#property version   "1.00"

#include <Okmich\Expert\SingleExpert.mqh>
#include <Okmich\Indicators\RsiWithBollingerBands.mqh>
#include <Okmich\Indicators\ADXWilder.mqh>

//+------------------------------------------------------------------+
//| Input parameters                                                 |
//+------------------------------------------------------------------+
input group "********* Strategy settings *********";
input ENUM_TIMEFRAMES InpTimeframe = PERIOD_M4;             //Timeframe
input ENUM_LONG_SHORT_FLAG InpLongShortFlag = LONG_SHORT;   //Long/Short Flag

input group "********* General Strategy settings *********";
input int      InpRsiPeriod=14;        // Short RSI Period
input int      InpRsiBBMaPeriod=20;    // Short BB Period
input double   InpRsiBBDeviation=2.0;  // Short BB Deviation
input int      InpRsiBBSignal=5;       // Short RSI Signal
input int InpDMIPeriod = 13;           // ADX DMI Period
input int InpADXPeriod = 8;            // ADX Period

input group "********* Long Strategy settings *********";
input ENUM_RsiBB_Strategies InpLongTriggerType = RsiBB_RsiBBMid_Crossover; //RsiBB Long Trigger type
input int InpLongADXLevel = 20;  

input group "********* Short Strategy settings *********";
input ENUM_RsiBB_Strategies InpShortTriggerType = RsiBB_RsiBBMid_Crossover; //RsiBB Short Trigger type
input int InpShortADXLevel = 20;

input group "********* Volume setting **********";
input int InpLotSizeMultiple = 1;                     //Multiple of minimum lot size

input group "********* Position management settings *********";
input ENUM_POSITION_MANAGEMENT InpPostManagmentType = POSITION_MGT_FIXED_ATR_MULTIPLES;  // Type of Position Management Algorithm
input int InpATRPeriod = 60;                          // ATR Period (Required)
input double InpStopLossPoints = -1;                  // Stop loss distance in points
input double InpBreakEvenPoints = -1;                 // Points to Break-even
input double InpTrailingOrTpPoints = -1;              // Trailing/Take profit points
input double InpMaxLossAmount = 100.00;               // Maximum allowable loss in dollars
input bool InpScratchBreakEvenFlag = true;            // Enable break-even with scratch profit
input double InpStopLossMultiple = 2;                 // ATR multiple for stop loss
input double InpBreakEvenMultiple = 1;                // ATR multiple for break-even
input double InpTrailingOrTpMultiple = 2;             // ATR multiple for Maximum floating/Take profit

input group "********* Other settings *********";
input ulong    ExpertMagic           = 34989345;              //Expert MagicNumbers

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
class CStrategyImpl : public CStrategy
  {
private :
   //--- indicators
   CRsiBBands        *m_RsiBband;
   CADXWilder         *m_AdxWilder;
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
//--- m_RsiBband
   m_RsiBband = new CRsiBBands(mSymbol, mTimeframe, InpRsiPeriod, InpRsiBBMaPeriod, 
                               InpRsiBBDeviation, InpRsiBBSignal);
//--- m_AdxWilder
   m_AdxWilder = new CADXWilder(mSymbol, mTimeframe, InpDMIPeriod, InpADXPeriod, InpLongADXLevel);
   return m_RsiBband.Init() && m_AdxWilder.Init();
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void CStrategyImpl::Release(void)
  {
   m_RsiBband.Release();
   m_AdxWilder.Release();

   delete m_RsiBband;
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

//--- implement entry logic
   if(SupportLongEntries(InpLongShortFlag))
     {
      ENUM_ENTRY_SIGNAL rsiBandSignal = m_RsiBband.TradeSignal(InpLongTriggerType);
      ENUM_ENTRY_SIGNAL dmiSignal = m_AdxWilder.DominantCrossOverWithRisingDX(InpLongADXLevel);
      if(rsiBandSignal == dmiSignal && dmiSignal == ENTRY_SIGNAL_BUY)
        {
         entry.signal = dmiSignal;
         entry.price = ask;
        }
     }

   if(SupportShortEntries(InpLongShortFlag))
     {
      ENUM_ENTRY_SIGNAL rsiBandSignal = m_RsiBband.TradeSignal(InpShortTriggerType);
      ENUM_ENTRY_SIGNAL dmiSignal = m_AdxWilder.DominantCrossOverWithRisingDX(InpShortADXLevel);

      if(rsiBandSignal == dmiSignal && dmiSignal == ENTRY_SIGNAL_SELL)
        {
         entry.signal = dmiSignal;
         entry.price = bid;
        }
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
      m_RsiBband.Refresh(mRefShift);
      m_AdxWilder.Refresh(mRefShift);
     }
  }

// the expert to run our strategy
CSingleExpert singleExpert(ExpertMagic, "ADX+RSI_BB");

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
