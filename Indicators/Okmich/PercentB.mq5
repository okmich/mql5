//+------------------------------------------------------------------+
//|                                                     PercentB.mq5 |
//|                                 Copyright 20024, MetaQuotes Ltd. |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright   "Copyright 2000-2023, MetaQuotes Ltd."
#property link        "https://www.mql5.com"
#property description "PercentB"
#include <MovingAverages.mqh>
//---
#property indicator_separate_window
#property indicator_buffers 5
#property indicator_plots   1
#property indicator_type1   DRAW_LINE
#property indicator_color1  LightSeaGreen
#property indicator_label1  "Percent B"
#property indicator_level1  0
//--- input parametrs
input int     InpBandsPeriod=20;       // Period
input double  InpBandsDeviations=2.0;  // Deviation
//--- global variables
int           ExtBandsPeriod,ExtBandsShift;
double        ExtBandsDeviations;
int           ExtPlotBegin=0;
//--- indicator buffer
double        ExtMLBuffer[];
double        ExtTLBuffer[];
double        ExtBLBuffer[];
double        ExtStdDevBuffer[];
double        ExtPercentBBuffer[];
//+------------------------------------------------------------------+
//| Custom indicator initialization function                         |
//+------------------------------------------------------------------+
void OnInit()
  {
//--- check for input values
   if(InpBandsPeriod<2)
     {
      ExtBandsPeriod=20;
      PrintFormat("Incorrect value for input variable InpBandsPeriod=%d. Indicator will use value=%d for calculations.",InpBandsPeriod,ExtBandsPeriod);
     }
   else
      ExtBandsPeriod=InpBandsPeriod;
   if(InpBandsDeviations==0.0)
     {
      ExtBandsDeviations=2.0;
      PrintFormat("Incorrect value for input variable InpBandsDeviations=%f. Indicator will use value=%f for calculations.",InpBandsDeviations,ExtBandsDeviations);
     }
   else
      ExtBandsDeviations=InpBandsDeviations;
//--- define buffers 
   SetIndexBuffer(0,ExtPercentBBuffer);
   SetIndexBuffer(1,ExtTLBuffer,INDICATOR_CALCULATIONS);
   SetIndexBuffer(2,ExtBLBuffer,INDICATOR_CALCULATIONS);
   SetIndexBuffer(3,ExtStdDevBuffer,INDICATOR_CALCULATIONS);
   SetIndexBuffer(4,ExtMLBuffer,INDICATOR_CALCULATIONS);
//--- set index labels
   PlotIndexSetString(0,PLOT_LABEL,"PercentB("+string(ExtBandsPeriod)+")");
//--- indicator name
   IndicatorSetString(INDICATOR_SHORTNAME,"%B");
//--- indexes draw begin settings
   ExtPlotBegin=ExtBandsPeriod-1;
   PlotIndexSetInteger(0,PLOT_DRAW_BEGIN,ExtBandsPeriod);
//--- indexes shift settings
   PlotIndexSetInteger(0,PLOT_SHIFT,ExtBandsShift);
//--- number of digits of indicator value
   IndicatorSetInteger(INDICATOR_DIGITS,_Digits+1);
  }
//+------------------------------------------------------------------+
//| Bollinger Bands                                                  |
//+------------------------------------------------------------------+
int OnCalculate(const int rates_total,
                const int prev_calculated,
                const int begin,
                const double &price[])
  {
   if(rates_total<ExtPlotBegin)
      return(0);
//--- indexes draw begin settings, when we've recieved previous begin
   if(ExtPlotBegin!=ExtBandsPeriod+begin)
     {
      ExtPlotBegin=ExtBandsPeriod+begin;
      PlotIndexSetInteger(0,PLOT_DRAW_BEGIN,ExtPlotBegin);
     }
//--- starting calculation
   int pos;
   if(prev_calculated>1)
      pos=prev_calculated-1;
   else
      pos=0;
//--- main cycle
   for(int i=pos; i<rates_total && !IsStopped(); i++)
     {
      //--- middle line
      ExtMLBuffer[i]=SimpleMA(i,ExtBandsPeriod,price);
      //--- calculate and write down StdDev
      ExtStdDevBuffer[i]=StdDev_Func(i,price,ExtMLBuffer,ExtBandsPeriod);
      //--- upper line
      ExtTLBuffer[i]=ExtMLBuffer[i]+ExtBandsDeviations*ExtStdDevBuffer[i];
      //--- lower line
      ExtBLBuffer[i]=ExtMLBuffer[i]-ExtBandsDeviations*ExtStdDevBuffer[i];
      
      ExtPercentBBuffer[i] = (price[i] - ExtBLBuffer[i])/(ExtTLBuffer[i] - ExtBLBuffer[i]) - 0.5;
     }
//--- OnCalculate done. Return new prev_calculated.
   return(rates_total);
  }
//+------------------------------------------------------------------+
//| Calculate Standard Deviation                                     |
//+------------------------------------------------------------------+
double StdDev_Func(const int position,const double &price[],const double &ma_price[],const int period)
  {
   double std_dev=0.0;
//--- calcualte StdDev
   if(position>=period)
     {
      for(int i=0; i<period; i++)
         std_dev+=MathPow(price[position-i]-ma_price[position],2.0);
      std_dev=MathSqrt(std_dev/period);
     }
//--- return calculated value
   return(std_dev);
  }
//+------------------------------------------------------------------+
