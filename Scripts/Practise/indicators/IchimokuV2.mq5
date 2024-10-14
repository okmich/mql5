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
double tenkanSen[], kijunSen[], senkouSpanA[], senkouSpanB[], chikouSpan[];
int iChimokuHandle;
void OnStart()
  {
//---
   ArraySetAsSeries(tenkanSen, true);
   ArraySetAsSeries(kijunSen, true);
   ArraySetAsSeries(senkouSpanA, true);
   ArraySetAsSeries(senkouSpanB, true);
   ArraySetAsSeries(chikouSpan, true);

   iChimokuHandle = iIchimoku(_Symbol, _Period, 9, 26, 52);

   int senkouSpanACopied = CopyBuffer(iChimokuHandle, 2, -26, 52, senkouSpanA);
   int senkouSpanBCopied = CopyBuffer(iChimokuHandle, 3, -26, 52, senkouSpanB);
   datetime dt;
   for(int i = 0; i< 52; i++)
     {
      dt = iTime(_Symbol, _Period, i-26);

      //string msg = StringFormat(", Tenkan - %.5f, Kijun - %.5f, Chikou - %.5f, Senkou A - %.5f, Senkou B - %.5f, Kumo - %.5f",
      //                          tenkan, kijun, chikou, senkouA, senkouB, kumoWidth);
      
      string msg = StringFormat(", Senkou A - %.5f, Senkou B - %.5f, Kumo - %.5f",
                        senkouSpanA[i], senkouSpanB[i], senkouSpanA[i]-senkouSpanB[i]);
      
      Print(dt, msg);

     }


  }
//+------------------------------------------------------------------+
