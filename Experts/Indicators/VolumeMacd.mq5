//+------------------------------------------------------------------+
//|                                                         MACD.mq5 |
//|                                    Copyright 2021, Michael Enudi |
//|                                             okmich2002@yahoo.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2021, Michael Enudi"
#property link      "okmich2002@yahoo.com"
#property version   "1.00"

#include <Okmich\Expert\SingleExpert.mqh>
#include <Okmich\Indicators\VolumeMacd.mqh>

//--- input parameters
input group "********* Setting **********";
input ENUM_TIMEFRAMES InpTimeframe = PERIOD_H1;             //Timeframe
input ENUM_LONG_SHORT_FLAG InpLongShortFlag = LONG;   //Long/Short Flag

input group "********* Strategy settings *********";
input ENUM_MACD_Strategies InpSignalType = MACD_ZeroLineCrossover; //Entry strategy
input int      InpFastMaPeriod=12;             // MACD fast ema
input int      InpSlowMaPeriod=26;             // MACD slow ema
input int      InpSignalPeriod=9;              // MACD Signal
input bool     InpUseVolumeAdjustment = false; //Use Volume aadjustment

input group "********* Position management settings *********";
input ENUM_POSITION_MANAGEMENT InpPostManagmentType = POSITION_MGT_NONE;  // Type of Position Management Algorithm
input int InpATRPeriod = 14;                         // ATR Period
input double InpStopLossPoints = -1;                 // Stop loss distance
input double InpBreakEvenPoints = -1;                // Points to Break-even
input double InpMaxFloatingPoints = -1;              // Maximum floating points/Take profit points
input double InpMaxLossAmount = 30.00;               // Maximum allowable loss in dollars
input bool InpScratchBreakEvenFlag = true;           // Enable break-even with scratch profit
input bool InpUseHiddenStops = false;                // Enable hidden stops
input double InpHiddenStopMultiple = 3;              // Hardstops (applicable only when hidden stop is enabled)
input double InpStopLossMultiple = 2;                // ATR multiple for stop loss
input double InpBreakEvenMultiple = 2;               // ATR multiple for break-even
input double InpFloatPointsMultiple = 5;             // ATR multiple for Maximum floating/Take profit

input group "********* Trade Size settings *********";
input int   InpTradeVolMultiple = 1;               // Minimum Lot size multiple

input group "********* Other Settings *********";
input ulong    ExpertMagic             = 2983233;      //Expert MagicNumber

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
class CStrategyImpl : public CStrategy
  {
private :
   //--- indicator values
   ENUM_ENTRY_SIGNAL signal;
   //--- indicator settings
   int               mFastMaPeriod, mSlowMaPeriod, mSignalPeriod;
   bool              mUseVolAdjustment;
   //--- indicators
   CVolumeMacd       *m_VolumeMacd;
   //--- indicator buffer
   //-- others

public:
                     CStrategyImpl(string symbol, ENUM_TIMEFRAMES period, int InptFastMaPeriod, int InptSlowMaPeriod,
                 int InptSignalPeriod, bool InptUseVolAdjustmnt): CStrategy(symbol, period)
     {
      mFastMaPeriod = InptFastMaPeriod;
      mSlowMaPeriod = InptSlowMaPeriod;
      mSignalPeriod = InptSignalPeriod;
      mUseVolAdjustment = InptUseVolAdjustmnt;

      mLotSize = InpTradeVolMultiple * SymbolInfoDouble(_Symbol, SYMBOL_VOLUME_MIN);
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
//--- m_VolumeMacd
   m_VolumeMacd = new CVolumeMacd(mSymbol, mTimeframe, mFastMaPeriod, mSlowMaPeriod, mSignalPeriod, mUseVolAdjustment, VOLUME_TICK);
   return m_VolumeMacd.Init();
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void CStrategyImpl::Release(void)
  {
   m_VolumeMacd.Release();
   delete m_VolumeMacd;
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void CStrategyImpl::CheckAndSetExitSignal(CPositionInfo &positionInfo, Position &position)
  {
   ENUM_POSITION_TYPE posType = positionInfo.PositionType();
   if(posType == POSITION_TYPE_BUY && mEntrySignal == ENTRY_SIGNAL_SELL)
     {
      position.signal = EXIT_SIGNAL_EXIT;
     }
   else
      if(posType == POSITION_TYPE_SELL && mEntrySignal == ENTRY_SIGNAL_BUY)
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
      m_VolumeMacd.Refresh();

      //--- take values from indicator
      signal = m_VolumeMacd.TradeSignal(InpSignalType);
      mEntrySignal = SupportShortEntries(InpLongShortFlag) && signal == ENTRY_SIGNAL_SELL ? signal :
                     SupportLongEntries(InpLongShortFlag) && signal == ENTRY_SIGNAL_BUY ? signal : ENTRY_SIGNAL_NONE;
     }
  }

// the expert to run our strategy
CSingleExpert singleExpert(ExpertMagic, "Volume Adjusted/Weighted MACD");

//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+
int OnInit()
  {
   CStrategyImpl *strategy = new CStrategyImpl(_Symbol, _Period,
         InpFastMaPeriod, InpSlowMaPeriod, InpSignalPeriod, InpUseVolumeAdjustment);
//--- set up Position manager Implementation
   CPositionManager *positionManager = CreatPositionManager(_Symbol, _Period, InpPostManagmentType,
                                       InpATRPeriod, InpStopLossPoints, InpBreakEvenPoints,
                                       InpMaxFloatingPoints, InpMaxLossAmount, InpScratchBreakEvenFlag,
                                       InpUseHiddenStops, InpHiddenStopMultiple, InpStopLossMultiple,
                                       InpBreakEvenMultiple, InpFloatPointsMultiple);
   strategy.SetPositionManager(positionManager);

//set strategy on expert
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
//---
   singleExpert.OnTickHandler();
  }
//+------------------------------------------------------------------+
