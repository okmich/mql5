//+------------------------------------------------------------------+
//|                                      RSIDivergenceDectection.mq5 |
//|                                    Copyright 2020, Michael Enudi |
//|                                             okmich2002@yahoo.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2020, Michael Enudi"
#property link      "okmich2002@yahoo.com"
#property version   "1.00"

#include <Okmich\Common\Divergence.mqh>
//+------------------------------------------------------------------+
//| Script program start function                                    |
//+------------------------------------------------------------------+
void OnStart()
  {
   int barsToCopy = 100;
   int rsiPeriod = 14;
   double rsi[], highs[], lows[];

   ArraySetAsSeries(rsi, true);
   ArraySetAsSeries(highs, true);
   ArraySetAsSeries(lows, true);

   int rsiHandle = iRSI(_Symbol, _Period, rsiPeriod, PRICE_CLOSE);
   CopyBuffer(rsiHandle, 0, 0, barsToCopy, rsi);
//copy price series
   CopyHigh(_Symbol, _Period, 0, barsToCopy, highs);
   CopyLow(_Symbol, _Period, 0, barsToCopy, lows);

   CDivergence m_cDivergence;
   DivergenceObj divergenceRes[];

   for(int i = 2; i< ArraySize(rsi)-2; i++)
     {
         if (m_cDivergence.isPeak(rsi, i)) Print("RSI Peak at ", TimeToString(iTime(_Symbol, _Period, i)));
         if (m_cDivergence.isTrough(rsi, i)) Print("RSI Trough at ", TimeToString(iTime(_Symbol, _Period, i)));
     }

   /**
      Print("============================================= UP");
      m_cDivergence.findDivergenceOnHighs(rsi, highs, divergenceRes);
      datetime dtFrom, dtTo;
      for(int i =0 ; i < ArraySize(divergenceRes); i++)
        {
         dtFrom = iTime(_Symbol, _Period, divergenceRes[i].shiftFrom);
         dtTo = iTime(_Symbol, _Period, divergenceRes[i].shiftTo);
         Print(EnumToString(divergenceRes[i].type), " detected from ", TimeToString(dtFrom), " to ", TimeToString(dtTo));
        }

      Print("============================================= DOWN");
      DivergenceObj divergenceRes2[];
      m_cDivergence.findDivergenceOnLows(rsi, lows, divergenceRes2);
      for(int i =0 ; i < ArraySize(divergenceRes2); i++)
        {
         dtFrom = iTime(_Symbol, _Period, divergenceRes2[i].shiftFrom);
         dtTo = iTime(_Symbol, _Period, divergenceRes2[i].shiftTo);
         Print(EnumToString(divergenceRes2[i].type), " detected from ", TimeToString(dtFrom), " to ", TimeToString(dtTo));
        }
        */
  }
//+------------------------------------------------------------------+
