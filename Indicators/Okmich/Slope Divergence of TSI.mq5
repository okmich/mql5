//+------------------------------------------------------------------+
//|                                      Slope Divergence of TSI.mq5 |
//|                                    Copyright 2020, Michael Enudi |
//|                                             okmich2002@yahoo.com |
//+------------------------------------------------------------------+
#property copyright     "Copyright 2020, Michael Enudi"
#property link          "okmich2002@yahoo.com"
#property description   "Implementation of William Blau's Slope Divergence of True Strength Index with triple smoothing"
#property version       "1.00"
#include <MovingAverages.mqh>
//--- indicator settings
#property indicator_applied_price PRICE_CLOSE
#property indicator_level1 0.0
#property indicator_levelcolor clrSilver
#property indicator_levelstyle STYLE_DOT
#property indicator_separate_window
#property indicator_buffers 12
#property indicator_plots   1
//--- plot TSI
#property indicator_label1  "SD TSI"
#property indicator_type1   DRAW_LINE
#property indicator_color1  clrLavenderBlush
#property indicator_style1  STYLE_SOLID
#property indicator_width1  1
//--- input parameters
input int      TSIPeriod=38;
input int      firstSmoothingPeriod=38;
input int      secondSmoothingPeriod=3;
input int      priceFirstSmoothingPeriod=23;
input int      priceSecondSmoothingPeriod=5;
//--- indicator buffers
double         SD_TSIBuffer[];
//staging buffers
double momBuffer1[];
double momBuffer2[], momBuffer3[], momBuffer4[];
double absMomBuffer1[];
double absMomBuffer2[], absMomBuffer3[], absMomBuffer4[];
double TSIBuffer[];
double priceBuffer1[], priceBuffer2[];
//--- other variables
int mBegin;
//+------------------------------------------------------------------+
//| Custom indicator initialization function                         |
//+------------------------------------------------------------------+
int OnInit()
  {
//--- indicator buffers mapping
   SetIndexBuffer(0, SD_TSIBuffer,INDICATOR_DATA);
   SetIndexBuffer(1, momBuffer1, INDICATOR_CALCULATIONS);
   SetIndexBuffer(2, momBuffer2, INDICATOR_CALCULATIONS);
   SetIndexBuffer(3, momBuffer3, INDICATOR_CALCULATIONS);
   SetIndexBuffer(4, absMomBuffer1, INDICATOR_CALCULATIONS);
   SetIndexBuffer(5, absMomBuffer2, INDICATOR_CALCULATIONS);
   SetIndexBuffer(6, absMomBuffer3, INDICATOR_CALCULATIONS);
   SetIndexBuffer(7, momBuffer4, INDICATOR_CALCULATIONS);
   SetIndexBuffer(8, absMomBuffer4, INDICATOR_CALCULATIONS);
   SetIndexBuffer(9, priceBuffer1, INDICATOR_CALCULATIONS);
   SetIndexBuffer(10, priceBuffer2, INDICATOR_CALCULATIONS);
   SetIndexBuffer(11, TSIBuffer, INDICATOR_CALCULATIONS);

   string shortname = StringFormat("SD TSI(%d, %d, %d, %d, %d)", TSIPeriod, firstSmoothingPeriod,
                                   secondSmoothingPeriod, priceFirstSmoothingPeriod, priceSecondSmoothingPeriod);
   IndicatorSetString(INDICATOR_SHORTNAME, shortname);
   IndicatorSetInteger(INDICATOR_DIGITS, _Digits);
   PlotIndexSetString(0,PLOT_LABEL,"SD_TSI");

   mBegin = TSIPeriod + firstSmoothingPeriod+ secondSmoothingPeriod - 3;
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
      momBuffer1[i] = price[i] - price[i-1];
      absMomBuffer1[i] = MathAbs(momBuffer1[i]);
     }

   ExponentialMAOnBuffer(rates_total,prev_calculated,limit,TSIPeriod,momBuffer1,momBuffer2);
   ExponentialMAOnBuffer(rates_total,prev_calculated,limit, firstSmoothingPeriod, momBuffer2, momBuffer3);
   ExponentialMAOnBuffer(rates_total,prev_calculated,limit, secondSmoothingPeriod, momBuffer3, momBuffer4);

   ExponentialMAOnBuffer(rates_total,prev_calculated,limit, TSIPeriod, absMomBuffer1, absMomBuffer2);
   ExponentialMAOnBuffer(rates_total,prev_calculated,limit, firstSmoothingPeriod, absMomBuffer2, absMomBuffer3);
   ExponentialMAOnBuffer(rates_total,prev_calculated,limit, secondSmoothingPeriod, absMomBuffer3, absMomBuffer4);

   ExponentialMAOnBuffer(rates_total,prev_calculated,
                         limit, priceFirstSmoothingPeriod, price, priceBuffer1);
   ExponentialMAOnBuffer(rates_total,prev_calculated,
                         limit, priceSecondSmoothingPeriod, priceBuffer1, priceBuffer2);

   double x, y;
   for(int i=limit; i<rates_total && !IsStopped(); i++)
     {
      if(absMomBuffer4[i] != 0)
         TSIBuffer[i] = 100 * (momBuffer4[i]/absMomBuffer4[i]);
      else
         TSIBuffer[i] = 0;

      x = (TSIBuffer[i] - TSIBuffer[i-1] > 0 && priceBuffer2[i] - priceBuffer2[i-1] > 0) ?
          TSIBuffer[i] : 0;
      y = (TSIBuffer[i] - TSIBuffer[i-1] < 0 && priceBuffer2[i] - priceBuffer2[i-1] < 0) ?
          TSIBuffer[i] : 0;

      SD_TSIBuffer[i] = x+y;
     }
//--- return value of prev_calculated for next call
   return(rates_total);
  }
//+------------------------------------------------------------------+
