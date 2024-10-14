//+------------------------------------------------------------------+
//|                                                  Aggregate M.mq5 |
//|                                    Copyright 2021, Michael Enudi |
//|                                             okmich2002@yahoo.com |
//+------------------------------------------------------------------+
// source is https://cssanalytics.wordpress.com/2009/11/05/trend-or-mean-reversion-why-make-a-choice-the-simple-aggregate-m-indicator/
#property copyright "Copyright 2021, Michael Enudi"
#property link      "okmich2002@yahoo.com"
#property version   "1.00"

#include <MovingAverages.mqh>

#property indicator_separate_window

#property indicator_buffers 4
#property indicator_plots   2
//--- plot AggM
#property indicator_label1  "AggM"
#property indicator_type1   DRAW_LINE
#property indicator_color1  clrLightSeaGreen
#property indicator_style1  STYLE_SOLID
#property indicator_width1  1
//--- plot Signal
#property indicator_label2  "Signal"
#property indicator_type2   DRAW_LINE
#property indicator_color2  clrDarkOrange
#property indicator_style2  STYLE_DOT
#property indicator_width2  1

#property indicator_minimum 0
#property indicator_maximum 100
#property indicator_level1 85.0
#property indicator_level2 50.0
#property indicator_level3 15.0

input int InpLongRankPeriod = 252; //Long Rank Period
input int InpShortRankPeriod = 10; //Short Rank Period
input int InpSignalPeriod = 3; //Signal Period

//--- indicator buffers
double         ExtAggMBuffer[], ExtSignalBuffer[];
double         ExtRankLongBuffer[], ExtRankShortBuffer[];

int plotBegins;
//+------------------------------------------------------------------+
//| Custom indicator initialization function                         |
//+------------------------------------------------------------------+
int OnInit()
  {
//--- indicator buffers mapping
   SetIndexBuffer(0,ExtAggMBuffer,INDICATOR_DATA);
   SetIndexBuffer(1,ExtSignalBuffer,INDICATOR_DATA);
   SetIndexBuffer(2,ExtRankLongBuffer,INDICATOR_CALCULATIONS);
   SetIndexBuffer(3,ExtRankShortBuffer,INDICATOR_CALCULATIONS);

//---- initializations of variable for indicator short name
   string shortname = StringFormat("AggM(%d,%d,%d)", InpLongRankPeriod, InpShortRankPeriod, InpSignalPeriod);
//---- creating name for displaying in a separate sub-window and in a tooltip
   IndicatorSetString(INDICATOR_SHORTNAME,shortname);
//---- set accuracy of displaying of the indicator values
   IndicatorSetInteger(INDICATOR_DIGITS, 4);
//--- indexes draw begin settings
   plotBegins = InpLongRankPeriod+InpSignalPeriod;
   PlotIndexSetInteger(0,PLOT_DRAW_BEGIN, plotBegins);
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
   int start = 0;
   if(prev_calculated > 0)
      start = prev_calculated - 1;
   else //=0
      start = plotBegins;
   if(rates_total < plotBegins)
      return 0;

   double value = 0, prevValue = 0;
   for(int i = start; i < rates_total; i++)
     {
      ExtRankLongBuffer[i] = PercentRankHLC(high, low, close, i, InpLongRankPeriod);
      ExtRankShortBuffer[i] = PercentRankHLC(high, low, close, i, InpShortRankPeriod);

      value = (ExtRankLongBuffer[i] + ExtRankShortBuffer[i]) / 2;
      prevValue = (ExtRankLongBuffer[i-1] + ExtRankShortBuffer[i-1]) / 2;

      ExtAggMBuffer[i] = (prevValue * 0.4) + (value * 0.6);
      ExtSignalBuffer[i] = SimpleMA(i, InpSignalPeriod, ExtAggMBuffer);
     }

//--- return value of prev_calculated for next call
   return(rates_total);
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
double PercentRankHLC(const double &high[], const double &low[], const double &close[], int idx, int period)
  {
   int start = idx - period;
   if(start < 0)
      return 0;

   int count=0;
   for(int i = start; i < idx; i++)
     {
      count += (high[i] < high[idx]) ? 1 : 0;
      count += (low[i] < low[idx]) ? 1 : 0;
      count += (close[i] < close[idx]) ? 1 : 0;
     }

   return (count/(period * 3.0 - 1.0))*100;
  }
//+------------------------------------------------------------------+
