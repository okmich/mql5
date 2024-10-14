//+------------------------------------------------------------------+
//|                                                   Stochastic.mq5 |
//|                                    Copyright 2020, Michael Enudi |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2020, Michael Enudi"
#property link      "https://www.mql5.com"
#property version   "1.00"
//+------------------------------------------------------------------+
//| Script program start function                                    |
//+------------------------------------------------------------------+
void OnStart()
  {
   int stoch_input_k = 5;
   int stoch_input_d = 3;
   int stoch_input_slow = 3;
   int barsToCopy = 20;
   
   double main[], signal[];
   
   ArraySetAsSeries(main,true);
   ArraySetAsSeries(signal,true);
   
   int stockHandle = iStochastic(_Symbol, _Period, stoch_input_k, stoch_input_d, stoch_input_slow, MODE_SMA, STO_LOWHIGH);
   CopyBuffer(stockHandle, 0, 0, barsToCopy, main); 
   CopyBuffer(stockHandle, 1, 0, barsToCopy, signal); 
   
   for (int i = 0; i < ArraySize(main); i++)
      Print("Main line is at ", NormalizeDouble(main[i], 2), ", while signal is ", NormalizeDouble(signal[i], 2));
  }
//+------------------------------------------------------------------+
