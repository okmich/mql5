//+------------------------------------------------------------------+
//|                                          TTMSqueeze+DayLater.mq5 |
//|                                    Copyright 2024, Michael Enudi |
//|                                             okmich2002@yahoo.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2024, Michael Enudi"
#property link      "okmich2002@yahoo.com"
#property version   "1.00"

#include <Okmich\Expert\SingleExpert.mqh>
#include <Okmich\Indicators\TTMSqueeze.mqh>

//+------------------------------------------------------------------+
//| Input parameters                                                 |
//+------------------------------------------------------------------+
input group "********* Strategy settings *********";
input ENUM_TIMEFRAMES InpTimeframe = PERIOD_D1;             //Timeframe
input ENUM_LONG_SHORT_FLAG InpLongShortFlag = LONG_SHORT;   //Long/Short Flag

input group "********* Long Strategy settings *********";
input int    InpLongBBandsPeriod     = 20;                      //BBMA period
input double InpLongBBandsDeviation  = 2.0;                     //BB deviation
input int    InpLongTtmSqzKcPeriod     = 20;                    //Kelter Channel period
input double InpLongTtmSqzKcDeviation  = 1.5;                   //Kelter Channel Multifactor
input int InpBuyHoldDays = 1;

input group "********* Short Strategy settings *********";
input int    InpShortBBandsPeriod     = 20;                      //BBMA period
input double InpShortBBandsDeviation  = 2.0;                     //BB deviation
input int    InpShortTtmSqzKcPeriod     = 20;                    //Kelter Channel period
input double InpShortTtmSqzKcDeviation  = 1.5;                   //Kelter Channel Multifactor
input int InpSellHoldDays = 1;

input group "********* Position management settings *********";
input ENUM_POSITION_MANAGEMENT InpPostManagmentType = POSITION_MGT_FIXED_POINTS;  // Type of Position Management Algorithm
input int InpATRPeriod = 14;                          // ATR Period
input double InpStopLossPoints = -1;                  // Stop loss distance in points
input double InpBreakEvenPoints = -1;                 // Points to Break-even
input double InpTrailingOrTpPoints = -1;              // Trailing/Take profit points
input double InpMaxLossAmount = 100.00;               // Maximum allowable loss in dollars

input group "********* Other setting **********";
input int InpLotSizeMultiple = 1;                     //Multiple of minimum lot size
input ulong    ExpertMagic   = 980023;                //Expert MagicNumbers

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
   CTTMSqueeze       *m_TtmSqueezes[2];
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
//--- m_TtmSqueezes
   m_TtmSqueezes[0] = new CTTMSqueeze(mSymbol, mTimeframe, InpLongBBandsPeriod, InpLongBBandsDeviation,
                                      InpLongTtmSqzKcPeriod, InpLongTtmSqzKcDeviation);
   m_TtmSqueezes[1] = new CTTMSqueeze(mSymbol, mTimeframe, InpShortBBandsPeriod, InpShortBBandsDeviation,
                                      InpShortTtmSqzKcPeriod, InpShortTtmSqzKcDeviation);
   bool maInited = m_TtmSqueezes[0].Init() && m_TtmSqueezes[1].Init();

   return maInited;
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void CStrategyImpl::Release(void)
  {
   for(int i = 0; i < 2; i++)
     {
      m_TtmSqueezes[i].Release();
      delete m_TtmSqueezes[i];
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
      ENUM_ENTRY_SIGNAL signal = m_TtmSqueezes[0].TradeSignal(TTMSqueeze_CrossesZeroLine);

      if(signal == ENTRY_SIGNAL_BUY)
        {
         entry.signal = signal;
         entry.price = ask;
        }
     }

   if(SupportShortEntries(InpLongShortFlag))
     {
      ENUM_ENTRY_SIGNAL signal = m_TtmSqueezes[1].TradeSignal(TTMSqueeze_CrossesZeroLine);

      if(signal == ENTRY_SIGNAL_SELL)
        {
         entry.signal = signal;
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
   if(!mIsNewBar)
      return;

   ENUM_POSITION_TYPE postType = positionInfo.PositionType();
//get the number of bars since open
   int shift = iBarShift(mSymbol, mTimeframe, positionInfo.Time());
   int holdDays = postType == POSITION_TYPE_BUY ? InpBuyHoldDays : InpSellHoldDays;
   if(shift >= holdDays)
     {
      position.signal = EXIT_SIGNAL_EXIT;
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
         m_TtmSqueezes[i].Refresh(mRefShift);
        }
     }
  }

// the expert to run our strategy
CSingleExpert singleExpert(ExpertMagic, "...");

//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+
int OnInit()
  {
//--- set up Trading Strategy Implementaion
   CStrategyImpl *strategy = new CStrategyImpl(_Symbol, InpTimeframe, InpLotSizeMultiple);
   CPositionManager *positionManager = CreatPositionManager(_Symbol, InpTimeframe,
                                       InpPostManagmentType,
                                       InpATRPeriod, InpStopLossPoints, InpBreakEvenPoints, InpTrailingOrTpPoints,
                                       InpMaxLossAmount, false, false, 5,
                                       -1, -1, -1);
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
