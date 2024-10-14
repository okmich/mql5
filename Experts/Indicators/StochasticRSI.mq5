//+------------------------------------------------------------------+
//|                                                StochasticRSI.mq5 |
//|                                    Copyright 2021, Michael Enudi |
//|                                             okmich2002@yahoo.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2021, Michael Enudi"
#property link      "okmich2002@yahoo.com"
#property version   "1.00"

#include <Okmich\Expert\SingleExpert.mqh>
#include <Okmich\Indicators\StochasticRSI.mqh>

//--- input parameters
input group "********* Strategy settings *********";
input ENUM_TIMEFRAMES InpTimeframe = PERIOD_H1;             //Timeframe
input ENUM_LONG_SHORT_FLAG InpLongShortFlag = LONG_SHORT;   //Long/Short Flag

input group "********* Trading strategy settings *********";
input ENUM_STOCHRSI_Strategies InpHowToEnter = STOCHRSI_EnterOsOBLevels; //Entry Strategy
input int         InpRsiPeriod=12;
input int         InpKPeriod=5;
input int         InpSmoothing=3;
input int         InpSignal=3;
input double      InpOBLevel=80;
input double      InpOSLevel=20;

input group "**************** Volume setting ****************";
input int InpLotSizeMultiple = 1;                     //Multiple of minimum lot size

input group "********* Position management settings *********";
input ENUM_POSITION_MANAGEMENT InpPostManagmentType = POSITION_MGT_FLEX_ATR_MULTIPLES;  // Type of Position Management Algorithm
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

input group "**************** Other settings ****************";
input ulong    ExpertMagic           = 980023;              //Expert MagicNumbers

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
class CMrv : public CStrategy
  {
private :
   //--- indicator values
   ENUM_ENTRY_SIGNAL signal;
   double            mCloseShift1;
   //--- indicator settings
   int               mRsiPeriod,mKPeriod,mSmoothing,mSignal;
   double            mOBLevel, mOSLevel;

   //--- indicators
   CStochasticRSI    *m_StochRsi;
   //--- indicator buffer
   double            m_CloseBuffer[];
   //-- others


public:
                     CMrv(string symbol, ENUM_TIMEFRAMES period,
        int InptRsiPeriod, int InptKPeriod, int InptSmoothing, int InptSignal, double InptOBLevel, double InptOSLevel): CStrategy(symbol, period)
     {
      mRsiPeriod = InptRsiPeriod;
      mKPeriod = InptKPeriod;
      mSmoothing = InptSmoothing;
      mSignal = InptSignal;
      mOBLevel = InptOBLevel;
      mOSLevel = InptOSLevel;

      mLotSize = InpLotSizeMultiple*SymbolInfoDouble(_Symbol, SYMBOL_VOLUME_MIN);
     };

   virtual bool      Init(ulong magic);
   virtual void      Refresh();
   virtual void      CheckAndSetExitSignal(CPositionInfo &positionInfo, Position &position);
   virtual void      Release();
  };

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
bool CMrv::Init(ulong magic)
  {
   CStrategy::Init(magic);
//--- price buffers
   ArraySetAsSeries(m_CloseBuffer, true);
//--- stoch_rsi
   m_StochRsi = new CStochasticRSI(mSymbol, mTimeframe, mRsiPeriod, mKPeriod, mSmoothing, mSignal, mOBLevel, mOSLevel);
   return m_StochRsi.Init();
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void CMrv::Release(void)
  {
   m_StochRsi.Release();
   delete m_StochRsi;
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void CMrv::CheckAndSetExitSignal(CPositionInfo &positionInfo, Position &position)
  {
   ENUM_POSITION_TYPE posType = positionInfo.PositionType();
   if(posType == POSITION_TYPE_BUY && signal == ENTRY_SIGNAL_SELL)
      position.signal = EXIT_SIGNAL_EXIT;

   else
      if(posType == POSITION_TYPE_SELL && signal == ENTRY_SIGNAL_BUY)
         position.signal = EXIT_SIGNAL_EXIT;
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void CMrv::Refresh(void)
  {
   if(IsNewBar())
     {
      int barsToCopy = 10;
      //--- price buffers
      int closeBarsCopied = CopyClose(mSymbol, mTimeframe, 0, barsToCopy, m_CloseBuffer);

      bool indRefreshed = m_StochRsi.Refresh(mRefShift);

      //--- take values from indicator
      signal = m_StochRsi.TradeSignal(InpHowToEnter);
      mEntrySignal = SupportShortEntries(InpLongShortFlag) && signal == ENTRY_SIGNAL_SELL ? signal :
                     SupportLongEntries(InpLongShortFlag) && signal == ENTRY_SIGNAL_BUY ? signal : ENTRY_SIGNAL_NONE;
     }
  }

// the expert to run our strategy
CSingleExpert singleExpert(ExpertMagic, "StochasticRSI");

//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+
int OnInit()
  {
//--- set up Position manager Implementaion
   CPositionManager *positionManager = CreatPositionManager(_Symbol, InpTimeframe, InpPostManagmentType,
                                       InpATRPeriod, InpStopLossPoints, InpBreakEvenPoints,
                                       InpBreakEvenPoints, InpMaxLossAmount, InpScratchBreakEvenFlag,
                                       InpUseHiddenStops, InpHiddenStopMultiple, InpStopLossMultiple,
                                       InpBreakEvenMultiple, InpFloatPointsMultiple);
//--- set up Trading Strategy Implementaion
   CMrv *strategy = new CMrv(_Symbol, InpTimeframe, InpRsiPeriod,
                             InpKPeriod, InpSmoothing, InpSignal,
                             InpOBLevel,  InpOSLevel);
   strategy.SetPositionManager(positionManager);
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
