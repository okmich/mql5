//+------------------------------------------------------------------+
//|                                        Trend Intensity Index.mq5 |
//|                                    Copyright 2021, Michael Enudi |
//|                                             okmich2002@yahoo.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2021, Michael Enudi"
#property link      "okmich2002@yahoo.com"
#property version   "1.00"
#include  <MovingAverages.mqh>

#property indicator_separate_window
#property indicator_level1 0.85
#property indicator_level2 0.15
#property indicator_minimum 0.0
#property indicator_maximum 1.0
#property indicator_buffers 5
#property indicator_plots   2
//--- plot ExtTTIBuffer
#property indicator_label1  "TTI"
#property indicator_type1   DRAW_LINE
#property indicator_color1  clrSteelBlue
#property indicator_style1  STYLE_SOLID
#property indicator_width1  2
//--- plot ExtSignalBuffer
#property indicator_label2  "Signal"
#property indicator_type2   DRAW_LINE
#property indicator_color2  clrSilver
#property indicator_style2  STYLE_DOT
#property indicator_width2  1
//--- input parameters
input int      InpPeriod=20;
input int      InpSignal=5;
//--- indicator buffers
double         ExtTTIBuffer[];
double         ExtSignalBuffer[];
double         maBuffer[], posDevBuffer[], negDevBuffer[];
int            PlotBegins, mPeriod;
//+------------------------------------------------------------------+
//| Custom indicator initialization function                         |
//+------------------------------------------------------------------+
int OnInit()
  {
//--- indicator buffers mapping
   SetIndexBuffer(0,ExtTTIBuffer,INDICATOR_DATA);
   SetIndexBuffer(1,ExtSignalBuffer,INDICATOR_DATA);
   SetIndexBuffer(2,maBuffer,INDICATOR_CALCULATIONS);
   SetIndexBuffer(3,posDevBuffer,INDICATOR_CALCULATIONS);
   SetIndexBuffer(4,negDevBuffer,INDICATOR_CALCULATIONS);

   string indicatorName = StringFormat("TTI(%d, %d)", InpPeriod, InpSignal);
   IndicatorSetString(INDICATOR_SHORTNAME, indicatorName);

   PlotIndexSetString(0, PLOT_LABEL, "TTI");
   PlotIndexSetString(1, PLOT_LABEL, "Signal");
//--- sets first bar from what index will be drawn
   PlotBegins = InpPeriod + InpSignal;
   PlotIndexSetInteger(0,PLOT_DRAW_BEGIN, PlotBegins);

//-- mPeriod
   mPeriod = (InpPeriod % 2 == 0) ? InpPeriod / 2 : (InpPeriod+1)/2;
//---
   return(INIT_SUCCEEDED);
  }
//+------------------------------------------------------------------+
//| Custom indicator iteration function                              |
//+------------------------------------------------------------------+
int OnCalculate(const int rates_total,
                const int prev_calculated,
                const int begin,
                const double &price[])
  {
   if(Bars(_Symbol,_Period)<rates_total)
      return(prev_calculated);

//--- check for rates total
   if(rates_total < PlotBegins)
      return(0); // not enough bars for calculation

   int startIdx;
   if(prev_calculated > 0)
      startIdx = prev_calculated - 1;
   else
      startIdx = PlotBegins;

   double ma, deviation;
   for(int i = startIdx; i < rates_total && !IsStopped(); i++)
     {
      ma = SimpleMA(i, InpPeriod, price);
      deviation = price[i] - ma;
      if(deviation > 0)
        {
         posDevBuffer[i] = deviation;
         negDevBuffer[i] = 0;
        }
      else
        {
         posDevBuffer[i] = 0;
         negDevBuffer[i] = MathAbs(deviation);
        }

      double sdPos = SumUp(posDevBuffer, i);
      double sdNeg = SumUp(negDevBuffer, i);
      double sd = sdPos + sdNeg;
      ExtTTIBuffer[i] = (sd == 0) ? 0: (sdPos / sd);
      ExtSignalBuffer[i] = SimpleMA(i, InpSignal, ExtTTIBuffer);

     }
//--- return value of prev_calculated for next call
   return(rates_total);
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
double SumUp(double &buffer[], int pos)
  {
   double sum=0;
   for(int i = pos-mPeriod+1; i <= pos; i++)
      sum += buffer[i];

   return sum;
  }
//+------------------------------------------------------------------+
