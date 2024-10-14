//+------------------------------------------------------------------+
//|                          FixedStopTrailTargetPositionManager.mqh |
//|                                                    Michael Enudi |
//|                                             okmich2002@yahoo.com |
//+------------------------------------------------------------------+
#property copyright "Michael Enudi"
#property link      "okmich2002@yahoo.com"

#include  "PositionManager.mqh"

//+-------------------------------------------------------------------------------------+
//| This type of position manager has a fixed stop loss and profit target levels.       |
//| However, once we are in profit, it uses the breakEvenPnts value to trail the stop   |
//| until either levels are hit.                                                        |
//+-------------------------------------------------------------------------------------+
class CFixedStopTrailTargetPositionManager : public CPositionManager
  {
protected:
   virtual void      manageLongPosition(CTrade &mTradeHandle, CPositionInfo &positionInfo);
   virtual void      manageShortPosition(CTrade &mTradeHandle, CPositionInfo &positionInfo);

public:
                     CFixedStopTrailTargetPositionManager(string symbolName,
                                        ENUM_TIMEFRAMES timeframe,
                                        double stopLossPnts,
                                        double breakEvenPnts, // use this field to represent condition for trailing
                                        double maxFloatingPnts,
                                        double maxLossAmnt,
                                        bool isScratchBrkEven=true,
                                        bool useHiddenStopLoss=false,
                                        double hardStopLossMultiple=1): CPositionManager(symbolName, timeframe,
                                                 stopLossPnts,
                                                 breakEvenPnts,
                                                 maxFloatingPnts,
                                                 maxLossAmnt,
                                                 isScratchBrkEven,
                                                 useHiddenStopLoss,
                                                 hardStopLossMultiple) {};

   virtual double    GetStopLoss(Entry &entry);
   virtual double    GetTakeProfit(Entry &entry);
  };


//////////////////////// CFixedStopTrailTargetPositionManager /////////////////////////
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void CFixedStopTrailTargetPositionManager::manageLongPosition(CTrade &mTradeHandle, CPositionInfo &positionInfo)
  {
   double symPoint = mSymbolInfo.Point();
   double stopLossDist = mUseHiddenStopLoss ?  mStopLossPoints * mHiddenStopLossMultiple : mStopLossPoints;
   double takeProfitDist = mUseHiddenStopLoss ?  mMaxFloatingPoints * mHiddenStopLossMultiple : mMaxFloatingPoints;
   double stopLoss = positionInfo.StopLoss();
   double takeProfit = positionInfo.TakeProfit();
   double openPrice = positionInfo.PriceOpen();
//--- if stop is not set, then set it
   if(stopLoss == 0 || stopLoss == EMPTY_VALUE || takeProfit == 0 || takeProfit == EMPTY_VALUE)
     {
      double newStopLoss = openPrice - (stopLossDist * symPoint);
      double newTakeProfit = openPrice + (takeProfitDist * symPoint);
      if(ModifyPosition(mTradeHandle, positionInfo.Ticket(), newStopLoss, newTakeProfit))
         return;
     }
   double currentPrice = positionInfo.PriceCurrent();
   double pointsFromSL = (currentPrice - stopLoss)/symPoint;
   double newSl = currentPrice - (stopLossDist * symPoint);
   if(pointsFromSL > mBreakEvenPoints && stopLoss < newSl && positionInfo.Profit() > 0)
     {
      //modify position
      if(ModifyPosition(mTradeHandle, positionInfo.Ticket(), newSl, positionInfo.TakeProfit()))
         return;
     }
//--- if we are currently mMaxLossAmount or more in loss, exit trade
   if(positionInfo.Profit() < -mMaxLossAmount)
      ClosePosition(mTradeHandle, positionInfo.Ticket());
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void CFixedStopTrailTargetPositionManager::manageShortPosition(CTrade &mTradeHandle, CPositionInfo &positionInfo)
  {
   double symPoint = mSymbolInfo.Point();
   double stopLossDist = mUseHiddenStopLoss ?  mStopLossPoints * mHiddenStopLossMultiple : mStopLossPoints;
   double takeProfitDist = mUseHiddenStopLoss ?  mMaxFloatingPoints * mHiddenStopLossMultiple : mMaxFloatingPoints;
   double stopLoss = positionInfo.StopLoss();
   double takeProfit = positionInfo.TakeProfit();
   double openPrice = positionInfo.PriceOpen();
//--- if stop is not set, then set it
   if(stopLoss == 0 || stopLoss == EMPTY_VALUE || takeProfit == 0 || takeProfit == EMPTY_VALUE)
     {
      double newStopLoss = openPrice + (stopLossDist * symPoint);
      double newTakeProfit = openPrice - (takeProfitDist * symPoint);
      if(ModifyPosition(mTradeHandle, positionInfo.Ticket(), newStopLoss, newTakeProfit))
         return;
     }
   double currentPrice = positionInfo.PriceCurrent();
   double pointsFromSL = (stopLoss - currentPrice)/symPoint;
   double newSl = currentPrice + (stopLossDist * symPoint);
   if(pointsFromSL > (mBreakEvenPoints+stopLossDist) && stopLoss > newSl && positionInfo.Profit() > 0)
     {
      //modify position
      if(ModifyPosition(mTradeHandle, positionInfo.Ticket(), newSl, positionInfo.TakeProfit()))
         return;
     }
//--- if we are currently mMaxLossAmount or more in loss, exit trade
   if(positionInfo.Profit() < -mMaxLossAmount)
      ClosePosition(mTradeHandle, positionInfo.Ticket());
  }
//+------------------------------------------------------------------+
