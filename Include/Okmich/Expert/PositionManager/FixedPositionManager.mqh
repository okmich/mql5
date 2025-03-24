//+------------------------------------------------------------------+
//|                                         FixedPositionManager.mqh |
//|                                                    Michael Enudi |
//|                                             okmich2002@yahoo.com |
//+------------------------------------------------------------------+
#property copyright "Michael Enudi"
#property link      "okmich2002@yahoo.com"

#include "PositionManager.mqh"

//+-------------------------------------------------------------------------------------+
//| This type of position manager uses predefined and fixed stop and take profit targets|
//| levels. More like a fire-and-forget management. Breakeven concept is not used.      |
//| It also help set these levels should the strategy implementation do not set it on   |
//| market entry.                                                                       |
//| It can also perform the actions of closing orders on stop loss or take profit by    |
//| monitoring the market prices against the set levels. This is useful should the EA   |
//| decides to hide the price levels from the position and instead set a loss level     |
//| unreasonably far from market price.                                                 |
//+-------------------------------------------------------------------------------------+
class CFixedPositionManager : public CPositionManager
  {
private:
   void              doFixedActionOnPrice(CTrade &mTradeHandle, CPositionInfo &positionInfo, double points);

protected:
   void              SetMaxLossAmnt(double maxLossAmount) {mMaxLossAmount = maxLossAmount;};
   void              SetScratchBrkEvenFlag(bool breakEvenFlag) {mUseScratchBreakEven = breakEvenFlag;};
   void              SetHiddenStopLossFlag(bool hiddenStopLossFlag) {mUseHiddenStopLoss = hiddenStopLossFlag;};
   void              SetHardStopLossMultiples(double multiples) {mHiddenStopLossMultiple = multiples;};

   virtual void      manageLongPosition(CTrade &mTradeHandle, CPositionInfo &positionInfo);
   virtual void      manageShortPosition(CTrade &mTradeHandle, CPositionInfo &positionInfo);

public:
                     CFixedPositionManager(string symbolName,
                         ENUM_TIMEFRAMES timeframe,
                         double stopLossPnts,
                         double breakEvenPnts,
                         double takeProfitPnts,
                         double maxLossAmnt,
                         bool isScratchBrkEven=true,
                         bool useHiddenStopLoss=false,
                         double hardStopLossMultiple=1): CPositionManager(symbolName, timeframe,
                                  stopLossPnts,
                                  breakEvenPnts,
                                  takeProfitPnts,
                                  maxLossAmnt,
                                  isScratchBrkEven,
                                  useHiddenStopLoss,
                                  hardStopLossMultiple) {};

   virtual double    GetStopLoss(Entry &entry);
   virtual double    GetTakeProfit(Entry &entry);
  };


//////////////////////// CFixedPositionManager /////////////////////////
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void CFixedPositionManager::manageLongPosition(CTrade &mTradeHandle, CPositionInfo &positionInfo)
  {
   mSymbolInfo.RefreshRates();
   double stopLoss = positionInfo.StopLoss();
   double takeProfit = positionInfo.TakeProfit();
   double openPrice = positionInfo.PriceOpen();
   double bidPrice = mSymbolInfo.Ask(); // long trades close at the bid
//--- if stop or tp is not set, then set both
   if(stopLoss == 0 || stopLoss == EMPTY_VALUE || takeProfit == 0 || takeProfit == EMPTY_VALUE)
     {
      //we are going to add spread to the tp
      double spread = iSpread(mSymbolInfo.Name(), mTimeframe, 0);
      double stopLossDist = mUseHiddenStopLoss ?  mStopLossPoints * mHiddenStopLossMultiple : mStopLossPoints;
      double takeProfitDist = mUseHiddenStopLoss ?  mMaxFloatingPoints * mHiddenStopLossMultiple : mMaxFloatingPoints;
      stopLoss = openPrice - ((stopLossDist + spread) * mSymbolInfo.Point());
      takeProfit = openPrice + (takeProfitDist * mSymbolInfo.Point());
      if(ModifyPosition(mTradeHandle, positionInfo.Ticket(), stopLoss, takeProfit))
         return;
     }

//--- stop loss or take profit
   double points = (positionInfo.PriceCurrent() - openPrice)/_Point;
   doFixedActionOnPrice(mTradeHandle, positionInfo, points);
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void CFixedPositionManager::manageShortPosition(CTrade &mTradeHandle, CPositionInfo &positionInfo)
  {
   mSymbolInfo.RefreshRates();
   double stopLoss = positionInfo.StopLoss();
   double takeProfit = positionInfo.TakeProfit();
   double openPrice = positionInfo.PriceOpen();
   double askPrice = mSymbolInfo.Ask(); // short trades close at the ask
//--- if stop is not set, then set it
   if(stopLoss == 0 || stopLoss == EMPTY_VALUE || takeProfit == 0 || takeProfit == EMPTY_VALUE)
     {
      double spread = iSpread(mSymbolInfo.Name(), mTimeframe, 0);
      double stopLossDist = mUseHiddenStopLoss ?  mStopLossPoints * mHiddenStopLossMultiple : mStopLossPoints;
      double takeProfitDist = mUseHiddenStopLoss ?  mMaxFloatingPoints * mHiddenStopLossMultiple : mMaxFloatingPoints;
      stopLoss = openPrice + ((stopLossDist + spread) * mSymbolInfo.Point());
      takeProfit = openPrice - (takeProfitDist * mSymbolInfo.Point());
      if(ModifyPosition(mTradeHandle, positionInfo.Ticket(), stopLoss, takeProfit))
         return;
     }

//--- check for stop loss hit or take profit
   double points = MathAbs(openPrice - positionInfo.PriceCurrent())/_Point;
   doFixedActionOnPrice(mTradeHandle, positionInfo, points);
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void CFixedPositionManager::doFixedActionOnPrice(CTrade &mTradeHandle, CPositionInfo &positionInfo, double points)
  {
//--- close on stop loss
   if(positionInfo.Profit() < 0 && points >= mStopLossPoints)
      if(ClosePosition(mTradeHandle, positionInfo.Ticket()))
         return;

//--- close on take profit
   if(positionInfo.Profit() > 0 && points >= mMaxFloatingPoints)
      if(ClosePosition(mTradeHandle, positionInfo.Ticket()))
         return;

   double profit = positionInfo.Profit();
//--- close if maximum acceptable loss is hit
   if(profit <= -mMaxLossAmount)
      if(ClosePosition(mTradeHandle, positionInfo.Ticket()))
         return;
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
double CFixedPositionManager::GetStopLoss(Entry &entry)
  {
   double stopDist = ((mUseHiddenStopLoss) ? mStopLossPoints * mHiddenStopLossMultiple : mStopLossPoints) * mSymbolInfo.Point();
   switch(entry.signal)
     {
      case ENTRY_SIGNAL_BUY:
         return entry.price - stopDist;
      case ENTRY_SIGNAL_SELL:
         return entry.price + stopDist;
      default:
         return 0;
     }
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
double CFixedPositionManager::GetTakeProfit(Entry &entry)
  {
   double takeProfDist = ((mUseHiddenStopLoss) ? mMaxFloatingPoints * mHiddenStopLossMultiple : mMaxFloatingPoints)
                         * mSymbolInfo.Point();
   switch(entry.signal)
     {
      case ENTRY_SIGNAL_BUY:
         return entry.price + takeProfDist;
      case ENTRY_SIGNAL_SELL:
         return entry.price - takeProfDist;
      default:
         return 0;
     }
  }