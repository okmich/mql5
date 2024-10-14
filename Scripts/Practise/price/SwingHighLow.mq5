//+------------------------------------------------------------------+
//|                                                 SwingHighLow.mq5 |
//|                                    Copyright 2020, Michael Enudi |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2020, Michael Enudi"
#property link      "https://www.mql5.com"
#property version   "1.00"
#property script_show_inputs
//--- input parameters
input int      bars=100;

double highs[], lows[];
datetime times[];
//+------------------------------------------------------------------+
//| Script program start function                                    |
//+------------------------------------------------------------------+
void OnStart()
  {
   ArraySetAsSeries(highs, true);
   ArraySetAsSeries(lows, true);
   ArraySetAsSeries(times, true);

   CopyHigh(_Symbol, _Period, 0, bars, highs);
   CopyLow(_Symbol, _Period, 0, bars, lows);
   CopyTime(_Symbol, _Period, 0, bars, times);

   double lastHigh=0, lastLow=0;
   for(int i = 0; i < bars; i++)
     {
      int lastHighIdx= lastSwingHigh(highs, i, bars);
      if(lastHighIdx != -1)
         lastHigh = highs[lastHighIdx];
      int lastLowIdx= lastSwingLow(lows, i, bars);
      if(lastLowIdx != -1)
         lastLow = lows[lastLowIdx];

      string message = StringFormat("From Shift %s, the last high was %s, while the last low was %f",
                                    IntegerToString(i), IntegerToString(lastHighIdx), IntegerToString(lastHighIdx));
      Print(message);
     }

  }
//+------------------------------------------------------------------+

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
int lastSwingHigh(double& ihighs[], int fromIdx=0, int barsToCnt=100)
  {
   int start = fromIdx + 2;
   int end = ArraySize(ihighs) - 2;
   for(int i = start; i < end; i++)
      if(ihighs[i-2] < ihighs[i] && ihighs[i-1] < ihighs[i] &&
         ihighs[i] > ihighs[i+1] && ihighs[i] > ihighs[i+2])
         return i;

   return -1;
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
int lastSwingLow(double& ilows[], int fromIdx=0, int barsToCnt=100)
  {
   int start = fromIdx + 2;
   int end = ArraySize(ilows) - 2;
   for(int i = start; i < end; i++)
      if(ilows[i-2] > ilows[i] && ilows[i-1] > ilows[i] &&
         ilows[i] < ilows[i+1] && ilows[i] < ilows[i+2])
         return i;

   return -1;
  }
//+------------------------------------------------------------------+
