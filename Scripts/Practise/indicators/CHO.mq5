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
   CiChaikin ciChaikin;
   //create
   bool c = ciChaikin.Create(_Symbol, _Period, 3, 10, MODE_EMA, VOLUME_TICK);
   ciChaikin.Refresh();
      
   for (int i = 0; i < 100; i++)
      Print("Cho is ", NormalizeDouble(ciChaikin.Main(i), 2));
  
   ciChaikin.FullRelease();
  }
