//+------------------------------------------------------------------+
//|                                                 MathQuartile.mq5 |
//|                                    Copyright 2020, Michael Enudi |
//|                                             okmich2002@yahoo.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2020, Michael Enudi"
#property link      "okmich2002@yahoo.com"
#property version   "1.00"

#include <Math\Stat\Math.mqh>
//+------------------------------------------------------------------+
//| Script program start function                                    |
//+------------------------------------------------------------------+
void OnStart()
  {

   int barsToCopy = iBars(_Symbol, _Period);;
   long tickVol[];
   double vol[], quartile[4];
   double probs[4];
   probs[0] = 0.20;
   probs[1] = 0.40;
   probs[2] = 0.60;
   probs[3] = 0.80;

   ArraySetAsSeries(tickVol, true);
   CopyTickVolume(_Symbol, _Period, 0, barsToCopy, tickVol);
   ArrayResize(vol, barsToCopy);
   for(int j = 0; j < ArraySize(tickVol); j++)
      vol[j] = (double)tickVol[j];

   bool res = MathQuantile(vol, probs, quartile);
   Print(res);
   for(int i = 0; i < 4; i++)
      Print(probs[i], "   ", quartile[i]);
  }
//+------------------------------------------------------------------+
