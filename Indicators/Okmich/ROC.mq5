//+------------------------------------------------------------------+
//|                                                          ROC.mq5 |
//|                   Copyright 2009-2020, MetaQuotes Software Corp. |
//|                                              http://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright   "2009-2020, MetaQuotes Software Corp."
#property link        "http://www.mql5.com"
#property description "Rate of Change"
//--- indicator settings
#include <MovingAverages.mqh>
#property indicator_separate_window
#property indicator_buffers 3
#property indicator_plots   3
#property indicator_type1   DRAW_LINE
#property indicator_color1  LightSeaGreen
#property indicator_label1  "ROC"
#property indicator_type2   DRAW_LINE
#property indicator_color2  clrPeachPuff
#property indicator_style2  STYLE_DOT
#property indicator_label2  "Signal"

#property indicator_level1 0

//--- input parameters
input int InpRocPeriod=12; // Period
input bool InpIsSmoothed=true; // Smoothed
input int InpSmoothPeriod=11; // Smoothing Period
input ENUM_MA_METHOD InpSmoothMethod=MODE_EMA; // Smoothing Method

//--- indicator buffer
double    ExtRocBuffer[], ExtRocMABuffer[];
double    ExtTempBuffer[];

int       ExtRocPeriod;
//+------------------------------------------------------------------+
//| Rate of Change initialization function                           |
//+------------------------------------------------------------------+
void OnInit()
  {
//--- check for input
   if(InpRocPeriod<1)
     {
      ExtRocPeriod=12;
      PrintFormat("Incorrect value for input variable InpRocPeriod = %d. Indicator will use value %d for calculations.",
                  InpRocPeriod,ExtRocPeriod);
     }
   else
      ExtRocPeriod=InpRocPeriod;
//--- indicator buffers mapping
   SetIndexBuffer(0,ExtRocBuffer,INDICATOR_DATA);
   SetIndexBuffer(1,ExtRocMABuffer,INDICATOR_DATA);
   SetIndexBuffer(2,ExtTempBuffer,INDICATOR_CALCULATIONS);
//--- set accuracy
   IndicatorSetInteger(INDICATOR_DIGITS,2);
//--- name for DataWindow and indicator subwindow label
   IndicatorSetString(INDICATOR_SHORTNAME,"ROC("+string(ExtRocPeriod)+")");
//--- sets first bar from what index will be drawn
   PlotIndexSetInteger(0,PLOT_DRAW_BEGIN,ExtRocPeriod);
  }
//+------------------------------------------------------------------+
//| Rate of Change                                                   |
//+------------------------------------------------------------------+
int OnCalculate(const int rates_total,const int prev_calculated,const int begin,const double &price[])
  {
   if(rates_total<ExtRocPeriod)
      return(0);
//--- preliminary calculations
   int pos=prev_calculated-1;
   if(pos<ExtRocPeriod)
      pos=ExtRocPeriod;
//--- the main loop of calculations
   for(int i=pos; i<rates_total && !IsStopped(); i++)
     {
      if(price[i]==0.0)
         ExtTempBuffer[i]=0.0;
      else
         ExtTempBuffer[i]=(price[i]-price[i-ExtRocPeriod])/price[i]*100;

      if(InpIsSmoothed)
        {
         ExtRocBuffer[i] = (ExtTempBuffer[i] + 2 * ExtTempBuffer[i-1] + 2 * ExtTempBuffer[i-2] + ExtTempBuffer[i-3]) / 6;
        }
      else
        {
         ExtRocBuffer[i] = ExtTempBuffer[i];
        }
     }

   switch(InpSmoothMethod)
     {
      case MODE_EMA:
         ExponentialMAOnBuffer(rates_total, prev_calculated, begin, InpSmoothPeriod, ExtRocBuffer, ExtRocMABuffer);
         break;
      case MODE_LWMA:
         LinearWeightedMAOnBuffer(rates_total, prev_calculated, begin, InpSmoothPeriod, ExtRocBuffer, ExtRocMABuffer);
         break;
      case MODE_SMA:
         SimpleMAOnBuffer(rates_total, prev_calculated, begin, InpSmoothPeriod, ExtRocBuffer, ExtRocMABuffer);
         break;
      case MODE_SMMA:
         SimpleMAOnBuffer(rates_total, prev_calculated, begin, InpSmoothPeriod, ExtRocBuffer, ExtRocMABuffer);
     };

//--- OnCalculate done. Return new prev_calculated.
   return(rates_total);
  }
//+------------------------------------------------------------------+
