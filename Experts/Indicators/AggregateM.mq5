//+------------------------------------------------------------------+
//|                                                   AggregateM.mq5 |
//|                                    Copyright 2021, Michael Enudi |
//|                                             okmich2002@yahoo.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2021, Michael Enudi"
#property link      "okmich2002@yahoo.com"
#property version   "1.00"

#include <Okmich\Expert\SingleExpert.mqh>
#include <Okmich\Indicators\AggregateM.mqh>

//--- input parameters
input ENUM_AGGM_Strategies InpHowTo = AGGM_ContraEnterOsOBLevels; //Strategy for entry
input int      InpShortRankPeriod=10;
input int      InpLongRankPeriod=252;
input int      InpSignalPeriod=3;
input int      InpOBLevel=85;

input ulong    ExpertMagic           = 980023;              //Expert MagicNumbers

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
class CMrv : public CStrategy
  {
private :
   //--- indicator values
   //--- indicator settings
   int               mShortRankPeriod, mLongRnkPeriod, mSignalPeriod;
   double            mOBLevel;

   //--- indicators
   CAggregateM       *m_Aggm;
   //--- indicator buffer
   //-- others

public:
                     CMrv(string symbol, ENUM_TIMEFRAMES period,
        int InptShtRankPeriod, int InptLngRankPeriod, int InptSignalPeriod,
        int InptOBLevel): CStrategy(symbol, period)
     {
      mShortRankPeriod = InptShtRankPeriod;
      mLongRnkPeriod = InptLngRankPeriod;
      mSignalPeriod = InptSignalPeriod;
      mOBLevel = InptOBLevel;

      mLotSize = SymbolInfoDouble(mSymbol, SYMBOL_VOLUME_MIN);
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
//--- m_Aggm
   m_Aggm = new CAggregateM(mSymbol, mTimeframe, mShortRankPeriod, mLongRnkPeriod, mSignalPeriod,mOBLevel, 100-mOBLevel);
   return m_Aggm.Init();
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void CMrv::Release(void)
  {
   m_Aggm.Release();
   delete m_Aggm;
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void CMrv::CheckAndSetExitSignal(CPositionInfo &positionInfo, Position &position)
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
void CMrv::Refresh(void)
  {
   if(IsNewBar())
     {
      m_Aggm.Refresh();

      //--- take values from indicator
      mEntrySignal = m_Aggm.TradeSignal(InpHowTo);
     }
  }

// the expert to run our strategy
CSingleExpert singleExpert(ExpertMagic, 10);

//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+
int OnInit()
  {
//--- set up Position manager Implementaion
   CPositionManager *positionManager = new CNoPositionManager(_Symbol, _Period);
//--- set up Trading Strategy Implementaion
   CMrv *strategy = new CMrv(_Symbol, _Period, InpShortRankPeriod, InpLongRankPeriod, InpSignalPeriod, InpOBLevel);
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
