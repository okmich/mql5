//+------------------------------------------------------------------+
//|                                           CenterOfGravityDSL.mq5 |
//|                                    Copyright 2021, Michael Enudi |
//|           http://www.mesasoftware.com/papers/TheCGOscillator.pdf |
//+------------------------------------------------------------------+
#property copyright     "Copyright 2021, Michael Enudi"
#property description   "Implementation of John Ehler's center of gravity indicator that can control the lag and sensitive by using 3 period settings at once."
#property description   "It also uses discontinued signal line to guage longer term bullish or bearish pressure."
#property link          "http://www.mesasoftware.com/papers/TheCGOscillator.pdf"
#property version       "1.1"
#property indicator_separate_window
#property indicator_buffers 3
#property indicator_plots   3
//--- plot COGLine
#property indicator_label1  "TCG"
#property indicator_type1   DRAW_LINE
#property indicator_color1  clrPowderBlue
#property indicator_style1  STYLE_SOLID
#property indicator_width1  2
//--- plot Signal
#property indicator_label2  "OB Level"
#property indicator_type2   DRAW_LINE
#property indicator_color2  clrLimeGreen
#property indicator_style2  STYLE_DOT
//--- plot Signal
#property indicator_label3  "OS Level"
#property indicator_type3   DRAW_LINE
#property indicator_color3  clrOrangeRed
#property indicator_style3  STYLE_DOT
//--- applied Price
#property indicator_applied_price PRICE_MEDIAN
//--- input parameters
input int      InpCGPeriod=10; //Period
input int      InpSignal = 5;   //Signal
//--- indicator buffers
double         CoGLineBuffer[], ExtObLevel[], ExtOsLevel[];

//--- other variables
double mAlpha;
int mBegin;
//+------------------------------------------------------------------+
//| Custom indicator initialization function                         |
//+------------------------------------------------------------------+
int OnInit()
  {
//--- indicator buffers mapping
   SetIndexBuffer(0,CoGLineBuffer,INDICATOR_DATA);
   SetIndexBuffer(1,ExtObLevel,INDICATOR_DATA);
   SetIndexBuffer(2,ExtOsLevel,INDICATOR_DATA);

//---- initializations of variable for indicator short name
   string shortname = StringFormat("Center of Gravity(%d, %d)", InpCGPeriod, InpSignal);
//---- creating name for displaying in a separate sub-window and in a tooltip
   IndicatorSetString(INDICATOR_SHORTNAME,shortname);
//---- set accuracy of displaying of the indicator values
   IndicatorSetInteger(INDICATOR_DIGITS, 4);
//--- indexes draw begin settings
   mBegin = InpCGPeriod + InpSignal;
   PlotIndexSetInteger(0,PLOT_DRAW_BEGIN,mBegin);
   PlotIndexSetInteger(1,PLOT_DRAW_BEGIN,mBegin);
   PlotIndexSetInteger(2,PLOT_DRAW_BEGIN,mBegin);

   mAlpha=2.0/(1.0+InpSignal);

   ArrayInitialize(CoGLineBuffer, 0);
   ArrayInitialize(ExtObLevel, 0);
   ArrayInitialize(ExtOsLevel, 0);
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
   int start = 0;
   if(prev_calculated > 0)
      start = prev_calculated - 1;
   else //=0
      start = mBegin;

   if(rates_total < mBegin)
      return 0;

   for(int i = start; i < rates_total; i++)
     {
      double num = 0, denom=0;
      for(int j=0; j < InpCGPeriod; j++)
        {
         num += price[i-j] * (j + 1);
         denom += price[i-j];
        }

      CoGLineBuffer[i] = -num/denom + (InpCGPeriod + 1.0)/2.0;
      ExtObLevel[i] = (CoGLineBuffer[i]>0) ? ExtObLevel[i-1]+ mAlpha*(CoGLineBuffer[i]-ExtObLevel[i-1]) : ExtObLevel[i-1];
      ExtOsLevel[i] = (CoGLineBuffer[i]<0) ? ExtOsLevel[i-1]+ mAlpha*(CoGLineBuffer[i]-ExtOsLevel[i-1]) : ExtOsLevel[i-1];
     }
//--- return value of prev_calculated for next call
   return(rates_total);
  }
//+------------------------------------------------------------------+
