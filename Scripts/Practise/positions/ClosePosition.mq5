//+------------------------------------------------------------------+
//|                                                ClosePosition.mq5 |
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

void OnStart(){
   CTrade cTrade;

   if(PositionSelect(_Symbol)) { //assuming single position
      //close position
       cTrade.PositionClose(PositionGetInteger(POSITION_TICKET));
       Print("Trade successfully closed");
   }else{
      Print("Trade not successfully closed");
   }
   
}
//+------------------------------------------------------------------+