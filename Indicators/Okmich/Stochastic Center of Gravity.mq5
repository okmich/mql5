//+------------------------------------------------------------------+
//|                                 Stochastic Center of Gravity.mq5 |
//|                                    Copyright 2020, Michael Enudi |
//+------------------------------------------------------------------+
#property copyright     "Copyright 2020, Michael Enudi"
#property description   "Implementation of John Ehler's center of gravity indicator."
#property version   "1.1"
#property indicator_separate_window
#property indicator_buffers 4
#property indicator_plots   2
//--- plot COGLine
#property indicator_label1  "Stochastic CG"
#property indicator_type1   DRAW_LINE
#property indicator_color1  clrLightSeaGreen
#property indicator_style1  STYLE_SOLID
#property indicator_width1  2
//--- plot SignalLine
#property indicator_label2  "Signal"
#property indicator_type2   DRAW_LINE
#property indicator_color2  clrOrangeRed
#property indicator_style2  STYLE_DOT
#property indicator_width2  1
//--- applied Price
#property indicator_applied_price PRICE_MEDIAN
//--- input parameters
input int      coGPeriod=10; //COG Period
//--- indicator buffers
double         CoGBuffer[], StochCoGBuffer[], SmoothedStochCoGBuffer[];
double         CoGSignalBuffer[];

int plotBegins;
//+------------------------------------------------------------------+
//| Custom indicator initialization function                         |
//+------------------------------------------------------------------+
int OnInit()
  {
//--- indicator buffers mapping
   SetIndexBuffer(0,SmoothedStochCoGBuffer,INDICATOR_DATA);
   SetIndexBuffer(1,CoGSignalBuffer,INDICATOR_DATA);
   SetIndexBuffer(2,StochCoGBuffer,INDICATOR_CALCULATIONS);
   SetIndexBuffer(3,CoGBuffer,INDICATOR_CALCULATIONS);

//---- initializations of variable for indicator short name
   string shortname;
   StringConcatenate(shortname,"Stochastic Center of Gravity(",coGPeriod, ")");
//---- creating name for displaying in a separate sub-window and in a tooltip
   IndicatorSetString(INDICATOR_SHORTNAME,shortname);
//---- set accuracy of displaying of the indicator values
   IndicatorSetInteger(INDICATOR_DIGITS, 2);
   plotBegins = 2*coGPeriod;
   PlotIndexSetInteger(0,PLOT_DRAW_BEGIN, plotBegins);
//--- initialize stochBuffer
   ArrayInitialize(StochCoGBuffer, 0);
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

   for(int i = start; i < rates_total; i++)
     {
      double num = 0, denom=0;
      for(int j=0; j < coGPeriod; j++)
        {
         num += price[i-j] * (j + 1);
         denom += price[i-j];
        }
      CoGBuffer[i] = -num/denom + (coGPeriod + 1.0)/2.0;
      StochCoGBuffer[i] = stochastic(CoGBuffer, i);
      SmoothedStochCoGBuffer[i] = smooth(StochCoGBuffer, i);
      CoGSignalBuffer[i] = 0.96*(SmoothedStochCoGBuffer[i-1] + 0.02);
     }
   ArrayPrint(StochCoGBuffer, 2, "|", rates_total, 10);
//--- return value of prev_calculated for next call
   return(rates_total);
  }


//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
double stochastic(double &arr[], int index)
  {
   int start = index-coGPeriod + 1;
   double highest = arr[ArrayMaximum(arr, start, coGPeriod)];
   double lowest = arr[ArrayMinimum(arr, start, coGPeriod)];

   double stochValue = 0;
   if(highest != lowest)
      stochValue = (arr[index] - lowest) / (highest - lowest);

   return stochValue;
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
double smooth(double &arr[], int index)
  {
//smoothing
   if(index > plotBegins)
      return (4*StochCoGBuffer[index] + 3*StochCoGBuffer[index-1] + 2*StochCoGBuffer[index-2] + StochCoGBuffer[index-3]) / 10;
   else
      return StochCoGBuffer[index];
  }
//+------------------------------------------------------------------+
