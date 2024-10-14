//+------------------------------------------------------------------+
//|                                                    BarsCount.mq5 |
//|                                                    Michael Enudi |
//|                                             okmich2002@yahoo.com |
//+------------------------------------------------------------------+
#property copyright "Michael Enudi"
#property link      "okmich2002@yahoo.com"
#property version   "1.00"
//+------------------------------------------------------------------+
//| Script program start function                                    |
//+------------------------------------------------------------------+
void OnStart()
  {
// we want to test ability to get the number of bars between time
//answer is
   int bars = 3;
   datetime timeShiftN = iTime(_Symbol, _Period, bars); //remember that shift is zero-based
   datetime timeNow = TimeCurrent();

   Print(timeNow, "      ", timeShiftN);

   int barsResult = Bars(_Symbol, _Period, timeShiftN, timeNow);

   if(bars+1 == barsResult) //add one to bars because shift is zero-based and shift x means x+1 bars from 0
      Comment("CORRECT !!!!!");
   else
      Comment(StringFormat("Failed badly. Expect %d but got %d", bars, barsResult));
  }
//+------------------------------------------------------------------+
