//+------------------------------------------------------------------+
//|                                                  CandleStick.mq5 |
//|                        Copyright 2020, MetaQuotes Software Corp. |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2020, MetaQuotes Software Corp."
#property link      "https://www.mql5.com"
#property version   "1.00"

#include <Okmich\Candle.mqh>
//+------------------------------------------------------------------+
//| Script program start function                                    |
//+------------------------------------------------------------------+
void OnStart()
  {
   MqlRates rates[];
   ArraySetAsSeries(rates,true);
   int copied=CopyRates(_Symbol, 0, 0, 100, rates);
//Bar[open=1.086300, high=1.086300, close=1.085970, low=1.085450, ls=0.000000, up=0.000520, range=0.000850, body=0.000330, type=BEARISH]. And the type of bar is BAR_TYPE_NONE

   if(copied > 0)
     {
      for(int i=0; i<ArraySize(rates); i++)
        {
         CCandle candle(rates[i]);
         //if(candle.type() != CANDLE_NONE)
         Print("shift ", i, " is ", candle.toString(), "->", EnumToString(candle.type()));
         if(i < 98)
           {
            ENUM_CANDLE_MULTIPATTERN pattern = candle.findPattern(rates[i+1]);
            if(pattern != MULTIPATTERN_NONE)
               Print("Shift ", i, " is also ", EnumToString(pattern));
           }
        }
     }

  }
//+------------------------------------------------------------------+
