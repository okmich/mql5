//+------------------------------------------------------------------+
//|                                                          OOO.mq5 |
//|                                    Copyright 2020, Michael Enudi |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2020, Michael Enudi"
#property link      "https://www.mql5.com"
#property version   "1.00"

#include <Math\Stat\LogNormal.mqh>
#include <Okmich\Candle.mqh>
//+------------------------------------------------------------------+
//| Script program start function                                    |
//+------------------------------------------------------------------+
void OnStart()
  {
   CCandle lastBar(1.2430578015209242, //open
                   1.24417,                //high
                   1.2430099999999999,     //low
                   1.2435449999999999);    //close

   Print(lastBar.toString());
   Print(EnumToString(lastBar.type()));


   double mean = 7.226127493;
   double stdev = 0.643657813;
   int error;
   double resultLogNormal = MathQuantileLognormal(0.4, mean,stdev, true, false,error);
   if (error == ERR_OK)
   Comment(resultLogNormal);
   else
      Comment("error occured");
  }
//+------------------------------------------------------------------+
