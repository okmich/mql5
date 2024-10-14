//+------------------------------------------------------------------+
//|                                                     FilterEA.mq5 |
//|                                    Copyright 2021, Michael Enudi |
//|                                             okmich2002@yahoo.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2021, Michael Enudi"
#property link      "okmich2002@yahoo.com"
#property version   "1.00"

#include <Okmich\Expert\SingleExpert.mqh>
#include <Okmich\Indicators\DslRsiOfHull.mqh>

//--- input parameters
input group "********* Setting **********";
input ENUM_TIMEFRAMES InpTimeframe = PERIOD_H1;             //Timeframe
input ENUM_LONG_SHORT_FLAG InpLongShortFlag = LONG;   //Long/Short Flag

input ENUM_RSIHULL_Strategies  InpHowSignal = RSIHULL_AboveBelowMidLevelFilter;                    //Signal Type
input int    InpRsiPeriod = 14;                      //RSI period
input int    InpMaPeriod  = 32;                      //Moving average period
input int    InpDslSignalPeriod  = 9;                //DSL Signal period
input int    InpDslObLevel  = 80;                    //DSL Overbought Level
input bool   InpAnchorLevels  = true;                //Use floating levels
input ulong  ExpertMagic = 980023;                   //Expert MagicNumbers


//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
class CFilter : public CStrategy
  {
private :
   //--- indicator values
   ENUM_ENTRY_SIGNAL signal;
   //--- indicator settings
   int                m_RsiPeriod, m_MaPeriod, m_DslSignalPeriod;
   bool               m_FloatingLevels;
   //--- indicators
   CDslRsiHull       *mMaRSI;
   //--- indicator buffer
   //-- others


public:
                     CFilter(string symbol, ENUM_TIMEFRAMES period,
           int InptRsiPeriod=14, int InptMaPeriod=32, int InptDslSignal = 9,
           bool useFloatinglevels=true): CStrategy(symbol, period)
     {
      m_RsiPeriod = InptRsiPeriod;
      m_MaPeriod = InptMaPeriod;
      m_DslSignalPeriod = InptDslSignal;
      m_FloatingLevels = useFloatinglevels;

      mLotSize = SymbolInfoDouble(_Symbol, SYMBOL_VOLUME_MIN);
     };

   virtual bool      Init(ulong magic);
   virtual void      Refresh();
   virtual void      CheckAndSetExitSignal(CPositionInfo &positionInfo, Position &position);
   virtual void      Release();
  };

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
bool CFilter::Init(ulong magic)
  {
   CStrategy::Init(magic);
//--- mMaRSI
   mMaRSI = new CDslRsiHull(mSymbol, mTimeframe, m_RsiPeriod, m_MaPeriod, m_DslSignalPeriod, m_FloatingLevels, InpDslObLevel);
   return mMaRSI.Init();
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void CFilter::Release(void)
  {
   mMaRSI.Release();
   delete mMaRSI;
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void CFilter::CheckAndSetExitSignal(CPositionInfo &positionInfo, Position &position)
  {
   ENUM_POSITION_TYPE posType = positionInfo.PositionType();
   if(posType == POSITION_TYPE_BUY && signal == ENTRY_SIGNAL_SELL)
     {
      position.signal = EXIT_SIGNAL_EXIT;
     }
   else
      if(posType == POSITION_TYPE_SELL && signal == ENTRY_SIGNAL_BUY)
        {
         position.signal = EXIT_SIGNAL_EXIT;
        }
  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void CFilter::Refresh(void)
  {
   if(IsNewBar())
     {
      //-- mMaRSI
      bool bool1 = mMaRSI.Refresh();
      
      signal = mMaRSI.TradeSignal(InpHowSignal);
      mEntrySignal = SupportShortEntries(InpLongShortFlag) && signal == ENTRY_SIGNAL_SELL ? signal :
                     SupportLongEntries(InpLongShortFlag) && signal == ENTRY_SIGNAL_BUY ? signal : ENTRY_SIGNAL_NONE;
     }
  }

// the expert to run our strategy
CSingleExpert singleExpert(ExpertMagic, "DslRsiofHull");

//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+
int OnInit()
  {
   CFilter *strategy = new CFilter(_Symbol, _Period, InpRsiPeriod, InpMaPeriod, InpDslSignalPeriod, InpAnchorLevels);
//set position management
   CPositionManager *PositionManager = new CNoPositionManager(_Symbol, _Period);
   strategy.SetPositionManager(PositionManager);

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
