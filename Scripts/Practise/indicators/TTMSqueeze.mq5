//+------------------------------------------------------------------+
//|                                                   TTMSqueeze.mq5 |
//|                                    Copyright 2021, Michael Enudi |
//|                                             okmich2002@yahoo.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2021, Michael Enudi"
#property link      "okmich2002@yahoo.com"
#property version   "1.00"
//+------------------------------------------------------------------+
//| Script program start function                                    |
//+------------------------------------------------------------------+
void OnStart()
  {
//---
   double m_TTMSqueezeBuffer[];
   ArraySetAsSeries(m_TTMSqueezeBuffer, true);
   int m_Handle = iCustom(_Symbol, _Period, "Articles/TTM Squeeze Momentum");

   int momCopied = CopyBuffer(m_Handle, 3, 0, 20, m_TTMSqueezeBuffer);

   ArrayPrint(m_TTMSqueezeBuffer, 4, ",", 0);
  }
//+------------------------------------------------------------------+
