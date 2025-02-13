//------------------------------------------------------------------
#property copyright   "Copyright 2017, mladen"
#property link        "mladenfx@gmail.com"
#property description "Schaff Trend Cycle"
#property version     "1.00"
//------------------------------------------------------------------
#property indicator_separate_window
#property indicator_buffers 6
#property indicator_plots   1
#property indicator_label1  "Schaff Trend Cycle value"
#property indicator_type1   DRAW_COLOR_LINE
#property indicator_color1  clrSilver,clrLimeGreen,clrOrange
#property indicator_width1  2

#property indicator_maximum 100
#property indicator_minimum 0

#property indicator_level1 85
#property indicator_level2 15

//
//-----------------
//
enum enPrices
  {
   pr_close,      // Close
   pr_open,       // Open
   pr_high,       // High
   pr_low,        // Low
   pr_median,     // Median
   pr_typical,    // Typical
   pr_weighted,   // Weighted
   pr_average,    // Average (high+low+open+close)/4
   pr_medianb,    // Average median body (open+close)/2
   pr_tbiased,    // Trend biased price
   pr_tbiased2,   // Trend biased (extreme) price
   pr_haclose,    // Heiken Ashi close
   pr_haopen ,    // Heiken Ashi open
   pr_hahigh,     // Heiken Ashi high
   pr_halow,      // Heiken Ashi low
   pr_hamedian,   // Heiken Ashi median
   pr_hatypical,  // Heiken Ashi typical
   pr_haweighted, // Heiken Ashi weighted
   pr_haaverage,  // Heiken Ashi average
   pr_hamedianb,  // Heiken Ashi median body
   pr_hatbiased,  // Heiken Ashi trend biased price
   pr_hatbiased2  // Heiken Ashi trend biased (extreme) price
  };
// input parameters
input int       SchaffPeriod = 32;       // Schaff period
input int       FastEma      = 23;       // Fast EMA period
input int       SlowEma      = 50;       // Slow EMA period
input double    SmoothPeriod = 3;        // Smoothing period
input enPrices  Price        = pr_close; // Price

double  val[],valc[],macd[],fastk1[],fastd1[],fastk2[];
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void OnInit()
  {
   SetIndexBuffer(0,val,INDICATOR_DATA);
   SetIndexBuffer(1,valc,INDICATOR_COLOR_INDEX);
   SetIndexBuffer(2,macd,INDICATOR_CALCULATIONS);
   SetIndexBuffer(3,fastk1,INDICATOR_CALCULATIONS);
   SetIndexBuffer(4,fastk2,INDICATOR_CALCULATIONS);
   SetIndexBuffer(5,fastd1,INDICATOR_CALCULATIONS);
   IndicatorSetString(INDICATOR_SHORTNAME,"Schaff Trend Cycle ("+(string)SchaffPeriod+","+(string)FastEma+","+(string)SlowEma+","+(string)SmoothPeriod+")");
  }
//+------------------------------------------------------------------+
//|                                                                  |
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
   if(Bars(_Symbol,_Period)<rates_total) return(-1);
//
//
//
   double alpha=2.0/(1.0+SmoothPeriod);
   int i=(int)MathMax(prev_calculated-1,0); for(; i<rates_total && !_StopFlag; i++)
     {
      double price=getPrice(Price,open,close,high,low,i,rates_total);
      macd[i]=iEma(price,FastEma,i,rates_total,0)-iEma(price,SlowEma,i,rates_total,1);
      int    start    = MathMax(i-SchaffPeriod+1,0);
      double lowMacd  = macd[ArrayMinimum(macd,start,SchaffPeriod)];
      double highMacd = macd[ArrayMaximum(macd,start,SchaffPeriod)]-lowMacd;
      fastk1[i] = (highMacd > 0) ? 100*((macd[i]-lowMacd)/highMacd) : (i>0) ? fastk1[i-1] : 0;
      fastd1[i] = (i>0) ? fastd1[i-1]+alpha*(fastk1[i]-fastd1[i-1]) : fastk1[i];
      double lowStoch  = fastd1[ArrayMinimum(fastd1,start,SchaffPeriod)];
      double highStoch = fastd1[ArrayMaximum(fastd1,start,SchaffPeriod)]-lowStoch;
      fastk2[i] = (highStoch > 0) ? 100*((fastd1[i]-lowStoch)/highStoch) : (i>0) ? fastk2[i-1] : 0;
      val[i]    = (i>0) ?  val[i-1]+alpha*(fastk2[i]-val[i-1]) : fastk2[i];
      valc[i]   = (i>0) ? (val[i]>val[i-1]) ? 1 : (val[i]<val[i-1]) ? 2 : 0 : 0;
     }
   return(i);
  }
