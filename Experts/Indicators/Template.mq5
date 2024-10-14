//+------------------------------------------------------------------+
//|                                                     Template.mq5 |
//|                                                    Michael Enudi |
//|                                             okmich2002@yahoo.com |
//+------------------------------------------------------------------+
#property copyright "Michael Enudi"
#property link      "okmich2002@yahoo.com"
#property version   "1.00"

#include <Okmich\Expert\SingleExpert.mqh>

//--- input parameters
input group "********* Strategy settings *********";


input group "********* Position management settings *********";
input ENUM_POSITION_MANAGEMENT InpPostManagmentType = POSITION_MGT_FLEX_ATR_MULTIPLES;  // Type of Position Management Algorithm
input int InpATRPeriod = 14;                         // ATR Period
input double InpStopLossPoints = -1;                 // Stop loss distance
input double InpBreakEvenPoints = -1;                // Points to Break-even
input double InpMaxFloatingPoints = -1;              // Maximum floating points/Take profit points
input double InpMaxLossAmount = 30.00;               // Maximum allowable loss in dollars
input bool InpScratchBreakEvenFlag = true;           // Enable break-even with scratch profit
input bool InpUseHiddenStops = false;                // Enable hidden stops
input double InpHiddenStopMultiple = 3;              // Hardstops (applicable only when hidden stop is enabled)
input double InpStopLossMultiple = 2;                // ATR multiple for stop loss
input double InpBreakEvenMultiple = 2;               // ATR multiple for break-even
input double InpFloatPointsMultiple = 5;             // ATR multiple for Maximum floating/Take profit

input group "********* Trade Size settings *********";
input int   InpTradeVolMultiple = 1;               // Minimum Lot size multiple

input group "********* Other Settings *********";
input ulong    ExpertMagic             = 2983233;      // Expert MagicNumber

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
   //-- others

protected:
   virtual Entry     FindEntry(const double ask, const double bid);

public:
                     CStrategyImpl(string symbol, ENUM_TIMEFRAMES period,

                 int InptLotSizeMultiple): CStrategy(symbol, period)
     {

      mLotSize = InptLotSizeMultiple * SymbolInfoDouble(symbol, SYMBOL_VOLUME_MIN);
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
//--- price buffers
   ArraySetAsSeries(m_CloseBuffer, true);

   return true;
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void CStrategyImpl::Release(void)
  {

  }


//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
Entry CStrategyImpl::FindEntry(const double ask,const double bid)
  {
   Entry entry = noEntry(_expertMagic);

   if(!mIsNewBar) //-- time filter added
      return entry;


   if(mEntrySignal == ENTRY_SIGNAL_BUY)
     {
      entry.signal = mEntrySignal;
      entry.price = ask;
      entry.sl = entry.price - (m_Point * InpStopLossPoints);
     }
   else
      if(mEntrySignal == ENTRY_SIGNAL_SELL)
        {
         entry.signal = mEntrySignal;
         entry.price = bid;
         entry.sl = entry.price + (m_Point * InpStopLossPoints);

        }
        
//set common properties like symbols and trade vol
   entry.vol = mLotSize;
   entry.sym = mSymbol;

   return entry;
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void CStrategyImpl::CheckAndSetExitSignal(CPositionInfo &positionInfo, Position &position)
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
void CStrategyImpl::Refresh(void)
  {
   if(IsNewBar())
     {
      int barsToCopy = 10;
      //--- price buffers
      int closeBarsCopied = CopyClose(mSymbol, mTimeframe, 0, barsToCopy, m_CloseBuffer);

     }
  }

// the expert to run our strategy
CSingleExpert expert(ExpertMagic, 0);

//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+
int OnInit()
  {
//--- set up Position manager Implementation
   CPositionManager *positionManager = CreatPositionManager(_Symbol, _Period, InpPostManagmentType,
                                       InpATRPeriod, InpStopLossPoints, InpBreakEvenPoints,
                                       InpMaxFloatingPoints, InpMaxLossAmount, InpScratchBreakEvenFlag,
                                       InpUseHiddenStops, InpHiddenStopMultiple, InpStopLossMultiple,
                                       InpBreakEvenMultiple, InpFloatPointsMultiple);
//--- set up Trading Strategy Implementaion
   CStrategyImpl *strategy = new CStrategyImpl(_Symbol, _Period,
         InpTradeVolMultiple);
   strategy.SetPositionManager(positionManager);
   expert.SetStrategyImpl(strategy);

//---
   if(expert.OnInitHandler())
      return INIT_SUCCEEDED;
   else
      return INIT_FAILED;
  }

//+------------------------------------------------------------------+
//| Expert deinitialization function                                 |
//+------------------------------------------------------------------+
void OnDeinit(const int reason)
  {
   expert.OnDeinitHandler();
  }

//+------------------------------------------------------------------+
//| Expert tick function                                             |
//+------------------------------------------------------------------+
void OnTick()
  {
//---
   expert.OnTickHandler();
  }
//+------------------------------------------------------------------+
