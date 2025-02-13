//------------------------------------------------------------------
#property copyright "© mladen, 2017"
#property link      "mladenfx@gmail.com"
#property link      "www.forex-station.com"
#property version   "1.00"
//------------------------------------------------------------------
#property indicator_separate_window
#property indicator_buffers 1
#property indicator_plots   1
#property indicator_label1  "Precision Trend"
#property indicator_type1   DRAW_HISTOGRAM
#property indicator_color1  clrLimeGreen
#property indicator_width1  2
#property indicator_minimum 0
#property indicator_maximum 1

//
//
//
//
//

input int       PtrPeriod       = 14; // Precision trend period
input double    PtrSensitivity  = 3;  // Precision trend sensitivity

double  val[];

//------------------------------------------------------------------
//
//------------------------------------------------------------------
//
//
//
//
//

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void OnInit()
  {
   SetIndexBuffer(0,val,INDICATOR_DATA);
   IndicatorSetString(INDICATOR_SHORTNAME,"Precision Trend ("+(string)PtrPeriod+","+(string)PtrSensitivity+")");
  }

//------------------------------------------------------------------
//
//------------------------------------------------------------------
//
//
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
   if(Bars(_Symbol,_Period)<rates_total)
      return(-1);
   int i=(int)MathMax(prev_calculated-1,0);
   for(; i<rates_total && !_StopFlag; i++)
     {
      val[i] = 2-iPrecisionTrend(high,low,close,PtrPeriod,PtrSensitivity,i,rates_total);
     }
   return(i);
  }

//------------------------------------------------------------------
//
//------------------------------------------------------------------
//
//
//
//
//

#define _ptInstances     1
#define _ptInstancesSize 7
double  _ptWork[][_ptInstances*_ptInstancesSize];
#define __range 0
#define __trend 1
#define __avgr  2
#define __avgd  3
#define __avgu  4
#define __minc  5
#define __maxc  6
double iPrecisionTrend(const double& _high[], const double& _low[], const double& _close[], int _period, double _sensitivity, int i, int bars, int instanceNo=0)
  {
   if(ArrayRange(_ptWork,0)!=bars)
      ArrayResize(_ptWork,bars);
   instanceNo*=_ptInstancesSize;
   int r=i;

//
//
//
//
//

   _ptWork[r][instanceNo+__range] = _high[i]-_low[i];
   _ptWork[r][instanceNo+__avgr]  = _ptWork[r][instanceNo+__range];
   int k=1;
   for(; k<_period && (r-k)>=0; k++)
      _ptWork[r][instanceNo+__avgr] += _ptWork[r-k][instanceNo+__range];
   _ptWork[r][instanceNo+__avgr] /= k;
   _ptWork[r][instanceNo+__avgr] *= _sensitivity;

//
//
//
//
//

   if(r==0)
     {
      _ptWork[r][instanceNo+__trend] = 0;
      _ptWork[r][instanceNo+__avgd] = _close[i]-_ptWork[r][instanceNo+__avgr];
      _ptWork[r][instanceNo+__avgu] = _close[i]+_ptWork[r][instanceNo+__avgr];
      _ptWork[r][instanceNo+__minc] = _close[i];
      _ptWork[r][instanceNo+__maxc] = _close[i];
     }
   else
     {
      _ptWork[r][instanceNo+__trend] = _ptWork[r-1][instanceNo+__trend];
      _ptWork[r][instanceNo+__avgd]  = _ptWork[r-1][instanceNo+__avgd];
      _ptWork[r][instanceNo+__avgu]  = _ptWork[r-1][instanceNo+__avgu];
      _ptWork[r][instanceNo+__minc]  = _ptWork[r-1][instanceNo+__minc];
      _ptWork[r][instanceNo+__maxc]  = _ptWork[r-1][instanceNo+__maxc];

      //
      //
      //
      //
      //

      switch((int)_ptWork[r-1][instanceNo+__trend])
        {
         case 0 :
            if(_close[i]>_ptWork[r-1][instanceNo+__avgu])
              {
               _ptWork[r][instanceNo+__minc]  = _close[i];
               _ptWork[r][instanceNo+__avgd]  = _close[i]-_ptWork[r][instanceNo+__avgr];
               _ptWork[r][instanceNo+__trend] =  1;
              }
            if(_close[i]<_ptWork[r-1][instanceNo+__avgd])
              {
               _ptWork[r][instanceNo+__maxc]  = _close[i];
               _ptWork[r][instanceNo+__avgu]  = _close[i]+_ptWork[r][instanceNo+__avgr];
               _ptWork[r][instanceNo+__trend] =  2;
              }
            break;
         case 1 :
            _ptWork[r][instanceNo+__avgd] = _ptWork[r-1][instanceNo+__minc] - _ptWork[r][instanceNo+__avgr];
            if(_close[i]>_ptWork[r-1][instanceNo+__minc])
               _ptWork[r][instanceNo+__minc] = _close[i];
            if(_close[i]<_ptWork[r-1][instanceNo+__avgd])
              {
               _ptWork[r][instanceNo+__maxc] = _close[i];
               _ptWork[r][instanceNo+__avgu] = _close[i]+_ptWork[r][instanceNo+__avgr];
               _ptWork[r][instanceNo+__trend] = 2;
              }
            break;
         case 2 :
            _ptWork[r][instanceNo+__avgu] = _ptWork[r-1][instanceNo+__maxc] + _ptWork[r][instanceNo+__avgr];
            if(_close[i]<_ptWork[r-1][instanceNo+__maxc])
               _ptWork[r][instanceNo+__maxc] = _close[i];
            if(_close[i]>_ptWork[r-1][instanceNo+__avgu])
              {
               _ptWork[r][instanceNo+__minc]  = _close[i];
               _ptWork[r][instanceNo+__avgd]  = _close[i]-_ptWork[r][instanceNo+__avgr];
               _ptWork[r][instanceNo+__trend] = 1;
              }
        }
     }
   return(_ptWork[r][instanceNo+__trend]);
  }
//+------------------------------------------------------------------+
