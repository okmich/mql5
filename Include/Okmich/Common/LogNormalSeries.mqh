//+------------------------------------------------------------------+
//|                                                   SeriesStat.mqh |
//|                                    Copyright 2020, Michael Enudi |
//|                                             okmich2002@yahoo.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2020, Michael Enudi"
#property link      "okmich2002@yahoo.com"

#include <Math\Stat\LogNormal.mqh>
#include <Math\Stat\Math.mqh>
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
template<typename T>
class CLogNormalSeries
  {
private:
   int               m_bars;
   double            m_Mean, m_StdDev;

   void              CalcStats(const double &arr[]);

public:
                     CLogNormalSeries(int bars) {this.m_bars = bars;};
                    ~CLogNormalSeries() {};

   double            Mean() {return m_Mean;};
   double            StdDeviation() {return m_StdDev;};

   void              Refresh(const T &arr[]);
   void              Refresh(const T &arr[], int start, int count = 0);

   double            QuantileDistribution(T prob);
   void              QuantileDistribution(const T &prob[], double &results[]);
  };
//+------------------------------------------------------------------+

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
template<typename T>
void CLogNormalSeries::Refresh(const T &arr[])
  {
   double newArr[];
   int count = ArraySize(arr);
   ArrayResize(newArr,count);

   for(int i=0; i<count; i++)
      newArr[i] = log(arr[i]);

   CalcStats(newArr);
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
template<typename T>
void CLogNormalSeries::Refresh(const T &arr[], int start, int count = 0)
  {
   double newArr[];
   ArrayResize(newArr, count);

   if(start >= count-1 && count>0)
     {
      for(int i=0; i<count; i++)
         newArr[i] = log(arr[start-i]);
     }
   CalcStats(newArr);
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
template<typename T>
double CLogNormalSeries::QuantileDistribution(T prob)
  {
   int error;
   bool logMode = !(prob >= 0 && prob <= 1);
   double result = MathQuantileLognormal(prob, m_Mean, m_StdDev, true, logMode, error);
   if(error == ERR_OK)
      return result;
   else
      return QNaN;
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
template<typename T>
void CLogNormalSeries::QuantileDistribution(const T &probs[],double &results[])
  {
   int len = ArraySize(probs);
   ArrayResize(results, len);
   int error, logMode;
   for(int i = 0; i < len; i++)
     {
      logMode = !(probs[i] >= 0 && probs[i] <= 1);
      double result = MathQuantileLognormal(probs[i], m_Mean, m_StdDev, true, logMode, error);
      if(error == ERR_OK)
         results[i] = result;
      else
         results[i] = QNaN;
     }
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
template<typename T>
void CLogNormalSeries::CalcStats(const double &arr[])
  {
   m_Mean = MathMean(arr);
   m_StdDev = MathStandardDeviation(arr);
  }
//+------------------------------------------------------------------+
