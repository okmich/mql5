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
void OnStart()
  {
   int rsiPeriod = 14;
   double rsi[];
   
   ArraySetAsSeries(rsi, true);
   
   int rsiHandle = iRSI(_Symbol, _Period, rsiPeriod, PRICE_CLOSE);
   CopyBuffer(rsiHandle, 0, 0, 100, rsi); 
   
   for (int i = 0; i < ArraySize(rsi); i++)
      Print(NormalizeDouble(rsi[i], 2));
  }
//+------------------------------------------------------------------+
