//+------------------------------------------------------------------+
//|                                        MultipleSamePositions.mq5 |
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

void OnStart()
  {
   
//--- open one multiple positions for the current symbol 15 secs apart
   CTrade cTrade;
   int magicNumber = rand();   
   bool isBuy = rand() % 2 == 0;
   cTrade.SetExpertMagicNumber(magicNumber);
   
   placeTrade(cTrade, isBuy);
   Sleep(20 * 1000);
   placeTrade(cTrade, isBuy);
   
  }
//+------------------------------------------------------------------+

void placeTrade(CTrade &tradingEndPoint, bool isBuy){
   double point;
   double lots = 0.1;
   ENUM_ORDER_TYPE orderType;
   int stopLossLevel=20, takeProfitLevel=40;
   double currentPrice, stopLossPrice, takeProfitPrice;
   
   //set point value
   if (_Point == 1e-05) point = 1e-04;
   else if (_Point == 0.001) point = 0.01;
   else point  = _Point * 10;
   
   if (isBuy) {
      orderType = ORDER_TYPE_BUY;
      currentPrice = SymbolInfoDouble(_Symbol, SYMBOL_ASK);
      stopLossPrice = currentPrice - (stopLossLevel * point);
      takeProfitPrice = currentPrice + (takeProfitLevel * point);
   } else {
      orderType = ORDER_TYPE_SELL;
      currentPrice = SymbolInfoDouble(_Symbol, SYMBOL_BID);
      stopLossPrice = currentPrice + (stopLossLevel * _Point);
      takeProfitPrice = currentPrice - (takeProfitLevel * _Point);
   }
   
   tradingEndPoint.PositionOpen(_Symbol, orderType,lots,currentPrice, stopLossPrice, takeProfitPrice, "Placing trade for me.");
   uint resultCode = tradingEndPoint.ResultRetcode();
   if (resultCode == TRADE_RETCODE_PLACED || resultCode == TRADE_RETCODE_DONE) {
      Print("Trade placed successfully");
   }else {
      Print("Trade was not placed successfully. Reason: ", resultCode);
   }
}