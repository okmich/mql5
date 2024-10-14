//+------------------------------------------------------------------+
//|                                                           BB.mq5 |
//|                   Copyright 2009-2017, MetaQuotes Software Corp. |
//|                                              http://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright   "2009-2017, MetaQuotes Software Corp."
#property link        "http://www.mql5.com"
#property description "Z Score Indicator"
#include <MovingAverages.mqh>
//---
#property indicator_separate_window
#property indicator_buffers 3
#property indicator_plots   1
#property indicator_type1   DRAW_LINE
#property indicator_color1  clrOrangeRed
#property indicator_label1  "Z Score"

#property indicator_level1 2.0
#property indicator_level2 -2.0

//--- input parametrs
input int     InpMaPeriod=20;                // Period
input ENUM_MA_METHOD InpMaMethod = MODE_SMA; //Smoothing method

//--- global variables
int           ExtPeriod;
int           ExtPlotBegin=0;
//---- indicator buffer
double        ExtZScoreBuffer[];
double        ExtMaBuffer[];
double        ExtStdDevBuffer[];
//+------------------------------------------------------------------+
//| Custom indicator initialization function                         |
//+------------------------------------------------------------------+
void OnInit()
  {
//--- check for input values
   if(InpMaPeriod<2)
     {
      ExtPeriod=20;
      printf("Incorrect value for input variable InpBandsPeriod=%d. Indicator will use value=%d for calculations.",InpMaPeriod,ExtPeriod);
     }
   else
      ExtPeriod=InpMaPeriod;
//--- define buffers
   SetIndexBuffer(0, ExtZScoreBuffer);
   SetIndexBuffer(1, ExtMaBuffer,INDICATOR_CALCULATIONS);
   SetIndexBuffer(2, ExtStdDevBuffer,INDICATOR_CALCULATIONS);
//--- indicator name
   IndicatorSetString(INDICATOR_SHORTNAME, StringFormat("Z Score(%d,%s)", ExtPeriod, EnumToString(InpMaMethod)));
//--- indexes draw begin settings
   ExtPlotBegin=ExtPeriod-1;
   PlotIndexSetInteger(0,PLOT_DRAW_BEGIN,ExtPeriod);
//--- number of digits of indicator value
   IndicatorSetInteger(INDICATOR_DIGITS,3);
//---- OnInit done
  }
//+------------------------------------------------------------------+
//| Custom indicator iteration function                              |
//+------------------------------------------------------------------+
int OnCalculate(const int rates_total,
                const int prev_calculated,
                const int begin,
                const double &price[])
  {
//--- variables
   int pos;
//--- indexes draw begin settings, when we've received previous begin
   if(ExtPlotBegin!=ExtPeriod+begin)
     {
      ExtPlotBegin=ExtPeriod+begin;
      PlotIndexSetInteger(0,PLOT_DRAW_BEGIN,ExtPlotBegin);
     }
//--- check for bars count
   if(rates_total<ExtPlotBegin)
      return(0);
//--- starting calculation
   if(prev_calculated>1)
      pos=prev_calculated-1;
   else
      pos=0;
//--- main cycle
   for(int i=pos; i<rates_total && !IsStopped(); i++)
     {
      //--- moving average
      switch(InpMaMethod)
        {
         case MODE_EMA:
           {
            double previous = (i < 1) ? price[i] : ExtMaBuffer[i-1];
            ExtMaBuffer[i]=ExponentialMA(i,ExtPeriod,previous,price);
            break;
           }
         case MODE_SMMA:
           {
            double previous = (i < 1) ? price[i] : ExtMaBuffer[i-1];
            ExtMaBuffer[i]=SmoothedMA(i,ExtPeriod,previous,price);
            break;
           }
         case MODE_LWMA:
            ExtMaBuffer[i]=SimpleMA(i,ExtPeriod,price);
            break;
         case MODE_SMA:
         default:
            ExtMaBuffer[i]=SimpleMA(i,ExtPeriod,price);
        }
      //--- calculate and write down StdDev
      ExtStdDevBuffer[i]=StdDev_Func(i,price,ExtMaBuffer,ExtPeriod);

      if(ExtStdDevBuffer[i] != 0)
         //ExtZScoreBuffer[i] = (price[i] - ExtMaBuffer[i])/ExtStdDevBuffer[i];
         ExtZScoreBuffer[i] = (price[i] - ExtMaBuffer[i])/ExtStdDevBuffer[i];
      else
         ExtZScoreBuffer[i] = 0;
     }
//---- OnCalculate done. Return new prev_calculated.
   return(rates_total);
  }

//+------------------------------------------------------------------+
//| Calculate Standard Deviation                                     |
//+------------------------------------------------------------------+
double StdDev_Func(int position,const double &price[],const double &MAprice[],int period)
  {
//--- variables
   double StdDev_dTmp=0.0;
//--- check for position
   if(position<period)
      return(StdDev_dTmp);
//--- calcualte StdDev
   for(int i=0; i<period; i++)
      StdDev_dTmp+=MathPow(price[position-i]-MAprice[position],2);
   StdDev_dTmp=MathSqrt(StdDev_dTmp/period);
//--- return calculated value
   return(StdDev_dTmp);
  }
//+------------------------------------------------------------------+
