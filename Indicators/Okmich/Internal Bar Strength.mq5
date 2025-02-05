//+------------------------------------------------------------------+
//|                                        Internal Bar Strength.mq5 |
//|                             Copyright 2023, okmich2002@yahoo.com |
//|                                             okmich2002@yahoo.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2023, okmich2002@yahoo.com"
#property link      "okmich2002@yahoo.com"
#property version   "1.00"

#property indicator_separate_window

#property indicator_buffers 1
#property indicator_plots   1

#property indicator_type1   DRAW_LINE
#property indicator_color1  clrOrchid
#property indicator_style1  STYLE_SOLID
#property indicator_width1  1

#property indicator_level1 0.80
#property indicator_level2 0.20

double    ExtBufferIBS[];
//+------------------------------------------------------------------+
//| Custom indicator initialization function                         |
//+------------------------------------------------------------------+
void OnInit()
  {
//--- indicator buffers mapping
   SetIndexBuffer(0,ExtBufferIBS,INDICATOR_DATA);

   IndicatorSetString(INDICATOR_SHORTNAME,"IBS");
   IndicatorSetInteger(INDICATOR_DIGITS,2);

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
   if(rates_total < 2)
      return 0;
      
   int start = 0;
   if(prev_calculated > 2)
      start = prev_calculated - 1;

   for(int i = start; i < rates_total && !IsStopped(); i++)
     {
      ExtBufferIBS[i]=(high[i]!=low[i] ? (close[i]-low[i])/(high[i]-low[i]) : 0);
     }

//--- return value of prev_calculated for next call
   return(rates_total);
  }
//+------------------------------------------------------------------+
