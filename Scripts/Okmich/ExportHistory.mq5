//+------------------------------------------------------------------+
//|                                                ExportHistory.mq5 |
//|                                    Copyright 2024, Michael Enudi |
//|                                             okmich2002@yahoo.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2024, Michael Enudi"
#property link      "okmich2002@yahoo.com"
#property version   "1.00"
//+------------------------------------------------------------------+
#include <Trade\Trade.mqh>

// Input Parameters
input int Days = 30;                        // Number of days to include in the export

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void OnStart()
  {
// Generate File Name with Date and Time
   string FileName = "TradeHistory_.csv";

// File Handling
   Print(FileName);
   int fileHandle = FileOpen(FileName, FILE_WRITE | FILE_CSV);

   if(fileHandle == INVALID_HANDLE)
     {
      Print("Failed to open file for writing.");
      return;
     }

// Write Header
   FileWrite(fileHandle, "OpenTime,Ticket,Symbol,Type,Volume,Open,Close,Profit,Magic,CloseTime");

// Calculate Start Date
   datetime fromDate = TimeCurrent() - Days * 86400;
   
//--- request all the existing history on the account
   if(!HistorySelect(fromDate, TimeCurrent()))
     {
      Print("HistorySelect() failed. Error ", GetLastError());
      return;
     }

// Check if there are history orders
   int totalOrders = HistoryOrdersTotal();
   if(totalOrders == 0)
     {
      Print("No history orders available.");
      FileClose(fileHandle);
      return;
     }
     
   Print("Number of orders found: ", totalOrders);

// Loop through history orders
   for(int i = totalOrders - 1; i >= 0; i--)
     {
      // Use CHistoryOrderInfo to retrieve order details
      CHistoryOrderInfo order;
      if(!order.SelectByIndex(i))
         continue;

      datetime openTime = order.TimeSetup();
      if(openTime < fromDate)
         continue;

      // Extract Order Details
      string symbol = order.Symbol();
      string type = EnumToString(order.OrderType());
      double volume = order.VolumeInitial();
      double openPrice = order.PriceOpen();
      double profit = order.PriceOpen() - order.PriceCurrent();
      double current = order.PriceCurrent();
      ulong magic = order.Magic();
      datetime closeTime = order.TimeDone();

      // Write Data
      FileWrite(fileHandle,
                TimeToString(openTime, TIME_DATE|TIME_MINUTES|TIME_SECONDS),
                order.Ticket(), symbol, type, volume, openPrice, current, profit, magic,
                TimeToString(closeTime, TIME_DATE|TIME_MINUTES|TIME_SECONDS)
               );
     }

// Close File
   FileClose(fileHandle);
   Print("Export Complete: " + FileName);
  }
//+------------------------------------------------------------------+
