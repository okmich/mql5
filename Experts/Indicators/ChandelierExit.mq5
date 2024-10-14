//+------------------------------------------------------------------+
//|                                MovingAverageRsiDslFilter.mq5.mq5 |
//|                                    Copyright 2021, Michael Enudi |
//|                                             okmich2002@yahoo.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2021, Michael Enudi"
#property link      "okmich2002@yahoo.com"
#property version   "1.00"

#include <Okmich\Expert\SingleExpert.mqh>
#include <Okmich\Indicators\ChandelierExit.mqh>

input int    InpAtrPeriod = 22;                          //ATR period
input double InpAtrMultiplier1  = 1.5;                   //ATR multiplier 1
input double InpAtrMultiplier2  = 3.0;                   //ATR multiplier 2
input int   InpCceLookback  = 22;                        //CCE Lookback

input ulong    ExpertMagic = 980023;                     //Expert MagicNumbers

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
class CFilter : public CStrategy
  {
private :
   //--- indicator values
   double            mCloseShift1;
   bool              mIsTrending;
   //--- indicator settings
   int               m_AtrPeriod, m_CCELookback;
   double            m_AtrMulti1, m_AtrMulti2;
   //--- indicators
   CChandelierExit    *mCcExit;
   //--- indicator buffer
   double            m_CloseBuffer[];
   //-- others


public:
                     CFilter(string symbol, ENUM_TIMEFRAMES period,
           int InptAtrPeriod, double InptAtrMulti1,
           double InptAtrMulti2, int InptCexitLookback): CStrategy(symbol, period)
     {
      m_AtrPeriod = InptAtrPeriod;
      m_AtrMulti1 = InptAtrMulti1;
      m_AtrMulti2 = InptAtrMulti2;
      m_CCELookback = InptCexitLookback;

      mLotSize = 2 * SymbolInfoDouble(_Symbol, SYMBOL_VOLUME_MIN);
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
//--- mCcExit
   mCcExit = new CChandelierExit(mSymbol, mTimeframe, m_AtrPeriod, m_AtrMulti1, m_AtrMulti2, m_CCELookback);

   return mCcExit.Init();
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void CFilter::Release(void)
  {
   mCcExit.Release();
   delete mCcExit;
  }


//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void CFilter::CheckAndSetExitSignal(CPositionInfo &positionInfo, Position &position)
  {
   ENUM_POSITION_TYPE posType = positionInfo.PositionType();
   if(posType == POSITION_TYPE_BUY && mEntrySignal != ENTRY_SIGNAL_BUY)
      position.signal = EXIT_SIGNAL_EXIT;
   else
      if(posType == POSITION_TYPE_SELL && mEntrySignal != ENTRY_SIGNAL_SELL)
         position.signal = EXIT_SIGNAL_EXIT;
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void CFilter::Refresh(void)
  {
   if(IsNewBar())
     {
      //-- mCcExit
      mCcExit.Refresh();

      mEntrySignal = mCcExit.TradeSignal();
     }
  }
// the expert to run our strategy
CSingleExpert singleExpert(ExpertMagic, 0);

//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+
int OnInit()
  {
   CFilter *strategy = new CFilter(_Symbol, _Period,
                                   InpAtrPeriod, InpAtrMultiplier1, InpAtrMultiplier2, InpCceLookback);
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
