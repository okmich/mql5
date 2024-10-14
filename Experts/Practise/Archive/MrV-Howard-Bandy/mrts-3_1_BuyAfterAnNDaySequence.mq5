//+------------------------------------------------------------------+
//|                              mrts-3_1_BuyAfterAnNDaySequence.mq5 |
//|                                    Copyright 2023, Michael Enudi |
//|                                             okmich2002@yahoo.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2023, Michael Enudi"
#property link      "okmich2002@yahoo.com"
#property version   "1.00"

//--- includes directives here
#include <Okmich\Expert\SingleExpert.mqh>

//--- input EXPERT_MAGIC
const ulong EXPERT_MAGIC = 1000000000;

//+------------------------------------------------------------------+
//| Input parameters                                                 |
//+------------------------------------------------------------------+
input group "********* Strategy settings *********";
input ENUM_TIMEFRAMES InpTimeframe = PERIOD_D1;             //Timeframe
input ENUM_LONG_SHORT_FLAG InpLongShortFlag = LONG;   //Long/Short Flag
input bool InpDirection = 1;

input group "********* Long Strategy settings *********";
input int InpBuySequenceDays = 3;
input int InpBuyHoldDays = 4;
input double InpBuyProfitTarget = 0.4;

input group "********* Short Strategy settings *********";
input int InpSellSequenceDays = 3;
input int InpSellHoldDays = 4;
input double InpSellProfitTarget = 0.4;

input group "********* Volume setting **********";
input int InpLotSizeMultiple = 1;                     //Multiple of minimum lot size

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
class CStrategyImpl : public CStrategy
  {
private :
   //--- indicator values

   //--- indicator settings

   //--- indicators

   //--- indicator buffer
   double            m_CloseBuffer[];
   bool              Rising(int shift);
   bool              Falling(int shift);
   bool              NDaySequence(int n, bool    direction);

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
//--- initialize indicators
//--- price buffers
   return true;
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void CStrategyImpl::Release(void)
  {
//--- release indicators
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
      //-- refresh indicators
      //--- price buffers
      int closeBarsCopied = CopyClose(mSymbol, mTimeframe, 0, barsToCopy, m_CloseBuffer);
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

   if(SupportLongEntries(InpLongShortFlag) && NDaySequence(InpBuySequenceDays, InpDirection))
     {
      entry = anEntry(mSymbol, ENTRY_SIGNAL_BUY, ask, 0, 0, mLotSize, EXPERT_MAGIC);
      return entry;
     }

   if(SupportShortEntries(InpLongShortFlag) && NDaySequence(InpSellSequenceDays, InpDirection))
     {
      entry = anEntry(mSymbol, ENTRY_SIGNAL_SELL, bid, 0, 0, mLotSize, EXPERT_MAGIC);
      return entry;
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
//get the number of bars since open
   int shift = iBarShift(mSymbol, mTimeframe, positionInfo.Time());
   int holdDays = postType == POSITION_TYPE_BUY ? InpBuyHoldDays : InpSellHoldDays;
   if(shift >= holdDays)
     {
      position.signal = EXIT_SIGNAL_EXIT;
     }

   double currentPrice = positionInfo.PriceCurrent();
   double openPrice = positionInfo.PriceOpen();
   double percentageChange = (MathAbs(currentPrice - openPrice) / openPrice) * 100.0;
   int profitTarget = postType == POSITION_TYPE_BUY ? InpBuyProfitTarget : InpSellProfitTarget;
   if (percentageChange >= profitTarget)
      position.signal = EXIT_SIGNAL_EXIT;
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
bool CStrategyImpl::Rising(int shift)
  {
   return iClose(mSymbol, mTimeframe, shift+1) < iClose(mSymbol, mTimeframe, shift);
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
bool CStrategyImpl::Falling(int shift)
  {
   return iClose(mSymbol, mTimeframe, shift+1) > iClose(mSymbol, mTimeframe, shift);
  }

// Detect an N day sequence
bool CStrategyImpl::NDaySequence(int n, bool direction)
  {
   int count = 0;
   for(int i = 1; i <= n; i++)
     {
      if(direction && Rising(i))
         count++;
      else
         if(direction && Falling(i))
            count++;
     }
   return count == n;
  }

// the expert to run our strategy
CSingleExpert singleExpert(EXPERT_MAGIC, "Name of strategy here");

//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+
int OnInit()
  {
   CStrategy *strategy = new CStrategyImpl(_Symbol, _Period, InpLotSizeMultiple);
   CPositionManager *mPositionManager = CreatPositionManager(_Symbol, InpTimeframe,
                                        POSITION_MGT_NONE,
                                        0, 0, 0, 0, 0, 0, false, 0, 0, 0, 0);
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
