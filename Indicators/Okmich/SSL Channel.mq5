//+------------------------------------------------------------------+
//|                                                          SSL.mq5 |
//|                                    Copyright 2021, Michael Enudi |
//|                                             okmich2002@yahoo.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2021, Michael Enudi"
#property link      "okmich2002@yahoo.com"
#property version   "1.00"
#property description "converted from https://www.tradingview.com/script/rzdsCUGL-SSL-dasanc/"
#property indicator_chart_window
#property indicator_buffers 3
#property indicator_plots   2
//--- plot SSLUp
#property indicator_label1  "SSLUp"
#property indicator_type1   DRAW_LINE
#property indicator_color1  clrLightSeaGreen
#property indicator_style1  STYLE_SOLID
#property indicator_width1  2
//--- plot SSLDown
#property indicator_label2  "SSLDown"
#property indicator_type2   DRAW_LINE
#property indicator_color2  clrOrangeRed
#property indicator_style2  STYLE_SOLID
#property indicator_width2  2

#include <Okmich\Indicators\BaseIndicator.mqh>

//--- input parameters
input int      InpPeriod=10; //Period
input ENUM_MA_TYPE InpMethod    = MA_TYPE_EMA; //Smoothing method

//--- indicator buffers
double         SSLUpBuffer[];
double         SSLDownBuffer[];
double         maHighLowValueBuffer[];

int            maHighHandle, maLowHandle;
//+------------------------------------------------------------------+
//| Custom indicator initialization function                         |
//+------------------------------------------------------------------+
int OnInit()
  {
//--- indicator buffers mapping
   SetIndexBuffer(0,SSLUpBuffer,INDICATOR_DATA);
   SetIndexBuffer(1,SSLDownBuffer,INDICATOR_DATA);
   SetIndexBuffer(2,maHighLowValueBuffer,INDICATOR_CALCULATIONS);

   if(InpMethod != MA_TYPE_DEMA && InpMethod != MA_TYPE_TEMA)
     {
      ENUM_MA_METHOD maMethod;
      switch(InpMethod)
        {
         case MA_TYPE_EMA:
            maMethod = MODE_EMA;
            break;
         case MA_TYPE_LWMA:
            maMethod = MODE_LWMA;
            break;
         case MA_TYPE_SMA:
            maMethod = MODE_SMA;
            break;
         case MA_TYPE_SMMA:
            maMethod = MODE_SMMA;
            break;
         default:
            return INIT_PARAMETERS_INCORRECT;
        }
      maHighHandle = iMA(_Symbol, _Period, InpPeriod, 0, maMethod, PRICE_HIGH);
      maLowHandle = iMA(_Symbol, _Period, InpPeriod, 0, maMethod, PRICE_LOW);
     }
   else
     {
      switch(InpMethod)
        {
         case MA_TYPE_DEMA:
           {
            maHighHandle = iDEMA(_Symbol, _Period, InpPeriod, 0, PRICE_HIGH);
            maLowHandle = iDEMA(_Symbol, _Period, InpPeriod, 0, PRICE_LOW);
            break;
           }
         case MA_TYPE_TEMA:
           {
            maHighHandle = iTEMA(_Symbol, _Period, InpPeriod, 0, PRICE_HIGH);
            maLowHandle = iTEMA(_Symbol, _Period, InpPeriod, 0, PRICE_LOW);
            break;
           }
         default:
            return INIT_PARAMETERS_INCORRECT;
        }
     }

   IndicatorSetString(INDICATOR_SHORTNAME,"SSL Channel ("+(string)InpPeriod+","+ EnumToString(InpMethod)+")");

//---
   if(maHighHandle != INVALID_HANDLE && maLowHandle != INVALID_HANDLE)
      return(INIT_SUCCEEDED);
   else
      return (INIT_FAILED);
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
   if(InpPeriod > rates_total)
     {
      ArrayInitialize(SSLDownBuffer, EMPTY_VALUE);
      ArrayInitialize(SSLUpBuffer, EMPTY_VALUE);
      ArrayInitialize(maHighLowValueBuffer, EMPTY_VALUE);
      return(0);
     }

//--- detect start position
   int start;
   if(prev_calculated > 1)
      start=prev_calculated-1;
   else
     {
      start=1;
     }

//--- main cycle
   double highBuffer[], lowBuffer[];
   for(int i=start; i<rates_total && !IsStopped(); i++)
     {
      int ii = rates_total - i - 1; //flip the index to allow for CopyBuffer
      int highCopied = CopyBuffer(maHighHandle, 0, ii+1, 1, highBuffer);
      int lowCopied = CopyBuffer(maLowHandle, 0, ii+1, 1, lowBuffer);
      if(highCopied < 0 || lowCopied < 0)
         return 0;

      //hlv := close > sma_high[1] ? 1 : close < sma_low[1] ? -1 : hlv[1]
      maHighLowValueBuffer[i] = (close[i] > highBuffer[0]) ?  1 : (close[i] < lowBuffer[0]) ? -1 : maHighLowValueBuffer[i-1];

      //ssld = hlv == -1 ? sma_high[offset] : sma_low[offset]
      SSLDownBuffer[i] = maHighLowValueBuffer[i] == -1 ? lowBuffer[0] : highBuffer[0];
      //sslu = hlv == -1 ? sma_low[offset] : sma_high[offset]
      SSLUpBuffer[i] = maHighLowValueBuffer[i] == -1 ? highBuffer[0] : lowBuffer[0];
     }

//--- return value of prev_calculated for next call
   return(rates_total);
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void OnDeinit(const int reason)
  {
   IndicatorRelease(maHighHandle);
   IndicatorRelease(maLowHandle);
  }
//+------------------------------------------------------------------+
