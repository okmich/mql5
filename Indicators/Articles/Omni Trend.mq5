//+------------------------------------------------------------------+
//|                                                   Omni_Trend.mq5 |
//|                                                 Copyright © 2005 |
//|                                                                  |
//+------------------------------------------------------------------+
#property copyright "Copyright © 2005,  "
#property link      ""
//---- номер версии индикатора
#property version   "1.00"
//---- отрисовка индикатора в основном окне
#property indicator_chart_window
//---- количество индикаторных буферов 4
#property indicator_buffers 3
//---- использовано всего четыре графических построения
#property indicator_plots   3
//+----------------------------------------------+
//|  Параметры отрисовки индикатора              |
//+----------------------------------------------+
//---- отрисовка индикатора в виде значка
#property indicator_type1 DRAW_ARROW
//---- в качестве окраски индикатора использован
#property indicator_color1 clrBlue
//---- линия индикатора - сплошная
#property indicator_style1 STYLE_SOLID
//---- толщина линии индикатора равна 2
#property indicator_width1 2
//---- отображение метки сигнальной линии
#property indicator_label1  "Trend Up"
//+----------------------------------------------+
//|  Параметры отрисовки индикатора              |
//+----------------------------------------------+
//---- отрисовка индикатора в виде значка
#property indicator_type2 DRAW_ARROW
//---- в качестве окраски индикатора использован
#property indicator_color2 clrDarkOrange
//---- линия индикатора - сплошная
#property indicator_style2 STYLE_SOLID
//---- толщина линии индикатора равна 2
#property indicator_width2 2
//---- отображение метки сигнальной линии
#property indicator_label2  "Trend Down"

#include <Okmich\Indicators\BaseIndicator.mqh>

//+----------------------------------------------+
//|  Параметры отрисовки индикатора              |
//+----------------------------------------------+
#property indicator_type3 DRAW_LINE
#property indicator_color3 clrLavender
#property indicator_style3 STYLE_SOLID
#property indicator_width3 1
#property indicator_label3  "MA"
  
//+----------------------------------------------+
//|  объявление констант                         |
//+----------------------------------------------+
#define RESET  0 // Константа для возврата терминалу команды на пересчёт индикатора
//+----------------------------------------------+
//| Входные параметры индикатора                 |
//+----------------------------------------------+
input uint    MA_Length=13;
input  ENUM_MA_TYPE   MA_Type=MA_TYPE_EMA;
input ENUM_APPLIED_PRICE   MA_Price=PRICE_CLOSE;
input int     ATR_Length=100;     //ATR's Period
input double  Kv=2.0;            //Volatility's Factor or Multiplier
input double  MoneyRisk=0.15;    //Offset Factor
input int     Shift=0;           // Horizontal Bar shift
//+----------------------------------------------+
//---- объявление динамических массивов, которые будут в дальнейшем использованы в качестве индикаторных буферов
double Ma[],TrendUp[],TrendDown[];
//---- объявление целочисленных переменных начала отсчета данных
int min_rates_total;
//---- Объявление целых переменных для хендлов индикаторов
int MA_Handle,ATR_Handle;
//+------------------------------------------------------------------+
//| Custom indicator initialization function                         |
//+------------------------------------------------------------------+
int OnInit()
  {
//---- инициализация переменных начала отсчета данных
   min_rates_total=int(MathMax(ATR_Length,MA_Length));

//---- получение хендла индикатора iMA
   MA_Handle=GetHandleForMaType(MA_Type, MA_Length, MA_Price);
   if(MA_Handle==INVALID_HANDLE)
     {
      Print(" Не удалось получить хендл индикатора iMA");
      return(INIT_FAILED);
     }
//--- получение хендла индикатора ATR
   ATR_Handle=iATR(NULL,0,ATR_Length);
   if(ATR_Handle==INVALID_HANDLE)
     {
      Print(" Не удалось получить хендл индикатора ATR");
      return(INIT_FAILED);
     }

//---- инициализации переменной для короткого имени индикатора
   string shortname;
   StringConcatenate(shortname,"Omni_Trend(",string(MA_Length),")");
//---- создание имени для отображения в отдельном подокне и во всплывающей подсказке
   IndicatorSetString(INDICATOR_SHORTNAME,shortname);
//---- определение точности отображения значений индикатора
   IndicatorSetInteger(INDICATOR_DIGITS,_Digits);

//---- превращение динамического массива в индикаторный буфер
   SetIndexBuffer(0,TrendUp,INDICATOR_DATA);
//---- осуществление сдвига индикатора по горизонтали на Shift
   PlotIndexSetInteger(0,PLOT_SHIFT,Shift);
//---- осуществление сдвига начала отсчета отрисовки индикатора
   PlotIndexSetInteger(0,PLOT_DRAW_BEGIN,min_rates_total);
//---- запрет на отрисовку индикатором пустых значений
   PlotIndexSetDouble(0,PLOT_EMPTY_VALUE,NULL);
//---- индексация элементов в буферах, как в таймсериях
   ArraySetAsSeries(TrendUp,true);

//---- превращение динамического массива в индикаторный буфер
   SetIndexBuffer(1,TrendDown,INDICATOR_DATA);
//---- осуществление сдвига индикатора по горизонтали на Shift
   PlotIndexSetInteger(1,PLOT_SHIFT,Shift);
//---- осуществление сдвига начала отсчета отрисовки индикатора
   PlotIndexSetInteger(1,PLOT_DRAW_BEGIN,min_rates_total);
//---- запрет на отрисовку индикатором пустых значений
   PlotIndexSetDouble(1,PLOT_EMPTY_VALUE,NULL);
//---- индексация элементов в буферах, как в таймсериях
   ArraySetAsSeries(TrendDown,true);

   SetIndexBuffer(2,Ma,INDICATOR_DATA);
   PlotIndexSetInteger(2,PLOT_SHIFT,Shift);
   PlotIndexSetInteger(2,PLOT_DRAW_BEGIN,min_rates_total);
   PlotIndexSetDouble(2,PLOT_EMPTY_VALUE,NULL);
   ArraySetAsSeries(Ma,true);

//---- завершение инициализации
   return(INIT_SUCCEEDED);
  }
