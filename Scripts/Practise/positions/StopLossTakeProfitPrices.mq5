//+------------------------------------------------------------------+
//|                                     StopLossTakeProfitPrices.mq5 |
//|                                    Copyright 2020, Michael Enudi |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2020, Michael Enudi"
#property link      "https://www.mql5.com"
#property version   "1.00"
#property script_show_inputs

#include <practise\TradeManagement.mqh>

//--- input parameters
input int      StopLossPips=50;
input int      TakeProfitPips=100;
input int      PercentRisk=2;
//+------------------------------------------------------------------+
//| Script program start function                                    |
//+------------------------------------------------------------------+
double p;

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void OnStart()
  {
   if(_Point == 1e-05)
      p = 1e-04;
   else
      if(_Point == 0.001)
         p = 0.01;
      else
         p  = _Point * 10;

   double ask = SymbolInfoDouble(_Symbol, SYMBOL_ASK);
   double bid = SymbolInfoDouble(_Symbol, SYMBOL_BID);

   TradeValues buySettings = calcTradePrices(_Symbol, ask, bid, p, StopLossPips, TakeProfitPips, PercentRisk, LONG_SIGNAL);
   TradeValues sellSettings = calcTradePrices(_Symbol, ask, bid, p, StopLossPips, TakeProfitPips, PercentRisk, SHORT_SIGNAL);
  
   Print(StringFormat("Long Trade settings: price: %f, sl: %f, tpL: %f, vol: %f", buySettings.price, buySettings.sl, buySettings.tp, buySettings.lots));
   Print(StringFormat("Short Trade settings: price: %f, sl: %f, tp: %f, vol: %f", sellSettings.price, sellSettings.sl, sellSettings.tp, sellSettings.lots));
  }
//+------------------------------------------------------------------+



//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+



//+------------------------------------------------------------------+
