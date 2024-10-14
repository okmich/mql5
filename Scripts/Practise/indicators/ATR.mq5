//+------------------------------------------------------------------+
//|                                                          ATR.mq5 |
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
   CiATR ciATR;
   bool wasCreated = ciATR.Create(_Symbol, _Period, 14);
     
   double atr[];
   int period = 14;
   ArraySetAsSeries(atr, true);
   
   int atrHandle = iATR(_Symbol, _Period, 14);
   int barsCopied = CopyBuffer(atrHandle, 0, 0, 20, atr);
      
   ciATR.Refresh(); //always call this method before GetData() or Main() 
   for (int i = 0; i < 14; i++)
      Print("Manual is " , NormalizeDouble(atr[i], 5), " while oop is ", NormalizeDouble(ciATR.Main(i), 5));
   
  }
//+------------------------------------------------------------------+
