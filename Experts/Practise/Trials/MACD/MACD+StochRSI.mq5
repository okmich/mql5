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

input group "********* Long Strategy settings *********";
input int      InpLongFastMaPeriod=12;
input int      InpLongSlowMaPeriod=26;
input int      InpLongSignalPeriod=9;

input ENUM_STOCHRSI_Strategies InpLongStochHowToEnter = STOCHRSI_EnterOsOBLevels; //Entry Strategy
input int         InpLongStochRsiPeriod=12;
input int         InpLongStochKPeriod=5;
input int         InpLongStochSmoothing=3;
input int         InpLongStochSignal=3;
input double      InpLongStochOBLevel=80;
input double      InpLongStochOSLevel=20;

input double   InpLongTpAtrMultiples=2.25;
input double   InpLongSlAtrMultiples=3.75;

input group "********* Short Strategy settings *********";
input int      InpShortFastMaPeriod=12;
input int      InpShortSlowMaPeriod=26;
input int      InpShortSignalPeriod=9;

input ENUM_STOCHRSI_Strategies InpShortStochHowToEnter = STOCHRSI_EnterOsOBLevels; //Entry Strategy
input int         InpShortStochRsiPeriod=12;
input int         InpShortStochKPeriod=5;
input int         InpShortStochSmoothing=3;
input int         InpShortStochSignal=3;
input double      InpShortStochOBLevel=80;
input double      InpShortStochOSLevel=20;

input double   InpShortTpAtrMultiples=3.5;
input double   InpShortSlAtrMultiples=4.75;

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
   CStochasticRSI    *m_StochRsis[2];
   CMacd             *m_Macds[2];
   //-- others

protected:
   virtual Entry     FindEntry(const double ask, const double bid);

public:
                     CStrategyImpl(string symbol, ENUM_TIMEFRAMES period,
                 int InptLotSizeMultiple): CStrategy(symbol, period)
     {
      mLotSize = InptLotSizeMultiple * SymbolInfoDouble(mSymbol, SYMBOL_VOLUME_MIN);

      CAtrFixedPositionManager *posManager = new CAtrFixedPositionManager(
         symbol, InpTimeframe,
         ATR_PERIOD, InpLongSlAtrMultiples, 1000, InpLongTpAtrMultiples,1000,
         false, false, 100);
      SetPositionManager(posManager);
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
//--- m_StochRsis
   m_StochRsis[0] = new CStochasticRSI(mSymbol, mTimeframe, InpLongStochRsiPeriod, InpLongStochKPeriod,
                                       InpLongStochSmoothing, InpLongStochSignal,
                                       InpLongStochOBLevel, InpLongStochOSLevel);

   m_StochRsis[1] = new CStochasticRSI(mSymbol, mTimeframe, InpShortStochRsiPeriod, InpShortStochKPeriod,
                                       InpShortStochSmoothing, InpShortStochSignal,
                                       InpShortStochOBLevel, InpShortStochOSLevel);
   bool kcInited = m_Macds[0].Init() && m_Macds[1].Init();
//--- m_Macds
   m_Macds[0] = new CMacd(mSymbol, mTimeframe, InpLongFastMaPeriod, InpLongSlowMaPeriod, InpLongSignalPeriod);
   m_Macds[1] = new CMacd(mSymbol, mTimeframe, InpShortFastMaPeriod, InpShortSlowMaPeriod, InpShortSignalPeriod);
   bool maInited = m_Macds[0].Init() && m_Macds[1].Init();

   return kcInited && maInited;
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void CStrategyImpl::Release(void)
  {
   for(int i = 0; i < 2; i++)
     {
      m_StochRsis[i].Release();
      m_Macds[i].Release();

      delete m_StochRsis[i];
      delete m_Macds[i];
     }
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
      ENUM_ENTRY_SIGNAL stochSignal = m_StochRsis[0].TradeSignal(InpLongStochHowToEnter);
      ENUM_ENTRY_SIGNAL filterSignal = m_Macds[0].TradeSignal(MACD_ZeroLineCrossover);

      if(filterSignal == stochSignal && stochSignal == ENTRY_SIGNAL_BUY)
        {
         entry.signal = stochSignal;
         entry.price = ask;

         CAtrFixedPositionManager *posManager = mPositionManager;
         posManager.SetStopLossMultiple(InpLongSlAtrMultiples);
         posManager.SetTakeProfitMultiple(InpLongTpAtrMultiples);
        }
     }

   if(SupportShortEntries(InpLongShortFlag))
     {
      ENUM_ENTRY_SIGNAL stochSignal = m_StochRsis[1].TradeSignal(InpShortStochHowToEnter);
      ENUM_ENTRY_SIGNAL filterSignal = m_Macds[1].TradeSignal(MACD_ZeroLineCrossover);

      if(filterSignal == stochSignal && stochSignal == ENTRY_SIGNAL_SELL)
        {
         entry.signal = stochSignal;
         entry.price = bid;

         CAtrFixedPositionManager *posManager = mPositionManager;
         posManager.SetStopLossMultiple(InpShortSlAtrMultiples);
         posManager.SetTakeProfitMultiple(InpShortTpAtrMultiples);
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
      filterSignalValid = m_Macds[0].GetData(0, mRefShift) > 0;
      if(!filterSignalValid)
        {
         position.signal = EXIT_SIGNAL_EXIT;
        }
      else
        {
         ENUM_ENTRY_SIGNAL stochSignal = m_StochRsis[0].TradeSignal(STOCHRSI_EnterOsOBLevels);
         if(stochSignal == ENTRY_SIGNAL_SELL)
           {
            position.signal = EXIT_SIGNAL_EXIT;
           }
        }
     }
   else
      if(posType == POSITION_TYPE_SELL)
        {
         filterSignalValid = m_Macds[1].GetData(0, mRefShift) < 0;
         if(!filterSignalValid)
           {
            position.signal = EXIT_SIGNAL_EXIT;
           }
         else
           {
            ENUM_ENTRY_SIGNAL stochSignal = m_StochRsis[1].TradeSignal(STOCHRSI_EnterOsOBLevels);
            if(stochSignal == ENTRY_SIGNAL_BUY)
              {
               position.signal = EXIT_SIGNAL_EXIT;
              }
           }
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

      for(int i = 0; i < 2; i++)
        {
         m_Macds[i].Refresh(mRefShift);
         m_StochRsis[i].Refresh(mRefShift);
        }
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
