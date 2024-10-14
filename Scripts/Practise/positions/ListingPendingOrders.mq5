//+------------------------------------------------------------------+
//|                                         ListingPendingOrders.mq5 |
//|                                    Copyright 2021, Michael Enudi |
//|                                             okmich2002@yahoo.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2021, Michael Enudi"
#property link      "okmich2002@yahoo.com"
#property version   "1.00"

//+------------------------------------------------------------------+
//| Script program start function                                    |
//+------------------------------------------------------------------+
#include <Trade\OrderInfo.mqh>

COrderInfo orderInfo;
void OnStart()
  {
   int totalOrders = OrdersTotal();
   Print("totalOrders is ", totalOrders);
   for(int i = 0; i < totalOrders; i++)
     {
      orderInfo.SelectByIndex(i);
      Print("\\index is ", i, " order ticket is ", orderInfo.Ticket(), " magic is ", orderInfo.Magic());
     }
  }
//+------------------------------------------------------------------+
