//+------------------------------------------------------------------
#property copyright   "mladen"
#property link        "mladenfx@gmail.com"
#property link        "https://www.mql5.com"
#property description "RSI of Hull"
//+------------------------------------------------------------------
#property indicator_separate_window
#property indicator_buffers 5
#property indicator_plots   4
#property indicator_label1  "RSI of Hull"
#property indicator_type1   DRAW_COLOR_LINE
#property indicator_color1  clrDarkGray,clrLimeGreen,clrLightSalmon
#property indicator_width1  2
#property indicator_label2  "up level"
#property indicator_type2   DRAW_LINE
#property indicator_color2  clrLimeGreen
#property indicator_style2  STYLE_DOT
#property indicator_label3  "down level"
#property indicator_type3   DRAW_LINE
#property indicator_color3  clrLightSalmon
#property indicator_style3  STYLE_DOT
#property indicator_label4  "alt signal"
#property indicator_type4   DRAW_LINE
#property indicator_color4  clrSilver
#property indicator_style4  STYLE_DOT

#property indicator_maximum 100
#property indicator_minimum 0

//--- input parameters
input int                inpRsiPeriod  =  14;         // RSI period
input int                inpHullPeriod =  32;         // Hull period
input int                inpSignalPeriod =  9;        // Signal period
input ENUM_APPLIED_PRICE inpPrice      = PRICE_CLOSE; // Applied Price
input bool               inpAnchored   = true;        // Use Middle Anchor
//--- buffers declarations
double val[],valc[],levelUp[],levelDn[],signal[];

double alphaSignal;
//+------------------------------------------------------------------+
//| Custom indicator initialization function                         |
//+------------------------------------------------------------------+
int OnInit()
  {
//--- indicator buffers mapping
   SetIndexBuffer(0,val,INDICATOR_DATA);
   SetIndexBuffer(1,valc,INDICATOR_COLOR_INDEX);
   SetIndexBuffer(2,levelUp,INDICATOR_DATA);
   SetIndexBuffer(3,levelDn,INDICATOR_DATA);
   SetIndexBuffer(4,signal,INDICATOR_DATA);
//--- indicator short name assignment
   IndicatorSetString(INDICATOR_SHORTNAME,"RSI of Hull ("+(string)inpRsiPeriod+","+(string)inpHullPeriod+")");
   alphaSignal = 2.0/(1.0+MathMax(inpSignalPeriod,1.0));
//---
   return (INIT_SUCCEEDED);
  }
//+------------------------------------------------------------------+
//| Custom indicator de-initialization function                      |
//+------------------------------------------------------------------+
void OnDeinit(const int reason)
  {
  }
//+------------------------------------------------------------------+
//| Custom indicator iteration function                              |
//+------------------------------------------------------------------+
int OnCalculate(const int rates_total,const int prev_calculated,const datetime &time[],
                const double &open[],
                const double &high[],
                const double &low[],
                const double &close[],
                const long &tick_volume[],
                const long &volume[],
                const int &spread[])
  {
   if(Bars(_Symbol,_Period)<rates_total)
      return(prev_calculated);
   int i=(int)MathMax(prev_calculated-1,1);
   for(; i<rates_total && !_StopFlag; i++)
     {
      val[i]  = iRsi(iHull(getPrice(inpPrice,open,close,high,low,i,rates_total),inpHullPeriod,i,rates_total),inpRsiPeriod,i,rates_total);
      signal[i] = (i>0) ? signal[i-1] + alphaSignal*(val[i]-signal[i-1]) : val[i];
      if(inpAnchored)
        {
         levelUp[i] = (i>0) ? (val[i]>50) ? levelUp[i-1]+alphaSignal*(val[i]-levelUp[i-1]) : levelUp[i-1] : val[i];
         levelDn[i] = (i>0) ? (val[i]<50) ? levelDn[i-1]+alphaSignal*(val[i]-levelDn[i-1]) : levelDn[i-1] : val[i];
        }
      else
        {
         levelUp[i] = (i>0) ? (val[i]>val[i-1]) ? levelUp[i-1]+alphaSignal*(val[i]-levelUp[i-1]) : levelUp[i-1] : val[i];
         levelDn[i] = (i>0) ? (val[i]<val[i-1]) ? levelDn[i-1]+alphaSignal*(val[i]-levelDn[i-1]) : levelDn[i-1] : val[i];
        }
      valc[i]    = (val[i]>levelUp[i]) ? 1 : (val[i]<levelDn[i]) ? 2 : 0;
     }
   return (i);
  }
