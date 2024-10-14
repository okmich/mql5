//+------------------------------------------------------------------+
//|                                            TrueStrengthIndex.mq5 |
//|                                    Copyright 2020, Michael Enudi |
//|                                             okmich2002@yahoo.com |
//+------------------------------------------------------------------+
#property copyright     "Copyright 2020, Michael Enudi"
#property link          "okmich2002@yahoo.com"
#property description   "Implementation of William Blau's Erdogic True Strength Index"
#property version       "1.00"
#include <MovingAverages.mqh>
//--- indicator settings
#property indicator_applied_price PRICE_CLOSE
#property indicator_level1 0.0
#property indicator_levelcolor clrSilver
#property indicator_levelstyle STYLE_DOT
#property indicator_separate_window
#property indicator_buffers 10
#property indicator_plots   2
//--- plot TSI
#property indicator_label1  "Ergodic TSI"
#property indicator_type1   DRAW_LINE
#property indicator_color1  clrLightSeaGreen
#property indicator_style1  STYLE_SOLID
#property indicator_width1  2
//--- plot Signal
#property indicator_label2  "Signal"
#property indicator_type2   DRAW_LINE
#property indicator_color2  clrRed
#property indicator_style2  STYLE_DOT
#property indicator_width2  1
//--- input parameters
input int      TSIPeriod=13;
input int      firstSmoothingPeriod=25;
input int      secondSmoothingPeriod=2;
input int      TSISignalPeriod=5;
//--- indicator buffers
double         TSIBuffer[];
double         SignalBuffer[];
//staging buffers
double momBuffer1[];
double momBuffer2[], momBuffer3[], momBuffer4[];
double absMomBuffer1[];
double absMomBuffer2[], absMomBuffer3[], absMomBuffer4[];
//--- other variables
int mBegin;
//+------------------------------------------------------------------+
//| Custom indicator initialization function                         |
//+------------------------------------------------------------------+
int OnInit()
  {
//--- indicator buffers mapping
   SetIndexBuffer(0,TSIBuffer,INDICATOR_DATA);
   SetIndexBuffer(1,SignalBuffer,INDICATOR_DATA);

   SetIndexBuffer(2, momBuffer1, INDICATOR_CALCULATIONS);
   SetIndexBuffer(3, momBuffer2, INDICATOR_CALCULATIONS);
   SetIndexBuffer(4, momBuffer3, INDICATOR_CALCULATIONS);
   SetIndexBuffer(5, absMomBuffer1, INDICATOR_CALCULATIONS);
   SetIndexBuffer(6, absMomBuffer2, INDICATOR_CALCULATIONS);
   SetIndexBuffer(7, absMomBuffer3, INDICATOR_CALCULATIONS);
   SetIndexBuffer(8, momBuffer4, INDICATOR_CALCULATIONS);
   SetIndexBuffer(9, absMomBuffer4, INDICATOR_CALCULATIONS);

   string shortname = StringFormat("TSI(%d, %d, %d, %d)", TSIPeriod, firstSmoothingPeriod, secondSmoothingPeriod, TSISignalPeriod);
   IndicatorSetString(INDICATOR_SHORTNAME, shortname);
   IndicatorSetInteger(INDICATOR_DIGITS, _Digits);
   PlotIndexSetString(0,PLOT_LABEL,"TSI");
   PlotIndexSetString(1,PLOT_LABEL,"Signal");

   mBegin = TSIPeriod + firstSmoothingPeriod+ secondSmoothingPeriod+TSISignalPeriod - 4;
   PlotIndexSetInteger(0,PLOT_DRAW_BEGIN,mBegin);
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
//--- check for data
   if(rates_total < mBegin)
      return(0);

   int limit;
   if(prev_calculated==0)
      limit=1;
   else
      limit=prev_calculated-1;
//fill up with zero
   for(int i = 0; i < limit; i++)
     {
      momBuffer1[i] = 0.0;
      absMomBuffer1[i] = 0.0;
     }

   for(int i=limit; i<rates_total && !IsStopped(); i++)
     {
      momBuffer1[i] = MathLog(price[i]/price[i-1]);
      absMomBuffer1[i] = MathAbs(momBuffer1[i]);
     }

   ExponentialMAOnBuffer(rates_total,prev_calculated,TSIPeriod-1,TSIPeriod,momBuffer1,momBuffer2);
   ExponentialMAOnBuffer(rates_total,prev_calculated,firstSmoothingPeriod - 1, firstSmoothingPeriod, momBuffer2, momBuffer3);
   ExponentialMAOnBuffer(rates_total,prev_calculated,secondSmoothingPeriod - 1, secondSmoothingPeriod, momBuffer3, momBuffer4);

   ExponentialMAOnBuffer(rates_total,prev_calculated, TSIPeriod-1, TSIPeriod, absMomBuffer1, absMomBuffer2);
   ExponentialMAOnBuffer(rates_total,prev_calculated, firstSmoothingPeriod - 1, firstSmoothingPeriod, absMomBuffer2, absMomBuffer3);
   ExponentialMAOnBuffer(rates_total,prev_calculated, secondSmoothingPeriod - 1, secondSmoothingPeriod, absMomBuffer3, absMomBuffer4);

   for(int i=limit; i<rates_total && !IsStopped(); i++)
     {
      if(absMomBuffer4[i] != 0)
         TSIBuffer[i] = 100 * (momBuffer4[i]/absMomBuffer4[i]);
      else
         TSIBuffer[i] = 0;
     }
   ExponentialMAOnBuffer(rates_total,prev_calculated, TSISignalPeriod - 1, TSISignalPeriod, TSIBuffer, SignalBuffer);

//--- return value of prev_calculated for next call
   return(rates_total);
  }
//+------------------------------------------------------------------+
