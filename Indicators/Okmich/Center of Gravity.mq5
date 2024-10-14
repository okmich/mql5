//+------------------------------------------------------------------+
//|                                              CenterOfGravity.mq5 |
//|                                    Copyright 2020, Michael Enudi |
//|           http://www.mesasoftware.com/papers/TheCGOscillator.pdf |
//+------------------------------------------------------------------+
#property copyright     "Copyright 2020, Michael Enudi"
#property description   "Implementation of John Ehler's center of gravity indicator."
#property description   "This implementation removes the signal line as according to John, the signal line is equal to the CG line of the previous period."
#property description   "So, this implementation keep one less data structure in memory"
#property link      "http://www.mesasoftware.com/papers/TheCGOscillator.pdf"
#property version   "1.1"
#property indicator_separate_window
#property indicator_buffers 1
#property indicator_plots   1
//--- plot COGLine
#property indicator_label1  "CG"
#property indicator_type1   DRAW_LINE
#property indicator_color1  clrOrchid
#property indicator_style1  STYLE_SOLID
#property indicator_width1  1
//--- applied Price
#property indicator_applied_price PRICE_MEDIAN
//--- input parameters
input int      coGPeriod=10; //COG Period
//--- indicator buffers
double         CoGLineBuffer[];
//+------------------------------------------------------------------+
//| Custom indicator initialization function                         |
//+------------------------------------------------------------------+
int OnInit()
  {
//--- indicator buffers mapping
   SetIndexBuffer(0,CoGLineBuffer,INDICATOR_DATA);

//---- initializations of variable for indicator short name
   string shortname;
   StringConcatenate(shortname,"Center of Gravity(",coGPeriod, ")");
//---- creating name for displaying in a separate sub-window and in a tooltip
   IndicatorSetString(INDICATOR_SHORTNAME,shortname);
//---- set accuracy of displaying of the indicator values
   IndicatorSetInteger(INDICATOR_DIGITS, 4);
//---
   return(INIT_SUCCEEDED);
  }
//+------------------------------------------------------------------+
//| Custom indicator iteration function                              |
//+------------------------------------------------------------------+
int OnCalculate(const int rates_total,
                const int prev_calculated,
                const int begin,
                const double &price[])
  {
   int start = 0;
   if(prev_calculated > 0)
      start = prev_calculated - 1;
   else //=0
      start = coGPeriod;
   if(rates_total < coGPeriod)
      return 0;
      
   for(int i = start; i < rates_total && !IsStopped(); i++)
     {
      double num = 0, denom=0;
      for(int j=0; j < coGPeriod; j++)
        {
         num += price[i-j] * (j + 1);
         denom += price[i-j];
        }
      CoGLineBuffer[i] = -num/denom + (coGPeriod + 1.0)/2.0;
     }
//--- return value of prev_calculated for next call
   return(rates_total);
  }
//+------------------------------------------------------------------+
