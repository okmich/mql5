//+------------------------------------------------------------------+
//|                                                        Aroon.mq5 |
//|                                    Copyright 2021, Michael Enudi |
//|                                             okmich2002@yahoo.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2021, Michael Enudi"
#property link      "okmich2002@yahoo.com"
#property version   "1.00"

#include <Okmich\Expert\SingleExpert.mqh>
#include <Okmich\Indicators\Aroon.mqh>

//--- input parameters
input int      InpPeriod=12;
input int      InpOBLevel=70;
input ENUM_CAroon_Stategies InpSignalType = AROON_Stategies_CrossesLevels;
input double InpDefaultVolume=0.1; //Lot size

input group "********* Position management settings *********";
input ENUM_POSITION_MANAGEMENT InpPostManagmentType = POSITION_MGT_FIXED_ATR_MULTIPLES;  // Type of Position Management Algorithm
input int InpATRPeriod = 20;                          // ATR Period
input double InpStopLossPoints = -1;                  // Stop loss distance
input double InpBreakEvenPoints = -1;                 // Points to Break-even
input double InpMaxFloatingPoints = -1;               // Maximum floating points/Take profit points
input double InpMaxLossAmount = 40.00;                // Maximum allowable loss in dollars
input bool InpScratchBreakEvenFlag = true;            // Enable break-even with scratch profit
input bool InpUseHiddenStops = false;                 // Enable hidden stops
input double InpHiddenStopMultiple = 3;               // Hardstops (applicable only when hidden stop is enabled)
input double InpStopLossMultiple = 2;                 // ATR multiple for stop loss
input double InpBreakEvenMultiple = 2;                // ATR multiple for break-even
input double InpFloatPointsMultiple = 3;              // ATR multiple for Maximum floating/Take profit

input ulong    ExpertMagic           = 980023;              //Expert MagicNumbers

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
class CAroonStrategry : public CStrategy
  {
private :
   //--- indicator values
   //--- indicator settings
   int               mPeriod, mFilterLevel;
   //--- indicators
   CAroon            *m_Aroon;
   //--- indicator buffer
   //-- others


public:
                     CAroonStrategry(string symbol, ENUM_TIMEFRAMES period, int aroonPeriod, int obLevel): CStrategy(symbol, period)
     {
      mPeriod = aroonPeriod;
      mFilterLevel = obLevel;

      mLotSize = 1*SymbolInfoDouble(_Symbol, SYMBOL_VOLUME_MIN);
     };

   virtual bool      Init(ulong magic);
   virtual void      Refresh();
   virtual void      CheckAndSetExitSignal(CPositionInfo &positionInfo, Position &position);
   virtual void      Release();
  };

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
bool CAroonStrategry::Init(ulong magic)
  {
   CStrategy::Init(magic);
//--- m_Aroon
   m_Aroon = new CAroon(mSymbol, mTimeframe, mPeriod, mFilterLevel, 100-mFilterLevel);
   return m_Aroon.Init();
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void CAroonStrategry::Release(void)
  {
   m_Aroon.Release();
   delete m_Aroon;
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void CAroonStrategry::CheckAndSetExitSignal(CPositionInfo &positionInfo, Position &position)
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
void CAroonStrategry::Refresh(void)
  {
   if(IsNewBar())
     {
      bool refreshed = m_Aroon.Refresh();
      //--- take values from indicator
      mEntrySignal = m_Aroon.TradeSignal(InpSignalType);
     }
  }

// the expert to run our strategy
CSingleExpert singleExpert(ExpertMagic, 10);
//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+
int OnInit()
  {
   CAroonStrategry *strategy =
      new CAroonStrategry(_Symbol, _Period, InpPeriod, InpOBLevel);
//set position management
   strategy.SetPositionManager(new CNoPositionManager(_Symbol, _Period));

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
