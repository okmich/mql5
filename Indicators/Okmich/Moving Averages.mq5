//+------------------------------------------------------------------+
//|                                              Moving Averages.mq5 |
//|                                                 Copyright © 2020 |
//|                                                                  |
//+------------------------------------------------------------------+
#property copyright "Copyright © 2020,  "
#property link      ""

#property version   "1.00"
#property indicator_chart_window
#property indicator_buffers 1
#property indicator_plots   1

#include <Okmich\Indicators\BaseIndicator.mqh>

#property indicator_type1 DRAW_LINE
#property indicator_color1 clrGoldenrod
#property indicator_style1 STYLE_SOLID
#property indicator_width1 2
  
#define RESET  0

input uint    MA_Length=13;
input  ENUM_MA_TYPE   MA_Type=MA_TYPE_EMA;
input ENUM_APPLIED_PRICE   MA_Price=PRICE_CLOSE;
input int     Shift=0;           // Horizontal Bar shift
//+----------------------------------------------+
double Ma[];
int min_rates_total;
int MA_Handle;

//+------------------------------------------------------------------+
//| Custom indicator initialization function                         |
//+------------------------------------------------------------------+
int OnInit()
  {

   min_rates_total=int(MA_Length);
   
   MA_Handle=GetHandleForMaType(MA_Type, MA_Length, MA_Price);
   if(MA_Handle==INVALID_HANDLE)
     {
      Print(" Не удалось получить хендл индикатора iMA");
      return(INIT_FAILED);
     }

   string shortname;
   StringConcatenate(shortname,"MA(",string(MA_Length),")");
   IndicatorSetString(INDICATOR_SHORTNAME,shortname);
   IndicatorSetInteger(INDICATOR_DIGITS,_Digits);

   SetIndexBuffer(0,Ma,INDICATOR_DATA);
   PlotIndexSetInteger(0,PLOT_SHIFT,Shift);
   PlotIndexSetInteger(0,PLOT_DRAW_BEGIN,min_rates_total);
   PlotIndexSetDouble(0,PLOT_EMPTY_VALUE,NULL);
   ArraySetAsSeries(Ma,true);

   return(INIT_SUCCEEDED);
  }
//+------------------------------------------------------------------+
//| Custom indicator iteration function                              |
//+------------------------------------------------------------------+
int OnCalculate(const int rates_total,
                const int prev_calculated,
                const datetime &time[],
                const double &open[],
                const double& high[],
                const double& low[],
                const double &close[],
                const long &tick_volume[],
                const long &volume[],
                const int &spread[])
  {
   if(BarsCalculated(MA_Handle)<rates_total
      || rates_total<min_rates_total)
      return(RESET);

   int limit,to_copy;
   static int trend_prev;

//---- индексация элементов в массивах, как в таймсериях
   ArraySetAsSeries(low,true);
   ArraySetAsSeries(high,true);
   ArraySetAsSeries(close,true);
   //ArraySetAsSeries(MA,true);

//---- расчет стартового номера first для цикла пересчета баров
   if(prev_calculated>rates_total || prev_calculated<=0) // проверка на первый старт расчета индикатора
     {
      limit=rates_total-min_rates_total-1;               // стартовый номер для расчета всех баров
      trend_prev=0;
     }
   else
     {
      limit=rates_total-prev_calculated;                 // стартовый номер для расчета новых баров
     }
   to_copy=limit+1;

//---- копируем вновь появившиеся данные в массивы
   if(CopyBuffer(MA_Handle,0,0,to_copy,Ma)<=0)
      return(RESET);
      
   return(rates_total);
  }
//+------------------------------------------------------------------+
