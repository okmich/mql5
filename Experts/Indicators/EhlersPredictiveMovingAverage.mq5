//+------------------------------------------------------------------+
//|                                       EhlersLeadingIndicator.mq5 |
//|                                    Copyright 2022, Michael Enudi |
//|                                             okmich2002@yahoo.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2022, Michael Enudi"
#property link      "okmich2002@yahoo.com"
#property version   "1.00"

#include <Okmich\Expert\SingleExpert.mqh>
#include <Okmich\Indicators\EhlersPredictiveMovingAverage.mqh>

//--- input parameters
input group "********* Trading strategy settings *********";
input int      InpLotSizeMul = 1;                         //Minimum Lot size multiple

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
   //--- indicators
   CEhlersPredictiveMovingAverage            *m_EhlersPredictiveMovingAverage;
   //--- indicator buffer

   //-- others

public:
                     CStrategyImpl(string symbol, ENUM_TIMEFRAMES period,
                 int InptLotSizeMultiplier): CStrategy(symbol, period)
     {
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

//--- m_EhlersPredictiveMovingAverage
   m_EhlersPredictiveMovingAverage =
      new CEhlersPredictiveMovingAverage(mSymbol, mTimeframe);

   return m_EhlersPredictiveMovingAverage.Init();
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void CStrategyImpl::Release(void)
  {
   m_EhlersPredictiveMovingAverage.Release();
   delete m_EhlersPredictiveMovingAverage;
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void CStrategyImpl::Refresh(void)
  {
   if(IsNewBar())
     {
      m_EhlersPredictiveMovingAverage.Refresh();

      //--- signal logic
      mEntrySignal = m_EhlersPredictiveMovingAverage.TradeSignal();
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
   double indValue = m_EhlersPredictiveMovingAverage.GetData(1);

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
      new CStrategyImpl(_Symbol, _Period, InpLotSizeMul);
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
