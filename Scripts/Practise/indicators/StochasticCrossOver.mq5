//+------------------------------------------------------------------+
//|                                                   Stochastic.mq5 |
//|                                    Copyright 2020, Michael Enudi |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2020, Michael Enudi"
#property link      "https://www.mql5.com"
#property version   "1.00"
//+------------------------------------------------------------------+
//| Script program start function                                    |
//+------------------------------------------------------------------+
#include <Indicators\Oscilators.mqh>

enum ENUM_STO_CROSSOVER {
   BUY_CROSS_OVER,
   SELL_CROSS_OVER,
   NONE
};

int stoch_input_k = 5;
int stoch_input_d = 3;
int stoch_input_slow = 3;
int barsToCopy = 120;

void OnStart()
  {
   MqlRates mqlRates[];
   CiStochastic ciStoch;
   
   ArraySetAsSeries(mqlRates, true);
   
   //create it 
   ciStoch.Create(_Symbol, _Period, stoch_input_k, stoch_input_d, stoch_input_slow, MODE_SMA, STO_LOWHIGH);
   //load the data
   ciStoch.Refresh();
   
   //find stochastic cross overs
   if (CopyRates(_Symbol, _Period, 1, barsToCopy, mqlRates) > 0){
      for (int i = 2; i < barsToCopy; i++){ //we begin from shift 1
         ENUM_STO_CROSSOVER signal = didStochCrossOverOccur(ciStoch.Main(i-1), ciStoch.Signal(i-1), ciStoch.Main(i), ciStoch.Signal(i));
         if (signal != NONE)
            Print(EnumToString(signal), " occured at ", mqlRates[i].time);
      }
   }
   
    
   
  }
//+------------------------------------------------------------------+

ENUM_STO_CROSSOVER didStochCrossOverOccur(double prevMain, double prevSig, double currMain, double currSign){
   if (prevSig >= prevMain && currSign < currMain)
      return SELL_CROSS_OVER;
      
   if (prevSig <= prevMain && currSign > currMain) return BUY_CROSS_OVER;

   return NONE;
}