//+------------------------------------------------------------------+
//|                                              TestingIchimoku.mq5 |
//|                                    Copyright 2020, Michael Enudi |
//|                                             okmich2002@yahoo.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2020, Michael Enudi"
#property link      "okmich2002@yahoo.com"
#property version   "1.00"
//+------------------------------------------------------------------+
//| Script program start function                                    |
//+------------------------------------------------------------------+
#include <Indicators\Trend.mqh>
void OnStart()
  {
//---
   CiIchimoku ciIchimoku;
   bool isCreated = ciIchimoku.Create(_Symbol, _Period, 9, 26, 52);
   if(!isCreated)
      return;

   ciIchimoku.Refresh();
   double tenkan, kijun, chikou, senkouA, senkouB, kumoWidth;
   datetime dt;
   for(int i = -26; i< 30; i++)
     {
      tenkan = ciIchimoku.TenkanSen(i) == EMPTY_VALUE ? 0 : ciIchimoku.TenkanSen(i);
      kijun = ciIchimoku.KijunSen(i) == EMPTY_VALUE ? 0 : ciIchimoku.KijunSen(i);
      chikou = ciIchimoku.ChinkouSpan(i) == EMPTY_VALUE ? 0 : ciIchimoku.ChinkouSpan(i);
      senkouA = ciIchimoku.SenkouSpanA(i) == EMPTY_VALUE ? 0 : ciIchimoku.SenkouSpanA(i);
      senkouB = ciIchimoku.SenkouSpanB(i) == EMPTY_VALUE ? 0 : ciIchimoku.SenkouSpanB(i);
      kumoWidth = senkouA - senkouB;
      dt = iTime(_Symbol, _Period, i);

      string msg = StringFormat(", Tenkan - %.5f, Kijun - %.5f, Chikou - %.5f, Senkou A - %.5f, Senkou B - %.5f, Kumo - %.5f",
                                tenkan, kijun, chikou, senkouA, senkouB, kumoWidth);
      Print(dt, msg);
     }
     
     Print("*********************************************");
     ciIchimoku.FullRelease();
  }
//+------------------------------------------------------------------+
