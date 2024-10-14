//+------------------------------------------------------------------+
//|                                             Language-feature.mq5 |
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
//---
   int waitTime = rand() % 3000;
   if(waitTime < 1000)
      waitTime = 1000;
   Comment(waitTime);
  }
//+------------------------------------------------------------------+
