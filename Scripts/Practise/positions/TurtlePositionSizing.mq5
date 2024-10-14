//+------------------------------------------------------------------+
//|                                         TurtlePositionSizing.mq5 |
//|                                    Copyright 2021, Michael Enudi |
//|                                             okmich2002@yahoo.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2021, Michael Enudi"
#property link      "okmich2002@yahoo.com"
#property version   "1.00"

#include <Okmich\Common\AtrReader.mqh>
//+------------------------------------------------------------------+
//| Script program start function                                    |
//+------------------------------------------------------------------+
void OnStart()
  {
   CAtrReader cAtrReader(_Symbol, _Period);
   double freeMargin = 600.00;
   double percent = 0.02;
   double atrPoints = cAtrReader.atrPoints();
   double tickValue = SymbolInfoDouble(_Symbol, SYMBOL_TRADE_TICK_VALUE);
   double tickSize = SymbolInfoDouble(_Symbol, SYMBOL_TRADE_TICK_SIZE);

   double lotSize = (percent * freeMargin)/(2*atrPoints * tickValue);

   string message = StringFormat(
                       "Free Margin: %f\n" +
                       "ATR Points: %f\n" +
                       "Tick value: %f\n" +
                       "Risk percent: %f\n" +
                       "Tick Size: %f\n" +
                       "Lot size: %f\n ",
                       freeMargin, atrPoints, tickValue, percent, tickSize, lotSize);
   Comment(message);
  }
//+------------------------------------------------------------------+
