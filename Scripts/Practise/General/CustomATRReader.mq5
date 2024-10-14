//+------------------------------------------------------------------+
//|                                              CustomATRReader.mq5 |
//|                        Copyright 2020, MetaQuotes Software Corp. |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2020, MetaQuotes Software Corp."
#property link      "https://www.mql5.com"
#property version   "1.00"

#include <Okmich\Common\AtrReader.mqh>
//+------------------------------------------------------------------+
//| Script program start function                                    |
//+------------------------------------------------------------------+
void OnStart()
  {
   CAtrReader cAtrReader(_Symbol, _Period, 14, 90, 0.4);
   for(int i=0; i<50; i++)
     {
      Print("Shift ", i," ATR is ", cAtrReader.atr(i),
            ", atrpoint is ", cAtrReader.atrPoints(i),
            ", and is classified as ", EnumToString(cAtrReader.classifyATR(i))
            , " as threshold is ", cAtrReader.GetCurrentThreshold());
     }

  }
//+------------------------------------------------------------------+
