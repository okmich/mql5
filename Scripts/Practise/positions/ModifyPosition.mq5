//+------------------------------------------------------------------+
//|                                               ModifyPosition.mq5 |
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
      //modify position to add stop lose and take profit
       cTrade.PositionModify(PositionGetInteger(POSITION_TICKET), stopLoss, takePofit);
       
       //adding trailing stops is like changing your stop loss everytime the price movies in our favour
   }
   
}
//+------------------------------------------------------------------+
