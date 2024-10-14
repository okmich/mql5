//+------------------------------------------------------------------+
//|                                                    OmniTrend.mq5 |
//|                                    Copyright 2022, Michael Enudi |
//|                                             okmich2002@yahoo.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2022, Michael Enudi"
#property link      "okmich2002@yahoo.com"
#property version   "1.00"

#include <Okmich\Expert\SingleExpert.mqh>
#include <Okmich\Indicators\OmniTrend.mqh>

//--- input parameters
input group "********* Setting **********";
input ENUM_TIMEFRAMES InpTimeframe = PERIOD_H1;             //Timeframe
input ENUM_LONG_SHORT_FLAG InpLongShortFlag = LONG;   //Long/Short Flag

input group "********* Indicator settings *********";
input int      InpMaPeriod=13;                        //Omni Trend MA Period
input int      InpAtrPeriod=100;                      //Omni Trend ATR Period
input double   InpAtrMultiplier=2;                  //Omni Trend ATR Multiplier
input double   InpOffsetFactor=1;                   //Omni Trend ATR Offset Factor
input ENUM_MA_TYPE InpSmoothingMethod = MA_TYPE_EMA;   //Omni Trend Smoothing Method

input group "********* Trade Size settings *********";
input int   InpTradeVolMultiple = 1;               // Minimum Lot size multiple

input group "********* Other Settings *********";
input ulong    ExpertMagic           = 980023;              //Expert MagicNumbers


input group "********* Position management settings *********";
input ENUM_POSITION_MANAGEMENT InpPostManagmentType = POSITION_MGT_NONE;  // Type of Position Management Algorithm
input int InpATRPeriod = 14;                          // ATR Period
input double InpStopLossPoints = -1;                  // Stop loss distance in points
input double InpBreakEvenPoints = -1;                 // Points to Break-even
input double InpTrailingOrTpPoints = -1;              // Trailing/Take profit points
input double InpMaxLossAmount = 100.00;               // Maximum allowable loss in dollars
input bool InpScratchBreakEvenFlag = true;            // Enable break-even with scratch profit
input double InpStopLossMultiple = 2;                 // ATR multiple for stop loss
input double InpBreakEvenMultiple = 1;                // ATR multiple for break-even
input double InpTrailingOrTpMultiple = 2;             // ATR multiple for Maximum floating/Take profit

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
class CStrategyImpl : public CStrategy
  {
private :
   //--- indicator values
   ENUM_ENTRY_SIGNAL signal;
   //--- indicator settings
   int                m_MaPeriod, m_AtrPeriod;
   double             m_AtrMultiplier, m_OffsetFactor;
   ENUM_MA_TYPE     m_Smoothing_method;
   //--- indicators
   COmniTrend         *m_CiOmniTrend;
   //--- indicator buffer
   //-- others


public:
                     CStrategyImpl(string symbol, ENUM_TIMEFRAMES period, int InptMaPeriod=32, int InptAtrPeriod=20,
                 ENUM_MA_TYPE InptSmoothingMethod=MA_TYPE_EMA,  double InptAtrMultiplier=1.5, double InptOffsetFactor=3): CStrategy(symbol, period)
     {
      m_MaPeriod = InptMaPeriod;
      m_Smoothing_method = InptSmoothingMethod;
      m_AtrPeriod = InptAtrPeriod;
      m_AtrMultiplier = InptAtrMultiplier;
      m_OffsetFactor = InptOffsetFactor;

      mLotSize = InpTradeVolMultiple*SymbolInfoDouble(_Symbol, SYMBOL_VOLUME_MIN);
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
//--- m_CiOmniTrend
   m_CiOmniTrend = new COmniTrend(mSymbol, mTimeframe, m_MaPeriod, m_AtrPeriod, m_Smoothing_method,
                                  m_AtrMultiplier, m_OffsetFactor);

   return m_CiOmniTrend.Init();
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void CStrategyImpl::Release(void)
  {
   m_CiOmniTrend.Release();
   delete m_CiOmniTrend;
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void CStrategyImpl::CheckAndSetExitSignal(CPositionInfo &positionInfo, Position &position)
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
void CStrategyImpl::Refresh(void)
  {
   if(IsNewBar())
     {
      //-- m_CiOmniTrend
      m_CiOmniTrend.Refresh(mRefShift);
      signal = m_CiOmniTrend.TradeSignal();
      if (signal != ENTRY_SIGNAL_NONE)
      {
         m_CiOmniTrend.TradeSignal();
      }
      mEntrySignal = SupportShortEntries(InpLongShortFlag) && signal == ENTRY_SIGNAL_SELL ? signal :
                     SupportLongEntries(InpLongShortFlag) && signal == ENTRY_SIGNAL_BUY ? signal : ENTRY_SIGNAL_NONE;
     }
  }

// the expert to run our strategy
CSingleExpert singleExpert(ExpertMagic, "OmniTrend");

//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+
int OnInit()
  {
   CStrategyImpl *strategy = new CStrategyImpl(_Symbol, InpTimeframe, InpMaPeriod, InpAtrPeriod, InpSmoothingMethod,
         InpAtrMultiplier, InpOffsetFactor);

   CPositionManager *mPositionManager = CreatPositionManager(_Symbol, InpTimeframe,
                                        InpPostManagmentType,
                                        InpATRPeriod, InpStopLossPoints, InpBreakEvenPoints, InpTrailingOrTpPoints,
                                        InpMaxLossAmount, InpScratchBreakEvenFlag, false, 5,
                                        InpStopLossMultiple, InpBreakEvenMultiple, InpTrailingOrTpMultiple);
   strategy.SetPositionManager(mPositionManager);

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
