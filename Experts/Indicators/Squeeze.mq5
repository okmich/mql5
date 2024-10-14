//+------------------------------------------------------------------+
//|                                                      Squeeze.mq5 |
//|                                    Copyright 2021, Michael Enudi |
//|                                             okmich2002@yahoo.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2021, Michael Enudi"
#property link      "okmich2002@yahoo.com"
#property version   "1.00"

#include <Okmich\Expert\StrategyExecExpert.mqh>
#include <Okmich\Indicators\Squeeze.mqh>

input int    InpPeriod  = 25;                      //MA Period
input ulong  ExpertMagic = 980023;                 //Expert MagicNumbers


//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
class CFilter : public CStrategy
  {
private :
   //--- indicator values
   bool              mIsTrending;
   //--- indicator settings
   int               m_Period;
   //--- indicators
   CSqueeze          *mSqueeze;
   //--- indicator buffer
   //-- others


public:
                     CFilter(string symbol, ENUM_TIMEFRAMES period, int InptPeriod=25): CStrategy(symbol, period)
     {
      m_Period = InptPeriod;
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
//--- price buffers
//--- mSqueeze
   mSqueeze = new CSqueeze(mSymbol, mTimeframe, m_Period);
   return mSqueeze.Init();
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void CFilter::Release(void)
  {
   mSqueeze.Release();
   delete mSqueeze;
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void CFilter::CheckAndSetExitSignal(CPositionInfo &positionInfo, Position &position)
  {
   ENUM_POSITION_TYPE posType = positionInfo.PositionType();
   if(posType == POSITION_TYPE_BUY && mEntrySignal != ENTRY_SIGNAL_BUY)
     {
      position.signal = EXIT_SIGNAL_EXIT;
     }
   else
      if(posType == POSITION_TYPE_SELL && mEntrySignal != ENTRY_SIGNAL_SELL)
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
      int barsToCopy = 10;
      //--- price buffers
      //-- mSqueeze
      bool bool1 = mSqueeze.Refresh();

      mEntrySignal = mSqueeze.TradeSignal();
      mIsTrending = mSqueeze.IsTrending();
     }
  }

// the expert to run our strategy
CStrategyExecExpert expert(ExpertMagic, 0);

//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+
int OnInit()
  {
//--- set up Time Filter
   CTimeFilter *timeFilter = new CNoTimeFilter();
   expert.SetTimeFilter(timeFilter);

//--- set up Position manager Implementaion
   CPositionManager *positionManager = new CNoPositionManager(_Symbol, _Period);
   expert.SetPositionManager(new CNoPositionManager(_Symbol, _Period));

//--- set up Trading Strategy Implementaion
   CFilter *strategy = new CFilter(_Symbol, _Period, InpPeriod);
   expert.SetTradeStrategy(strategy);

//---
   return expert.DoInit();
  }

//+------------------------------------------------------------------+
//| Expert deinitialization function                                 |
//+------------------------------------------------------------------+
void OnDeinit(const int reason)
  {
//--- destroy timer
   expert.Deinit();
  }

//+------------------------------------------------------------------+
//| Expert tick function                                             |
//+------------------------------------------------------------------+
void OnTick()
  {
//---
   expert.DoOnTick();
  }
//+------------------------------------------------------------------+
