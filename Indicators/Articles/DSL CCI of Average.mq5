//------------------------------------------------------------------
#property copyright "© mladen, 2021"
#property link      "mladenfx@gmail.com"
#property version   "1.00"
//------------------------------------------------------------------
#property indicator_separate_window
#property indicator_buffers 6
#property indicator_plots   4
#property indicator_label1  "CCI"
#property indicator_type1   DRAW_COLOR_LINE
#property indicator_color1  clrSilver,clrLimeGreen,clrOrange
#property indicator_width1  2
#property indicator_label2  "up level"
#property indicator_type2   DRAW_LINE
#property indicator_color2  clrLimeGreen
#property indicator_style2  STYLE_DOT
#property indicator_label3  "down level"
#property indicator_type3   DRAW_LINE
#property indicator_color3  clrOrange
#property indicator_style3  STYLE_DOT
#property indicator_label4  "alt signal"
#property indicator_type4   DRAW_LINE
#property indicator_color4  clrSilver
#property indicator_style4  STYLE_DOT

#include <Okmich\Indicators\BaseIndicator.mqh>

input int                inpCciPeriod    = 32;          // CCI period
input int                inpMaPeriod     = 14;          // Average period (<= 1 for no average)
input ENUM_MA_TYPE       inpMaMethod     = MA_TYPE_EMA;    // Average method
input ENUM_APPLIED_PRICE inpPrice        = PRICE_CLOSE; // Price
input double             inpSignalPeriod = 9;           // Dsl signal period
input bool               inpAnchored = true;            // Anchored DSL Line

//
//
//

double  val[],valc[],levelUp[],levelDn[],signal[];
struct sGlobalStruct
  {
   int               avgPeriod;
   int               avgHandle;
   int               cciHandle;
   double            alphaSignal;
  };
sGlobalStruct global;

//------------------------------------------------------------------
//
//------------------------------------------------------------------
//
//
//

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void OnInit()
  {
   SetIndexBuffer(0,val,INDICATOR_DATA);
   SetIndexBuffer(1,valc,INDICATOR_COLOR_INDEX);
   SetIndexBuffer(2,levelUp,INDICATOR_DATA);
   SetIndexBuffer(3,levelDn,INDICATOR_DATA);
   SetIndexBuffer(4,signal,INDICATOR_DATA);
//
//
//
   global.avgPeriod   = inpMaPeriod>0 ? inpMaPeriod : 1;
   global.alphaSignal = 2.0/(1.0+MathMax(inpSignalPeriod,1.0));
   global.avgHandle = GetHandleForMaType(inpMaMethod, inpMaPeriod, inpPrice);
   if(global.avgHandle==INVALID_HANDLE)
     {
      Alert(" Failed to get MA indicator");
     }
   global.cciHandle   = iCCI(_Symbol,0,inpCciPeriod,global.avgHandle);

   IndicatorSetString(INDICATOR_SHORTNAME,StringFormat("(DSL) CCI %s (%s,%s,%s)",StringSubstr(EnumToString(inpMaMethod),5,-1),(string)inpCciPeriod,(string)global.avgPeriod,(string)inpSignalPeriod));
  }

//------------------------------------------------------------------
//
//------------------------------------------------------------------
//
//
//

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
int OnCalculate(const int rates_total,
                const int prev_calculated,
                const datetime& time[],
                const double& open[],
                const double& high[],
                const double& low[],
                const double& close[],
                const long& tick_volume[],
                const long& volume[],
                const int& spread[])
  {
   int limit     = (prev_calculated>0) ? prev_calculated-1 : 0;
   int copyLimit = (prev_calculated>0) ? rates_total-prev_calculated+1 : rates_total;
   if(CopyBuffer(global.cciHandle,0,0,copyLimit,val)!=copyLimit)
      return(prev_calculated);

//
//
//

   for(int i=limit; i<rates_total && !_StopFlag; i++)
     {
      if(val[i]==EMPTY_VALUE)
         val[i]=0;
      signal[i] = (i>0) ? signal[i-1] + global.alphaSignal*(val[i]-signal[i-1]) : val[i];
      if(inpAnchored)
        {
         levelUp[i] = (i>0) ? (val[i]>0) ? levelUp[i-1]+global.alphaSignal*(val[i]-levelUp[i-1]) : levelUp[i-1] : 0;
         levelDn[i] = (i>0) ? (val[i]<0) ? levelDn[i-1]+global.alphaSignal*(val[i]-levelDn[i-1]) : levelDn[i-1] : 0;
        }
      else
        {
         levelUp[i] = (i>0) ? (val[i]>val[i-1]) ? levelUp[i-1]+global.alphaSignal*(val[i]-levelUp[i-1]) : levelUp[i-1] : 0;
         levelDn[i] = (i>0) ? (val[i]<val[i-1]) ? levelDn[i-1]+global.alphaSignal*(val[i]-levelDn[i-1]) : levelDn[i-1] : 0;
        }
      valc[i]    = (val[i]>levelUp[i]) ? 1 : (val[i]<levelDn[i]) ? 2 : 0;
     }
   return(rates_total);
  }
//+------------------------------------------------------------------+
