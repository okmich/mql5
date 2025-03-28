//+------------------------------------------------------------------+
//|                                  Bull and Bear Power Balance.mq5 |
//|                        Copyright 2018, MetaQuotes Software Corp. |
//|                                                 https://mql5.com |
//|                               https://www.mql5.com/en/code/21023 |
//+------------------------------------------------------------------+
#property copyright "Copyright 2018, MetaQuotes Software Corp."
#property link      "https://mql5.com"
#property version   "1.00"
#property description "Bull And Bear Balance indicator"
#property indicator_separate_window
#property indicator_buffers 7
#property indicator_plots   1
//--- plot BBB
#property indicator_label1  "Bull and Bear Power Balance"
#property indicator_type1   DRAW_HISTOGRAM
#property indicator_color1  clrLightSeaGreen
#property indicator_style1  STYLE_SOLID
#property indicator_width1  1
//--- input parameters
input uint           InpPeriod   =  20;         // Period
input ENUM_MA_METHOD InpMethod   =  MODE_EMA;   // Method
input uint           InpPeriodSm =  20;         // Smoothing period
input ENUM_MA_METHOD InpMethodSm =  MODE_EMA;   // Smoothing method
//--- indicator buffers
double         BufferBBB[];
double         BufferBull[];
double         BufferBear[];
double         BufferMaBull[];
double         BufferMaBear[];
double         BufferRAW[];
//--- global variables
int            period_ind;
int            period_sm;
int            i_weight_sum;

//--- includes
#include <MovingAverages.mqh>

//+------------------------------------------------------------------+
//| Custom indicator initialization function                         |
//+------------------------------------------------------------------+
int OnInit()
  {
//--- set global variables
   period_ind=int(InpPeriod<1 ? 1 : InpPeriod);
   period_sm=int(InpPeriodSm<2 ? 2 : InpPeriodSm);
//--- indicator buffers mapping
   SetIndexBuffer(0,BufferBBB,INDICATOR_DATA);
   SetIndexBuffer(1,BufferBull,INDICATOR_CALCULATIONS);
   SetIndexBuffer(2,BufferBear,INDICATOR_CALCULATIONS);
   SetIndexBuffer(3,BufferMaBull,INDICATOR_CALCULATIONS);
   SetIndexBuffer(4,BufferMaBear,INDICATOR_CALCULATIONS);
   SetIndexBuffer(5,BufferRAW,INDICATOR_CALCULATIONS);

//--- setting indicator parameters
   IndicatorSetString(INDICATOR_SHORTNAME,"Bull And Bear Balance ("+(string)period_ind+","+(string)period_sm+")");
   IndicatorSetInteger(INDICATOR_DIGITS,Digits());

//--- setting buffer arrays as timeseries
   ArraySetAsSeries(BufferBBB,true);
   ArraySetAsSeries(BufferBull,true);
   ArraySetAsSeries(BufferBear,true);
   ArraySetAsSeries(BufferMaBull,true);
   ArraySetAsSeries(BufferMaBear,true);
   ArraySetAsSeries(BufferRAW,true);
//---
   return(INIT_SUCCEEDED);
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
//--- Установка массивов буферов как таймсерий
   ArraySetAsSeries(open,true);
   ArraySetAsSeries(high,true);
   ArraySetAsSeries(low,true);
   ArraySetAsSeries(close,true);
   //ArraySetAsSeries(tick_volume,true);
//--- Проверка и расчёт количества просчитываемых баров
   if(rates_total<2) return 0;
//--- Проверка и расчёт количества просчитываемых баров
   int limit=rates_total-prev_calculated;
   if(limit>1)
     {
      limit=rates_total-2;
      ArrayInitialize(BufferBBB,EMPTY_VALUE);
      ArrayInitialize(BufferBull,0);
      ArrayInitialize(BufferBear,0);
      ArrayInitialize(BufferMaBull,0);
      ArrayInitialize(BufferMaBear,0);
      ArrayInitialize(BufferRAW,0);
     }
//--- Подготовка данных
   for(int i=limit; i>=0 && !IsStopped(); i--)
     {
      BufferBull[i]=BullPower(i,open,high,low,close);
      BufferBear[i]=BearPower(i,open,high,low,close);
     }
   switch(InpMethod)
     {
      case MODE_EMA  :  
        ExponentialMAOnBuffer(rates_total,prev_calculated,0,period_ind,BufferBull,BufferMaBull);               
        ExponentialMAOnBuffer(rates_total,prev_calculated,0,period_ind,BufferBear,BufferMaBear);               
        break;
      case MODE_SMMA :  
        SmoothedMAOnBuffer(rates_total,prev_calculated,0,period_ind,BufferBull,BufferMaBull);                  
        SmoothedMAOnBuffer(rates_total,prev_calculated,0,period_ind,BufferBear,BufferMaBear);                  
        break;
      case MODE_LWMA :  
        LinearWeightedMAOnBuffer(rates_total,prev_calculated,0,period_ind,BufferBull,BufferMaBull,i_weight_sum); 
        LinearWeightedMAOnBuffer(rates_total,prev_calculated,0,period_ind,BufferBear,BufferMaBear,i_weight_sum); 
        break;
      //---MODE_SMA
      default        :  
        SimpleMAOnBuffer(rates_total,prev_calculated,0,period_ind,BufferBull,BufferMaBull);                    
        SimpleMAOnBuffer(rates_total,prev_calculated,0,period_ind,BufferBear,BufferMaBear);                    
        break;
     }
   for(int i=limit; i>=0 && !IsStopped(); i--)
      BufferRAW[i]=BufferMaBull[i]-BufferMaBear[i];

//--- Расчёт индикатора
   switch(InpMethodSm)
     {
      case MODE_EMA  :  ExponentialMAOnBuffer(rates_total,prev_calculated,period_ind,period_sm,BufferRAW,BufferBBB);               break;
      case MODE_SMMA :  SmoothedMAOnBuffer(rates_total,prev_calculated,period_ind,period_sm,BufferRAW,BufferBBB);                  break;
      case MODE_LWMA :  LinearWeightedMAOnBuffer(rates_total,prev_calculated,period_ind,period_sm,BufferRAW,BufferBBB,i_weight_sum); break;
      //---MODE_SMA
      default        :  SimpleMAOnBuffer(rates_total,prev_calculated,period_ind,period_sm,BufferRAW,BufferBBB);                    break;
     }

//--- return value of prev_calculated for next call
   return(rates_total);
  }
