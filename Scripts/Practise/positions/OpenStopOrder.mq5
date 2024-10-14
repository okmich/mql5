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
   string symbol = "GBPUSD";
   CTrade cTrade;
   double lots = 0.02;
   double point = SymbolInfoDouble(symbol, SYMBOL_POINT);
   int magicNumber = 2983233;
   ENUM_ORDER_TYPE orderType;

   double entryPrice = 0, stopLoss = 0, currentPrice = SymbolInfoDouble(symbol, SYMBOL_ASK);
   cTrade.SetExpertMagicNumber(magicNumber);

   if(rand() % 2 == 0)
     {
      orderType = ORDER_TYPE_BUY_STOP;
      entryPrice = currentPrice + (400 * point);
      stopLoss = entryPrice - (600 * point);
     }
   else
     {
      orderType = ORDER_TYPE_SELL_STOP;
      entryPrice = currentPrice - (400 * point);
      stopLoss = entryPrice + (600 * point);
     }

   string message = StringFormat("Buy stop order:[p:%f | sl: %f | tp: %f | vol: %f]",
                                 NormalizeDouble(entryPrice, 5), NormalizeDouble(stopLoss, 5),
                                 NormalizeDouble(0, 5), NormalizeDouble(lots, 2));
   Print(message);
   int expireAfterBars = 3;
   datetime expirationTime = TimeCurrent() + (expireAfterBars * PeriodSeconds(PERIOD_CURRENT));
   Print("Cuurent time " , TimeToString(TimeCurrent()), ". Expiration time ", TimeToString(expirationTime));
//   MqlTradeRequest tradeRequest;
//   tradeRequest.price = entryPrice;
//   tradeRequest.sl = stopLoss;
//   tradeRequest.symbol = symbol;
//   tradeRequest.tp = 0.0;
//   tradeRequest.volume = lots;
//   tradeRequest.type = orderType;
//   tradeRequest.expiration = expirationTime;
//
//   MqlTradeCheckResult tradeCheckRequest;
//   if(cTrade.OrderCheck(tradeRequest, tradeCheckRequest))
//      Print("Order check passed");
//   else
//     {
//      Print("Order check did not pass - ", tradeCheckRequest.retcode);
//      //return;
//     }

   long stopLevel = SymbolInfoInteger(symbol, SYMBOL_TRADE_STOPS_LEVEL);
   Print("Stop level  ", stopLevel);

   bool executed = cTrade.OrderOpen(symbol, orderType, lots, 0, entryPrice, stopLoss, 0.0, ORDER_TIME_SPECIFIED, expirationTime, message);
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
