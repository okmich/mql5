//+------------------------------------------------------------------+
//|                                                BaseIndicator.mqh |
//|                                    Copyright 2021, Michael Enudi |
//|                                             okmich2002@yahoo.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2021, Michael Enudi"
#property link      "okmich2002@yahoo.com"

#include <Okmich\Common\Common.mqh>

enum ENUM_MA_TYPE
  {
   MA_TYPE_DEMA, //Double Exponential Moving Average
   MA_TYPE_EMA,  //Exponential Moving Average
   MA_TYPE_LWMA, //Linear Weighted Moving Average
   MA_TYPE_SMA,  //Simple Moving Average
   MA_TYPE_SMMA, //Smoothed Moving Average
   MA_TYPE_TEMA, //Triple Exponential Moving Average
   MA_TYPE_VMMA  //Volume Weighted Moving Average
  };

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
int GetHandleForMaType(ENUM_MA_TYPE maType, int avgPeriod, ENUM_APPLIED_PRICE priceType=PRICE_CLOSE)
  {
   int avgHandle=INVALID_HANDLE;
   if(maType != MA_TYPE_DEMA && maType != MA_TYPE_TEMA)
     {
      ENUM_MA_METHOD maMethod;
      switch(maType)
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
            maMethod = MODE_EMA;
        }
      avgHandle   = iMA(_Symbol,0,avgPeriod,0,maMethod,priceType);
     }
   else
     {
      switch(maType)
        {
         case MA_TYPE_TEMA:
           {
            avgHandle   = iTEMA(_Symbol,0,avgPeriod,0,priceType);
            break;
           }
         case MA_TYPE_DEMA:
         default:
           {
            avgHandle   = iDEMA(_Symbol,0,avgPeriod,0,priceType);
            break;
           }
        }
     }
   return avgHandle;
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
class CBaseIndicator
  {
protected :
   //-- general
   int               m_ShiftToUse;
   string            m_Symbol;
   ENUM_TIMEFRAMES   m_TF;

   double            SimpleMA(const int position,const int period,const double &price[]);
   double            ExponentialMA(const int position,const int period,const double prev_value,const double &price[]);
   double            SmoothedMA(const int position,const int period,const double prev_value,const double &price[]);
   double            LinearWeightedMA(const int position,const int period,const double &price[]);
   double                RegressionSlope(const double &buffer[], int period, int start=0);

   ENUM_ENTRY_SIGNAL     _AboveBelowObOsLinesFilter(const double &value[], const double OverBoughtLevel=80, const double OverSoldLevel=20);
   ENUM_ENTRY_SIGNAL     _AboveBelowSignalLinesFilter(const double &value[], const double &overBoughtBuffer[], const double &overSoldBuffer[]);
   ENUM_ENTRY_SIGNAL     _ContraAboveBelowObOsLinesFilter(const double &value[], const double OverBoughtLevel=80, const double OverSoldLevel=20);
   ENUM_ENTRY_SIGNAL     _ContraObOsZoneBiasedFilter(const double &value[], const double OverBoughtLevel=80, const double OverSoldLevel=20);
   ENUM_ENTRY_SIGNAL     _CrossesDiscontinuedSignalLinesSignal(const double &value[], const double &overBoughtBuffer[], const double &overSoldBuffer[]);
   ENUM_ENTRY_SIGNAL     _DirectionalFilter(const double &value[], int period=3);
   ENUM_ENTRY_SIGNAL     _ObOsZoneBiasedFilter(const double &value[], const double OverBoughtLevel=80, const double OverSoldLevel=20);
   ENUM_ENTRY_SIGNAL     _Phase(const double &value[], const double midLevel=50);

   ENUM_ENTRY_SIGNAL    _EnterOsOBSignal(const double &buffer[], const double mObLevel=80, const double mOsLevel=20);
   ENUM_ENTRY_SIGNAL    _ExitOsOBSignal(const double &buffer[], const double mObLevel=80, const double mOsLevel=20);
   ENUM_ENTRY_SIGNAL    _CrossMidSignal(const double &buffer[], const double midLevel=50);
   ENUM_ENTRY_SIGNAL    _DirectionalSignal(const double &buffer[]);

public:
                     CBaseIndicator(string symbol, ENUM_TIMEFRAMES timeFrame)
     {
      m_Symbol = symbol;
      m_TF = timeFrame;
     };

   virtual bool                   Init();
   virtual bool                   Refresh(int ShiftToUse=1);
   virtual void                   Release();
  };

