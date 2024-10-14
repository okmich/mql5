//+------------------------------------------------------------------+
//|                                              TR Adjusted EMA.mq5 |
//|                                    Copyright 2023, Michael Enudi |
//|                                             okmich2002@yahoo.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2023, Michael Enudi"
#property link      "okmich2002@yahoo.com"
#property version   "1.00"

#include <Okmich/Common/Common.mqh>

#property indicator_chart_window
#property indicator_buffers 2
#property indicator_plots   1
//--- plot ExtMaBuffer
#property indicator_label1  "ExtMaBuffer"
#property indicator_type1   DRAW_LINE
#property indicator_color1  clrGold
#property indicator_style1  STYLE_SOLID
#property indicator_width1  1
//--- input parameters
input int      InpMAPeriod=21;
input int      InpMultiplier=13;
//--- indicator buffers
double    ExtMaBuffer[];
double    ExtTRBuffer[];

double alpha;
//+------------------------------------------------------------------+
//| Custom indicator initialization function                         |
//+------------------------------------------------------------------+
int OnInit()
  {
//--- indicator buffers mapping
   SetIndexBuffer(0,ExtMaBuffer,INDICATOR_DATA);
   SetIndexBuffer(1,ExtTRBuffer,INDICATOR_CALCULATIONS);

//---
   IndicatorSetInteger(INDICATOR_DIGITS,_Digits);
   alpha = 2.0 / (InpMAPeriod + 1);
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
//---
   if(rates_total<=InpMAPeriod)
      return(0);

   int i,tr_start, main_start;
   tr_start = prev_calculated==0 ? 1 : prev_calculated-1;
   if(prev_calculated==0)
     {
      ExtTRBuffer[0]=0.0;
     }
//--- filling out the array of True Range values for each period
   for(i=tr_start; i<rates_total && !IsStopped(); i++)
      ExtTRBuffer[i]=MathMax(high[i],close[i-1])-MathMin(low[i],close[i-1]);

//--- the main loop of calculations
   main_start = prev_calculated <= InpMAPeriod ? InpMAPeriod : prev_calculated-1;
   for(i=main_start; i<rates_total && !IsStopped(); i++)
     {
      double trAdj = PointInRange(ExtTRBuffer, i, InpMAPeriod)/100;
      ExtMaBuffer[i] = i < 2 ? 0 : ExtMaBuffer[i-1] +
                       (alpha * (1 + (trAdj * InpMultiplier)) * (close[i] - ExtMaBuffer[i-1]));
     }
//--- return value of prev_calculated for next call
   return(rates_total);
  }
//+------------------------------------------------------------------+
