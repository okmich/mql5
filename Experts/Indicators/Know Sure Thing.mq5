//+------------------------------------------------------------------+
//|                                                     FilterEA.mq5 |
//|                                    Copyright 2022, Michael Enudi |
//|                                             okmich2002@yahoo.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2022, Michael Enudi"
#property link      "okmich2002@yahoo.com"
#property version   "1.00"

#include <Okmich\Expert\SingleExpert.mqh>
#include <Okmich\Indicators\KnowSureThing.mqh>

input ENUM_KST_Strategies InpHowTo = KST_AboveBelowSignal;
input int      InpRoc1Period=10;
input int      InpRoc1Ma=10;
input int      InpRoc2Period=15;
input int      InpRoc2Ma=10;
input int      InpRoc3Period=20;
input int      InpRoc3Ma=10;
input int      InpRoc4Period=30;
input int      InpRoc4Ma=15;
input int      InpSignalPeriod=9;

input ulong    ExpertMagic           = 980023;              //Expert MagicNumbers


//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
class CFilter : public CStrategy
  {
private :
   //--- indicator values
   //--- indicator settings
   int                m_Roc1Period, m_Roc2Period, m_Roc3Period, m_Roc4Period, m_Signal;
   int                m_RocMa1Period, m_RocMa2Period, m_RocMa3Period, m_RocMa4Period;

   //--- indicators
   CKst              *mKst;
   //--- indicator buffer
   //-- others


public:
                     CFilter(string symbol, ENUM_TIMEFRAMES period,
           int InptRoc1Period=10, int InptRoc2Period=15, int InptRoc3Period=20, int InptRoc4Period=30,
           int InptRocMa1Period=10, int InptRocMa2Period=10, int InptRocMa3Period=10, int InptRocMa4Period=15,
           int signal=5, int InptLotSizeMul=1): CStrategy(symbol, period)
     {
      m_Roc1Period = InptRoc1Period;
      m_Roc2Period = InptRoc2Period;
      m_Roc3Period = InptRoc3Period;
      m_Roc4Period = InptRoc4Period;
      m_RocMa1Period = InptRocMa1Period;
      m_RocMa2Period = InptRocMa2Period;
      m_RocMa3Period = InptRocMa3Period;
      m_RocMa4Period = InptRocMa4Period;
      m_Signal = signal;


      mLotSize = InptLotSizeMul*SymbolInfoDouble(_Symbol, SYMBOL_VOLUME_MIN);
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
//--- mKst
   mKst = new CKst(mSymbol, mTimeframe, m_Roc1Period, m_RocMa1Period,
                   m_Roc2Period, m_RocMa2Period,
                   m_Roc3Period, m_RocMa3Period,
                   m_Roc4Period, m_RocMa4Period,m_Signal);

   return mKst.Init();
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void CFilter::Release(void)
  {
   mKst.Release();
   delete mKst;
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void CFilter::CheckAndSetExitSignal(CPositionInfo &positionInfo, Position &position)
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
void CFilter::Refresh(void)
  {
   if(IsNewBar())
     {
      //--- mKst
      mKst.Refresh();
      mEntrySignal = mKst.TradeFilter(InpHowTo);
     }
  }

// the expert to run our strategy
CSingleExpert singleExpert(ExpertMagic, 10);

//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+
int OnInit()
  {
   CFilter *strategy = new CFilter(_Symbol, _Period, InpRoc1Ma, InpRoc1Period,  InpRoc2Ma, InpRoc2Period,
                                   InpRoc3Ma, InpRoc3Period, InpRoc4Ma, InpRoc4Period);
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
