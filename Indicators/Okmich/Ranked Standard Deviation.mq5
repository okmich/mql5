//+------------------------------------------------------------------+
//|                                    Ranked Standard Deviation.mq5 |
//|                                    Copyright 2024, Michael Enudi |
//|                                             okmich2002@yahoo.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2024, Michael Enudi"
#property link      "okmich2002@yahoo.com"
#property version   "1.00"

#include <Okmich\Common\Common.mqh>

#property indicator_separate_window
#property indicator_buffers 2
#property indicator_plots   1
//--- plot ExtRankedStdDev
#property indicator_label1  "ExtRankedStdDev"
#property indicator_type1   DRAW_LINE
#property indicator_color1  clrDodgerBlue
#property indicator_style1  STYLE_SOLID
#property indicator_width1  1
//--- input parameters
input int      InpPeriod=20;
input int      InpRankPeriod=55;
input ENUM_MA_METHOD InpMaMethod=MODE_SMA;
//--- indicator buffers
double         ExtStdDevBuffer[], ExtRankedStdDevBuffer[];
//--- indicator handle
int   stdDevHandle;
//+------------------------------------------------------------------+
//| Custom indicator initialization function                         |
//+------------------------------------------------------------------+
int OnInit()
  {
   //ArraySetAsSeries(ExtStdDevBuffer, true);
//--- indicator buffers mapping
   SetIndexBuffer(0,ExtRankedStdDevBuffer,INDICATOR_DATA);
   SetIndexBuffer(1, ExtStdDevBuffer, INDICATOR_CALCULATIONS);

   stdDevHandle = iStdDev(NULL, 0, InpPeriod, 0, InpMaMethod, PRICE_CLOSE);
//---
   return stdDevHandle == INVALID_HANDLE ? INIT_FAILED : (INIT_SUCCEEDED);
  }
//+------------------------------------------------------------------+
//| Custom indicator iteration function                              |
//+------------------------------------------------------------------+
int OnCalculate(const int rates_total,
                const int prev_calculated,
                const int begin,
                const double &price[])
  {
//---
   int limit = 0;
   if(prev_calculated > InpRankPeriod)
      limit = rates_total-1;
   else
      limit = prev_calculated;

   int count=rates_total-limit;
   if(CopyBuffer(stdDevHandle, 0, 0, count, ExtStdDevBuffer) < count)
      return(0);

   for(int i=limit; i<rates_total && !IsStopped(); i++)
     {
      ExtRankedStdDevBuffer[i] = PercentRank(ExtStdDevBuffer, i, InpRankPeriod);
     }
//--- return value of prev_calculated for next call
   return(rates_total);
  }
//+------------------------------------------------------------------+
