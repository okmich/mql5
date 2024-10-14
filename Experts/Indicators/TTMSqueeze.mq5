//+------------------------------------------------------------------+
//|                                             Just TTM Squeeze.mq5 |
//|                                    Copyright 2021, Michael Enudi |
//|                                             okmich2002@yahoo.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2021, Michael Enudi"
#property link      "okmich2002@yahoo.com"
#property version   "1.00"

#include <Okmich\Expert\SingleExpert.mqh>
#include <Okmich\Indicators\TTMSqueeze.mqh>

input group "********* Strategy settings *********";
input ENUM_TTMSQZ_Strategies InpHowTo = TTMSqueeze_CrossesZeroLine;
input int    InpBBandsPeriod     = 20;                      //Bollinger bands moving average period
input double InpBBandsDeviation  = 2.0;                     //Bollinger bands deviation
input int    InpKcPeriod     = 20;                          //Kelter Channel period
input double InpKcDeviation  = 1.5;                         //Kelter Channel Multifactor

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

input group "********* Trade Size settings *********";
input int   InpTradeVolMultiple = 1;               // Minimum Lot size multiple

input group "********* Other Settings *********";
input ulong    ExpertMagic             = 2983233;      //Expert Magic


//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
class CStrategyImpl : public CStrategy
  {
private :
   //--- indicator values
   bool              mIsTrending;
   double            mCloseShift1, mSqMomShift1, mSqMomShift2;
   //--- indicator settings
   int               m_BbPeriod, m_KcPeriod;
   double            m_BbDeviation, m_KcDeviation;

   //--- indicators
   CTTMSqueeze       *mSqsMom;
   //--- indicator buffer
   double            m_CloseBuffer[];
   //-- others


public:
                     CStrategyImpl(string symbol, ENUM_TIMEFRAMES period,
                 int InptBbPeriod=20, double InptBbDeviatn=2.0,
                 int InptKcPeriod=20, double InptkcDeviatn=1.5,
                 int InptLotSizeMultiple=1): CStrategy(symbol, period)
     {
      m_BbPeriod = InptBbPeriod;
      m_BbDeviation = InptBbDeviatn;
      m_KcPeriod = InptKcPeriod;
      m_KcDeviation = InptkcDeviatn;

      mLotSize = InptLotSizeMultiple*SymbolInfoDouble(_Symbol, SYMBOL_VOLUME_MIN);
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
//--- price buffers
   ArraySetAsSeries(m_CloseBuffer, true);
//--- bollinger bands
   mSqsMom = new CTTMSqueeze(mSymbol, mTimeframe, m_BbPeriod, m_BbDeviation, m_KcPeriod, m_KcDeviation);
   return mSqsMom.Init();
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void CStrategyImpl::Release(void)
  {
   mSqsMom.Release();
   delete mSqsMom;
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void CStrategyImpl::CheckAndSetExitSignal(CPositionInfo &positionInfo, Position &position)
  {
   ENUM_POSITION_TYPE posType = positionInfo.PositionType();
   if(posType == POSITION_TYPE_BUY && mEntrySignal == ENTRY_SIGNAL_SELL)
      position.signal = EXIT_SIGNAL_EXIT;
   else
      if(posType == POSITION_TYPE_SELL && mEntrySignal == ENTRY_SIGNAL_BUY)
         position.signal = EXIT_SIGNAL_EXIT;
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void CStrategyImpl::Refresh(void)
  {
   if(IsNewBar())
     {
      int barsToCopy = 10;
      //--- price buffers
      //-- mSqsMom
      bool bool1 = mSqsMom.Refresh();

      mIsTrending = mSqsMom.IsTrending();
      mEntrySignal = mSqsMom.TradeSignal(InpHowTo);
     }
  }

// the expert to run our strategy
CSingleExpert singleExpert(ExpertMagic, 10);

//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+
int OnInit()
  {
//--- set up Position manager Implementation
   CPositionManager *positionManager = CreatPositionManager(_Symbol, InpPostManagmentType,
                                       InpATRPeriod, InpStopLossPoints, InpBreakEvenPoints,
                                       InpMaxFloatingPoints, InpMaxLossAmount, InpScratchBreakEvenFlag,
                                       InpUseHiddenStops, InpHiddenStopMultiple, InpStopLossMultiple,
                                       InpBreakEvenMultiple, InpFloatPointsMultiple);

//--- set up Trading Strategy Implementaion
   CStrategyImpl *strategy = new CStrategyImpl(_Symbol, _Period, InpBBandsPeriod,
         InpBBandsDeviation, InpKcPeriod, InpKcDeviation,
         InpTradeVolMultiple);
//set position management
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
