//+------------------------------------------------------------------+
//|                                                         MACD.mq5 |
//|                                    Copyright 2020, Michael Enudi |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2020, Michael Enudi"
#property link      "https://www.mql5.com"
#property version   "1.00"
//+------------------------------------------------------------------+
//| Script program start function                                    |
//+------------------------------------------------------------------+
#include <Indicators\Oscilators.mqh>

void OnStart()
  {
   CiMACD ciMACD;
   //create
   bool i = ciMACD.Create(_Symbol, _Period, 12, 26, 9, PRICE_CLOSE);
   ciMACD.Refresh();
   
   
   for (int i = 0; i < 100; i++)
      Print("Price is ", NormalizeDouble(ciMACD.Main(i), 5), " and signal is ", NormalizeDouble(ciMACD.Signal(i), 5));
  }
//+------------------------------------------------------------------+
