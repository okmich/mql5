//+------------------------------------------------------------------+
//|                                                         VWAP.mq5 |
//|                                    Copyright 2020, Michael Enudi |
//|                                             okmich2002@yahoo.com |
//+------------------------------------------------------------------+
#property copyright     "Copyright 2020, Michael Enudi"
#property link          "okmich2002@yahoo.com"
#property description   "Volume-Weighted Average Price"
#property version   "1.00"
#property indicator_chart_window
#property indicator_buffers 2
#property indicator_plots   1
//--- plot VWAP
#property indicator_label1  "VWAP"
#property indicator_type1   DRAW_LINE
#property indicator_color1  clrLightBlue
#property indicator_style1  STYLE_SOLID
#property indicator_width1  1
//--- input parameters
input int      VPeriod=32;
//--- indicator buffers
double         VWAPBuffer[];
double         PriceVolBuffer[];
//+------------------------------------------------------------------+
//| Custom indicator initialization function                         |
//+------------------------------------------------------------------+
int OnInit()
  {
//--- indicator buffers mapping
   SetIndexBuffer(0,VWAPBuffer,INDICATOR_DATA);
   SetIndexBuffer(1,PriceVolBuffer,INDICATOR_CALCULATIONS);

   IndicatorSetString(INDICATOR_SHORTNAME, "VWAP(" + IntegerToString(VPeriod) + ")");

   IndicatorSetInteger(INDICATOR_DIGITS, _Digits);
   PlotIndexSetString(0,PLOT_LABEL,"Main");
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
//--- check for data
   if(rates_total < VPeriod)
      return(0);

   int start = (prev_calculated==0) ? prev_calculated: prev_calculated-1;

   double typicalPrice;
   double cummVolPrice, cummVol;
   for(int i=start; i<rates_total && !IsStopped(); i++)
     {
      typicalPrice = (high[i]+low[i]+close[i])/3;
      PriceVolBuffer[i] = typicalPrice * tick_volume[i];
      cummVol = (double)volumeSum(tick_volume, i);
      cummVolPrice = summation(PriceVolBuffer, i);

      if(cummVol == 0)
         VWAPBuffer[i] =  typicalPrice;
      else
         VWAPBuffer[i] = cummVolPrice / cummVol;
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
   if(start < VPeriod)
      return 0;
   double sum=0;
   int pos = start - VPeriod + 1;
   for(int i = pos; i <= start; i++)
      sum += arr[i];

   return sum;
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
long volumeSum(const long &arr[], const int start)
  {
   if(start < VPeriod)
      return 0;
   long sum=0;
   int pos = start - VPeriod + 1;
   for(int i = pos; i <= start; i++)
      sum += arr[i];

   return sum;
  }
//+------------------------------------------------------------------+
