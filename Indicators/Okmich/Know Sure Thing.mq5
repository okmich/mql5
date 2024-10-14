//+------------------------------------------------------------------+
//|                                              Know Sure Thing.mq5 |
//|                                    Copyright 2021, Michael Enudi |
//|                                             okmich2002@yahoo.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2021, Michael Enudi"
#property link      "okmich2002@yahoo.com"
#property version   "1.00"

#include <MovingAverages.mqh>

#property indicator_separate_window
#property indicator_buffers 6
#property indicator_plots   2
#property indicator_level1 0
//--- plot ExtKstBuffer
#property indicator_label1  "KST"
#property indicator_type1   DRAW_LINE
#property indicator_color1  clrLightSeaGreen
#property indicator_style1  STYLE_SOLID
#property indicator_width1  2
//--- plot ExtSignal
#property indicator_label2  "Signal"
#property indicator_type2   DRAW_LINE
#property indicator_color2  clrDarkOrange
#property indicator_style2  STYLE_DOT
#property indicator_width2  1
//--- input parameters
input int      InpRoc1Period=10;
input int      InpRoc1Ma=10;
input int      InpRoc2Period=15;
input int      InpRoc2Ma=10;
input int      InpRoc3Period=20;
input int      InpRoc3Ma=10;
input int      InpRoc4Period=30;
input int      InpRoc4Ma=15;
input int      InpSignalPeriod=9;
//--- indicator buffers
double         ExtKstBufferBuffer[];
double         ExtSignalBuffer[];
double         ExtRoc1Buffer[], ExtRoc2Buffer[], ExtRoc3Buffer[], ExtRoc4Buffer[];

double         RocsCalc[4];
//+------------------------------------------------------------------+
//| Custom indicator initialization function                         |
//+------------------------------------------------------------------+
int OnInit()
  {
//--- indicator buffers mapping
   SetIndexBuffer(0,ExtKstBufferBuffer,INDICATOR_DATA);
   SetIndexBuffer(1,ExtSignalBuffer,INDICATOR_DATA);
   SetIndexBuffer(2,ExtRoc1Buffer,INDICATOR_DATA);
   SetIndexBuffer(3,ExtRoc2Buffer,INDICATOR_DATA);
   SetIndexBuffer(4,ExtRoc3Buffer,INDICATOR_DATA);
   SetIndexBuffer(5,ExtRoc4Buffer,INDICATOR_DATA);

//--- set accuracy
   IndicatorSetInteger(INDICATOR_DIGITS,2);
//--- name for DataWindow and indicator subwindow label
   IndicatorSetString(INDICATOR_SHORTNAME,StringFormat("KST(%d,%d,%d,%d,%d,%d,%d,%d,%d)",
   InpRoc1Period, InpRoc1Ma, InpRoc2Period, InpRoc2Ma,
   InpRoc3Period, InpRoc3Ma, InpRoc4Period, InpRoc4Ma,
   InpSignalPeriod));
//--- sets first bar from what index will be drawn
   PlotIndexSetInteger(0,PLOT_DRAW_BEGIN,InpRoc4Ma+InpRoc4Period);
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
//---
   if(rates_total<InpRoc4Period)
      return(0);
//--- preliminary calculations
   int pos=prev_calculated-1;
   if(pos<InpRoc4Period)
      pos=InpRoc4Period;

   double sma1=0, sma2=0, sma3=0, sma4=0;
   for(int i = pos; i < rates_total && !IsStopped(); i++)
     {
      ExtRoc1Buffer[i] = roc(price, i, InpRoc1Period);
      ExtRoc2Buffer[i] = roc(price, i, InpRoc2Period);
      ExtRoc3Buffer[i] = roc(price, i, InpRoc3Period);
      ExtRoc4Buffer[i] = roc(price, i, InpRoc4Period);

      sma1 = SimpleMA(i, InpRoc1Ma, ExtRoc1Buffer);
      sma2 = SimpleMA(i, InpRoc2Ma, ExtRoc2Buffer);
      sma3 = SimpleMA(i, InpRoc3Ma, ExtRoc3Buffer);
      sma4 = SimpleMA(i, InpRoc4Ma, ExtRoc4Buffer);

      ExtKstBufferBuffer[i] = (sma1 * 1) + (sma2 * 2) + (sma3 * 3) + (sma4 * 4);
      ExtSignalBuffer[i] = SimpleMA(i, InpSignalPeriod, ExtKstBufferBuffer);
     }
//--- return value of prev_calculated for next call
   return(rates_total);
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
double roc(const double &buffer[], int i, int period)
  {
   return (buffer[i]-buffer[i-period])/buffer[i]*100;
  }
//+------------------------------------------------------------------+
