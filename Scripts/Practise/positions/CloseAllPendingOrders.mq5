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
#include <Trade\Trade.mqh>

COrderInfo orderInfo;
CTrade cTrade;
void OnStart()
  {
   int totalOrders = OrdersTotal();
   Print("totalOrders is ", totalOrders);
   for(int i = 0; i < totalOrders; i++)
     {
      orderInfo.SelectByIndex(i);
      cTrade.OrderDelete(orderInfo.Ticket());
      Sleep(2000);
     }
  }
//+------------------------------------------------------------------+
