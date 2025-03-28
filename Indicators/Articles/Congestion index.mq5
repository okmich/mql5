//+------------------------------------------------------------------
#property copyright   "mladen"
#property link        "mladenfx@gmail.com"
#property description "Congestion index"
// https://www.mql5.com/en/code/20431
//+------------------------------------------------------------------
#property indicator_separate_window
#property indicator_buffers 3
#property indicator_plots   2
#property indicator_label1  "Congestion idex"
#property indicator_type1   DRAW_LINE
#property indicator_color1  clrCrimson
#property indicator_width1  2
#property indicator_label2  "Signal line"
#property indicator_type2   DRAW_LINE
#property indicator_color2  clrSilver
#property indicator_style2  STYLE_DOT
#property indicator_width2  1
#property indicator_minimum -100
#property indicator_maximum  100
#property indicator_level1  -85
#property indicator_level2  -20
#property indicator_level3    0
#property indicator_level4   20
#property indicator_level5   85

//--- input parameters
input int                inpLookBack     = 28;          // Lookback period
input ENUM_APPLIED_PRICE inpPrice        = PRICE_CLOSE; // Price
input int                inpSmoothPeriod = 10;          // Smoothing period
input int                inpSignalPeriod = 10;          // Signal period
//--- buffers declarations
double val[],signal[],prices[];
//+------------------------------------------------------------------+
//| Custom indicator initialization function                         |
//+------------------------------------------------------------------+
int OnInit()
  {
//--- indicator buffers mapping
   SetIndexBuffer(0,val,INDICATOR_DATA);
   SetIndexBuffer(1,signal,INDICATOR_DATA);
   SetIndexBuffer(2,prices,INDICATOR_CALCULATIONS);
   PlotIndexSetInteger(0,PLOT_SHOW_DATA,false);
//---
   IndicatorSetString(INDICATOR_SHORTNAME,"Congestion index ("+(string)inpLookBack+","+(string)inpSmoothPeriod+","+(string)inpSignalPeriod+")");
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
   double _alpha  = 2.0/(1.0 + inpSmoothPeriod);
   double _alphas = 2.0/(1.0 + inpSignalPeriod);
   int i=(int)MathMax(prev_calculated-1,1);
   for(; i<rates_total && !_StopFlag; i++)
     {
      int _start= MathMax(i-inpLookBack+1,0);
      prices[i] = getPrice(inpPrice,open,close,high,low,i,rates_total);
      double lowest   = low[ArrayMinimum(low,_start,inpLookBack)];
      double dividend = (i>=inpLookBack) ? 100.00 * (prices[i]-prices[i-inpLookBack+1])/prices[i-inpLookBack+1] : 0;
      double divisor  = (lowest != 0) ? (high[ArrayMaximum(high,_start,inpLookBack)]-lowest)/lowest : 0;
      double ci       = (divisor != 0) ? dividend/divisor : 0;

      val[i]    = (i>0) ? val[i-1]+_alpha*(ci-val[i-1]) : ci;
      signal[i] = (i>0) ? signal[i-1] +_alphas*(val[i]-signal[i-1]) : val[i];
     }
   return (i);
  }
//+------------------------------------------------------------------+
//| Custom functions                                                 |
//+------------------------------------------------------------------+
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
