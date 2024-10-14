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
   double opens[], highs[], lows[], closes[];
   datetime times[];
   ArraySetAsSeries(opens,true);
   ArraySetAsSeries(highs,true);
   ArraySetAsSeries(lows,true);
   ArraySetAsSeries(closes,true);
   ArraySetAsSeries(times, true);

   int bars = 200;
//--- get a handle to ha indicator
   int haHandle = iCustom(_Symbol, _Period, "Examples\\Heiken_Ashi");

   CopyBuffer(haHandle, 0, 0, bars, opens);
   CopyBuffer(haHandle, 1, 0, bars, highs);
   CopyBuffer(haHandle, 2, 0, bars, lows);
   CopyBuffer(haHandle, 3, 0, bars, closes);
   CopyTime(_Symbol, _Period, 0, bars, times);

   for(int i=0; i<bars; i++)
     {
      CCandle candle(times[i], opens[i], highs[i], lows[i], closes[i]);
      //if(candle.type() != CANDLE_NONE)
      Print("shift ", i, " is ", candle.toString(), "->", EnumToString(candle.type()));
     }
  }
//+------------------------------------------------------------------+
