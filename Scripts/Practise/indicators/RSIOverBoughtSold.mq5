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

int rsiPeriod = 14;
int lookBackBars = 200;

void OnStart()
  {
   MqlRates mqlRates[];
   CiRSI ciRSI;
   
   ArraySetAsSeries(mqlRates, true);
   
   //create indicator
   ciRSI.Create(_Symbol, _Period, rsiPeriod, PRICE_CLOSE);
   //load data
   ciRSI.Refresh();
   
   //now, lets load price data
   if (CopyRates(_Symbol, _Period, 0, lookBackBars, mqlRates) > 0){
      for (int i = 0; i< lookBackBars; i++)
         if (ciRSI.Main(i) >= 69) Print("OVERBOUGHT_SIGNAL @ ", mqlRates[i].time);
         else if (ciRSI.Main(i) <= 30) Print("OVERSOLD_SIGNAL @ ", mqlRates[i].time);
   }
   
  }
//+------------------------------------------------------------------+
