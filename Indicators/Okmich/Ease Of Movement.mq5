//+------------------------------------------------------------------+
//|                                             Ease Of Movement.mq5 |
//|                                    Copyright 2020, Michael Enudi |
//|                                             okmich2002@yahoo.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2020, Michael Enudi"
#property link      "okmich2002@yahoo.com"
#property version   "1.00"
#include <MovingAverages.mqh>

#property indicator_separate_window
#property indicator_buffers 2
#property indicator_plots   1
//--- plot EMBuffer
#property indicator_label1  "EOM"
#property indicator_type1   DRAW_LINE
#property indicator_color1  clrMediumSlateBlue
#property indicator_style1  STYLE_SOLID
#property indicator_width1  1

//--- enum
enum SmoothMethod
  {
   SMA=0,// Simple MA
   EMA=1 // Exponential MA
  };

//--- input parameters
input ENUM_APPLIED_VOLUME volumeType=VOLUME_TICK;  // Volumes
input int eomPeriod=14;                            // Smoothing Period
input SmoothMethod smoothingType=SMA;              // Smoothing method
//--- indicator buffers
double         EMBuffer[];
double         SmoothedEMBuffer[];
//--- variables
double scale=EMPTY_VALUE;
//+------------------------------------------------------------------+
//| Custom indicator initialization function                         |
//+------------------------------------------------------------------+
int OnInit()
  {
//--- indicator buffers mapping
   SetIndexBuffer(0,SmoothedEMBuffer,INDICATOR_DATA);
   SetIndexBuffer(1,EMBuffer,INDICATOR_CALCULATIONS);
//--- set draw begin
   PlotIndexSetInteger(0,PLOT_DRAW_BEGIN,eomPeriod);

   string shortname = StringFormat("EOM(%d)", eomPeriod);
   IndicatorSetString(INDICATOR_SHORTNAME, shortname);
   IndicatorSetInteger(INDICATOR_DIGITS, _Digits);

   PlotIndexSetString(0,PLOT_LABEL,"EOM");

//---
   return(INIT_SUCCEEDED);
  }
//+------------------------------------------------------------------+
//| Custom indicator iteration function                              |
//+------------------------------------------------------------------+
int OnCalculate(const int rates_total,
                const int prev_calculated,
                const datetime &time[],
                const double &open[],
                const double &high[],
                const double &low[],
                const double &close[],
                const long &tick_volume[],
                const long &volume[],
                const int &spread[])
  {
   int pos;
//--- check for bars count
   if(rates_total < eomPeriod)
      return(0);
//--- starting calculation
   if(prev_calculated>1)
      pos=prev_calculated-1;
   else
     {
      pos=1;
      EMBuffer[0] = EMPTY_VALUE;
     }
//calculate and hold the scale as an average of all available volume
   if(scale == EMPTY_VALUE)
      if(volumeType == VOLUME_TICK)
         scale = MathRound(MathMean(tick_volume));
      else
         scale = MathRound(MathMean(volume));

//--- main cycle
   double price1, price2;
   double distance, boxRatio;
   for(int i=pos; i<rates_total && !IsStopped(); i++)
     {
      price1 = (high[i] + low[i])/2.0;
      price2 = (high[i-1] + low[i-1])/2.0;
      //--- distance
      distance= (price1 - price2)/price1;
      //--- box_ratio
      boxRatio = ((volumeType == VOLUME_TICK ? tick_volume[i] : volume[i])/scale) / (high[i] + low[i]);
      //--- eom
      if(boxRatio != 0)
         EMBuffer[i]=distance/boxRatio;
      else
         EMBuffer[i]= 0;
     }
   if(smoothingType == 0)
      SimpleMAOnBuffer(rates_total, prev_calculated, eomPeriod + 1, eomPeriod, EMBuffer, SmoothedEMBuffer);
   else
      ExponentialMAOnBuffer(rates_total, prev_calculated, eomPeriod + 1, eomPeriod, EMBuffer, SmoothedEMBuffer);

//--- return value of prev_calculated for next call
   return(rates_total);
  }
//+------------------------------------------------------------------+

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
double MathMean(const long &array[])
  {
   int size=ArraySize(array);
//--- calculate mean
   double mean=0.0;
   for(int i=0; i<size; i++)
      mean+=(double)array[i];
   mean=mean/size;
//--- return mean
   return(mean);
  }
//+------------------------------------------------------------------+
