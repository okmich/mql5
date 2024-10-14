//+------------------------------------------------------------------+
//|                                                          Roc.mq5 |
//|                                    Copyright 2023, Michael Enudi |
//|                                             okmich2002@yahoo.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2021, Michael Enudi"
#property link      "okmich2002@yahoo.com"
#property version   "1.00"

#include <Okmich\Expert\SingleExpert.mqh>
#include <Okmich\Indicators\Roc.mqh>

//--- input parameters
input group "********* Strategy settings *********";
input int      InpRocPeriod=20;                        // Period
input bool     InpIsSmoothed=false;                        // Smoothed

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
   //--- indicator settings
   int               mRocPeriod;
   //--- indicators
   CRoc              *m_Roc;
   //--- indicator buffer
   double            m_CloseBuffer[], m_RocBuffer[];
   //-- others

public:
                     CStrategyImpl(string symbol, ENUM_TIMEFRAMES period,
                 int InptRocPeriod, int InptLotSizeMultiple): CStrategy(symbol, period)
     {
      mRocPeriod = InptRocPeriod;

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
//--- price buffers
   ArraySetAsSeries(m_CloseBuffer, true);
   ArraySetAsSeries(m_RocBuffer, true);
//--- m_Roc
   m_Roc = new CRoc(mSymbol, mTimeframe, mRocPeriod, InpIsSmoothed);
   return m_Roc.Init();
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void CStrategyImpl::Release(void)
  {
   m_Roc.Release();
   delete m_Roc;
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
      int barsToCopy = 10;
      //--- price buffers
      m_Roc.Refresh(mRefShift);
      mEntrySignal = m_Roc.TradeSignal();
     }
  }

// the expert to run our strategy
CSingleExpert expert(ExpertMagic, 0);

//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+
int OnInit()
  {
//--- set up Position manager Implementation
   CPositionManager *positionManager = CreatPositionManager(_Symbol, _Period, InpPostManagmentType,
                                       InpATRPeriod, InpStopLossPoints, InpBreakEvenPoints,
                                       InpMaxFloatingPoints, InpMaxLossAmount, InpScratchBreakEvenFlag,
                                       InpUseHiddenStops, InpHiddenStopMultiple, InpStopLossMultiple,
                                       InpBreakEvenMultiple, InpFloatPointsMultiple);
//--- set up Trading Strategy Implementaion
   CStrategyImpl *strategy = new CStrategyImpl(_Symbol, _Period,
         InpRocPeriod, InpTradeVolMultiple);
   strategy.SetPositionManager(positionManager);
   expert.SetStrategyImpl(strategy);

//---

   if(expert.OnInitHandler())
      return INIT_SUCCEEDED ;
   else
      return INIT_FAILED;
  }

//+------------------------------------------------------------------+
//| Expert deinitialization function                                 |
//+------------------------------------------------------------------+
void OnDeinit(const int reason)
  {
   expert.OnDeinitHandler();
  }

//+------------------------------------------------------------------+
//| Expert tick function                                             |
//+------------------------------------------------------------------+
void OnTick()
  {
//---
   expert.OnTickHandler();
  }
//+------------------------------------------------------------------+
