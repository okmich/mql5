//+------------------------------------------------------------------+
//|                                                     TTMTrend.mq5 |
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
   double m_TTMTrendBuffer[];
   ArraySetAsSeries(m_TTMTrendBuffer, true);
   int m_Handle = iCustom(_Symbol, _Period, "Articles/TTM Trend", 10);

   int momCopied = CopyBuffer(m_Handle, 2, 0, 20, m_TTMTrendBuffer);

   ArrayPrint(m_TTMTrendBuffer, 6, ",", 0);
  }
//+------------------------------------------------------------------+
