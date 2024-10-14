//+------------------------------------------------------------------+
//|                                             CMoneyExpertTest.mq5 |
//|                                    Copyright 2020, Michael Enudi |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2020, Michael Enudi"
#property link      "https://www.mql5.com"
#property version   "1.00"
//+------------------------------------------------------------------+
//| Script program start function                                    |
//+------------------------------------------------------------------+
#include <Expert\Money\MoneyFixedRisk.mqh>
#include <Expert\Money\MoneyFixedLot.mqh>
#include <Expert\Money\MoneyFixedMargin.mqh>

input double percentRisk = 2.0; //Percent Risk
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void OnStart()
  {
   CSymbolInfo cSymbolInfo;
   cSymbolInfo.Name(_Symbol);
   cSymbolInfo.Refresh();

   CMoneyFixedRisk cMoneyFixedRisk;

   cMoneyFixedRisk.Init(GetPointer(cSymbolInfo), _Period, cSymbolInfo.Point()* 10);

   cMoneyFixedRisk.Symbol(_Symbol);
   cMoneyFixedRisk.Percent(percentRisk);

   double ask = SymbolInfoDouble(_Symbol, SYMBOL_ASK);
   double lots = cMoneyFixedRisk.CheckOpenLong(ask, 20);

   Print("Volume is ", DoubleToString(lots, 2)) ;
   
   
   
   
   CMoneyFixedMargin cMoneyFixedMargin;

   cMoneyFixedMargin.Init(GetPointer(cSymbolInfo), _Period, cSymbolInfo.Point()* 10);

   cMoneyFixedMargin.Symbol(_Symbol);
   cMoneyFixedMargin.Percent(percentRisk);

   double mask = SymbolInfoDouble(_Symbol, SYMBOL_ASK);
   double mlots = cMoneyFixedMargin.CheckOpenL  ong(mask, 5);

   Print("Volume is ", DoubleToString(mlots, 2)) ;
   
   
   
   CMoneyFixedLot cMoneyFixedLot;
   cMoneyFixedLot.Init(GetPointer(cSymbolInfo), _Period, cSymbolInfo.Point()* 10);
   cMoneyFixedLot.Lots(0.4);
   cMoneyFixedLot.Symbol(_Symbol);
   cMoneyFixedLot.Percent(percentRisk);

   double fask = SymbolInfoDouble(_Symbol, SYMBOL_ASK);
   double flots = cMoneyFixedLot.CheckOpenLong(fask, 50);

   Print("Volume is ", DoubleToString(flots, 2)) ;
  }
//+------------------------------------------------------------------+