//+------------------------------------------------------------------+
//| Custom functions                                                 |
//+------------------------------------------------------------------+
#define rsiInstances 1
double workRsi[][rsiInstances*3];
#define _price  0
#define _prices 3
#define _change 1
#define _changa 2
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
double iRsi(double price,double period,int r,int bars,int instanceNo=0)
  {
   if(ArrayRange(workRsi,0)!=bars)
      ArrayResize(workRsi,bars);
   int z=instanceNo*3;

//
//
//
//
//

   workRsi[r][z+_price]=price;
   double alpha=1.0/MathMax(period,1);
   if(r<period)
     {
      int k;
      double sum=0;
      for(k=0; k<period && (r-k-1)>=0; k++)
         sum+=MathAbs(workRsi[r-k][z+_price]-workRsi[r-k-1][z+_price]);
      workRsi[r][z+_change] = (workRsi[r][z+_price]-workRsi[0][z+_price])/MathMax(k,1);
      workRsi[r][z+_changa] =                                         sum/MathMax(k,1);
     }
   else
     {
      double change=workRsi[r][z+_price]-workRsi[r-1][z+_price];
      workRsi[r][z+_change] = workRsi[r-1][z+_change] + alpha*(change  - workRsi[r-1][z+_change]);
      workRsi[r][z+_changa] = workRsi[r-1][z+_changa] + alpha*(MathAbs(change) - workRsi[r-1][z+_changa]);
     }
   return(50.0*(workRsi[r][z+_change]/MathMax(workRsi[r][z+_changa],DBL_MIN)+1));
  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
double workHull[][2];
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
double iHull(double price,double period,int r,int bars,int instanceNo=0)
  {
   if(ArrayRange(workHull,0)!=bars)
      ArrayResize(workHull,bars);
   instanceNo*=2;
   workHull[r][instanceNo]=price;
   if(period<=1)
      return(price);
//
//---
//
   int HmaPeriod  = (int)MathMax(period,2);
   int HalfPeriod = (int)MathFloor(HmaPeriod/2);
   int HullPeriod = (int)MathFloor(MathSqrt(HmaPeriod));
   double hma,hmw,weight;
   hmw=HalfPeriod;
   hma=hmw*price;
   for(int k=1; k<HalfPeriod && (r-k)>=0; k++)
     {
      weight = HalfPeriod-k;
      hmw   += weight;
      hma   += weight*workHull[r-k][instanceNo];
     }
   workHull[r][instanceNo+1]=2.0*hma/hmw;
   hmw=HmaPeriod;
   hma=hmw*price;
   for(int k=1; k<period && (r-k)>=0; k++)
     {
      weight = HmaPeriod-k;
      hmw   += weight;
      hma   += weight*workHull[r-k][instanceNo];
     }
   workHull[r][instanceNo+1]-=hma/hmw;
   hmw=HullPeriod;
   hma=hmw*workHull[r][instanceNo+1];
   for(int k=1; k<HullPeriod && (r-k)>=0; k++)
     {
      weight = HullPeriod-k;
      hmw   += weight;
      hma   += weight*workHull[r-k][1+instanceNo];
     }
   return(hma/hmw);
  }
//
//---
//
double getPrice(ENUM_APPLIED_PRICE tprice,const double &open[],const double &close[],const double &high[],const double &low[],int i,int _bars)
  {
   switch(tprice)
     {
      case PRICE_CLOSE:
         return(close[i]);
      case PRICE_OPEN:
         return(open[i]);
      case PRICE_HIGH:
         return(high[i]);
      case PRICE_LOW:
         return(low[i]);
      case PRICE_MEDIAN:
         return((high[i]+low[i])/2.0);
      case PRICE_TYPICAL:
         return((high[i]+low[i]+close[i])/3.0);
      case PRICE_WEIGHTED:
         return((high[i]+low[i]+close[i]+close[i])/4.0);
     }
   return(0);
  }
//+------------------------------------------------------------------+
