//+------------------------------------------------------------------+
//|                                                  Ergodic MDI.mq5 |
//|                                    Copyright 2020, Michael Enudi |
//|                                             okmich2002@yahoo.com |
//+------------------------------------------------------------------+
#property copyright     "Copyright 2020, Michael Enudi"
#property link          "okmich2002@yahoo.com"
#property description   "Implementation of Ergodic Mean Deviation Index by William Blau"
#property version   "1.00"
#include <MovingAverages.mqh>

#property indicator_separate_window
#property indicator_buffers 6
#property indicator_plots   3
//--- plot indicator level
#property indicator_level1 0.0
#property indicator_levelcolor clrSilver
#property indicator_levelstyle STYLE_DOT
//--- plot MDIMain
#property indicator_label1  "MDI"
#property indicator_type1   DRAW_LINE
#property indicator_color1  clrLightSeaGreen
#property indicator_style1  STYLE_SOLID
#property indicator_width1  2
//--- plot MDISignal
#property indicator_label2  "Signal"
#property indicator_type2   DRAW_LINE
#property indicator_color2  clrOrange
#property indicator_style2  STYLE_DOT
#property indicator_width2  1
//--- plot TrenInd
#property indicator_label3  "Trend"
#property indicator_type3   DRAW_LINE
#property indicator_color3  clrLavender
#property indicator_style3  STYLE_DOT
#property indicator_width3  1

//--- input parameters
input int      mMDIPeriod=32;       //Moving Average window
input int      mMDISmoothing=5;    //Smoothing
input int      mDblSmoothing=5;     //Dbl Smoothing
input int      MDISignal=5;         //Signal
input double   mTrendMarket=0.0001;  //Trend Mark Height
input ENUM_MA_METHOD   mMaType=MODE_EMA;  //Smoothing Method

//--- indicator buffers
double         MDIBuffer[];
double         MDISignalBuffer[], trendIndBuffer[];
double         movingAvgBuffer[], detrendBuffer[], dblDeTrendBuffer[];
//--- other variables
static int beginPeriod, beginSmooth, beginDblSmooth, beginSignal;

//+------------------------------------------------------------------+
//| Custom indicator initialization function                         |
//+------------------------------------------------------------------+
int OnInit()
  {
//--- indicator buffers mapping
   SetIndexBuffer(0,MDIBuffer,INDICATOR_DATA);
   SetIndexBuffer(1,MDISignalBuffer,INDICATOR_DATA);
   SetIndexBuffer(2,trendIndBuffer,INDICATOR_DATA);
   SetIndexBuffer(3,movingAvgBuffer,INDICATOR_CALCULATIONS);
   SetIndexBuffer(4,detrendBuffer,INDICATOR_CALCULATIONS);
   SetIndexBuffer(5,dblDeTrendBuffer,INDICATOR_CALCULATIONS);

   string shortname = StringFormat("MDI(%d, %d, %d, %d)",
                                   mMDIPeriod, mMDISmoothing, mDblSmoothing, MDISignal);
   IndicatorSetString(INDICATOR_SHORTNAME, shortname);
   int digits = (_Digits <= 4) ? 4 : _Digits;
   IndicatorSetInteger(INDICATOR_DIGITS, digits);

//---
   beginPeriod = mMDIPeriod-1;
   beginSmooth = beginPeriod + mMDISmoothing -1;
   beginDblSmooth = beginPeriod + mDblSmoothing -1;
   beginSignal = beginSmooth + MDISignal -1;

   PlotIndexSetInteger(0, PLOT_DRAW_BEGIN, beginSignal + 1);
   PlotIndexSetInteger(1, PLOT_DRAW_BEGIN, beginSignal + 1);
   PlotIndexSetInteger(2, PLOT_DRAW_BEGIN, beginSignal + 1);

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
//--- check for data
   if(rates_total < beginSignal)
      return(0);

   int start = (prev_calculated==0) ? prev_calculated: prev_calculated-1;
//get ema of price
   CalculateMaOnBuffer(rates_total, prev_calculated, beginPeriod, mMDIPeriod, price, movingAvgBuffer);

   for(int i=start; i<rates_total && !IsStopped(); i++)
     {
      detrendBuffer[i] = (price[i] - movingAvgBuffer[i])/price[i];
     }
//get ma of detrendBuffer
   CalculateMaOnBuffer(rates_total, prev_calculated, beginSmooth, mMDISmoothing, detrendBuffer, dblDeTrendBuffer);
   CalculateMaOnBuffer(rates_total, prev_calculated, beginDblSmooth, mDblSmoothing, dblDeTrendBuffer, MDIBuffer);
   ExponentialMAOnBuffer(rates_total, prev_calculated, beginSignal, MDISignal, MDIBuffer, MDISignalBuffer);

   for(int i=start; i<rates_total && !IsStopped(); i++)
      if(i == 0)
         trendIndBuffer[i] = 0;
      else
         if(MDISignalBuffer[i] > MDISignalBuffer[i-1] && movingAvgBuffer[i] > movingAvgBuffer[i-1])
            trendIndBuffer[i] = mTrendMarket;
         else
            if(MDISignalBuffer[i] < MDISignalBuffer[i-1] && movingAvgBuffer[i] < movingAvgBuffer[i-1])
               trendIndBuffer[i] = -mTrendMarket;
            else
               trendIndBuffer[i] = 0.0;


//--- return value of prev_calculated for next call
   return(rates_total);
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void CalculateMaOnBuffer(int rates_total, int prev_calculated, int start, int period, const double &price[], double &buffer[])
  {
   switch(mMaType)
     {

      case MODE_LWMA:
         LinearWeightedMAOnBuffer(rates_total, prev_calculated, start, period, price, buffer);
         break;
      case MODE_SMA:
         SimpleMAOnBuffer(rates_total, prev_calculated, start, period, price, buffer);
         break;
      case MODE_SMMA:
         SmoothedMAOnBuffer(rates_total, prev_calculated, start, period, price, buffer);
         break;
      case MODE_EMA:
      default:
         ExponentialMAOnBuffer(rates_total, prev_calculated, start, period, price, buffer);

     }
  }

//+------------------------------------------------------------------+
