//+------------------------------------------------------------------+
//|                                        TripleCenterOfGravity.mq5 |
//|                                    Copyright 2021, Michael Enudi |
//|           http://www.mesasoftware.com/papers/TheCGOscillator.pdf |
//+------------------------------------------------------------------+
#property copyright     "Copyright 2021, Michael Enudi"
#property description   "Implementation of John Ehler's center of gravity indicator that can control the lag and sensitive by using 3 period settings at once."
#property link      "http://www.mesasoftware.com/papers/TheCGOscillator.pdf"
#property version   "1.1"
#property indicator_separate_window
#property indicator_buffers 2
#property indicator_plots   2
//--- plot COGLine
#property indicator_label1  "TCG"
#property indicator_type1   DRAW_LINE
#property indicator_color1  clrLavender
#property indicator_style1  STYLE_SOLID
#property indicator_width1  2
//--- plot Signal
#property indicator_label2  "Signal"
#property indicator_type2   DRAW_LINE
#property indicator_color2  clrOrangeRed
#property indicator_style2  STYLE_DOT
//--- applied Price
#property indicator_applied_price PRICE_MEDIAN
//--- input parameters
input int      InpCGPeriod1=10; //Short COG Period
input int      InpCGPeriod2=16; //Middle COG Period
input int      InpCGPeriod3=26; //Long COG Period
input int      InpShortMul=3;   //Short COG Multiplier
input int      InpMediumMul=2;  //Middle COG Multiplier
input int      InpLongMul=1;    //Long COG Multiplier
input int      InpSignal = 5;   //Signal
//--- indicator buffers
double         CoGLineBuffer[], ExtSignalBuffer[];

//--- other variables
double mAlpha, divisor;
int mBegin;
//+------------------------------------------------------------------+
//| Custom indicator initialization function                         |
//+------------------------------------------------------------------+
int OnInit()
  {
//--- indicator buffers mapping
   SetIndexBuffer(0,CoGLineBuffer,INDICATOR_DATA);
   SetIndexBuffer(1,ExtSignalBuffer,INDICATOR_DATA);

//---- initializations of variable for indicator short name
   string shortname = StringFormat("Triple Center of Gravity(%d, %d, %d)", InpCGPeriod1, InpCGPeriod2, InpCGPeriod3);
//---- creating name for displaying in a separate sub-window and in a tooltip
   IndicatorSetString(INDICATOR_SHORTNAME,shortname);
//---- set accuracy of displaying of the indicator values
   IndicatorSetInteger(INDICATOR_DIGITS, 4);
//--- indexes draw begin settings
   mBegin = InpCGPeriod3 + InpSignal;
   PlotIndexSetInteger(0,PLOT_DRAW_BEGIN,mBegin);
   PlotIndexSetInteger(1,PLOT_DRAW_BEGIN,mBegin);
   PlotIndexSetInteger(2,PLOT_DRAW_BEGIN,mBegin);
   
   divisor = (InpLongMul > 0 ? 1 : 0) + (InpMediumMul > 0 ? 1 : 0) + (InpShortMul > 0 ? 1 : 0);
   mAlpha=2.0/(1.0+InpSignal);
   
   ArrayInitialize(CoGLineBuffer, 0);
   ArrayInitialize(ExtSignalBuffer, 0);
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
      double shortNum = 0, shortDenom=0;
      double midNum = 0, midDenom=0;
      double longNum = 0, longDenom=0;

      for(int j=0; j < InpCGPeriod3; j++)
        {
         //-- short
         if(j < InpCGPeriod1)
           {
            shortNum += price[i-j] * (j + 1);
            shortDenom += price[i-j];
           }

         //-- mid
         if(j < InpCGPeriod2)
           {
            midNum += price[i-j] * (j + 1);
            midDenom += price[i-j];
           }

         longNum += price[i-j] * (j + 1);
         longDenom += price[i-j];
        }

      double shortCG = -shortNum/shortDenom + (InpCGPeriod1 + 1.0)/2.0;
      double midCG = -midNum/midDenom + (InpCGPeriod2 + 1.0)/2.0;
      double longCG = -longNum/longDenom + (InpCGPeriod3 + 1.0)/2.0;
      
      CoGLineBuffer[i] = ((shortCG * InpShortMul) + (midCG * InpMediumMul) + (longCG * InpLongMul))/divisor;
      ExtSignalBuffer[i] = ExtSignalBuffer[i-1]+ mAlpha*(CoGLineBuffer[i]-ExtSignalBuffer[i-1]);
     }
//--- return value of prev_calculated for next call
   return(rates_total);
  }
//+------------------------------------------------------------------+
