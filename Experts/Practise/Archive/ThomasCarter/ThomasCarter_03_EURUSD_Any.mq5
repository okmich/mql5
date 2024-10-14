//+------------------------------------------------------------------+
//|                                     ThomasCarter_3_Any_MAJOR.mq5 |
//|                                    Copyright 2021, Michael Enudi |
//|                                             okmich2002@yahoo.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2021, Michael Enudi"
#property link      "okmich2002@yahoo.com"
#property version   "1.00"

#include <Okmich\Expert\SingleExpert.mqh>
#include <Okmich\Indicators\DoubleMovingAverages.mqh>
#include <Okmich\Indicators\Macd.mqh>

const ulong EXPERT_MAGIC = 987650003;
//+------------------------------------------------------------------+
//| Input parameters                                                 |
//+------------------------------------------------------------------+
input group "********* Strategy settings *********";
input ENUM_TIMEFRAMES InpTimeframe = PERIOD_M30;            //Timeframe
input ENUM_LONG_SHORT_FLAG InpLongShortFlag = LONG_SHORT;   //Long/Short Flag

input group "********* Long Strategy settings *********";
input ENUM_MA_TYPE      InpBuyEmaMethod=MA_EMA;
input int      InpBuyFastEmaParam=50;
input int      InpBuySlowEmaParam=100;
input int      InpBuyFastMACDParam=12;
input int      InpBuySlowMACDParam=26;
input int      InpBuySignalMACDParam=9;
input int      InpBuyBreakByXPntsParam=100;
input int      InpBuyMacdNoLongerThanBars = 3;

input group "********* Short Strategy settings *********";
input ENUM_MA_TYPE      InpSellEmaMethod=MA_EMA;
input int      InpSellFastEmaParam=50;
input int      InpSellSlowEmaParam=100;
input int      InpSellFastMACDParam=12;
input int      InpSellSlowMACDParam=26;
input int      InpSellSignalMACDParam=9;
input int      InpSellBreakByXPntsParam=100;
input int      InpSellMacdNoLongerThanBars = 3;

input group "********* Volume setting **********";
input int InpLotSizeMultiple = 2;                     //Multiple of minimum lot size

input group "********* Position management settings *********";
input ENUM_POSITION_MANAGEMENT InpPostManagmentType = POSITION_MGT_MAX_LOSS_AMOUNT;  // Type of Position Management Algorithm
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

   //--- indicator settings
   //--- indicators
   CMacd             *m_Macd[2];
   CDoubleMovingAverages *m_DblMa[2];
   //--- indicator buffer

protected:
   virtual Entry     FindEntry(const double ask, const double bid);

