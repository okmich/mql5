//+------------------------------------------------------------------+
//|                                                     AscTrend.mq5 |
//|                                    Copyright 2022, Michael Enudi |
//|                                             okmich2002@yahoo.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2022, Michael Enudi"
#property link      "okmich2002@yahoo.com"
#property version   "1.00"

#include <Okmich\Expert\SingleExpert.mqh>
#include <Okmich\Indicators\AscTrend.mqh>

//--- input parameters
input group "********* Settings *********";
input ENUM_TIMEFRAMES InpTimeframe = PERIOD_CURRENT;             //Timeframe
input ENUM_LONG_SHORT_FLAG InpLongShortFlag = LONG_SHORT;   //Long/Short Flag

input group "********* Strategy settings *********";
input int      InpRisk=3;
input int      InpLotSizeMultiple=1; //Lot size

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
class CStrategyImpl : public CStrategy
  {
private :
   //--- indicator values
   ENUM_ENTRY_SIGNAL signal;
   //--- indicator settings
   int               mRisk;
   //--- indicators
   CAscTrend         *m_AscTrend;
   //--- indicator buffer
   //-- others


public:
                     CStrategyImpl(string symbol, ENUM_TIMEFRAMES period, int InptRisk): CStrategy(symbol, period)
     {
      mRisk = InptRisk;
      mLotSize = InpLotSizeMultiple * SymbolInfoDouble(mSymbol, SYMBOL_VOLUME_MIN);
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
//--- m_AscTrend
   m_AscTrend = new CAscTrend(mSymbol, mTimeframe, mRisk);
   return m_AscTrend.Init();
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void CStrategyImpl::Release(void)
  {
   m_AscTrend.Release();
   delete m_AscTrend;
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void CStrategyImpl::CheckAndSetExitSignal(CPositionInfo &positionInfo, Position &position)
  {
   ENUM_POSITION_TYPE posType = positionInfo.PositionType();
   if(posType == POSITION_TYPE_BUY && signal == ENTRY_SIGNAL_SELL)
      position.signal = EXIT_SIGNAL_EXIT;
   else
      if(posType == POSITION_TYPE_SELL && signal == ENTRY_SIGNAL_BUY)
         position.signal = EXIT_SIGNAL_EXIT;
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void CStrategyImpl::Refresh(void)
  {
   if(IsNewBar())
     {
      bool refreshed = m_AscTrend.Refresh();
      //--- take values from indicator
      signal = m_AscTrend.TradeSignal();
      ENUM_ENTRY_SIGNAL filter = m_AscTrend.TradeFilter();
      if(SupportLongEntries(InpLongShortFlag) && signal == ENTRY_SIGNAL_BUY)
        {
         mEntrySignal = ENTRY_SIGNAL_BUY;
        }
      else
         if(SupportShortEntries(InpLongShortFlag) && signal == ENTRY_SIGNAL_SELL)
           {
            mEntrySignal = ENTRY_SIGNAL_SELL;
           }
         else
           {
            mEntrySignal = ENTRY_SIGNAL_NONE;
           }
     }
  }

// the expert to run our strategy
CSingleExpert singleExpert(32938393, "AscTrend");
//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+
int OnInit()
  {
   CStrategyImpl *strategy =
      new CStrategyImpl(_Symbol, _Period, InpRisk);
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

//+------------------------------------------------------------------+
