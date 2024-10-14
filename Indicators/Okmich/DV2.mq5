//+------------------------------------------------------------------+
//|                                                          DV2.mq5 |
//|                                    Copyright 2021, Michael Enudi |
//|                                             okmich2002@yahoo.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2021, Michael Enudi"
#property link      "okmich2002@yahoo.com"
#property version   "1.00"

#include <MovingAverages.mqh>
#include <Okmich\Common\Common.mqh>
#property indicator_separate_window
#property indicator_buffers 3
#property indicator_plots   1
//--- plot ExtDV2Buffer
#property indicator_label1  "DV2"
#property indicator_type1   DRAW_LINE
#property indicator_color1  clrGoldenrod
#property indicator_style1  STYLE_SOLID
#property indicator_width1  1

#property indicator_minimum 0
#property indicator_maximum 100
#property indicator_level1 85.0
#property indicator_level2 15.0

input int InpMaPeriod = 2;             //MA Period
input int InpRankLookBackPeriod = 252; //Rank Look Back Period

//--- indicator buffers
double         ExtDV2Buffer[];
double         ExtTempBuffer[], ExtHCAvgBufferBuffer[];

int plotBegins;
//+------------------------------------------------------------------+
//| Custom indicator initialization function                         |
//+------------------------------------------------------------------+
int OnInit()
  {
//--- indicator buffers mapping
   SetIndexBuffer(0,ExtDV2Buffer,INDICATOR_DATA);
   SetIndexBuffer(1,ExtHCAvgBufferBuffer,INDICATOR_CALCULATIONS);
   SetIndexBuffer(2,ExtTempBuffer,INDICATOR_CALCULATIONS);

//---- initializations of variable for indicator short name
   string shortname = StringFormat("DV2(%d,%d)", InpMaPeriod, InpRankLookBackPeriod);
//---- creating name for displaying in a separate sub-window and in a tooltip
   IndicatorSetString(INDICATOR_SHORTNAME,shortname);
//---- set accuracy of displaying of the indicator values
   IndicatorSetInteger(INDICATOR_DIGITS, 2);
//--- indexes draw begin settings
   plotBegins = InpMaPeriod+1;
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

   for(int i = start; i < rates_total; i++)
     {
      ExtHCAvgBufferBuffer[i] = (close[i] / (0.5 * (high[i]+low[i]))) - 1;
      ExtTempBuffer[i] = 100 * SimpleMA(i, InpMaPeriod, ExtHCAvgBufferBuffer);
      ExtDV2Buffer[i] = PercentRank(ExtTempBuffer, i, InpRankLookBackPeriod);
     }

//--- return value of prev_calculated for next call
   return(rates_total);
  }
