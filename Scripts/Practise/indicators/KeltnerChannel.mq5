//+------------------------------------------------------------------+
//|                                    Articles\\Keltner Channel.mq5 |
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
   double top[];
   double ma[];
   double bottom[];
   
   ArraySetAsSeries(top, true);
   ArraySetAsSeries(ma, true);
   ArraySetAsSeries(bottom, true);
   
   int m_Handle = iCustom(_Symbol, _Period, "Articles\\Keltner Channel");
   CopyBuffer(m_Handle, 0, 0, 20, top); 
   CopyBuffer(m_Handle, 1, 0, 20, ma); 
   CopyBuffer(m_Handle, 2, 0, 20, bottom); 
   
   for (int i = 0; i < ArraySize(top); i++)
      Print(NormalizeDouble(top[i], 2), ", ", NormalizeDouble(ma[i], 2), ", ", NormalizeDouble(bottom[i], 2));
  }
//+------------------------------------------------------------------+
