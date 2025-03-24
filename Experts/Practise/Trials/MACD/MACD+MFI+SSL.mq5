//+------------------------------------------------------------------+
//|                                                 MACD+MFI+SSL.mq5 |
//|                                    Copyright 2025, Michael Enudi |
//|                                             okmich2002@yahoo.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2025, Michael Enudi"
#property link      "okmich2002@yahoo.com"
#property version   "1.00"

#include <Okmich\Expert\SingleExpert.mqh>
#include <Okmich\Indicators\macd.mqh>
#include <Okmich\Indicators\mfi.mqh>
#include <Okmich\Indicators\SSL.mqh>

enum ENUM_MACD_RSI_Strategy
  {
   MACD_FILTER_RSI_TRIGGER,
   MACD_DIVERGENCE_RSI_OB_OS,
   MACD_HIST_RSI_MOMENTUM_SHIFT,
   MACD_RSI_CYCLE_SYNC
  };

//+------------------------------------------------------------------+
//| Input parameters                                                 |
//+------------------------------------------------------------------+
input group "********* Strategy settings *********";
input ENUM_TIMEFRAMES InpTimeframe = PERIOD_CURRENT;             //Timeframe
input ENUM_LONG_SHORT_FLAG InpLongShortFlag = LONG_SHORT;   //Long/Short Flag

input group "********* General Strategy settings *********";
input ENUM_MACD_RSI_Strategy InpStrategyType = MACD_FILTER_RSI_TRIGGER; //Strategy type
input int      InpFastMaPeriod=12;
input int      InpSlowMaPeriod=26;
input int      InpSignalPeriod=9;

input ENUM_MFI_Strategies InpMfiHowToEnter = MFI_EnterOsOBLevels; //Entry Signal
input int         InpMfiPeriod=12;

input group "********* Long Strategy settings *********";
input double      InpLongMfiOBLevel=80;
input double      InpLongMfiOSLevel=20;

input group "********* Short Strategy settings *********";
input double      InpShortMfiOBLevel=80;
input double      InpShortMfiOSLevel=20;