//+------------------------------------------------------------------+
//| Custom indicator iteration function                              |
//+------------------------------------------------------------------+
int OnCalculate(const int rates_total,    // количество истории в барах на текущем тике
                const int prev_calculated,// количество истории в барах на предыдущем тике
                const datetime &time[],
                const double &open[],
                const double& high[],     // ценовой массив максимумов цены для расчета индикатора
                const double& low[],      // ценовой массив минимумов цены для расчета индикатора
                const double &close[],
                const long &tick_volume[],
                const long &volume[],
                const int &spread[])
  {
//---- проверка количества баров на достаточность для расчета
   if(BarsCalculated(MA_Handle)<rates_total
      || BarsCalculated(ATR_Handle)<rates_total
      || rates_total<min_rates_total)
      return(RESET);

//---- объявления локальных переменных
   double ATR[],smin,smax;
   static double smin_prev,smax_prev;
   int limit,to_copy,bar,trend;
   static int trend_prev;

//---- индексация элементов в массивах, как в таймсериях
   ArraySetAsSeries(low,true);
   ArraySetAsSeries(high,true);
   ArraySetAsSeries(close,true);
   //ArraySetAsSeries(MA,true);
   ArraySetAsSeries(ATR,true);

//---- расчет стартового номера first для цикла пересчета баров
   if(prev_calculated>rates_total || prev_calculated<=0) // проверка на первый старт расчета индикатора
     {
      limit=rates_total-min_rates_total-1;               // стартовый номер для расчета всех баров
      trend_prev=0;
      smin_prev=smax_prev=close[limit];
     }
   else
     {
      limit=rates_total-prev_calculated;                 // стартовый номер для расчета новых баров
     }
   to_copy=limit+1;

//---- копируем вновь появившиеся данные в массивы
   if(CopyBuffer(MA_Handle,0,0,to_copy,Ma)<=0)
      return(RESET);
   if(CopyBuffer(ATR_Handle,0,0,to_copy,ATR)<=0)
      return(RESET);

//---- основной цикл расчета индикатора
   for(bar=limit; bar>=0 && !IsStopped(); bar--)
     {
      TrendUp[bar]=NULL;
      TrendDown[bar]=NULL;

      double bprice=Ma[bar];
      double sprice=Ma[bar];
      smax=bprice+Kv*ATR[bar];
      smin=sprice-Kv*ATR[bar];
      trend=trend_prev;
      if(high[bar]>smax_prev)
         trend=+1;
      if(low[bar]<smin_prev)
         trend=-1;


      if(trend>0)
        {
         if(smin<smin_prev)
            smin=smin_prev;
         TrendUp[bar]=smin-(MoneyRisk-1)*ATR[bar];
         if(TrendUp[bar]<TrendUp[bar+1] && TrendUp[bar+1])
            TrendUp[bar]=TrendUp[bar+1];
        }

      if(trend<0)
        {
         if(smax>smax_prev)
            smax=smax_prev;
         TrendDown[bar]=smax+(MoneyRisk-1)*ATR[bar];
         if(TrendDown[bar]>TrendDown[bar+1] && TrendDown[bar+1])
            TrendDown[bar]=TrendDown[bar+1];
        }

      if(bar)
        {
         trend_prev=trend;
         smin_prev=smin;
         smax_prev=smax;
        }
     }
//----
   return(rates_total);
  }
//+------------------------------------------------------------------+
