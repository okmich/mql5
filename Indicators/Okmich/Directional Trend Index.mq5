//+------------------------------------------------------------------+
//|                                      Directional Trend Index.mq5 |
//|                                   Copyright 2020, Michael Enudi. |
//|                                             okmich2002@yahoo.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2020, Michael Enudi"
#property link      "okmich2002@yahoo.com"
#property version   "1.00"
#property description "Directional Trend Index as proposed by Williams Blau in his book Momentum, Direction and Divergence"
#include  <MovingAverages.mqh>

#property indicator_separate_window
#property indicator_buffers 10
#property indicator_plots   4
//--- plot DTI
#property indicator_label1  "DTI"
#property indicator_type1   DRAW_LINE
#property indicator_color1  clrLightSkyBlue
#property indicator_style1  STYLE_SOLID
#property indicator_width1  2
//--- plot Signal Line
#property indicator_label2  "Signal"
#property indicator_type2   DRAW_LINE
#property indicator_color2  clrSilver
#property indicator_style2  STYLE_DOT
//--- plot LevelUp
#property indicator_label3  "OB level"
#property indicator_type3   DRAW_LINE
#property indicator_color3  clrLimeGreen
#property indicator_style3  STYLE_DOT
//--- plot LevelDown
#property indicator_label4  "OS level"
#property indicator_type4   DRAW_LINE
#property indicator_color4  clrOrange
#property indicator_style4  STYLE_DOT
//--- input parameters
input int      InpPeriod=20;
input int      InpSmoothing=20;
input int      InpSignal=9;
input bool     InpAnchor=true;
//--- indicator buffers
double         DtiBuffer[], DtiSignalBuffer[], DtiLevelObBuffer[], DtiLevelOsBuffer[];
double         HLMBuffer[], AbsHLMBuffer[];
double         FirstHLMEMABuffer[], FirstAbsHLMEMABuffer[];
double         NextHLMEMABuffer[], NextAbsHLMEMABuffer[];

double alpha=0;
int mBegin = 0;

//+------------------------------------------------------------------+
//| Custom indicator initialization function                         |
//+------------------------------------------------------------------+
int OnInit()
  {
//--- indicator buffers mapping
   SetIndexBuffer(0,DtiBuffer,INDICATOR_DATA);
   SetIndexBuffer(1,DtiSignalBuffer,INDICATOR_DATA);
   SetIndexBuffer(2,DtiLevelObBuffer,INDICATOR_DATA);
   SetIndexBuffer(3,DtiLevelOsBuffer,INDICATOR_DATA);
   SetIndexBuffer(4,HLMBuffer,INDICATOR_CALCULATIONS);
   SetIndexBuffer(5,AbsHLMBuffer,INDICATOR_CALCULATIONS);
   SetIndexBuffer(6,FirstHLMEMABuffer,INDICATOR_CALCULATIONS);
   SetIndexBuffer(7,FirstAbsHLMEMABuffer,INDICATOR_CALCULATIONS);
   SetIndexBuffer(8,NextHLMEMABuffer,INDICATOR_CALCULATIONS);
   SetIndexBuffer(9,NextAbsHLMEMABuffer,INDICATOR_CALCULATIONS);
//--- set draw begin
   mBegin = InpPeriod + InpSmoothing;
   PlotIndexSetInteger(0,PLOT_DRAW_BEGIN,mBegin);
   PlotIndexSetInteger(1,PLOT_DRAW_BEGIN,mBegin);
//--- indicator short name
   string short_name="DTI("+string(InpPeriod) + ", " +string(InpSmoothing) + ", " +string(InpSignal)+")";
   IndicatorSetString(INDICATOR_SHORTNAME,short_name);
//--- indicator digits
   IndicatorSetInteger(INDICATOR_DIGITS, 2);
   ArrayInitialize(DtiSignalBuffer, 0);
   alpha=2.0/(1.0+InpSignal);
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
   if(rates_total < mBegin)
      return(0);

   int limit;
//--- preliminary calculations
   if(prev_calculated==0)
      limit = 1;
   else
      limit = prev_calculated-1;

   double hmu; //high momentum up
   double lmd; //low momentum down
   for(int i = limit; i < rates_total; i++)
     {
      hmu = high[i] > high[i-1] ? high[i]-high[i-1] : 0;
      lmd = low[i] < low[i-1] ? -(low[i] - low[i-1]) : 0;
      HLMBuffer[i] = hmu - lmd;
      AbsHLMBuffer[i] = MathAbs(HLMBuffer[i]);
     }

//smoothing
   ExponentialMAOnBuffer(rates_total, prev_calculated, mBegin-1, InpPeriod, HLMBuffer, FirstHLMEMABuffer);
   ExponentialMAOnBuffer(rates_total, prev_calculated, mBegin-1, InpSmoothing, FirstHLMEMABuffer, NextHLMEMABuffer);
//absolute value buffer
   ExponentialMAOnBuffer(rates_total, prev_calculated, mBegin-1, InpPeriod, AbsHLMBuffer, FirstAbsHLMEMABuffer);
   ExponentialMAOnBuffer(rates_total, prev_calculated, mBegin-1, InpSmoothing, FirstAbsHLMEMABuffer, NextAbsHLMEMABuffer);

   for(int i=limit; i < rates_total; i++)
     {
      if(NextAbsHLMEMABuffer[i] != 0)
         DtiBuffer[i] = 100 * (NextHLMEMABuffer[i]/NextAbsHLMEMABuffer[i]);
      else
         DtiBuffer[i]=0;

      DtiSignalBuffer[i] = DtiSignalBuffer[i-1] + (alpha*(DtiBuffer[i] - DtiSignalBuffer[i-1]));
      if(InpAnchor)
        {
         DtiLevelObBuffer[i] = (DtiBuffer[i]>0) ? DtiLevelObBuffer[i-1]+ alpha*(DtiBuffer[i]-DtiLevelObBuffer[i-1]) :
                               DtiLevelObBuffer[i-1];
         DtiLevelOsBuffer[i] = (DtiBuffer[i]<0) ? DtiLevelOsBuffer[i-1]+ alpha*(DtiBuffer[i]-DtiLevelOsBuffer[i-1]) :
                               DtiLevelOsBuffer[i-1];
        }
      else
        {
         DtiLevelObBuffer[i] = (DtiBuffer[i]>DtiBuffer[i-1]) ? DtiLevelObBuffer[i-1]+ alpha*(DtiBuffer[i]-DtiLevelObBuffer[i-1]) :
                               DtiLevelObBuffer[i-1];
         DtiLevelOsBuffer[i] = (DtiBuffer[i]<DtiBuffer[i-1]) ? DtiLevelOsBuffer[i-1]+ alpha*(DtiBuffer[i]-DtiLevelOsBuffer[i-1]) :
                               DtiLevelOsBuffer[i-1];
        }
     }

//--- return value of prev_calculated for next call
   return(rates_total);
  }
//+------------------------------------------------------------------+
