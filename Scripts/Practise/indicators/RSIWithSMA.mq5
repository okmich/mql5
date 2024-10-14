//+------------------------------------------------------------------+
//|                                                          RSI.mq5 |
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
#include <MovingAverages.mqh>
void OnStart()
  {
   CiRSI ciRSI;
   double rsiBuffer[];
   double smaBuffer[];
   
   if (!ciRSI.Create(_Symbol, _Period, 14, PRICE_CLOSE)){
      Print("Error occured. Code:", GetLastError());
      return;
   }
   ArraySetAsSeries(rsiBuffer, true);
   ArraySetAsSeries(smaBuffer, true);
   
   ciRSI.GetData(0, 100, 0, rsiBuffer);
   ArrayResize(smaBuffer, ArraySize(rsiBuffer));
   ExponentialMAOnBuffer(ArraySize(rsiBuffer), 0, 0, 8, rsiBuffer, smaBuffer);

   for (int i = 0; i < ArraySize(rsiBuffer); i++)
      Print("RSI value at shift ", i, " is ", NormalizeDouble(rsiBuffer[i], 2), 
      " while sma(8) is ", NormalizeDouble(smaBuffer[i], 2));
  }
//+------------------------------------------------------------------+
