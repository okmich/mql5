//+------------------------------------------------------------------+
//|                                                   SeriesStat.mqh |
//|                                    Copyright 2020, Michael Enudi |
//|                                             okmich2002@yahoo.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2020, Michael Enudi"
#property link      "okmich2002@yahoo.com"

#include <Math\Stat\Normal.mqh>
#include <Math\Stat\Math.mqh>
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
template<typename T>
class CNormalSeries
  {
private:
   int               m_bars;
   double            m_Mean, m_StdDev;

public:
                     CNormalSeries(int bars) {this.m_bars = bars;};
                    ~CNormalSeries() {};

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
void CNormalSeries::Refresh(const T &arr[])
  {
   m_Mean = MathMean(arr);
   m_StdDev = MathStandardDeviation(arr);
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
template<typename T>
void CNormalSeries::Refresh(const T &arr[], int start, int count = 0)
  {
   double newArr[];
   ArrayResize(newArr, count);

   if(start >= count-1 && count>0)
      for(int i=0; i<count; i++)
         newArr[i] = (double)arr[start-i];

   Refresh(newArr);
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
template<typename T>
double CNormalSeries::QuantileDistribution(T prob)
  {
   int error;
   bool logMode = !(prob >= 0 && prob <= 1);
   double result = MathQuantileNormal(prob, m_Mean, m_StdDev, true, logMode, error);
   if(error == ERR_OK)
      return result;
   else
      return QNaN;
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
template<typename T>
void CNormalSeries::QuantileDistribution(const T &probs[],double &results[])
  {
   int len = ArraySize(probs);
   ArrayResize(results, len);
   int error, logMode;
   for(int i = 0; i < len; i++)
     {
      logMode = !(probs[i] >= 0 && probs[i] <= 1);
      double result = MathQuantileNormal(probs[i], m_Mean, m_StdDev, true, logMode, error);
      if(error == ERR_OK)
         results[i] = result;
      else
         results[i] = QNaN;
     }
  }
//+------------------------------------------------------------------+
