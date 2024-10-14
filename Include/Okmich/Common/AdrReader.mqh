//+------------------------------------------------------------------+
//|                                                    AdrReader.mqh |
//|                                    Copyright 2022, Michael Enudi |
//|                                             okmich2002@yahoo.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2022, Michael Enudi"
#property description "A utility class for calculating ADR values and returning values necessary for describing volatility"
#property link      "okmich2002@yahoo.com"

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
double calculateAverageDailyRange(string sym, int barCount=252)
  {
   double highs[], lows[];
   int highCopied = CopyHigh(sym, PERIOD_D1, 1, barCount, highs);
   int lowsCopied = CopyLow(sym, PERIOD_D1, 1, barCount, lows);
   if(highCopied != lowsCopied || highCopied == 0)
      return EMPTY_VALUE;

   double totalRange=0;
   for(int i=0; i<highCopied; i++)
      totalRange += (highs[i]-lows[i]);

   return totalRange/highCopied;
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
double calculateAverageDailyRangeInPoints(string sym, int barCount=252)
  {
   double adr = calculateAverageDailyRange(sym, barCount);
   if(adr == EMPTY_VALUE)
      return EMPTY_VALUE;
   double point = SymbolInfoDouble(sym, SYMBOL_POINT);
   return adr/point;
  }
//+------------------------------------------------------------------+