//+------------------------------------------------------------------+
//| Сила медведей                                                    |
//+------------------------------------------------------------------+
double BearPower(int index,const double &open[],const double &high[],const double &low[],const double &close[])
  {
   double Value=0;
   if(close[index]<open[index])
     {
      if(close[index+1]>open[index])
        {
         Value=MathMax(close[index+1]-open[index],high[index]-low[index]);
        }
      else
        {
         Value=high[index]-low[index];
        }
     }
   else
     {
      if(close[index]>open[index])
        {
         if(close[index+1]>open[index])
           {
            Value=MathMax(close[index+1]-low[index],high[index]-close[index]);
           }
         else
           {
            Value=MathMax(open[index]-low[index],high[index]-close[index]);
           }
        }
      else
        {
         if(high[index]-close[index]>close[index]-low[index])
           {
            if(close[index+1]>open[index])
              {
               Value=MathMax(close[index+1]-open[index],high[index]-low[index]);
              }
            else
              {
               Value=high[index]-low[index];
              }
           }
         else
           {
            if(high[index]-close[index]<close[index]-low[index])
              {
               if(close[index+1]>open[index])
                 {
                  Value=MathMax(close[index+1]-low[index],high[index]-close[index]);
                 }
               else
                 {
                  Value=open[index]-low[index];
                 }
              }
            else
              {
               if(close[index+1]>open[index])
                 {
                  Value=MathMax(close[index+1]-open[index],high[index]-low[index]);
                 }
               else
                 {
                  if(close[index+1]<open[index])
                    {
                     Value=MathMax(open[index]-low[index],high[index]-close[index]);
                    }
                  else
                    {
                     Value=high[index]-low[index];
                    }
                 }
              }
           }
        }
     }
   return (Value);
  }
//+------------------------------------------------------------------+
//| Сила быков                                                       |
//+------------------------------------------------------------------+
double BullPower(int index,const double &open[],const double &high[],const double &low[],const double &close[])
  {
   double Value=0;
   if(close[index]<open[index])
     {
      if(close[index+1]<open[index])
        {
         Value=MathMax(high[index]-close[index+1],close[index]-low[index]);
        }
      else
        {
         Value=MathMax(high[index]-open[index],close[index]-low[index]);
        }
     }
   else
     {
      if(close[index]>open[index])
        {
         if(close[index+1]>open[index])
           {
            Value=high[index]-low[index];
           }
         else
           {
            Value=MathMax(open[index]-close[index+1],high[index]-low[index]);
           }
        }
      else
        {
         if(high[index]-close[index]>close[index]-low[index])
           {
            if(close[index+1]<open[index])
              {
               Value=MathMax(high[index]-close[index+1],close[index]-low[index]);
              }
            else
              {
               Value=high[index]-open[index];
              }
           }
         else
           {
            if(high[index]-close[index]<close[index]-low[index])
              {
               if(close[index+1]>open[index])
                 {
                  Value=high[index]-low[index];
                 }
               else
                 {
                  Value=MathMax(open[index]-close[index+1],high[index]-low[index]);
                 }
              }
            else
              {
               if(close[index+1]>open[index])
                 {
                  Value=MathMax(high[index]-open[index],close[index]-low[index]);
                 }
               else
                 {
                  if(close[index+1]<open[index])
                    {
                     Value=MathMax(open[index]-close[index+1],high[index]-low[index]);
                    }
                  else
                    {
                     Value=high[index]-low[index];
                    }
                 }
              }
           }
        }
     }

   return (Value);
  }
//+------------------------------------------------------------------+