input group "********* Exit Strategy settings *********";
input int      InpSslMaPeriod=20;                        // Period
input ENUM_SSL_MODE      InpSslMaMethod=MODE_SSL_EMA;    // Smoothing Method

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
input ulong    ExpertMagic           = 4523485723;    //Expert MagicNumbers

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
class CStrategyImpl : public CStrategy
  {
private :
   //--- indicator values
   //--- indicator settings
   //--- indicators
   CMfi              *m_Mfi;
   CMacd             *m_Macd;
   CSsl              *m_Ssl;

   //-- others

   ENUM_ENTRY_SIGNAL macdZeroLineFilterMfiObosFilter();
   ENUM_ENTRY_SIGNAL macdDivergenceMfiObOs();
   ENUM_ENTRY_SIGNAL macdHistogramMfiMomentum();
   ENUM_ENTRY_SIGNAL macdMfiCycleSync(void);

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
//--- m_Mfi
   m_Mfi = new CMfi(mSymbol, mTimeframe, InpMfiPeriod);
//--- m_Macd
   m_Macd = new CMacd(mSymbol, mTimeframe, InpFastMaPeriod, InpSlowMaPeriod, InpSignalPeriod);
//--- m_Ssl
   m_Ssl = new CSsl(mSymbol, mTimeframe, InpSslMaPeriod, InpSslMaMethod);

   return m_Mfi.Init() && m_Macd.Init() && m_Ssl.Init();
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void CStrategyImpl::Release(void)
  {
   m_Macd.Release();
   delete m_Macd;

   m_Mfi.Release();
   delete m_Mfi;

   m_Ssl.Release();
   delete m_Ssl;
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
Entry CStrategyImpl::FindEntry(const double ask, const double bid)
  {
   Entry entry = noEntry();
   if(!mIsNewBar)
      return entry;

   ENUM_ENTRY_SIGNAL signal = ENTRY_SIGNAL_NONE;
   switch(InpStrategyType)
     {
      case MACD_DIVERGENCE_RSI_OB_OS:
         signal = macdDivergenceMfiObOs();
         break;
      case MACD_FILTER_RSI_TRIGGER:
         signal = macdZeroLineFilterMfiObosFilter();
         break;
      case MACD_HIST_RSI_MOMENTUM_SHIFT:
         signal = macdHistogramMfiMomentum();
         break;
      case MACD_RSI_CYCLE_SYNC:
         signal = macdMfiCycleSync();
         break;
     };

//--- implement entry logic
   if(SupportLongEntries(InpLongShortFlag) && signal == ENTRY_SIGNAL_BUY)
     {
      entry.signal = signal;
      entry.price = ask;
     }

   if(SupportShortEntries(InpLongShortFlag) && signal == ENTRY_SIGNAL_SELL)
     {
      entry.signal = signal;
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
   ENUM_POSITION_TYPE posType = positionInfo.PositionType();
   if(posType == POSITION_TYPE_BUY)
     {
     }
   else
      if(posType == POSITION_TYPE_SELL)
        {
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
      m_Mfi.Refresh(mRefShift);
      m_Ssl.Refresh(mRefShift);
     }
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
ENUM_ENTRY_SIGNAL CStrategyImpl::macdDivergenceMfiObOs(void)
  {
   if(m_Macd.Divergence(mRefShift, true))
     {
      m_Mfi.SetLevels(InpLongMfiOBLevel, InpLongMfiOSLevel);
      return m_Mfi.TradeSignal(InpMfiHowToEnter);
     }

   else
      if(m_Macd.Divergence(mRefShift, false))
        {
         m_Mfi.SetLevels(InpShortMfiOBLevel, InpShortMfiOSLevel);
         return m_Mfi.TradeSignal(InpMfiHowToEnter);
        }
      else
         return ENTRY_SIGNAL_NONE;
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
ENUM_ENTRY_SIGNAL CStrategyImpl::macdHistogramMfiMomentum(void)
  {
   double rsi = m_Mfi.GetData(mRefShift);
   ENUM_ENTRY_SIGNAL macdSignal = m_Macd.TradeSignal(MACD_OsMA);

   return macdSignal == ENTRY_SIGNAL_BUY && rsi > 50.0 ? macdSignal :
          macdSignal == ENTRY_SIGNAL_SELL && rsi < 50.0 ? macdSignal : ENTRY_SIGNAL_NONE;
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
ENUM_ENTRY_SIGNAL CStrategyImpl::macdZeroLineFilterMfiObosFilter(void)
  {
   ENUM_ENTRY_SIGNAL macdFilter = m_Macd.TradeFilter(MACD_ZeroLineCrossover);
   if(macdFilter == ENTRY_SIGNAL_BUY)
     {
      m_Mfi.SetLevels(InpLongMfiOBLevel, InpLongMfiOSLevel);
      return m_Mfi.TradeSignal(InpMfiHowToEnter);
     }
   else
      if(macdFilter == ENTRY_SIGNAL_SELL)
        {
         m_Mfi.SetLevels(InpShortMfiOBLevel, InpShortMfiOSLevel);
         return m_Mfi.TradeSignal(InpMfiHowToEnter);
        }
      else
         return ENTRY_SIGNAL_NONE;
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
ENUM_ENTRY_SIGNAL CStrategyImpl::macdMfiCycleSync(void)
  {
   ENUM_ENTRY_SIGNAL rsiSignal = m_Mfi.TradeSignal(MFI_Directional);
   ENUM_ENTRY_SIGNAL macdSignal = m_Macd.TradeFilter(MACD_Directional);

   return macdSignal == rsiSignal && rsiSignal != ENTRY_SIGNAL_NONE ? rsiSignal : ENTRY_SIGNAL_NONE;
  }

// the expert to run our strategy
CSingleExpert singleExpert(ExpertMagic, "MACD & RSI");

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
