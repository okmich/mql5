//+------------------------------------------------------------------+
//|                                    FlexiblePositionManagerEA.mq5 |
//|                                    Copyright 2020, Michael Enudi |
//|                                             okmich2002@yahoo.com |
//+------------------------------------------------------------------+
#property copyright   "Copyright 2020, Michael Enudi"
#property link        "okmich2002@yahoo.com"
#property description "EA to manage existing open positions."
#property version     "1.00"

#include <Okmich\Expert\PositionManager.mqh>

input ENUM_POSITION_MANAGEMENT InpPostManagmentType;  // Type of Position Management Algorithm
input int InpATRPeriod = 14;                          // ATR Period
input double InpStopLossPoints = -1;                  // Stop loss distance in points
input double InpBreakEvenPoints = -1;                 // Points to Break-even
input double InpTrailingOrTpPoints = -1;              // Trailing/Take profit points
input double InpMaxLossAmount = 40.00;                // Maximum allowable loss in dollars
input bool InpScratchBreakEvenFlag = true;            // Enable break-even with scratch profit
input double InpStopLossMultiple = 1;                 // ATR multiple for stop loss
input double InpBreakEvenMultiple = 1;                // ATR multiple for break-even
input double InpTrailingOrTpMultiple = 2;             // ATR multiple for Maximum floating/Take profit

CPositionManager  *mPositionManager;
CTrade             mCTradeHandle;
//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+
int OnInit()
  {
   mPositionManager = CreatPositionManager(_Symbol, _Period,
                                           InpPostManagmentType,
                                           InpATRPeriod, InpStopLossPoints, InpBreakEvenPoints, InpTrailingOrTpPoints,
                                           InpMaxLossAmount, InpScratchBreakEvenFlag, false, 5,
                                           InpStopLossMultiple, InpBreakEvenMultiple, InpTrailingOrTpMultiple);
   return(INIT_SUCCEEDED);
  }
//+------------------------------------------------------------------+
//| Expert deinitialization function                                 |
//+------------------------------------------------------------------+
void OnDeinit(const int reason)
  {
//---
   delete mPositionManager;
  }
//+------------------------------------------------------------------+
//| Expert tick function                                             |
//+------------------------------------------------------------------+
void OnTick()
  {
//---
   mPositionManager.ManagePositions(mCTradeHandle);
  }
//+------------------------------------------------------------------+