//+------------------------------------------------------------------+
//| Simple Moving Average                                            |
//+------------------------------------------------------------------+
double CBaseIndicator::SimpleMA(const int position,const int period,const double &price[])
  {
   double result=0.0;
   int EndPos = period+position;
//--- check period
   if(period>0 && EndPos<=ArraySize(price))
     {
      for(int i=position; i<EndPos; i++)
         result+=price[i];

      result/=period;
     }

   return(result);
  }

//+------------------------------------------------------------------+
//| Exponential Moving Average                                       |
//+------------------------------------------------------------------+
double CBaseIndicator::ExponentialMA(const int position,const int period,const double prev_value,const double &price[])
  {
   double result=0.0;
//--- check period
   if(period>0)
     {
      double pr=2.0/(period+1.0);
      result=price[position]*pr+prev_value*(1-pr);
     }

   return(result);
  }

//+------------------------------------------------------------------+
//| Smoothed Moving Average                                          |
//+------------------------------------------------------------------+
double CBaseIndicator::SmoothedMA(const int position,const int period,const double prev_value,const double &price[])
  {
   double result=0.0;
   int EndPos = period+position;
//--- check period
   if(period>0 && EndPos<=ArraySize(price))
     {
      if(position==period-1)
        {
         for(int i=position; i<EndPos; i++)
            result+=price[i];

         result/=period;
        }

      result=(prev_value*(period-1)+price[position])/period;
     }

   return(result);
  }

