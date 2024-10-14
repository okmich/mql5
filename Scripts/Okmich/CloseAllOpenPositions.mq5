//+------------------------------------------------------------------+
//|                                            CloseAllPositions.mq5 |
//|                                    Copyright 2020, Michael Enudi |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2020, Michael Enudi"
#property link      "https://www.mql5.com"
#property version   "1.00"
//+------------------------------------------------------------------+
//| Script program start function                                    |
//+------------------------------------------------------------------+

#include <Trade\Trade.mqh>

#define  ORDER_SEND_RETRIES_COUNT 3
#define  ORDER_SEND_RETRIES_INTERVAL_MAX 3000

CTrade cTrade;
// close all positions of a specific symbol
void OnStart()
  {

//get the number of open positions
   int positionCount = PositionsTotal();
   for(int i = positionCount - 1; i >= 0; i--)
     {
      string symbol = PositionGetSymbol(i);
      //get properties of the open trade and symbol
      if(PositionSelect(symbol))
        {
         //integer
         long ticketNumber = PositionGetInteger(POSITION_TICKET);
         //call the PositionClose of CTrade
         if(CallPositionClosed(ticketNumber))
            Print("I have closed ", ticketNumber, " -    ", i);
         else
            Print("Failed to close ticket - ", ticketNumber);
        }
     }
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
bool CallPositionClosed(ulong ticket)
  {
   Print("CallPositionClosed - ", ticket);
   int attempts = 1;
   bool _isSuccessful = false;
   uint resultCode = 0;
   do
     {
      if(cTrade.PositionClose(ticket))
        {
         resultCode = cTrade.ResultRetcode();
         if(resultCode == TRADE_RETCODE_PLACED || resultCode == TRADE_RETCODE_DONE)
           {
            return true;
           }
        }

      if(!_isSuccessful)
        {
         attempts++;
         int waitTime = rand() % ORDER_SEND_RETRIES_INTERVAL_MAX;
         if(waitTime < 1000)
            waitTime = 1000;
         Print(StringFormat("Failed to place order successfully. Reason: %s. Waiting to retry in %d ms",
                            resultCode, waitTime));
         Sleep(waitTime);
        }
     }
   while(attempts <= ORDER_SEND_RETRIES_COUNT && !_isSuccessful);

   return false;
  }
//+------------------------------------------------------------------+
