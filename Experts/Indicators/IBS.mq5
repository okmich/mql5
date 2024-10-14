//+------------------------------------------------------------------+
//|                                                          IBS.mq5 |
//|                                    Copyright 2022, Michael Enudi |
//|                                             okmich2002@yahoo.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2022, Michael Enudi"
#property link      "okmich2002@yahoo.com"
#property version   "1.00"

#include <Okmich\Expert\SingleExpert.mqh>
#include <Okmich\Indicators\InternalBarStrength.mqh>

//--- input parameters
input group "********* Strategy settings *********";
input ENUM_TIMEFRAMES InpTimeframe = PERIOD_H1;             //Timeframe
input ENUM_LONG_SHORT_FLAG InpLongShortFlag = LONG_SHORT;   //Long/Short Flag

input group "********* Indicator settings *********";
input ENUM_IBS_Strategies InpHowTo = IBS_EnterOsOBLevels; //Type
input int      InpSmoothingPeriod=1;
input double   InpOBLevel=0.80;
input int      InpLotSizeMultiple=1; //Lot size Multiple

input ulong    ExpertMagic           = 980023;              //Expert MagicNumbers

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
class CMrv : public CStrategy
  {
private :
   ENUM_ENTRY_SIGNAL signal;
   //--- indicator values
   //--- indicator settings
   int               mMaPeriod;
   double            mOBLevel;

   //--- indicators
   CIbs              *m_Ibs;
   //--- indicator buffer
   //-- others

public:
                     CMrv(string symbol, ENUM_TIMEFRAMES period,
        int InptMaPeriod, double InptOBLevel): CStrategy(symbol, period)
     {
      mMaPeriod = InptMaPeriod;
      mOBLevel = InptOBLevel;

      mLotSize = InpLotSizeMultiple*SymbolInfoDouble(_Symbol, SYMBOL_VOLUME_MIN);
     };

   virtual bool      Init(ulong magic);
   virtual void      Refresh();
   virtual void      CheckAndSetExitSignal(CPositionInfo &positionInfo, Position &position);
   virtual void      Release();
  };

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
bool CMrv::Init(ulong magic)
  {
   CStrategy::Init(magic);
//--- price buffers
//--- m_Ibs
   m_Ibs = new CIbs(mSymbol, mTimeframe, mOBLevel, 1-mOBLevel, mMaPeriod > 2, mMaPeriod);
   return m_Ibs.Init();
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void CMrv::Release(void)
  {
   m_Ibs.Release();
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void CMrv::CheckAndSetExitSignal(CPositionInfo &positionInfo, Position &position)
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
void CMrv::Refresh(void)
  {
   if(IsNewBar())
     {
      int barsToCopy = 10;
      m_Ibs.Refresh();

      //--- take values from indicator
      signal = m_Ibs.TradeSignal(InpHowTo);
      mEntrySignal = SupportShortEntries(InpLongShortFlag) && signal == ENTRY_SIGNAL_SELL ? signal :
                     SupportLongEntries(InpLongShortFlag) && signal == ENTRY_SIGNAL_BUY ? signal : ENTRY_SIGNAL_NONE;
     }
  }

// the expert to run our strategy
CSingleExpert singleExpert(ExpertMagic, "...");

//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+
int OnInit()
  {
//--- set up Position manager Implementaion
   CPositionManager *positionManager = new CNoPositionManager(_Symbol, _Period);
//--- set up Trading Strategy Implementaion
   CMrv *strategy = new CMrv(_Symbol, _Period, InpSmoothingPeriod, InpOBLevel);
   strategy.SetPositionManager(positionManager);
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
