//+------------------------------------------------------------------+
//|                                           LotSizeCalculation.mq5 |
//|                                    Copyright 2020, Michael Enudi |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2020, Michael Enudi"
#property link      "https://www.mql5.com"
#property version   "1.00"
//+------------------------------------------------------------------+
//| Script program start function                                    |
//+------------------------------------------------------------------+
#include <practise\TradeManagement.mqh>

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void OnStart()
  {
//calculating the lot size from the stoploss distance and a fixed risk amount
   double lot1 = calcLotSizeForFixedRiskAmount(_Symbol, 13.8, 2);
   Print("lot size is ", lot1);

//calculating the lot size from the stoploss distance and a percentage of free margin
   double lot2 = calcLotSizeForRiskPercent(_Symbol, 13.8, 2);
   Print("lot size is ", lot2);

//calculating the stop loss distance from a fixed lot size and a fixed risk amount
   double stopLossDist = getStopLossForRiskAmount(_Symbol, 15, 0.1);
   Print("stop loss should be ", stopLossDist, " away");

   string message = "SYMBOL_TRADE_STOPS_LEVEL - " + IntegerToString(SymbolInfoInteger(_Symbol, SYMBOL_TRADE_STOPS_LEVEL));
   message += "\nSYMBOL_TRADE_TICK_VALUE - " + DoubleToString(SymbolInfoDouble(_Symbol, SYMBOL_TRADE_TICK_VALUE),3);
   message += "\nSYMBOL_TRADE_TICK_SIZE - " + DoubleToString(SymbolInfoDouble(_Symbol, SYMBOL_TRADE_TICK_SIZE),3);

   Comment(message);
  }
//+------------------------------------------------------------------+
