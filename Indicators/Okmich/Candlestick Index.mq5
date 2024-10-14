//+------------------------------------------------------------------+
//|                                            Candlestick Index.mq5 |
//|                                    Copyright 2020, Michael Enudi |
//|                                             okmich2002@yahoo.com |
//+------------------------------------------------------------------+
#property copyright     "Copyright 2020, Michael Enudi"
#property link          "okmich2002@yahoo.com"
#property description   "Implementation of Ergodic Candlestick Index By William Blau"
#property version   "1.00"

#include <MovingAverages.mqh>

#property indicator_separate_window
#property indicator_buffers 10
#property indicator_plots   2
//--- plot indicator level
#property indicator_level1 0.0
#property indicator_levelcolor clrSilver
#property indicator_levelstyle STYLE_DOT
//--- plot CSIMain
#property indicator_label1  "CSI"
#property indicator_type1   DRAW_LINE
#property indicator_color1  clrLightSeaGreen
#property indicator_style1  STYLE_SOLID
#property indicator_width1  2
//--- plot InpCsiSignal
#property indicator_label2  "Signal"
#property indicator_type2   DRAW_LINE
#property indicator_color2  clrRed
#property indicator_style2  STYLE_DOT
#property indicator_width2  1

//--- input parameters
input int      InpCsiPeriod=20;
input int      InpCsiSmooth=13;
input int      InpCsiDblSmooth=2;
input int      InpCsiSignal=5;
//--- indicator buffers
double         ExtCsiMainBuffer[];
double         ExtCsiSignalBuffer[];
double         rangeBuffer[], bodyBuffer[];
double         emaRangeBuffer[], emaBodyBuffer[];
double         dblEmaRangeBuffer[], dblEmaBodyBuffer[];
double         trpEmaRangeBuffer[], trpEmaBodyBuffer[];
//--- other variables
static int beginPeriod, beginSmooth, beginDblSmooth, beginSignal;
//+------------------------------------------------------------------+
//| Custom indicator initialization function                         |
//+------------------------------------------------------------------+
int OnInit()
  {
//--- indicator buffers mapping
   SetIndexBuffer(0,ExtCsiMainBuffer,INDICATOR_DATA);
   SetIndexBuffer(1,ExtCsiSignalBuffer,INDICATOR_DATA);
   SetIndexBuffer(2,rangeBuffer,INDICATOR_CALCULATIONS);
   SetIndexBuffer(3,bodyBuffer,INDICATOR_CALCULATIONS);
   SetIndexBuffer(4,emaRangeBuffer,INDICATOR_CALCULATIONS);
   SetIndexBuffer(5,emaBodyBuffer,INDICATOR_CALCULATIONS);
   SetIndexBuffer(6,dblEmaRangeBuffer,INDICATOR_CALCULATIONS);
   SetIndexBuffer(7,dblEmaBodyBuffer,INDICATOR_CALCULATIONS);
   SetIndexBuffer(8,trpEmaRangeBuffer,INDICATOR_CALCULATIONS);
   SetIndexBuffer(9,trpEmaBodyBuffer,INDICATOR_CALCULATIONS);

   string shortname = StringFormat("CSI(%d, %d, %d, %d)",
                                   InpCsiPeriod, InpCsiSmooth, InpCsiDblSmooth, InpCsiSignal);
   IndicatorSetString(INDICATOR_SHORTNAME, shortname);
   IndicatorSetInteger(INDICATOR_DIGITS, _Digits);
   PlotIndexSetString(0,PLOT_LABEL,"CSI");
   PlotIndexSetString(1,PLOT_LABEL,"Signal");

   beginPeriod = InpCsiPeriod -1;
   beginSmooth = beginPeriod + InpCsiSmooth -1;
   beginDblSmooth = beginSmooth + InpCsiDblSmooth -1;
   beginSignal = beginDblSmooth + InpCsiSignal -1;

   PlotIndexSetInteger(0, PLOT_DRAW_BEGIN, beginSignal + 1);
   PlotIndexSetInteger(1, PLOT_DRAW_BEGIN, beginSignal + 1);

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
   if(rates_total < beginSignal)
      return(0);

   int limit;
   if(prev_calculated==0)
      limit=0;
   else
      limit=prev_calculated-1;

//fill up with zero
   for(int i = 0; i < limit; i++)
     {
      bodyBuffer[i] = 0.0;
      rangeBuffer[i] = 0.0;
     }

   for(int i=limit; i<rates_total && !IsStopped(); i++)
     {
      rangeBuffer[i] = high[i] - low[i];
      bodyBuffer[i] = close[i] - open[i];
     }

   ExponentialMAOnBuffer(rates_total, prev_calculated, beginPeriod, InpCsiPeriod, rangeBuffer, emaRangeBuffer);
   ExponentialMAOnBuffer(rates_total, prev_calculated, beginPeriod, InpCsiPeriod, bodyBuffer, emaBodyBuffer);

   ExponentialMAOnBuffer(rates_total, prev_calculated, beginSmooth, InpCsiSmooth, emaRangeBuffer, dblEmaRangeBuffer);
   ExponentialMAOnBuffer(rates_total, prev_calculated, beginSmooth, InpCsiSmooth, emaBodyBuffer, dblEmaBodyBuffer);

   ExponentialMAOnBuffer(rates_total, prev_calculated, beginDblSmooth,
                         InpCsiDblSmooth, dblEmaRangeBuffer, trpEmaRangeBuffer);
   ExponentialMAOnBuffer(rates_total, prev_calculated, beginDblSmooth,
                         InpCsiDblSmooth, dblEmaBodyBuffer, trpEmaBodyBuffer);

   for(int i=limit; i<rates_total && !IsStopped(); i++)
     {
      if(trpEmaRangeBuffer[i] != 0)
         ExtCsiMainBuffer[i] = 100 * trpEmaBodyBuffer[i]/trpEmaRangeBuffer[i];
      else
         ExtCsiMainBuffer[i] = 0;
     }

   ExponentialMAOnBuffer(rates_total, prev_calculated, beginSignal, InpCsiSignal, ExtCsiMainBuffer, ExtCsiSignalBuffer);

//--- return value of prev_calculated for next call
   return(rates_total);
  }
//+------------------------------------------------------------------+
