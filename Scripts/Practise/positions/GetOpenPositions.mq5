//+------------------------------------------------------------------+
//|                                             GetOpenPositions.mq5 |
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

void OnStart() {
   CTrade cTrade;   
   
   //get the number of open positions
   int positionCount = PositionsTotal();
   Print("Total number of positions ", positionCount);
   for (int i = 0; i < positionCount; i++){
      string symbol = PositionGetSymbol(i);
      ulong ticket = PositionGetTicket(i);
      Print(StringFormat("Position Symbol is %s and the ticket is %d", symbol,ticket));
      //get properties of the open trade and symbol
      if (PositionSelectByTicket(ticket)){
         ENUM_POSITION_TYPE positionType = (ENUM_POSITION_TYPE)PositionGetInteger(POSITION_TYPE); //options POSITION_TYPE_BUY and POSITION_TYPE_SELL
         
         //double
         double volumn = PositionGetDouble(POSITION_VOLUME);
         double openPrice = PositionGetDouble(POSITION_PRICE_OPEN); 
         double stopLoss = PositionGetDouble(POSITION_SL); 
         double takeProfit = PositionGetDouble(POSITION_TP); 
         double currentPrice = PositionGetDouble(POSITION_PRICE_CURRENT); 
         double swap = PositionGetDouble(POSITION_SWAP); 
         double profit = PositionGetDouble(POSITION_PROFIT); 
         
         //string
         string _symbol = PositionGetString(POSITION_SYMBOL);
         
         Print("volume ", volumn, ", open price ", openPrice, ", stoploss ", ", sl ", stopLoss, ", tp ", takeProfit, ", cur price ", currentPrice, ", swap ", swap, ", profit ",profit);
         
      }
   }
   
   // Print(EnumToString((ENUM_ACCOUNT_MARGIN_MODE)AccountInfoInteger(ACCOUNT_MARGIN_MODE))); //Prints - ACCOUNT_MARGIN_MODE_RETAIL_HEDGING

}
//+------------------------------------------------------------------+
