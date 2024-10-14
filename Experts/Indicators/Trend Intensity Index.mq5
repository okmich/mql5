//+------------------------------------------------------------------+
//|                                                  LaguerreRSI.mq5 |
//|                                    Copyright 2021, Michael Enudi |
//|                                             okmich2002@yahoo.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2021, Michael Enudi"
#property link      "okmich2002@yahoo.com"
#property version   "1.00"

#include <Okmich\Expert\SingleExpert.mqh>
#include <Okmich\Indicators\TrendIntensityIndex.mqh>

//--- input parameters
input group "********* Trading strategy settings *********";
input ENUM_CTTI_Stategies  InpEntryOption = TTI_Stategies_ContraEnterObOsLevels; //Entry Option
input int      InpPeriod=20;                           // Period
input int      InpSignal=5;                            // Signal
input double   InpObLevel=0.80;                        // Overbought level
input int      InpLotSizeMul = 1;                      //Minimum Lot size multiple

input group "********* Other Settings *********";
input ulong    ExpertMagic             = 777776;      //Expert MagicNumber

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
class CStrategyImpl : public CStrategy
  {
private :
   //--- indicator values

   //--- indicator settings
   int               m_Period, m_Signal;
   double            m_LevelUp, m_LevelDown;
   ENUM_CTTI_Stategies mEntryOption;
   //--- indicators
   CTrendIntensityIndex *m_Tti;
   //--- indicator buffer

   //-- others

public:
                     CStrategyImpl(string symbol, ENUM_TIMEFRAMES period,
                 int InptPeriod, int InptSignal, double InptLevelUp,
                 ENUM_CTTI_Stategies InptEntryOption,
                 int InptLotSizeMultiplier): CStrategy(symbol, period)
     {
      m_Period = InptPeriod;
      m_Signal = InptSignal;
      m_LevelUp = InptLevelUp;
      m_LevelDown = 1 - InptLevelUp;
      mEntryOption = InptEntryOption;
      mLotSize = InptLotSizeMultiplier*SymbolInfoDouble(_Symbol, SYMBOL_VOLUME_MIN);
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
//--- m_Tti
   m_Tti = new CTrendIntensityIndex(mSymbol, mTimeframe, m_Period, m_Signal, m_LevelUp, m_LevelDown);

   return m_Tti.Init();
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void CStrategyImpl::Release(void)
  {
   m_Tti.Release();
   delete m_Tti;
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void CStrategyImpl::Refresh(void)
  {
   if(IsNewBar())
     {
      m_Tti.Refresh();

      //--- signal logic
      mEntrySignal = m_Tti.TradeSignal(mEntryOption);
     }
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void CStrategyImpl::CheckAndSetExitSignal(CPositionInfo &positionInfo, Position &position)
  {
   ENUM_POSITION_TYPE posType = positionInfo.PositionType();
   double profit = positionInfo.Profit();
   double openPrice = positionInfo.PriceOpen();
   double currentPrice = positionInfo.PriceCurrent();
   double indValue = m_Tti.GetData(1);

   if(posType == POSITION_TYPE_BUY && mEntrySignal == ENTRY_SIGNAL_SELL)
      position.signal = EXIT_SIGNAL_EXIT;
   else
      if(posType == POSITION_TYPE_SELL && mEntrySignal == ENTRY_SIGNAL_BUY)
         position.signal = EXIT_SIGNAL_EXIT;
  }

// the expert to run our strategy
CSingleExpert singleExpert(ExpertMagic, 10);

//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+
int OnInit()
  {
   CStrategyImpl *strategy =
      new CStrategyImpl(_Symbol, _Period, InpPeriod, InpSignal, InpObLevel, InpEntryOption, InpLotSizeMul);
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
