//+------------------------------------------------------------------+
//|                                                MACD+StochRSI.mq5 |
//|                                    Copyright 2024, Michael Enudi |
//|                                             okmich2002@yahoo.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2024, Michael Enudi"
#property link      "okmich2002@yahoo.com"
#property version   "1.00"

#include <Okmich\Expert\SingleExpert.mqh>
#include <Okmich\Indicators\Macd.mqh>

//--- input EXPERT_MAGIC
const ulong EXPERT_MAGIC = 1000000000;

//+------------------------------------------------------------------+
//| Input parameters                                                 |
//+------------------------------------------------------------------+
input group "********* Strategy settings *********";
input ENUM_TIMEFRAMES InpTimeframe = PERIOD_M12;             //Timeframe
input ENUM_TIMEFRAMES InpHigherTimeframe = PERIOD_H1;        //Higher Timeframe
input ENUM_LONG_SHORT_FLAG InpLongShortFlag = LONG_SHORT;    //Long/Short Flag

input group "********* Long Strategy settings *********";
input ENUM_MACD_Strategies InpSignalType = MACD_ZeroLineCrossover; //Entry strategy
input int      InpFastMaPeriod=12;
input int      InpSlowMaPeriod=26;
input int      InpSignalPeriod=9;

input group "********* Volume setting **********";
input int InpLotSizeMultiple = 1;                     //Multiple of minimum lot size

input group "********* Position management settings *********";
input ENUM_POSITION_MANAGEMENT InpPostManagmentType = POSITION_MGT_FIXED_ATR_MULTIPLES;  // Type of Position Management Algorithm
input int InpATRPeriod = 14;                          // ATR Period
input double InpStopLossPoints = -1;                  // Stop loss distance in points
input double InpBreakEvenPoints = -1;                 // Points to Break-even
input double InpTrailingOrTpPoints = -1;              // Trailing/Take profit points
input double InpMaxLossAmount = 100.00;               // Maximum allowable loss in dollars
input bool InpScratchBreakEvenFlag = true;            // Enable break-even with scratch profit
input double InpStopLossMultiple = 2;                 // ATR multiple for stop loss
input double InpBreakEvenMultiple = 1;                // ATR multiple for break-even
input double InpTrailingOrTpMultiple = 2;             // ATR multiple for Maximum floating/Take profit

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
class CStrategyImpl : public CStrategy
  {
private :
   //--- indicator values
   ENUM_ENTRY_SIGNAL macdSignal, higherMacdFilter;
   //--- indicator settings

   //--- indicators
   CMacd             *m_Macds[2];

   //--- indicator buffer

protected:
   virtual Entry     FindEntry(const double ask, const double bid);

public:
                     CStrategyImpl(string symbol, ENUM_TIMEFRAMES period, int InptVolMultiple): CStrategy(symbol, period)
     {
      mLotSize = InptVolMultiple*SymbolInfoDouble(_Symbol, SYMBOL_VOLUME_MIN);
     };

   virtual bool      Init(ulong magic);
   virtual void      CheckAndSetExitSignal(CPositionInfo &positionInfo, Position &position);
   virtual void      Refresh();
   virtual void      Release();
  };

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
bool CStrategyImpl::Init(ulong magic)
  {
   if(mTimeframe >= InpHigherTimeframe)
     {
      SetReturnError(1000);
      return false;
     }

   CStrategy::Init(magic);
//--- m_Macds
   m_Macds[0] = new CMacd(mSymbol, mTimeframe, InpFastMaPeriod, InpSlowMaPeriod, InpSignalPeriod);
   m_Macds[1] = new CMacd(mSymbol, InpHigherTimeframe, InpFastMaPeriod, InpSlowMaPeriod, InpSignalPeriod);

   return m_Macds[0].Init() && m_Macds[1].Init();
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void CStrategyImpl::Release(void)
  {
   for(int i = 0; i < 2; i++)
     {
      m_Macds[i].Release();
      delete m_Macds[i];
     }
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void CStrategyImpl::Refresh(void)
  {
   int barsToCopy = 4;
//--- Check for new bar
   if(IsNewBar())
     {
      m_Macds[0].Refresh(mRefShift);
      m_Macds[1].Refresh(0);

      macdSignal = m_Macds[0].TradeSignal(InpSignalType);
      higherMacdFilter = m_Macds[1].TradeFilter(InpSignalType);
      mEntrySignal = higherMacdFilter == macdSignal && macdSignal == ENTRY_SIGNAL_SELL ? macdSignal :
                     higherMacdFilter == macdSignal && macdSignal == ENTRY_SIGNAL_BUY ? macdSignal :
                     ENTRY_SIGNAL_NONE;
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
      if(mEntrySignal == ENTRY_SIGNAL_BUY)
        {
         entry.signal = ENTRY_SIGNAL_BUY;
         entry.price = ask;
        }
     }
   else
      if(SupportShortEntries(InpLongShortFlag))
        {
         if(mEntrySignal == ENTRY_SIGNAL_SELL)
           {
            entry.signal = ENTRY_SIGNAL_SELL;
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
void CStrategyImpl::CheckAndSetExitSignal(CPositionInfo &positionInfo,Position &position)
  {
   if(!mIsNewBar)
      return;

   ENUM_POSITION_TYPE postType = positionInfo.PositionType();
//if(postType == POSITION_TYPE_BUY && macdSignal == ENTRY_SIGNAL_SELL)
//  {
//   position.signal = EXIT_SIGNAL_EXIT;
//  }
//else
//   if(postType == POSITION_TYPE_SELL && macdSignal == ENTRY_SIGNAL_BUY)
//     {
//      position.signal = EXIT_SIGNAL_EXIT;
//     }
  }
//+------------------------------------------------------------------+


// the expert to run our strategy
CSingleExpert singleExpert(EXPERT_MAGIC, "MACD__001");

//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+
int OnInit()
  {
   CStrategy *strategy = new CStrategyImpl(_Symbol, _Period, InpLotSizeMultiple);
   CPositionManager *mPositionManager = CreatPositionManager(_Symbol, InpTimeframe,
                                        InpPostManagmentType,
                                        InpATRPeriod, InpStopLossPoints, InpBreakEvenPoints, InpTrailingOrTpPoints,
                                        InpMaxLossAmount, InpScratchBreakEvenFlag, false, 5,
                                        InpStopLossMultiple, InpBreakEvenMultiple, InpTrailingOrTpMultiple);
   strategy.SetPositionManager(mPositionManager);

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
   singleExpert.OnTickHandler();
  }
//+------------------------------------------------------------------+
