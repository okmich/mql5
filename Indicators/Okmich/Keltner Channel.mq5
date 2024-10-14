//+------------------------------------------------------------------+
//|                                              Keltner Channel.mq5 |
//|                                    Copyright 2024, Michael Enudi |
//|                                             okmich2002@yahoo.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2024, Michael Enudi"
#property link      "okmich2002@yahoo.com"
#property version   "1.00"
#property indicator_chart_window
#property indicator_buffers 3
#property indicator_plots   3

//--- plot ExtTop
#property indicator_label1  "Top"
#property indicator_type1   DRAW_LINE
#property indicator_color1  clrOrangeRed
#property indicator_style1  STYLE_SOLID
#property indicator_width1  1
//--- plot ExtMa
#property indicator_label2  "Ma"
#property indicator_type2   DRAW_LINE
#property indicator_color2  clrDarkGray
#property indicator_style2  STYLE_DASH
#property indicator_width2  1
//--- plot ExtBottom
#property indicator_label3  "Bottom"
#property indicator_type3   DRAW_LINE
#property indicator_color3  clrOrangeRed
#property indicator_style3  STYLE_SOLID
#property indicator_width3  1

#include <Okmich\Indicators\BaseIndicator.mqh>

//--- input parameters
input int      InpPeriod=32;           // Period
input double   InpAtrMultiple=2.0;  // ATR Multiple
input ENUM_MA_TYPE InpMaType = MA_TYPE_EMA;  // MA Type
input ENUM_APPLIED_PRICE InpPriceType = PRICE_CLOSE;// Price Type

//--- indicator buffers
double         ExtTopBuffer[];
double         ExtMaBuffer[];
double         ExtBottomBuffer[];

int maHandle, atrHandle;
double atrBuffer[], maBuffer[];
//+------------------------------------------------------------------+
//| Custom indicator initialization function                         |
//+------------------------------------------------------------------+
int OnInit()
  {
//--- indicator buffers mapping
   SetIndexBuffer(0,ExtTopBuffer,INDICATOR_DATA);
   SetIndexBuffer(1,ExtMaBuffer,INDICATOR_DATA);
   SetIndexBuffer(2,ExtBottomBuffer,INDICATOR_DATA);

   IndicatorSetString(INDICATOR_SHORTNAME, "Keltner Channel (" + string(InpPeriod) + ", " + string(InpMaType) + ", " + string(InpAtrMultiple) + ")");
   IndicatorSetInteger(INDICATOR_DIGITS,_Digits);

   maHandle = GetHandleForMaType(InpMaType, InpPeriod, InpPriceType);
   if(maHandle == INVALID_HANDLE)
     {
      Print("Error while open iMA");
      return(INIT_FAILED);
     }

// ATR is used to compute the upper and lower bounds.
   atrHandle = iATR(NULL, 0, InpPeriod);
   if(atrHandle == INVALID_HANDLE)
     {
      Print("Error while open iATR");
      return(INIT_FAILED);
     }
   PlotIndexSetInteger(0,PLOT_DRAW_BEGIN, InpPeriod+1);
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
   int maCalculated=BarsCalculated(maHandle);
   int atrCalculated=BarsCalculated(atrHandle);

   if(maCalculated<=0)
     {
      PrintFormat("BarsCalculated() by Moving Average returned %d, error code %d",maCalculated,GetLastError());
      return(0);
     }

   if(atrCalculated<=0)
     {
      PrintFormat("BarsCalculated() by ATR returned %d, error code %d",atrCalculated,GetLastError());
      return(0);
     }

   if(atrCalculated != maCalculated)
     {
      PrintFormat("Bars calculated by ATR (%d) not equals to same by MovingAverage (%d)",
                  atrCalculated, maCalculated);
      return(0);
     }

   if(rates_total < InpPeriod)
      return(0);

   int start;
   if(prev_calculated==0)
      start=prev_calculated;
   else
      start=prev_calculated-1;

   if(CopyBuffer(maHandle, 0, 0, rates_total-start, maBuffer) <= 0)
     {
      Print("Failed to copy MA values ");
      return 0;
     }

   if(CopyBuffer(atrHandle, 0, 0, rates_total-start, atrBuffer) <= 0)
     {
      Print("Failed to copy ATR values ");
      return 0;
     }

   for(int i = start; i < rates_total && !IsStopped(); i++)
     {
      ExtMaBuffer[i] = maBuffer[i - start];
      ExtTopBuffer[i] = ExtMaBuffer[i] + atrBuffer[i - start] * InpAtrMultiple;
      ExtBottomBuffer[i] = ExtMaBuffer[i] - atrBuffer[i - start] * InpAtrMultiple;
     }

   return rates_total;
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void OnDeinit(const int reason)
  {
   IndicatorRelease(maHandle);
   IndicatorRelease(atrHandle);
  }
//+------------------------------------------------------------------+