//+------------------------------------------------------------------+
//| Linear Weighted Moving Average                                   |
//+------------------------------------------------------------------+
double CBaseIndicator::LinearWeightedMA(const int position,const int period,const double &price[])
  {
   double result=0.0;
   int EndPos = period+position;
//--- check period
   if(period>0 && EndPos<=ArraySize(price))
     {
      double sum =0.0;
      int    wsum=0;

      for(int i=position; i<EndPos; i++)
        {
         wsum+=i;
         sum +=price[i+1]*(period-i+1);
        }

      result=sum/wsum;
     }

   return(result);
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
double CBaseIndicator::RegressionSlope(const double &buffer[],int period, int start=0)
  {
   LinReg lr;
   if(start > 0)
     {
      double newArr[];
      //ArraySetAsSeries(newArr, true);
      ArrayResize(newArr, period);
      ArrayCopy(newArr, buffer, 0, start, period);

      lr = CalculateLinearRegression(newArr, period, 0);
     }
   else
     {
      lr = CalculateLinearRegression(buffer, period, 1);
     }
   return lr.slope;
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
ENUM_ENTRY_SIGNAL CBaseIndicator::_AboveBelowSignalLinesFilter(
   const double &value[],
   const double &overBoughtBuffer[],
   const double &overSoldBuffer[])
  {
   if(value[m_ShiftToUse] > overBoughtBuffer[m_ShiftToUse])
      return ENTRY_SIGNAL_BUY;
   else
      if(value[m_ShiftToUse] < overSoldBuffer[m_ShiftToUse])
         return ENTRY_SIGNAL_SELL;
      else
         return ENTRY_SIGNAL_NONE;
  }


//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
ENUM_ENTRY_SIGNAL CBaseIndicator::_CrossesDiscontinuedSignalLinesSignal(
   const double &value[],
   const double &overBoughtBuffer[],
   const double &overSoldBuffer[])
  {
   if(value[m_ShiftToUse+1] < overBoughtBuffer[m_ShiftToUse+1] && value[m_ShiftToUse] > overBoughtBuffer[m_ShiftToUse])
      return ENTRY_SIGNAL_BUY;
   else
      if(value[m_ShiftToUse+1] > overSoldBuffer[m_ShiftToUse+1] && value[m_ShiftToUse] < overSoldBuffer[m_ShiftToUse])
         return ENTRY_SIGNAL_SELL;
      else
         return ENTRY_SIGNAL_NONE;
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
ENUM_ENTRY_SIGNAL CBaseIndicator::_Phase(const double &value[], const double midLevel=50)
  {
   if(value[m_ShiftToUse] > midLevel)
      return ENTRY_SIGNAL_BUY;
   else
      if(value[m_ShiftToUse] < midLevel)
         return ENTRY_SIGNAL_SELL;

   return ENTRY_SIGNAL_NONE;
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
ENUM_ENTRY_SIGNAL CBaseIndicator::_AboveBelowObOsLinesFilter(const double &value[], const double OverBoughtLevel=80, const double OverSoldLevel=20)
  {
   if(value[m_ShiftToUse] > OverBoughtLevel)
      return ENTRY_SIGNAL_BUY;
   else
      if(value[m_ShiftToUse] < OverSoldLevel)
         return ENTRY_SIGNAL_SELL;

   return ENTRY_SIGNAL_NONE;
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
ENUM_ENTRY_SIGNAL CBaseIndicator::_ContraAboveBelowObOsLinesFilter(const double &value[], const double OverBoughtLevel=80, const double OverSoldLevel=20)
  {
   ENUM_ENTRY_SIGNAL normalCase = _AboveBelowObOsLinesFilter(value, OverBoughtLevel, OverSoldLevel);
   return normalCase == ENTRY_SIGNAL_BUY ? ENTRY_SIGNAL_SELL :
          normalCase == ENTRY_SIGNAL_SELL ? ENTRY_SIGNAL_BUY :
          ENTRY_SIGNAL_NONE;
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
ENUM_ENTRY_SIGNAL CBaseIndicator::_ObOsZoneBiasedFilter(const double &value[], const double OverBoughtLevel=80, const double OverSoldLevel=20)
  {
   if(value[m_ShiftToUse+1] > OverSoldLevel && value[m_ShiftToUse] < OverSoldLevel)
      return ENTRY_SIGNAL_BUY;
   else
      if(value[m_ShiftToUse+1] < OverBoughtLevel && value[m_ShiftToUse] > OverBoughtLevel)
         return ENTRY_SIGNAL_SELL;

   return ENTRY_SIGNAL_NONE;
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
ENUM_ENTRY_SIGNAL CBaseIndicator::_ContraObOsZoneBiasedFilter(const double &value[], const double OverBoughtLevel=80, const double OverSoldLevel=20)
  {
   if(value[m_ShiftToUse+1] < OverSoldLevel && value[m_ShiftToUse] > OverSoldLevel)
      return ENTRY_SIGNAL_BUY;
   else
      if(value[m_ShiftToUse+1] > OverBoughtLevel &&
         value[m_ShiftToUse] < OverBoughtLevel)
         return ENTRY_SIGNAL_SELL;

   return ENTRY_SIGNAL_NONE;
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
ENUM_ENTRY_SIGNAL CBaseIndicator::_DirectionalFilter(const double &value[], int period=3)
  {
   if(ArraySize(value) < period)
      return ENTRY_SIGNAL_NONE;

   double slope = RegressionSlope(value, period);
   return (slope > 0) ? ENTRY_SIGNAL_BUY :
          (slope < 0) ? ENTRY_SIGNAL_SELL  : ENTRY_SIGNAL_NONE;
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
ENUM_ENTRY_SIGNAL CBaseIndicator::_EnterOsOBSignal(const double &buffer[], const double mObLevel=80, const double mOsLevel=20)
  {
   if(buffer[m_ShiftToUse+1] > mOsLevel &&  buffer[m_ShiftToUse] < mOsLevel)
      return ENTRY_SIGNAL_BUY;
   else
      if(buffer[m_ShiftToUse+1] < mObLevel &&  buffer[m_ShiftToUse] > mObLevel)
         return ENTRY_SIGNAL_SELL;
   return ENTRY_SIGNAL_NONE;
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
ENUM_ENTRY_SIGNAL CBaseIndicator::_ExitOsOBSignal(const double &buffer[], const double mObLevel=80, const double mOsLevel=20)
  {
   if(buffer[m_ShiftToUse+1] > mObLevel &&  buffer[m_ShiftToUse] < mObLevel)
      return ENTRY_SIGNAL_SELL;
   else
      if(buffer[m_ShiftToUse+1] < mOsLevel &&  buffer[m_ShiftToUse] > mOsLevel)
         return ENTRY_SIGNAL_BUY;
   return ENTRY_SIGNAL_NONE;
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
ENUM_ENTRY_SIGNAL CBaseIndicator::_CrossMidSignal(const double &buffer[], const double midLevel=50)
  {
   if(buffer[m_ShiftToUse+1] > midLevel &&  buffer[m_ShiftToUse] < midLevel)
      return ENTRY_SIGNAL_SELL;
   else
      if(buffer[m_ShiftToUse+1] < midLevel && buffer[m_ShiftToUse] > midLevel)
         return ENTRY_SIGNAL_BUY;
      else
         return ENTRY_SIGNAL_NONE;
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
ENUM_ENTRY_SIGNAL CBaseIndicator::_DirectionalSignal(const double &buffer[])
  {
   return (buffer[m_ShiftToUse+1] > buffer[m_ShiftToUse]) ? ENTRY_SIGNAL_SELL :
          (buffer[m_ShiftToUse+1] < buffer[m_ShiftToUse]) ? ENTRY_SIGNAL_BUY : ENTRY_SIGNAL_NONE;
  }
//+------------------------------------------------------------------+
