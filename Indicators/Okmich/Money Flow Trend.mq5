//+------------------------------------------------------------------+
//|                                               MoneyFlowTrend.mq5 |
//|                                    Copyright 2020, Michael Enudi |
//|                                             okmich2002@yahoo.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2020, Michael Enudi"
#property link      "okmich2002@yahoo.com"
#property description "Adaptations of both AD and OBV to show the trend of money flow"

#property indicator_separate_window
#property indicator_buffers 2
#property indicator_plots   2
#property indicator_type1   DRAW_LINE
#property indicator_color1  clrCrimson
#property indicator_label1  "MFTrend"
#property indicator_width1  2
#property indicator_type2   DRAW_LINE
#property indicator_color2  clrSilver
#property indicator_label2  "Signal"
#property indicator_width2  1
#property indicator_style2  STYLE_DOT

#include <MovingAverages.mqh>
//--- input params
input ENUM_APPLIED_VOLUME InpVolumeType=VOLUME_TICK;  // Volume type
input int   InpSignalPeriod=12;                       // Smoothing Period
input ENUM_MA_METHOD InpSmoothingType=MODE_SMA;       // Smoothing type
//---- buffers
double ExtADbuffer[],ExtSignlbuffer[];
//+------------------------------------------------------------------+
//| Custom indicator initialization function                         |
//+------------------------------------------------------------------+
void OnInit()
  {
//--- indicator digits
   IndicatorSetInteger(INDICATOR_DIGITS,0);
//--- indicator short name
   string shortName = StringFormat("MFTrend (%s, %d, %s)", EnumToString(InpVolumeType), InpSignalPeriod, EnumToString(InpSmoothingType));
   IndicatorSetString(INDICATOR_SHORTNAME, shortName);
//---- index buffer
   SetIndexBuffer(0,ExtADbuffer);
   SetIndexBuffer(1,ExtSignlbuffer);
//--- set index draw begin
   PlotIndexSetInteger(0,PLOT_DRAW_BEGIN,InpSignalPeriod);
//---- OnInit done
  }
//+------------------------------------------------------------------+
//| Accumulation/Distribution                                        |
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
//--- check for bars count
   if(rates_total<InpSignalPeriod)
      return(0); //exit with zero result
//--- get current position
   int pos=prev_calculated-1;
   if(pos < 0)
      pos = 0;
//--- calculate with appropriate volumes
   if(InpVolumeType==VOLUME_TICK)
      Calculate(rates_total,pos,open,high,low,close,tick_volume);
   else
      Calculate(rates_total,pos,open,high,low,close,volume);
//----
   int begin = pos < InpSignalPeriod ? 0 : pos-InpSignalPeriod;
   switch(InpSmoothingType)
     {
      case MODE_EMA:
         ExponentialMAOnBuffer(rates_total, prev_calculated, begin, InpSignalPeriod, ExtADbuffer, ExtSignlbuffer);
         break;
      case MODE_LWMA:
         LinearWeightedMAOnBuffer(rates_total, prev_calculated, begin, InpSignalPeriod, ExtADbuffer, ExtSignlbuffer);
         break;
      case MODE_SMMA:
         SmoothedMAOnBuffer(rates_total, prev_calculated, begin, InpSignalPeriod, ExtADbuffer, ExtSignlbuffer);
         break;
      case MODE_SMA:
      default:
         SimpleMAOnBuffer(rates_total, prev_calculated, begin, InpSignalPeriod, ExtADbuffer, ExtSignlbuffer);
     }
   return(rates_total);
  }

//+------------------------------------------------------------------+
//| Calculating with selected volume                                 |
//+------------------------------------------------------------------+
void Calculate(const int rates_total,const int pos,
               const double &open[],
               const double &high[],
               const double &low[],
               const double &close[],
               const long &volume[])
  {
   double op,hi,lo,cl;
//--- main cycle
   for(int i=pos; i<rates_total && !IsStopped(); i++)
     {
      //--- get some data from arrays
      op=open[i];
      hi=high[i];
      lo=low[i];
      cl=close[i];
      //--- calculate new AD
      double sum=0;
      if(hi!=lo)
         sum=((cl-op)/(hi-lo))*volume[i];
      if(i>0)
         sum+=ExtADbuffer[i-1];
      ExtADbuffer[i]=sum;
     }
//----
  }
//+------------------------------------------------------------------+
