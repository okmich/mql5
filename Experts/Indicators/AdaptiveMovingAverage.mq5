//+------------------------------------------------------------------+
//|                                        AdaptiveMovingAverage.mq5 |
//|                                    Copyright 2022, Michael Enudi |
//|                                             okmich2002@yahoo.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2022, Michael Enudi"
#property link      "okmich2002@yahoo.com"
#property version   "1.00"

#include <Okmich\Expert\SingleExpert.mqh>
#include <Okmich\Indicators\AdaptiveMovingAverage.mqh>

//--- input parameters
input group "********* Trading strategy settings *********";
input ENUM_AMA_Strategies InpHowToEntry = AMA_PriceAboveBelowLine; //Entry logic
input int      InpPeriod=9;                                // AMA Period
input int      InpFastMaPeriod=2;                          // AMA Fast MA Period
input int      InpSlowMaPeriod=30;                          // AMA Slow MA Period
input int      InpSlopeCalcPeriod=3;                       // AMA Slope Calc Period
input int      InpLotSizeMul = 1;                          //Minimum Lot size multiple

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
   int                m_Period, m_FastMaPeriod, m_SlowMaPeriod, m_SlopCalcPeriod;
   //--- indicators
   CAma              *m_Ama;
   //--- indicator buffer

   //-- others

public:
                     CStrategyImpl(string symbol, ENUM_TIMEFRAMES period,
                 int InptPeriod=9, int InptFastMaPeriod=2, int InptSlowMaPeriod=30,
                 int InptSlopCalcPeriod = 3, int InptLotSizeMultiplier=1): CStrategy(symbol, period)
     {
      m_Period = InptPeriod;
      m_FastMaPeriod = InptFastMaPeriod;
      m_SlowMaPeriod = InptSlowMaPeriod;
      m_SlopCalcPeriod = InptSlopCalcPeriod;

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
//--- m_Ama
   m_Ama = new CAma(mSymbol, mTimeframe, m_Period, m_FastMaPeriod, m_SlowMaPeriod, m_SlopCalcPeriod);
   return m_Ama.Init();
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void CStrategyImpl::Release(void)
  {
   m_Ama.Release();
   delete m_Ama;
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
   double onePip = OnePip(mSymbol);

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
      m_Ama.Refresh();
      //--- signal logic
      mEntrySignal = m_Ama.TradeFilter(InpHowToEntry);
     }
  }

// the expert to run our strategy
CSingleExpert singleExpert(ExpertMagic, 10);
//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+
int OnInit()
  {
   CStrategyImpl *strategy =
      new CStrategyImpl(_Symbol, _Period, InpPeriod,
                        InpFastMaPeriod, InpSlowMaPeriod, InpSlopeCalcPeriod, InpLotSizeMul);
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