public:
                     CStrategyImpl(string symbol, ENUM_TIMEFRAMES period,
                 int InptVolMultiple): CStrategy(symbol, period)
     {
      //lot size must be at least 2 the minimum lot size
      mLotSize = MathMax(InptVolMultiple, 2)*SymbolInfoDouble(_Symbol, SYMBOL_VOLUME_MIN);
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
//--- m_DblMa
   m_DblMa[0] = new CDoubleMovingAverages(mSymbol, mTimeframe, InpBuyFastEmaParam, InpBuySlowEmaParam, InpBuyEmaMethod);
   m_DblMa[1] = new CDoubleMovingAverages(mSymbol, mTimeframe, InpSellFastEmaParam, InpSellSlowEmaParam, InpSellEmaMethod);
   bool dblMasOk = m_DblMa[0].Init() && m_DblMa[1].Init();
//--- m_Macd
   m_Macd[0] = new CMacd(mSymbol, mTimeframe, InpBuyFastMACDParam, InpBuySlowMACDParam, InpBuySignalMACDParam);
   m_Macd[1] = new CMacd(mSymbol, mTimeframe, InpSellFastMACDParam, InpSellSlowMACDParam, InpSellSignalMACDParam);
   bool macdsOk = m_Macd[0].Init() && m_Macd[1].Init();

   return dblMasOk && macdsOk;
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void CStrategyImpl::Release(void)
  {
   for(int i = 0; i< 2; i++)
     {
      m_DblMa[i].Release();
      delete m_DblMa[i];

      m_Macd[i].Release();
      delete m_Macd[i];
     }
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void CStrategyImpl::Refresh(void)
  {
//--- Check for new bar
   if(IsNewBar())
     {
      for(int i = 0; i< 2; i++)
        {
         //-- m_DblMa
         m_DblMa[i].Refresh(mRefShift);
         //-- m_Macd
         m_Macd[i].Refresh(mRefShift);
        }
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

   bool goLongerThanBarsAgo  = false;
   double prevPrice = iClose(mSymbol, mTimeframe, mRefShift);
   double smallEmaValue = m_DblMa[0].GetData(0, mRefShift);
   double largeEmaValue = m_DblMa[0].GetData(1, mRefShift);
   bool isPriceAboveDblMas = prevPrice > smallEmaValue &&
                             prevPrice > largeEmaValue;
   bool hasBrokenClosestEmaByXPips = prevPrice >
                                     ((InpBuyBreakByXPntsParam*OnePoint()) +
                                      MathMax(smallEmaValue, largeEmaValue));
   if(SupportLongEntries(InpLongShortFlag) && isPriceAboveDblMas &&
      m_Macd[0].GetData(0, mRefShift) > 0)
     {
      //check that the macd cross into position territory no longer than 5 bars ago
      for(int i = 0; i < InpBuyMacdNoLongerThanBars; i++)
         if(m_Macd[0].GetData(0, mRefShift+1+i) < 0)
           {
            goLongerThanBarsAgo = true;
            break;
           }
      if(goLongerThanBarsAgo)
        {
         int lowIndex = iLowest(mSymbol, mTimeframe, MODE_LOW, 5, mRefShift);
         double stop = iLow(mSymbol, mTimeframe, lowIndex);
         entry = anEntry(mSymbol, ENTRY_SIGNAL_BUY, ask, stop, 0, mLotSize, EXPERT_MAGIC);
        }
      else
         return entry;
     }

   smallEmaValue = m_DblMa[1].GetData(0, mRefShift);
   largeEmaValue = m_DblMa[1].GetData(1, mRefShift);
   bool isPriceBelowDblMas = prevPrice < smallEmaValue && prevPrice < largeEmaValue;
   if(SupportShortEntries(InpLongShortFlag) && isPriceBelowDblMas &&
      m_Macd[1].GetData(0, mRefShift) < 0)
     {
      for(int i = 0; i < InpSellMacdNoLongerThanBars; i++)
         if(m_Macd[0].GetData(0, mRefShift+1+i) < 0)
           {
            goLongerThanBarsAgo = true;
            break;
           }
      if(goLongerThanBarsAgo)
        {
         int highIndex = iHighest(mSymbol, mTimeframe, MODE_HIGH, 5, mRefShift);
         double stop = iHigh(mSymbol, mTimeframe, highIndex);
         entry = anEntry(mSymbol, ENTRY_SIGNAL_SELL, bid, stop, 0, mLotSize, EXPERT_MAGIC);
        }
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
   double point = OnePoint();
   double stopLoss = positionInfo.StopLoss();
   double openPrice = positionInfo.PriceOpen();
   double currentPrice = positionInfo.PriceCurrent();
   double profit = positionInfo.Profit();

   double riskInDist = MathAbs(openPrice - stopLoss) / point;
   double profitDist = MathAbs(currentPrice - openPrice) / point;

   if(postType == POSITION_TYPE_BUY && profit > 0)
     {
      if(stopLoss < openPrice)
        {
         //Exit half of the position at two times risk; move stop to breakeven.
         //we have not yet broken even or taking profit
         if(profitDist >= 2 * riskInDist)
           {
            //close half the position
            if(this.PartialClose(positionInfo.Ticket(), positionInfo.Volume() / 2))
              {
               //move stop to breakeven.
               position.signal = EXIT_SIGNAL_MODIFY;
               position.stopLoss = openPrice + (10 * OnePoint());
               position.sym = mSymbol;
              }
           }
        }
      else
        {
         //Exit remaining position when price breaks below 50 EMA by 10 pips.
         double close = iClose(mSymbol, mTimeframe, mRefShift);
         double smallEmaReading = m_DblMa[1].GetData(0, mRefShift);

         bool belowSmallEmaByXPips = close <
                                     ((InpBuyBreakByXPntsParam*OnePoint()) +smallEmaReading);
         if(belowSmallEmaByXPips)
           {
            position.signal = EXIT_SIGNAL_EXIT;
           }
        }
     }
   else
      if(postType == POSITION_TYPE_SELL && profit > 0)
        {
         if(stopLoss > openPrice)
           {
            //Exit half of the position at two times risk; move stop to breakeven.
            //we have not yet broken even or taking profit
            if(profitDist >= 2 * riskInDist)
              {
               if(this.PartialClose(positionInfo.Ticket(), positionInfo.Volume() / 2))
                 {
                  //move stop to breakeven.
                  position.signal = EXIT_SIGNAL_MODIFY;
                  position.stopLoss = openPrice - (10 * OnePoint());
                  position.sym = mSymbol;
                 }
              }
           }
         else
           {
            //Exit remaining position when price breaks below 50 EMA by 10 pips.
            double close = iClose(mSymbol, mTimeframe, mRefShift);
            double smallEmaReading = m_DblMa[1].GetData(0, mRefShift);

            bool aboveSmallEmaByXPips = close >
                                        ((InpBuyBreakByXPntsParam*OnePoint()) +smallEmaReading);
            if(aboveSmallEmaByXPips)
              {
               position.signal = EXIT_SIGNAL_EXIT;
               position.sym = mSymbol;
              }
           }
        }

//position manager
  }
//+------------------------------------------------------------------+


// the expert to run our strategy
CSingleExpert singleExpert(EXPERT_MAGIC, "");

//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+
int OnInit()
  {
   CStrategy *strategy = new CStrategyImpl(_Symbol, InpTimeframe, InpLotSizeMultiple);
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
