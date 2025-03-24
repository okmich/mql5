//+------------------------------------------------------------------+
//|                            PercentBasedFixedPositionManager.mqh  |
//|                                                    Michael Enudi |
//|                                             okmich2002@yahoo.com |
//+------------------------------------------------------------------+
#property copyright "Michael Enudi"
#property link      "okmich2002@yahoo.com"

#include "PositionManager.mqh"

//+-------------------------------------------------------------------------------------+
//| This class extends CPositionManager to manage positions using percentage-based      |
//| stop loss and take profit levels calculated from the entry price.                  |
//+-------------------------------------------------------------------------------------+
class CPercentBasedFixedPositionManager : public CPositionManager
{
private:
   double            mStopLossPercent;    // Stop loss percentage (e.g., 0.02 for 2%)
   double            mTakeProfitPercent;  // Take profit percentage (e.g., 0.05 for 5%)

protected:
   virtual void      manageLongPosition(CTrade &mTradeHandle, CPositionInfo &positionInfo);
   virtual void      manageShortPosition(CTrade &mTradeHandle, CPositionInfo &positionInfo);

public:
                     CPercentBasedFixedPositionManager(string symbolName,
                                                       ENUM_TIMEFRAMES timeframe,
                                                       double stopLossPercent,
                                                       double takeProfitPercent,
                                                       double maxLossAmnt,
                                                       bool isScratchBrkEven=true,
                                                       bool useHiddenStopLoss=false,
                                                       double hardStopLossMultiple=1)
                       : CPositionManager(symbolName, timeframe, 0, 0, 0, maxLossAmnt, isScratchBrkEven, useHiddenStopLoss, hardStopLossMultiple)
     {
      mStopLossPercent = stopLossPercent;
      mTakeProfitPercent = takeProfitPercent;
     };

   virtual double    GetStopLoss(Entry &entry);
   virtual double    GetTakeProfit(Entry &entry);
};

//+------------------------------------------------------------------+
//| Manage a long position                                           |
//+------------------------------------------------------------------+
void CPercentBasedFixedPositionManager::manageLongPosition(CTrade &mTradeHandle, CPositionInfo &positionInfo)
{
   double entryPrice = positionInfo.PriceOpen();
   double stopLoss = positionInfo.StopLoss();
   double takeProfit = positionInfo.TakeProfit();
   
   // If stop loss or take profit is not set, calculate and apply them
   if (stopLoss == 0 || takeProfit == 0)
   {
      double sl = GetStopLoss({ENTRY_SIGNAL_BUY, entryPrice, 0, 0});
      double tp = GetTakeProfit({ENTRY_SIGNAL_BUY, entryPrice, 0, 0});
      ModifyPosition(mTradeHandle, positionInfo.Ticket(), sl, tp);
   }
   else
   {
      // Close position if maximum loss is exceeded
      if (positionInfo.Profit() <= -mMaxLossAmount)
      {
         ClosePosition(mTradeHandle, positionInfo.Ticket());
      }
   }
}

//+------------------------------------------------------------------+
//| Manage a short position                                          |
//+------------------------------------------------------------------+
void CPercentBasedFixedPositionManager::manageShortPosition(CTrade &mTradeHandle, CPositionInfo &positionInfo)
{
   double entryPrice = positionInfo.PriceOpen();
   double stopLoss = positionInfo.StopLoss();
   double takeProfit = positionInfo.TakeProfit();
   
   // If stop loss or take profit is not set, calculate and apply them
   if (stopLoss == 0 || takeProfit == 0)
   {
      double sl = GetStopLoss({ENTRY_SIGNAL_SELL, entryPrice, 0, 0});
      double tp = GetTakeProfit({ENTRY_SIGNAL_SELL, entryPrice, 0, 0});
      ModifyPosition(mTradeHandle, positionInfo.Ticket(), sl, tp);
   }
   else
   {
      // Close position if maximum loss is exceeded
      if (positionInfo.Profit() <= -mMaxLossAmount)
      {
         ClosePosition(mTradeHandle, positionInfo.Ticket());
      }
   }
}

//+------------------------------------------------------------------+
//| Calculate stop loss based on entry signal and price              |
//+------------------------------------------------------------------+
double CPercentBasedFixedPositionManager::GetStopLoss(Entry &entry)
{
   double stopLoss = 0;
   if (entry.signal == ENTRY_SIGNAL_BUY)
   {
      stopLoss = entry.price * (1 - mStopLossPercent);
   }
   else if (entry.signal == ENTRY_SIGNAL_SELL)
   {
      stopLoss = entry.price * (1 + mStopLossPercent);
   }
   return NormalizeDouble(stopLoss, mSymbolInfo.Digits());
}

//+------------------------------------------------------------------+
//| Calculate take profit based on entry signal and price            |
//+------------------------------------------------------------------+
double CPercentBasedFixedPositionManager::GetTakeProfit(Entry &entry)
{
   double takeProfit = 0;
   if (entry.signal == ENTRY_SIGNAL_BUY)
   {
      takeProfit = entry.price * (1 + mTakeProfitPercent);
   }
   else if (entry.signal == ENTRY_SIGNAL_SELL)
   {
      takeProfit = entry.price * (1 - mTakeProfitPercent);
   }
   return NormalizeDouble(takeProfit, mSymbolInfo.Digits());
}