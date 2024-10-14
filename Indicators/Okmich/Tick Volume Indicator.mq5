//+------------------------------------------------------------------+
//|                                                          TVI.mq5 |
//|                                    Copyright 2020, Michael Enudi |
//|                                             okmich2002@yahoo.com |
//+------------------------------------------------------------------+
#property copyright     "Copyright 2020, Michael Enudi"
#property link          "okmich2002@yahoo.com"
#property description   "Implementation of William Blau's Tick Volume Indicator"
#property version   "1.00"
#include <MovingAverages.mqh>

#property indicator_separate_window
#property indicator_buffers 8
#property indicator_plots   2
//--- plot TVI
#property indicator_label1  "TVI"
#property indicator_type1   DRAW_LINE
#property indicator_color1  clrLightSeaGreen
#property indicator_style1  STYLE_SOLID
#property indicator_width1  2
//--- plot Signal
#property indicator_label2  "Signal"
#property indicator_type2   DRAW_LINE
#property indicator_color2  clrRed
#property indicator_style2  STYLE_DOT
#property indicator_width2  1

#property indicator_level1  0

//--- input parameters
input int      TVIPeriod=25;
input int      TVISmoothing=13;
input int      TVISignal=5;
//--- indicator buffers
double         TVIBuffer[], TVISignalBuffer[];
double         UpTickBuffer[], DownTickBuffer[];
double         EmaUpTickBuffer[], EmaDownTickBuffer[];
double         DblEmaUpTickBuffer[], DblEmaDownTickBuffer[];
//--- other variables
static int plotBegins;
//+------------------------------------------------------------------+
//| Custom indicator initialization function                         |
//+------------------------------------------------------------------+
int OnInit()
  {
//--- indicator buffers mapping
   SetIndexBuffer(0,TVIBuffer,INDICATOR_DATA);
   SetIndexBuffer(1,TVISignalBuffer,INDICATOR_DATA);
   SetIndexBuffer(2,DownTickBuffer,INDICATOR_CALCULATIONS);
   SetIndexBuffer(3,UpTickBuffer,INDICATOR_CALCULATIONS);
   SetIndexBuffer(4,EmaDownTickBuffer,INDICATOR_CALCULATIONS);
   SetIndexBuffer(5,EmaUpTickBuffer,INDICATOR_CALCULATIONS);
   SetIndexBuffer(6,DblEmaDownTickBuffer,INDICATOR_CALCULATIONS);
   SetIndexBuffer(7,DblEmaUpTickBuffer,INDICATOR_CALCULATIONS);

   string shortname = StringFormat("Ergodic TVI(%d, %d, %d)", TVIPeriod, TVISmoothing, TVISignal);
   IndicatorSetString(INDICATOR_SHORTNAME, shortname);

   IndicatorSetInteger(INDICATOR_DIGITS, _Digits);

   PlotIndexSetString(0,PLOT_LABEL,"Main");
   PlotIndexSetString(1,PLOT_LABEL,"Signal");

   plotBegins = TVIPeriod + TVISmoothing + TVISignal;

   PlotIndexSetInteger(0, PLOT_DRAW_BEGIN, plotBegins);
   PlotIndexSetInteger(1, PLOT_DRAW_BEGIN, plotBegins);
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
//--- check for data
   if(rates_total < plotBegins)
      return(0);

   int start;
   if(prev_calculated==0)
      start=prev_calculated;
   else
      start=prev_calculated-1;

   for(int i=start; i<rates_total && !IsStopped(); i++)
     {
      DownTickBuffer[i] = (close[i] <= open[i]) ? (double)tick_volume[i] : 0 ;
      UpTickBuffer[i] = (close[i] <= open[i]) ? 0 : (double)tick_volume[i] ;
     }

   ExponentialMAOnBuffer(rates_total, prev_calculated,0, TVIPeriod, DownTickBuffer, EmaDownTickBuffer);
   ExponentialMAOnBuffer(rates_total, prev_calculated,0, TVIPeriod, UpTickBuffer, EmaUpTickBuffer);

   ExponentialMAOnBuffer(rates_total, prev_calculated, TVIPeriod + TVISmoothing-1, TVISmoothing, EmaDownTickBuffer, DblEmaDownTickBuffer);
   ExponentialMAOnBuffer(rates_total, prev_calculated, TVIPeriod + TVISmoothing-1, TVISmoothing, EmaUpTickBuffer, DblEmaUpTickBuffer);

   double denum;
   for(int i=start; i<rates_total && !IsStopped(); i++)
     {
      denum = DblEmaUpTickBuffer[i] + DblEmaDownTickBuffer[i];
      if(denum != 0)
         TVIBuffer[i] =  100 * (DblEmaUpTickBuffer[i] - DblEmaDownTickBuffer[i])/denum;
      else
         TVIBuffer[i] = 0;
     }

   ExponentialMAOnBuffer(rates_total,prev_calculated, start, TVISignal, TVIBuffer, TVISignalBuffer);

//--- return value of prev_calculated for next call
   return(rates_total);
  }
//+------------------------------------------------------------------+
