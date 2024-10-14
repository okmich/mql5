//+------------------------------------------------------------------+
//|                                                   CMoneyTest.mq5 |
//|                                    Copyright 2020, Michael Enudi |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2020, Michael Enudi"
#property link      "https://www.mql5.com"
#property version   "1.00"

#include <Okmich/Money/FixedLotMoney.mqh>
#include <Okmich/Money/PercentMarginMoney.mqh>
//+------------------------------------------------------------------+
//| Script program start function                                    |
//+------------------------------------------------------------------+
void OnStart()
  {

   CBaseMoney *money;
   
   money = new CFixedLotMoney();
   Print("CFixedLotMoney ", money.lots());
   delete money;
   
   money = new CPercentMarginMoney();
   Print("CPercentMarginMoney ", money.lots());
   
   delete money;
  }
//+------------------------------------------------------------------+
