//+------------------------------------------------------------------+
//|                                                       iTrend.mq5 |
//|                                    Copyright 2022, Michael Enudi |
//|                                             okmich2002@yahoo.com |
//+------------------------------------------------------------------+
#property copyright " Copyright 2022, Michael Enudi"
#property link      "okmich2002@yahoo.com"
#property version   "1.00"

#include <Okmich\Expert\SingleExpert.mqh>
#include <Okmich\Indicators\iTrend.mqh>

//--- input parameters
input int    InpBBandsPeriod       = 20;                      //Bollinger bands moving average period
input double InpBBandsDeviation    = 2.0;                     //Bollinger bands deviation
input ENUM_BBLine    InpBBLineType = Base;         //Bollinger band 
input int    InpBullBearPeriod     = 14;                      //Bull and Bear period
input ulong    ExpertMagic         = 980023;              //Expert MagicNumbers

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
class CStrategryImpl : public CStrategy
  {
private :
   //--- indicator values
   //--- indicator settings
   int                m_MaPeriod, m_BullBearPeriod;
   double             m_Deviation;
   ENUM_BBLine        m_BBLineType;
   //--- indicators
   CiTrend           *m_iTrend;
   //--- indicator buffer
   //-- others


public:
                     CStrategryImpl(string symbol, ENUM_TIMEFRAMES period,
                  int InputBBMaPeriod,  double InputDeviation,
                  int InputBearBullPeriod, ENUM_BBLine InputBBLineType): CStrategy(symbol, period)
     {
      m_MaPeriod = InputBBMaPeriod;
      m_BullBearPeriod = InputBearBullPeriod;
      m_Deviation = InputDeviation;
      m_BBLineType = InputBBLineType;

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
bool CStrategryImpl::Init(ulong magic)
  {
   CStrategy::Init(magic);
//--- m_iTrend
   m_iTrend = new CiTrend(mSymbol, mTimeframe, m_MaPeriod, m_Deviation, m_BullBearPeriod, m_BBLineType);
   return m_iTrend.Init();
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void CStrategryImpl::Release(void)
  {
   m_iTrend.Release();
   delete m_iTrend;
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void CStrategryImpl::CheckAndSetExitSignal(CPositionInfo &positionInfo, Position &position)
  {
   ENUM_POSITION_TYPE posType = positionInfo.PositionType();
   if(posType == POSITION_TYPE_BUY && mEntrySignal == ENTRY_SIGNAL_SELL)
      position.signal = EXIT_SIGNAL_EXIT;
   else
      if(posType == POSITION_TYPE_SELL && mEntrySignal == ENTRY_SIGNAL_BUY)
         position.signal = EXIT_SIGNAL_EXIT;
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void CStrategryImpl::Refresh(void)
  {
   if(IsNewBar())
     {
      bool refreshed = m_iTrend.Refresh();
      //--- take values from indicator
      mEntrySignal = m_iTrend.TradeSignal();
     }
  }

// the expert to run our strategy
CSingleExpert singleExpert(ExpertMagic, 10);
//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+
int OnInit()
  {
   CStrategryImpl *strategy =
      new CStrategryImpl(_Symbol, _Period, InpBBandsPeriod, InpBBandsDeviation, InpBullBearPeriod, InpBBLineType);
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