//------------------------------------------------------------------
// custom functions
//------------------------------------------------------------------
double workEma[][2];
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
double iEma(double price,double period,int r,int _bars,int instanceNo=0)
  {
   if(ArrayRange(workEma,0)!=_bars) ArrayResize(workEma,_bars);

   workEma[r][instanceNo]=price;
   if(r>0 && period>1)
      workEma[r][instanceNo]=workEma[r-1][instanceNo]+(2.0/(1.0+period))*(price-workEma[r-1][instanceNo]);
   return(workEma[r][instanceNo]);
  }
//
//----------------------
//
#define _pricesInstances 1
#define _pricesSize      4
double workHa[][_pricesInstances*_pricesSize];
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
double getPrice(int tprice,const double &open[],const double &close[],const double &high[],const double &low[],int i,int _bars,int instanceNo=0)
  {
   if(tprice>=pr_haclose)
     {
      if(ArrayRange(workHa,0)!=_bars) ArrayResize(workHa,_bars); instanceNo*=_pricesSize;
      double haOpen;
      if(i>0)
         haOpen  = (workHa[i-1][instanceNo+2] + workHa[i-1][instanceNo+3])/2.0;
      else   haOpen  = (open[i]+close[i])/2;
      double haClose = (open[i] + high[i] + low[i] + close[i]) / 4.0;
      double haHigh  = MathMax(high[i], MathMax(haOpen,haClose));
      double haLow   = MathMin(low[i] , MathMin(haOpen,haClose));

      if(haOpen  <haClose) { workHa[i][instanceNo+0] = haLow;  workHa[i][instanceNo+1] = haHigh; }
      else                 { workHa[i][instanceNo+0] = haHigh; workHa[i][instanceNo+1] = haLow;  }
      workHa[i][instanceNo+2] = haOpen;
      workHa[i][instanceNo+3] = haClose;
      //
      //--------------------
      //
      switch(tprice)
        {
         case pr_haclose:     return(haClose);
         case pr_haopen:      return(haOpen);
         case pr_hahigh:      return(haHigh);
         case pr_halow:       return(haLow);
         case pr_hamedian:    return((haHigh+haLow)/2.0);
         case pr_hamedianb:   return((haOpen+haClose)/2.0);
         case pr_hatypical:   return((haHigh+haLow+haClose)/3.0);
         case pr_haweighted:  return((haHigh+haLow+haClose+haClose)/4.0);
         case pr_haaverage:   return((haHigh+haLow+haClose+haOpen)/4.0);
         case pr_hatbiased:
            if(haClose>haOpen)
            return((haHigh+haClose)/2.0);
            else  return((haLow+haClose)/2.0);
         case pr_hatbiased2:
            if(haClose>haOpen)  return(haHigh);
            if(haClose<haOpen)  return(haLow);
            return(haClose);
        }
     }
//
//--------------------------
//
   switch(tprice)
     {
      case pr_close:     return(close[i]);
      case pr_open:      return(open[i]);
      case pr_high:      return(high[i]);
      case pr_low:       return(low[i]);
      case pr_median:    return((high[i]+low[i])/2.0);
      case pr_medianb:   return((open[i]+close[i])/2.0);
      case pr_typical:   return((high[i]+low[i]+close[i])/3.0);
      case pr_weighted:  return((high[i]+low[i]+close[i]+close[i])/4.0);
      case pr_average:   return((high[i]+low[i]+close[i]+open[i])/4.0);
      case pr_tbiased:
         if(close[i]>open[i])
         return((high[i]+close[i])/2.0);
         else  return((low[i]+close[i])/2.0);
      case pr_tbiased2:
         if(close[i]>open[i]) return(high[i]);
         if(close[i]<open[i]) return(low[i]);
         return(close[i]);
     }
   return(0);
  }
//+------------------------------------------------------------------+
