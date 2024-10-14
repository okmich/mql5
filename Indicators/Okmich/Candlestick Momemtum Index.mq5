//+------------------------------------------------------------------+
//|                                   Candlestick Momemtum Index.mq5 |
//|                                    Copyright 2020, Michael Enudi |
//|                                             okmich2002@yahoo.com |
//+------------------------------------------------------------------+
#property copyright     "Copyright 2020, Michael Enudi"
#property link          "okmich2002@yahoo.com"
#property description   "Implementation of Ergodic Candlestick Momemtum Index By William Blau"
#property version   "1.00"

#include <MovingAverages.mqh>

#property indicator_separate_window
#property indicator_buffers 10
#property indicator_plots   2
//--- plot indicator level
#property indicator_level1 0.0
#property indicator_levelcolor clrSilver
#property indicator_levelstyle STYLE_DOT
//--- plot CMIMain
#property indicator_label1  "CMI"
#property indicator_type1   DRAW_LINE
#property indicator_color1  clrLightSeaGreen
#property indicator_style1  STYLE_SOLID
#property indicator_width1  2
//--- plot InpCmiSignal
#property indicator_label2  "Signal"
#property indicator_type2   DRAW_LINE
#property indicator_color2  clrRed
#property indicator_style2  STYLE_DOT
#property indicator_width2  1

//--- input parameters
input int      InpCmiPeriod=20;
input int      InpCmiSmooth=13;
input int      InpDblCmiSmooth=2;
input int      InpCmiSignal=5;
//--- indicator buffers
double         ExtCmiMainBuffer[];
double         ExtCmiSignalBuffer[];
double         bodyBuffer[], absBodyBuffer[];
double         smthBodyBuffer[], smthAbsBuffer[];
double         dblSmthBodyBuffer[], dblSmthAbsBodyBuffer[];
double         trpSmthBodyBuffer[], trpSmthAbsBodyBuffer[];
//--- other variables
static int beginPeriod, beginSmooth, beginDblSmooth, beginSignal;
//+------------------------------------------------------------------+
//| Custom indicator initialization function                         |
//+------------------------------------------------------------------+
int OnInit()
  {
//--- indicator buffers mapping
   SetIndexBuffer(0,ExtCmiMainBuffer,INDICATOR_DATA);
   SetIndexBuffer(1,ExtCmiSignalBuffer,INDICATOR_DATA);
   SetIndexBuffer(2,bodyBuffer,INDICATOR_CALCULATIONS);
   SetIndexBuffer(3,absBodyBuffer,INDICATOR_CALCULATIONS);
   SetIndexBuffer(4,smthBodyBuffer,INDICATOR_CALCULATIONS);
   SetIndexBuffer(5,smthAbsBuffer,INDICATOR_CALCULATIONS);
   SetIndexBuffer(6,dblSmthBodyBuffer,INDICATOR_CALCULATIONS);
   SetIndexBuffer(7,dblSmthAbsBodyBuffer,INDICATOR_CALCULATIONS);
   SetIndexBuffer(8,trpSmthBodyBuffer,INDICATOR_CALCULATIONS);
   SetIndexBuffer(9,trpSmthAbsBodyBuffer,INDICATOR_CALCULATIONS);

   string shortname = StringFormat("CMI(%d, %d, %d, %d)", InpCmiPeriod, InpCmiSmooth, InpDblCmiSmooth, InpCmiSignal);
   IndicatorSetString(INDICATOR_SHORTNAME, shortname);
   IndicatorSetInteger(INDICATOR_DIGITS, _Digits);
   PlotIndexSetString(0,PLOT_LABEL,"CMI");
   PlotIndexSetString(1,PLOT_LABEL,"Signal");

   beginPeriod = InpCmiPeriod -1;
   beginSmooth = beginPeriod + InpCmiSmooth -1;
   beginDblSmooth = beginSmooth + InpDblCmiSmooth -1;
   beginSignal = beginDblSmooth + InpCmiSignal -1;

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
      absBodyBuffer[i] = 0.0;
     }

   for(int i=limit; i<rates_total && !IsStopped(); i++)
     {
      bodyBuffer[i] = close[i] - open[i];
      absBodyBuffer[i] = MathAbs(close[i] - open[i]);
     }

   ExponentialMAOnBuffer(rates_total, prev_calculated, beginPeriod, InpCmiPeriod, bodyBuffer, smthBodyBuffer);
   ExponentialMAOnBuffer(rates_total, prev_calculated, beginPeriod, InpCmiPeriod, absBodyBuffer, smthAbsBuffer);

   ExponentialMAOnBuffer(rates_total, prev_calculated, beginSmooth, InpCmiSmooth, smthBodyBuffer, dblSmthBodyBuffer);
   ExponentialMAOnBuffer(rates_total, prev_calculated, beginSmooth, InpCmiSmooth, smthAbsBuffer, dblSmthAbsBodyBuffer);

   ExponentialMAOnBuffer(rates_total, prev_calculated, beginDblSmooth,
                         InpDblCmiSmooth, dblSmthBodyBuffer, trpSmthBodyBuffer);
   ExponentialMAOnBuffer(rates_total, prev_calculated, beginDblSmooth,
                         InpDblCmiSmooth, dblSmthAbsBodyBuffer, trpSmthAbsBodyBuffer);

   for(int i=limit; i<rates_total && !IsStopped(); i++)
     {
      if(trpSmthAbsBodyBuffer[i] != 0)
         ExtCmiMainBuffer[i] = 100 * trpSmthBodyBuffer[i]/trpSmthAbsBodyBuffer[i];
      else
         ExtCmiMainBuffer[i] = 0;
     }

   ExponentialMAOnBuffer(rates_total, prev_calculated, beginSignal,
                         InpCmiSignal, ExtCmiMainBuffer, ExtCmiSignalBuffer);

//--- return value of prev_calculated for next call
   return(rates_total);
  }
//+------------------------------------------------------------------+
