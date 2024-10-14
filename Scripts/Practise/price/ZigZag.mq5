//+------------------------------------------------------------------+
//|                                                       ZigZag.mq5 |
//|                                    Copyright 2020, Michael Enudi |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2020, Michael Enudi"
#property link      "https://www.mql5.com"
#property version   "1.00"
//+------------------------------------------------------------------+
//| Script program start function                                    |
//+------------------------------------------------------------------+

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void OnStart()
  {

   double            allValues[], zigzagHighs[], zigzagLows[];
   int               zigzag;

   int maxBars = MathMin(TerminalInfoInteger(TERMINAL_MAXBARS), 500);

   ArraySetAsSeries(allValues, true);
   ArraySetAsSeries(zigzagHighs, true);
   ArraySetAsSeries(zigzagLows, true);

   zigzag = iCustom(_Symbol, _Period, "Examples\\ZigZag", 6, 5, 3);
   CopyBuffer(zigzag,0,0,maxBars,allValues);
   CopyBuffer(zigzag,1,0,maxBars,zigzagHighs);
   CopyBuffer(zigzag,2,0,maxBars,zigzagLows);

   for(int i=0; i<maxBars; i++)
     {
      string message = StringFormat("shift %d -> allValues buffer=%f, zigzagHighs= %f, zigzagLows=%f",
                                    i, allValues[i], zigzagHighs[i], zigzagLows[i]);
      Print(message);
     }
  }
//+------------------------------------------------------------------+
