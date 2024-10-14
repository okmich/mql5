//+------------------------------------------------------------------+
//|                                      FlexiblePositionManager.mqh |
//|                                                    Michael Enudi |
//|                                             okmich2002@yahoo.com |
//+------------------------------------------------------------------+
#property copyright "Michael Enudi"
#property link      "okmich2002@yahoo.com"

#include "PositionManager.mqh"

//+------------------------------------------------------------------------------------+
//| This type of position manager begins with a fixed stop loss but without profit     |
//| target levels. One gaining breakEvenPnts, stop loss is moved to break even with or |
//| without set scratch profit. Afterwards, price is trailed by mMaxFloatingPoints     |
//| until the stop loss level is hit.                                                  |
//+------------------------------------------------------------------------------------+
class CFlexiblePositionManager : public CPositionManager
  {
protected:
   void              SetStopLossPnts(double stopLssPnt) {mStopLossPoints = stopLssPnt;};
   void              SetBreakEvenPoints(double brkEvenPnts) {mBreakEvenPoints = brkEvenPnts;};
   void              SetTakeProfitPoints(double tkPrftPnts) {mMaxFloatingPoints = tkPrftPnts;};
   void              SetMaxLossAmnt(double maxLossAmount) {mMaxLossAmount = maxLossAmount;};
   void              SetScratchBrkEvenFlag(bool breakEvenFlag) {mUseScratchBreakEven = breakEvenFlag;};
   void              SetHiddenStopLossFlag(bool hiddenStopLossFlag) {mUseHiddenStopLoss = hiddenStopLossFlag;};
   void              SetHardStopLossMultiples(int multiples) {mHiddenStopLossMultiple = multiples;};

   virtual void      manageLongPosition(CTrade &mTradeHandle, CPositionInfo &positionInfo);
   virtual void      manageShortPosition(CTrade &mTradeHandle, CPositionInfo &positionInfo);

   double            ApplyStopHiding(double value);
   double            UnApplyStopHiding(double value);

public:
                     CFlexiblePositionManager(string symbolName,
                            ENUM_TIMEFRAMES timeframe,
                            double stopLossPnts,
                            double breakEvenPnts,
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

   //--- the TightenPosition method should be call to trail existing position by mStopLossPoints
   //--- or exit the position if distance is less than mStopLossPoints
   virtual bool              TightenPosition(CTrade &mTradeHandle, CPositionInfo &positionInfo);

   virtual double    GetStopLoss(Entry &entry);
   virtual double    GetTakeProfit(Entry &entry);

  };

//////////////////////// CFlexiblePositionManager /////////////////////////
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void CFlexiblePositionManager::manageLongPosition(CTrade &mTradeHandle, CPositionInfo &positionInfo)
  {
   double symPoint = mSymbolInfo.Point();
   double stopLoss = positionInfo.StopLoss();
   double openPrice = positionInfo.PriceOpen();
//--- if stop is not set, then set it
   if(stopLoss == 0 || stopLoss == EMPTY_VALUE)
     {
      double stopLossDist = mUseHiddenStopLoss ?  mStopLossPoints * mHiddenStopLossMultiple : mStopLossPoints;
      stopLoss = openPrice - (stopLossDist *symPoint);
      if(ModifyPosition(mTradeHandle, positionInfo.Ticket(), stopLoss, positionInfo.TakeProfit()))
         return;
     }
   double currentPrice = positionInfo.PriceCurrent();
   double pointsFromSL = UnApplyStopHiding((currentPrice - stopLoss)/symPoint);
   double pointsFromOpen = UnApplyStopHiding((currentPrice - openPrice)/symPoint);
//--- if in profit by mBreakEvenPoint and open price is above stop loss,
//--- then break even
   if(pointsFromOpen >= mBreakEvenPoints && stopLoss < openPrice)
     {
      double scratch = mUseScratchBreakEven ? ApplyStopHiding(mSymbolInfo.Spread()) * symPoint: 0;
      double newPrice = openPrice + scratch;
      //modify position
      if(ModifyPosition(mTradeHandle, positionInfo.Ticket(), newPrice, positionInfo.TakeProfit()))
         return;
     }
//--- trail by mMaxFloatingPoints when in profit
   if(pointsFromSL >= mMaxFloatingPoints && positionInfo.Profit() > 0)
     {
      double newSl = currentPrice - (ApplyStopHiding(mMaxFloatingPoints) * symPoint);
      //modify position
      if(ModifyPosition(mTradeHandle, positionInfo.Ticket(), newSl, positionInfo.TakeProfit()))
         return;
     }
//--- if we are currently mMaxLossAmount or more in loss, exit trade
   if(positionInfo.Profit() <= -mMaxLossAmount)
      ClosePosition(mTradeHandle, positionInfo.Ticket());
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void CFlexiblePositionManager::manageShortPosition(CTrade &mTradeHandle, CPositionInfo &positionInfo)
  {
   double symPoint = mSymbolInfo.Point();
   double stopLoss = positionInfo.StopLoss();
   double openPrice = positionInfo.PriceOpen();
//--- if stop is not set, then set it
   if(stopLoss == 0 || stopLoss == EMPTY_VALUE)
     {
      double stopLossDist = mUseHiddenStopLoss ?  mStopLossPoints * mHiddenStopLossMultiple : mStopLossPoints;
      stopLoss = openPrice + (stopLossDist * mSymbolInfo.Point());
      if(ModifyPosition(mTradeHandle, positionInfo.Ticket(), stopLoss, positionInfo.TakeProfit()))
         return;
     }
   double currentPrice = positionInfo.PriceCurrent();
   double pointsFromSL = UnApplyStopHiding((stopLoss - currentPrice)/symPoint);
   double pointsFromOpen = UnApplyStopHiding((openPrice - currentPrice)/symPoint);

//--- if in profit by mBreakEvenPoint and open price is below stop loss,
//--- then break even
   if(pointsFromOpen >= mBreakEvenPoints && stopLoss > openPrice)
     {
      double scratch = mUseScratchBreakEven ? ApplyStopHiding(mSymbolInfo.Spread()) * symPoint: 0;
      double newPrice = openPrice - scratch;
      if(ModifyPosition(mTradeHandle, positionInfo.Ticket(), newPrice, positionInfo.TakeProfit()))
         return;
     }
//--- trail by mMaxFloatingPoints when in profit
   if(pointsFromSL >= mMaxFloatingPoints && positionInfo.Profit() > 0)
     {
      double newSl = currentPrice + (ApplyStopHiding(mMaxFloatingPoints) * symPoint);
      //modify position
      if(ModifyPosition(mTradeHandle, positionInfo.Ticket(), newSl, positionInfo.TakeProfit()))
         return;
     }
//--- if we are currently mMaxLossAmount or more in loss, exit trade
   if(positionInfo.Profit() <= -mMaxLossAmount)
      ClosePosition(mTradeHandle, positionInfo.Ticket());
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
bool CFlexiblePositionManager::TightenPosition(CTrade &mTradeHandle, CPositionInfo &positionInfo)
  {
   bool isLongPos = positionInfo.PositionType() == POSITION_TYPE_BUY;
   long stopLevel = SymbolInfoInteger(_Symbol,SYMBOL_TRADE_STOPS_LEVEL);
   double openPrice = positionInfo.PriceOpen();
   double currentPrice = positionInfo.PriceCurrent();
   double stopLoss = positionInfo.StopLoss();
   double distance = isLongPos ?
                     (currentPrice - openPrice)/_Point : (openPrice - currentPrice)/_Point;
//--- if we are already close enough
   if(distance <= mStopLossPoints + stopLevel)
      return ClosePosition(mTradeHandle, positionInfo.Ticket());

//--- if we are already close enough
   if(positionInfo.Profit() < 0)
      return ClosePosition(mTradeHandle, positionInfo.Ticket());

//--- tighten close loss
   if(isLongPos)
     {
      double sl = currentPrice - ApplyStopHiding(mStopLossPoints * _Point);
      //--- check that existing stop loss is not greater than our new sl
      if(stopLoss < sl)
         return ModifyPosition(mTradeHandle, positionInfo.Ticket(), sl, positionInfo.TakeProfit());
      else //close if stop loss too close
         return ClosePosition(mTradeHandle, positionInfo.Ticket());
     }
   else
     {
      double sl = currentPrice + ApplyStopHiding(mStopLossPoints * _Point);
      if(stopLoss > sl)
         return ModifyPosition(mTradeHandle, positionInfo.Ticket(), sl, positionInfo.TakeProfit());
      else //close if stop loss too close
         return ClosePosition(mTradeHandle, positionInfo.Ticket());
     }

   return false;
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
double CFlexiblePositionManager::ApplyStopHiding(double value)
  {
   return mUseHiddenStopLoss ?  value * mHiddenStopLossMultiple : value;
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
double CFlexiblePositionManager::UnApplyStopHiding(double value)
  {
   return mUseHiddenStopLoss ?  value / mHiddenStopLossMultiple : value;
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
double CFlexiblePositionManager::GetStopLoss(Entry &entry)
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
double CFlexiblePositionManager::GetTakeProfit(Entry &entry)
  {
   return 0;
  }
//+------------------------------------------------------------------+
