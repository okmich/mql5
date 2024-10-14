//+------------------------------------------------------------------+
//|                                              single_position.mq5 |
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

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void OnStart()
  {
//--- open one single position for the current symbol
   CTrade cTrade;
   double lots = 0.2;

   int magicNumber = 30669;
   ENUM_ORDER_TYPE orderType;
   double entryPrice, stopLoss;

   cTrade.SetExpertMagicNumber(magicNumber);
//set point value
   double point = SymbolInfoDouble(_Symbol, SYMBOL_POINT);
   long limitLevel = SymbolInfoInteger(_Symbol, SYMBOL_TRADE_STOPS_LEVEL);
   double currentPrice = SymbolInfoDouble(_Symbol, SYMBOL_ASK);

   if(rand() % 2 == 0)
     {
      orderType = ORDER_TYPE_BUY_LIMIT;
      entryPrice = currentPrice - (400 * point);
      stopLoss = entryPrice - (600 * point);
     }
   else
     {
      orderType = ORDER_TYPE_SELL_LIMIT;
      entryPrice = currentPrice + (400 * point);
      stopLoss = entryPrice + (600 * point);
     }
   int expireAfterBars = 3;
   datetime expirationTime = TimeCurrent() + (expireAfterBars * PeriodSeconds(PERIOD_H1));
   bool executed = cTrade.OrderOpen(_Symbol, orderType, lots, 0, entryPrice, stopLoss, 0, ORDER_TIME_GTC, expirationTime, "");
   uint resultCode = cTrade.ResultRetcode();
   if(executed)
     {
      Print("Trade placed successfully. To expire by ", TimeToString(expirationTime));
     }
   else
     {
      Print("Trade was not placed successfully. Reason: ", resultCode);
     }
  }
//+------------------------------------------------------------------+
