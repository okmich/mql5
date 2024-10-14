//+------------------------------------------------------------------+
//|                                              Fibonacci Range.mq5 |
//|                                                    Michael Enudi |
//|                                             okmich2002@yahoo.com |
//+------------------------------------------------------------------+
#property copyright "Michael Enudi"
#property link      "okmich2002@yahoo.com"
#property version   "1.00"
#property indicator_chart_window
#property indicator_buffers 3
#property indicator_plots   1
//--- plot FiboRange
#property indicator_label1  "FiboRange"
#property indicator_type1   DRAW_COLOR_HISTOGRAM2
#property indicator_color1  clrNONE,clrDeepSkyBlue,clrSandyBrown
#property indicator_style1  STYLE_SOLID
#property indicator_width1  3
//--- indicator buffers
double         fbOpenBuffer[], fbCloseBuffer[], fbColorBuffer[];

static int PlotBegins = 13;
//+------------------------------------------------------------------+
//| Custom indicator initialization function                         |
//+------------------------------------------------------------------+
int OnInit()
  {
//--- indicator buffers mapping
   SetIndexBuffer(0,fbOpenBuffer,INDICATOR_DATA);
   SetIndexBuffer(1,fbCloseBuffer,INDICATOR_DATA);
   SetIndexBuffer(2,fbColorBuffer,INDICATOR_COLOR_INDEX);

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
   if(rates_total < PlotBegins)
      return 0;

   int pos = prev_calculated > 0 ? prev_calculated - 1 : PlotBegins;
   for(int i = pos; i < rates_total; i++)
     {

      if(high[i] > low[i-2] &&
         high[i] > low[i-3] &&
         high[i] > low[i-5] &&
         high[i] > low[i-8] &&
         high[i] > low[i-13])
        {
         fbOpenBuffer[i] = low[i];
         fbCloseBuffer[i] = high[i];
         fbColorBuffer[i] = 1.0;
        }
      else
         if(low[i] < high[i-2] &&
            low[i] < high[i-3] &&
            low[i] < high[i-5] &&
            low[i] < high[i-8] &&
            low[i] < high[i-13])
           {
            fbOpenBuffer[i] = low[i];
            fbCloseBuffer[i] = high[i];
            fbColorBuffer[i] = 2;
           }
         else
           {
            fbOpenBuffer[i] = EMPTY_VALUE;
            fbCloseBuffer[i] = EMPTY_VALUE;
            fbColorBuffer[i] = 0;
           }
     }

//--- return value of prev_calculated for next call
   return(rates_total);
  }
//+------------------------------------------------------------------+
