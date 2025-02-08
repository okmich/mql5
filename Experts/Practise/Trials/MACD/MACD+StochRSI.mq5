//+------------------------------------------------------------------+
//|                                                MACD+StochRSI.mq5 |
//|                                    Copyright 2024, Michael Enudi |
//|                                             okmich2002@yahoo.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2024, Michael Enudi"
#property link      "okmich2002@yahoo.com"
#property version   "1.00"

#include <Okmich\Expert\SingleExpert.mqh>
#include <Okmich\Indicators\macd.mqh>
#include <Okmich\Indicators\StochasticRsi.mqh>

//+------------------------------------------------------------------+
//| Input parameters                                                 |
//+------------------------------------------------------------------+
input group "********* Strategy settings *********";
input ENUM_TIMEFRAMES InpTimeframe = PERIOD_CURRENT;             //Timeframe
input ENUM_LONG_SHORT_FLAG InpLongShortFlag = LONG_SHORT;   //Long/Short Flag

input group "********* General Strategy settings *********";
input ENUM_MACD_Strategies InpMACDHowToEnter = MACD_ZeroLineCrossover; //MACD Signal
input int      InpFastMaPeriod=12;
input int      InpSlowMaPeriod=26;
input int      InpSignalPeriod=9;

input ENUM_STOCHRSI_Strategies InpStochHowToEnter = STOCHRSI_EnterOsOBLevels; //Entry Strategy
input int         InpStochRsiPeriod=12;
input int         InpStochKPeriod=5;
input int         InpStochSmoothing=3;
input int         InpStochSignal=3;

input group "********* Long Strategy settings *********";
input double      InpLongStochOBLevel=80;
input double      InpLongStochOSLevel=20;

input group "********* Short Strategy settings *********";
input double      InpShortStochOBLevel=80;
input double      InpShortStochOSLevel=20;

input group "********* Volume setting **********";
input int InpLotSizeMultiple = 1;                     //Multiple of minimum lot size

input ulong    ExpertMagic           = 980023;              //Expert MagicNumbers

const int ATR_PERIOD = 60;
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
class CStrategyImpl : public CStrategy
  {
private :
   //--- indicator values
   //--- indicator settings
   //--- indicators
   CStochasticRSI    *m_StochRsi;
   CMacd             *m_Macd;
   //-- others

protected:
   virtual Entry     FindEntry(const double ask, const double bid);

public:
                     CStrategyImpl(string symbol, ENUM_TIMEFRAMES period,
                 int InptLotSizeMultiple): CStrategy(symbol, period)
     {
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
//--- m_StochRsi
   m_StochRsi = new CStochasticRSI(mSymbol, mTimeframe, InpStochRsiPeriod, InpStochKPeriod,
                                   InpStochSmoothing, InpStochSignal);
//--- m_Macd
   m_Macd = new CMacd(mSymbol, mTimeframe, InpFastMaPeriod, InpSlowMaPeriod, InpSignalPeriod);

   return m_StochRsi.Init() && m_Macd.Init();
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void CStrategyImpl::Release(void)
  {
   m_StochRsi.Release();
   m_Macd.Release();

   delete m_StochRsi;
   delete m_Macd;
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
Entry CStrategyImpl::FindEntry(const double ask, const double bid)
  {
   Entry entry = noEntry();
   if(!mIsNewBar)
      return entry;

//--- implement entry logic
   if(SupportLongEntries(InpLongShortFlag))
     {
      ENUM_ENTRY_SIGNAL stochSignal = m_StochRsi.TradeSignal(InpStochHowToEnter);
      ENUM_ENTRY_SIGNAL filterSignal = m_Macd.TradeSignal(InpMACDHowToEnter);

      if(filterSignal == stochSignal && stochSignal == ENTRY_SIGNAL_BUY)
        {
         entry.signal = stochSignal;
         entry.price = ask;
        }
     }

   if(SupportShortEntries(InpLongShortFlag))
     {
      ENUM_ENTRY_SIGNAL stochSignal = m_StochRsi.TradeSignal(InpStochHowToEnter);
      ENUM_ENTRY_SIGNAL filterSignal = m_Macd.TradeSignal(InpMACDHowToEnter);

      if(filterSignal == stochSignal && stochSignal == ENTRY_SIGNAL_SELL)
        {
         entry.signal = stochSignal;
         entry.price = bid;
        }
     }

   if(entry.signal != ENTRY_SIGNAL_NONE)
     {
      entry.sym = mSymbol;
      entry.magic = _expertMagic;
      entry.vol = mLotSize;
     }

   return entry;
  }


//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void CStrategyImpl::CheckAndSetExitSignal(CPositionInfo &positionInfo, Position &position)
  {
   ENUM_POSITION_TYPE posType = positionInfo.PositionType();
   bool filterSignalValid;

   if(posType == POSITION_TYPE_BUY)
     {
     }
   else
      if(posType == POSITION_TYPE_SELL)
        {
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

      m_Macd.Refresh(mRefShift);
      m_StochRsi.Refresh(mRefShift);
     }
  }

// the expert to run our strategy
CSingleExpert singleExpert(ExpertMagic, "MACD & Stochastic RSI");

//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+
int OnInit()
  {
//--- set up Trading Strategy Implementaion
   CStrategyImpl *strategy = new CStrategyImpl(_Symbol, InpTimeframe, InpLotSizeMultiple);
   CPositionManager *positionManager = new CMaxLossAmountPositionManager(_Symbol, InpTimeframe, 100);
   strategy.SetPositionManager(positionManager);
   singleExpert.SetStrategyImpl(strategy);

   if(singleExpert.OnInitHandler())
      return INIT_SUCCEEDED;
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
