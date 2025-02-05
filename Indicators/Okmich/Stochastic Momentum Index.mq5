//+------------------------------------------------------------------
#property copyright   "mladen"
#property link        "mladenfx@gmail.com"
#property link        "https://www.mql5.com"
#property description "Implementation of Stochastc Momentum Index By William Blau"
//+------------------------------------------------------------------
#property indicator_separate_window
#property indicator_buffers 2
#property indicator_plots   2
#property indicator_label1  "Smi"
#property indicator_type1   DRAW_LINE
#property indicator_color1  clrLightSeaGreen
#property indicator_width1  2
#property indicator_label2  "Smi signal"
#property indicator_type2   DRAW_LINE
#property indicator_color2  clrRed
#property indicator_style2  STYLE_DOT
#property indicator_width2  1
#property indicator_level1  40
#property indicator_level2  -40

//--- input parameters
input int                inpLength   = 13;        // Length
input int                inpSmooth1  = 25;        // Smooth period 1
input int                inpSmooth2  =  2;        // Smooth period 2
input int                inpSignal   =  5;        // Signal period
input ENUM_APPLIED_PRICE inpPrice=PRICE_CLOSE;    // Applied Price
//--- buffers declarations
double val[],signal[];
//+------------------------------------------------------------------+
//| Custom indicator initialization function                         |
//+------------------------------------------------------------------+
int OnInit()
  {
//--- indicator buffers mapping
   SetIndexBuffer(0,val,INDICATOR_DATA);
   SetIndexBuffer(1,signal,INDICATOR_DATA);
//---
   IndicatorSetString(INDICATOR_SHORTNAME,"SMI ("+(string)inpLength+","+(string)inpSmooth1+","+(string)inpSmooth2+","+(string)inpSignal+")");
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
      int _start=(int)MathMax(i-inpLength+1,0);
      double hh = high[ArrayMaximum(high,_start,inpLength)];
      double ll = low [ArrayMinimum(low,_start,inpLength)];
      double pr = getPrice(inpPrice,open,close,high,low,i,rates_total);

      double ema10 = pr - 0.5*(hh+ll);
      double ema11 = iEma(ema10,inpSmooth1,i,rates_total,0);
      double ema12 = iEma(ema11,inpSmooth2,i,rates_total,1);

      double ema20 = hh-ll;
      double ema21 = iEma(ema20,inpSmooth1,i,rates_total,2);
      double ema22 = iEma(ema21,inpSmooth2,i,rates_total,3);

      val[i]    = (ema22!=0) ? 100.00 * ema12 / (0.5 * ema22) : 0;
      signal[i] = iEma(val[i],inpSignal,i,rates_total,4);
     }
   return (i);
  }
//+------------------------------------------------------------------+
//| Custom functions                                                 |
//+------------------------------------------------------------------+
double workEma[][5];
//
double iEma(double price,double period,int r,int _bars,int instanceNo=0)
  {
   if(ArrayRange(workEma,0)!=_bars)
      ArrayResize(workEma,_bars);

   workEma[r][instanceNo]=price;
   if(r>0 && period>1)
      workEma[r][instanceNo]=workEma[r-1][instanceNo]+(2.0/(1.0+period))*(price-workEma[r-1][instanceNo]);
   return(workEma[r][instanceNo]);
  }
//
//
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
