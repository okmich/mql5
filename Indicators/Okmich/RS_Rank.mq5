//+------------------------------------------------------------------+
//|                                                      RS_Rank.mq5 |
//|                                    Copyright 2023, Michael Enudi |
//|                                             okmich2002@yahoo.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2023, Michael Enudi"
#property link      "okmich2002@yahoo.com"
#property version   "1.00"

#include  <MovingAverages.mqh>

#property indicator_separate_window
#property indicator_buffers 2
#property indicator_plots   2
//--- plot RsRank
#property indicator_label1  "RsRank"
#property indicator_type1   DRAW_LINE
#property indicator_color1  clrRed
#property indicator_style1  STYLE_SOLID
#property indicator_width1  1
//--- plot Signal
#property indicator_label2  "Signal"
#property indicator_type2   DRAW_LINE
#property indicator_color2  clrSilver
#property indicator_style2  STYLE_DOT
#property indicator_width2  1

#property indicator_level1 0

//--- indicator buffers
double         RsRankBuffer[], SignalBuffer[];

input bool   ExtUseFibSeq = true; //Use Fibonacci Sequence
input int   ExtSmoothPeriod = 13; //Smoothing Period
input ENUM_MA_METHOD   ExtSmoothMethod = MODE_SMA; //Smoothing Method

int defaultSeries[] = {63, 126, 189, 252};
int fibSeries[] = {34, 55, 89, 144};
int PlotBegins = 0, SignalPlotBegins = 0;
double expAlpha=0;
//+------------------------------------------------------------------+
//| Custom indicator initialization function                         |
//+------------------------------------------------------------------+
int OnInit()
  {
//--- indicator buffers mapping
   SetIndexBuffer(0,RsRankBuffer,INDICATOR_DATA);
   SetIndexBuffer(1,SignalBuffer,INDICATOR_DATA);

   string shortName = "";
   if(ExtUseFibSeq)
      shortName = "RS_Rank (With Fib Sequence)";
   else
      shortName = "RS_Rank (63, 126, 189, 252)";
   IndicatorSetString(INDICATOR_SHORTNAME,shortName);

   PlotBegins = (ExtUseFibSeq ? fibSeries[3] : defaultSeries[3]) ;
   SignalPlotBegins = PlotBegins + ExtSmoothPeriod;
   expAlpha = 2.0/(1.0+ExtSmoothPeriod);
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
   if(rates_total < SignalPlotBegins)
      return 0;

//--- preliminary calculations
   int pos=prev_calculated-1;
   if(pos < PlotBegins)
      pos= PlotBegins;

   for(int i = pos; i<rates_total && !_StopFlag; i++)
     {
      RsRankBuffer[i] =
         (
            (price[i] - price[i-getLb()])/price[i-getLb()] * 0.4 +
            (price[i] - price[i-getLb(1)])/price[i-getLb(1)] * 0.2 +
            (price[i] - price[i-getLb(2)])/price[i-getLb(2)] * 0.2 +
            (price[i] - price[i-getLb(3)])/price[i-getLb(3)] * -0.2
         ) * 100;
      if(i < SignalPlotBegins)
         SignalBuffer[i] = RsRankBuffer[i];
      else
         switch(ExtSmoothMethod)
           {
            case MODE_EMA:
               SignalBuffer[i]=RsRankBuffer[i]*expAlpha+SignalBuffer[i-1]*(1.0-expAlpha);
               break;
            case MODE_LWMA:
               SignalBuffer[i]=LinearWeightedMA(i, ExtSmoothPeriod, RsRankBuffer);
               break;
            case MODE_SMMA:
                SignalBuffer[i]=SmoothedMA(i, ExtSmoothPeriod, SignalBuffer[i-1], RsRankBuffer);
               break;
            case MODE_SMA:
            default:
               SignalBuffer[i] = SimpleMA(i, ExtSmoothPeriod, RsRankBuffer);
               break;
           }

     }

//--- return value of prev_calculated for next call
   return(rates_total);
  }


//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
int getLb(int i=0)
  {
   if(ExtUseFibSeq)
      return fibSeries[i];
   else
      return defaultSeries[i];
  }
//+------------------------------------------------------------------+
