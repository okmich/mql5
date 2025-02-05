//+------------------------------------------------------------------+
//|                                           Chaikin Money Flow.mq5 |
//|                                   Copyright 2020, Michael Enudi. |
//|                                             okmich2002@yahoo.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2020, Michael Enudi."
#property link      "okmich2002@yahoo.com"
#property version   "1.00"
#property indicator_separate_window
#property indicator_buffers 2
#property indicator_plots   1
//--- plot IIIndex
#property indicator_type1   DRAW_LINE
#property indicator_color1  clrLightCoral
#property indicator_style1  STYLE_SOLID
#property indicator_width1  1
//--- input parameters
input int                 InpPeriod    =21;           //Period
input ENUM_APPLIED_VOLUME InpVolumeType=VOLUME_TICK;  // Volume Type
//--- indicator buffers
double         CMFBuffer[];
double         ADBuffer[];
//+------------------------------------------------------------------+
//| Custom indicator initialization function                         |
//+------------------------------------------------------------------+
int OnInit()
  {
//--- check for input values
   if(InpPeriod<2)
     {
      printf("Incorrect value for input variable InpPeriod=%d. Indicator will use value=%d for calculations.",InpPeriod, 21);
      return INIT_PARAMETERS_INCORRECT;
     }

//--- indicator buffers mapping
   SetIndexBuffer(0,CMFBuffer,INDICATOR_DATA);
   SetIndexBuffer(1,ADBuffer,INDICATOR_CALCULATIONS);

   PlotIndexSetString(0, PLOT_LABEL,"Chaikin Money Flow");
   PlotIndexSetInteger(0, PLOT_DRAW_BEGIN, InpPeriod);
   IndicatorSetString(INDICATOR_SHORTNAME, "Chaikin Money Flow (" + IntegerToString(InpPeriod) + ")");
   IndicatorSetInteger(INDICATOR_DIGITS, _Digits);
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
   int start;
   if(rates_total < InpPeriod)
      return 0;

   if(prev_calculated > 0)
      start = prev_calculated - 1;
   else
      start = 0;
   double range, volToUse;
   for(int i = start; i < rates_total && !IsStopped(); i++)
     {
      range = (high[i]-low[i] == 0 ? 1: high[i]-low[i]);
      volToUse = (double)(InpVolumeType == VOLUME_REAL ? volume[i] : tick_volume[i]);
      ADBuffer[i] = ((close[i] * 2) - high[i] - low[i])/ range * (volToUse == 0 ? 1 : volToUse);
     }

   double num=0, div = 0;
   for(int i = (start < InpPeriod ? InpPeriod : start); i < rates_total && !IsStopped(); i++)
     {
      num = summation(ADBuffer, i);
      div = (double)(InpVolumeType == VOLUME_REAL ? volumeSum(volume, i) : volumeSum(tick_volume, i));

      if(div == 0)
         CMFBuffer[i] = 0;
      else
         CMFBuffer[i] = 100 * (num/div);
     }
//--- return value of prev_calculated for next call
   return(rates_total);
  }
//+------------------------------------------------------------------+

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
double summation(const double &arr[], const int start)
  {
   double sum=0;
   int pos = start - InpPeriod + 1;
   for(int i = pos; i <= start; i++)
      sum += arr[i];

   return sum;
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
long volumeSum(const long &arr[], const int start)
  {
   long sum=0;
   int pos = start - InpPeriod + 1;
   for(int i = pos; i <= start; i++)
      sum += arr[i];

   return sum;
  }

//+------------------------------------------------------------------+
