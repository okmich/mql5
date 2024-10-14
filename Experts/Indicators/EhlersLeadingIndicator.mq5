//+------------------------------------------------------------------+
//|                                       EhlersLeadingIndicator.mq5 |
//|                                    Copyright 2022, Michael Enudi |
//|                                             okmich2002@yahoo.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2022, Michael Enudi"
#property link      "okmich2002@yahoo.com"
#property version   "1.00"

#include <Okmich\Expert\SingleExpert.mqh>
#include <Okmich\Indicators\EhlersLeadingIndicator.mqh>

//--- input parameters
input group "********* Trading strategy settings *********";
input ENUM_TIMEFRAMES InpTimeframe = PERIOD_M30;            //Timeframe
input ENUM_LONG_SHORT_FLAG InpLongShortFlag = LONG_SHORT;   //Long/Short Flag
input double   InpAlpha1=0.25;                            // ELI Alpha 1
input double   InpAlpha2=0.33;                            // ELI Alpha 2
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
   double            m_Alpha1, m_Alpha2;
   //--- indicators
   CEhlersLeadingIndicator            *m_EhlersLeadingIndicator;
   //--- indicator buffer

   //-- others

public:
                     CStrategyImpl(string symbol, ENUM_TIMEFRAMES period,
                 double InptAlpha1, double InptAlpha2,
                 int InptLotSizeMultiplier): CStrategy(symbol, period)
     {
      m_Alpha1 = InptAlpha1;
      m_Alpha2 = InptAlpha2;
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

//--- m_EhlersLeadingIndicator
   m_EhlersLeadingIndicator =
      new CEhlersLeadingIndicator(mSymbol, mTimeframe, m_Alpha1, m_Alpha2);

   return m_EhlersLeadingIndicator.Init();
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void CStrategyImpl::Release(void)
  {
   m_EhlersLeadingIndicator.Release();
   delete m_EhlersLeadingIndicator;
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void CStrategyImpl::Refresh(void)
  {
   if(IsNewBar())
     {
      m_EhlersLeadingIndicator.Refresh();

      //--- signal logic
      ENUM_ENTRY_SIGNAL signal = m_EhlersLeadingIndicator.TradeSignal();
      mEntrySignal = signal == ENTRY_SIGNAL_BUY && SupportLongEntries(InpLongShortFlag) ? signal :
                     signal == ENTRY_SIGNAL_SELL && SupportShortEntries(InpLongShortFlag) ? signal : ENTRY_SIGNAL_NONE;
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
   double indValue = m_EhlersLeadingIndicator.GetData(1);

   ENUM_ENTRY_SIGNAL signal = m_EhlersLeadingIndicator.TradeSignal();
   if(posType == POSITION_TYPE_BUY && signal == ENTRY_SIGNAL_SELL)
      position.signal = EXIT_SIGNAL_EXIT;
   else
      if(posType == POSITION_TYPE_SELL && signal == ENTRY_SIGNAL_BUY)
         position.signal = EXIT_SIGNAL_EXIT;
  }

// the expert to run our strategy
CSingleExpert singleExpert(ExpertMagic, "");

//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+
int OnInit()
  {
   CStrategyImpl *strategy =
      new CStrategyImpl(_Symbol, InpTimeframe, InpAlpha1, InpAlpha2, InpLotSizeMul);
//set position management
   strategy.SetPositionManager(new CNoPositionManager(_Symbol, InpTimeframe));

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
