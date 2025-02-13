//+------------------------------------------------------------------+
//|                                                     ASCTrend.mq5 |
//|                             Copyright © 2011,   Nikolay Kositsin |
//|                              Khabarovsk,   farria@mail.redcom.ru |
//+------------------------------------------------------------------+
#property copyright "Copyright © 2011, Nikolay Kositsin"
#property link "farria@mail.redcom.ru"
#property description "ASCtrend"
//--- íîìåð âåðñèè èíäèêàòîðà
#property version   "1.00"
//--- îòðèñîâêà èíäèêàòîðà â ãëàâíîì îêíå
#property indicator_chart_window
//--- äëÿ ðàñ÷åòà è îòðèñîâêè èíäèêàòîðà èñïîëüçîâàíî äâà áóôåðà
#property indicator_buffers 2
//--- èñïîëüçîâàíî âñåãî äâà ãðàôè÷åñêèõ ïîñòðîåíèÿ
#property indicator_plots   2
//+----------------------------------------------+
//|  Ïàðàìåòðû îòðèñîâêè ìåäâåæüåãî èíäèêàòîðà   |
//+----------------------------------------------+
//--- îòðèñîâêà èíäèêàòîðà 1 â âèäå ñèìâîëà
#property indicator_type1   DRAW_ARROW
//--- â êà÷åñòâå öâåòà ìåäâåæüåé ëèíèè èíäèêàòîðà èñïîëüçîâàí ðîçîâûé öâåò
#property indicator_color1  Magenta
//--- òîëùèíà ëèíèè èíäèêàòîðà 1 ðàâíà 4
#property indicator_width1  2
//--- îòîáðàæåíèå áû÷üåé ìåòêè èíäèêàòîðà
#property indicator_label1  "ASCTrend Sell"
//+----------------------------------------------+
//|  Ïàðàìåòðû îòðèñîâêè áû÷üåãî èíäèêàòîðà      |
//+----------------------------------------------+
//--- îòðèñîâêà èíäèêàòîðà 2 â âèäå ñèìâîëà
#property indicator_type2   DRAW_ARROW
//--- â êà÷åñòâå öâåòà áû÷üåé ëèíèè èíäèêàòîðà èñïîëüçîâàí ñèíèé öâåò
#property indicator_color2  Blue
//--- òîëùèíà ëèíèè èíäèêàòîðà 2 ðàâíà 4
#property indicator_width2  2
//--- îòîáðàæåíèå ìåäâåæüåé ìåòêè èíäèêàòîðà
#property indicator_label2 "ASCTrend Buy"
//+----------------------------------------------+
//|  îáúÿâëåíèå êîíñòàíò                         |
//+----------------------------------------------+
#define RESET  0 // Êîíñòàíòà äëÿ âîçâðàòà òåðìèíàëó êîìàíäû íà ïåðåñ÷¸ò èíäèêàòîðà
//+----------------------------------------------+
//| Âõîäíûå ïàðàìåòðû èíäèêàòîðà                 |
//+----------------------------------------------+
input int RISK=3;
//+----------------------------------------------+
//--- îáúÿâëåíèå äèíàìè÷åñêèõ ìàññèâîâ, êîòîðûå â äàëüíåéøåì
//--- áóäóò èñïîëüçîâàíû â êà÷åñòâå èíäèêàòîðíûõ áóôåðîâ
double SellBuffer[];
double BuyBuffer[];
//--- îáúÿâëåíèå öåëî÷èñëåííûõ ïåðåìåííûõ íà÷àëà îòñ÷åòà äàííûõ
int min_rates_total;
int  x1,x2,value10,value11,WPR_Handle[3];
//+------------------------------------------------------------------+
//| Custom indicator initialization function                         |
//+------------------------------------------------------------------+
int OnInit()
  {
//--- èíèöèàëèçàöèÿ ãëîáàëüíûõ ïåðåìåííûõ
   x1=67+RISK;
   x2=33-RISK;
   value10=2;
   value11=value10;
   min_rates_total=int(MathMax(3+RISK*2,4)+1);
//--- ïîëó÷åíèå õåíäëà èíäèêàòîðà iWPR 1
   WPR_Handle[0]=iWPR(NULL,0,3);
   if(WPR_Handle[0]==INVALID_HANDLE)
     {
      Print(" Íå óäàëîñü ïîëó÷èòü õåíäë èíäèêàòîðà iWPR 1");
      return(INIT_FAILED);
     }
//--- ïîëó÷åíèå õåíäëà èíäèêàòîðà iWPR 2
   WPR_Handle[1]=iWPR(NULL,0,4);
   if(WPR_Handle[1]==INVALID_HANDLE)
     {
      Print(" Íå óäàëîñü ïîëó÷èòü õåíäë èíäèêàòîðà iWPR 2");
      return(INIT_FAILED);
     }
//--- ïîëó÷åíèå õåíäëà èíäèêàòîðà iWPR 3
   WPR_Handle[2]=iWPR(NULL,0,3+RISK*2);
   if(WPR_Handle[2]==INVALID_HANDLE)
     {
      Print(" Íå óäàëîñü ïîëó÷èòü õåíäë èíäèêàòîðà iWPR 3");
      return(INIT_FAILED);
     }
//--- ïðåâðàùåíèå äèíàìè÷åñêîãî ìàññèâà â èíäèêàòîðíûé áóôåð
   SetIndexBuffer(0,SellBuffer,INDICATOR_DATA);
//--- îñóùåñòâëåíèå ñäâèãà íà÷àëà îòñ÷åòà îòðèñîâêè èíäèêàòîðà 1
   PlotIndexSetInteger(0,PLOT_DRAW_BEGIN,min_rates_total);
//--- ñîçäàíèå ìåòêè äëÿ îòîáðàæåíèÿ â DataWindow
   PlotIndexSetString(0,PLOT_LABEL,"ASCtrend Sell");
//--- ñèìâîë äëÿ èíäèêàòîðà
   PlotIndexSetInteger(0,PLOT_ARROW,108);
//--- èíäåêñàöèÿ ýëåìåíòîâ â áóôåðå, êàê â òàéìñåðèè
   ArraySetAsSeries(SellBuffer,true);
//--- óñòàíîâêà çíà÷åíèé èíäèêàòîðà, êîòîðûå íå áóäóò âèäèìû íà ãðàôèêå
   PlotIndexSetDouble(0,PLOT_EMPTY_VALUE,0);
//--- ïðåâðàùåíèå äèíàìè÷åñêîãî ìàññèâà â èíäèêàòîðíûé áóôåð
   SetIndexBuffer(1,BuyBuffer,INDICATOR_DATA);
//--- îñóùåñòâëåíèå ñäâèãà íà÷àëà îòñ÷åòà îòðèñîâêè èíäèêàòîðà 2
   PlotIndexSetInteger(1,PLOT_DRAW_BEGIN,min_rates_total);
//--- ñîçäàíèå ìåòêè äëÿ îòîáðàæåíèÿ â DataWindow
   PlotIndexSetString(1,PLOT_LABEL,"ASCtrend Buy");
//--- ñèìâîë äëÿ èíäèêàòîðà
   PlotIndexSetInteger(1,PLOT_ARROW,108);
//--- èíäåêñàöèÿ ýëåìåíòîâ â áóôåðå, êàê â òàéìñåðèè
   ArraySetAsSeries(BuyBuffer,true);
//--- óñòàíîâêà çíà÷åíèé èíäèêàòîðà, êîòîðûå íå áóäóò âèäèìû íà ãðàôèêå
   PlotIndexSetDouble(1,PLOT_EMPTY_VALUE,0);
//--- óñòàíîâêà ôîðìàòà òî÷íîñòè îòîáðàæåíèÿ èíäèêàòîðà
   IndicatorSetInteger(INDICATOR_DIGITS,_Digits);
//--- èìÿ äëÿ îêîí äàííûõ è ìåòêà äëÿ ïîäîêîí
   string short_name="ASCtrend";
   IndicatorSetString(INDICATOR_SHORTNAME,short_name);
//--- çàâåðøåíèå èíèöèàëèçàöèè
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
//--- ïðîâåðêà êîëè÷åñòâà áàðîâ íà äîñòàòî÷íîñòü äëÿ ðàñ÷åòà
   if(BarsCalculated(WPR_Handle[0])<rates_total
      || BarsCalculated(WPR_Handle[1])<rates_total
      || BarsCalculated(WPR_Handle[2])<rates_total
      || rates_total<min_rates_total)
      return(RESET);
//--- îáúÿâëåíèÿ ëîêàëüíûõ ïåðåìåííûõ
   int limit,bar,count,iii;
   double value2,value3,Vel=0,WPR[];
   double TrueCount,Range,AvgRange,MRO1,MRO2;
//--- ðàñ÷åòû íåîáõîäèìîãî êîëè÷åñòâà êîïèðóåìûõ äàííûõ
//--- è ñòàðòîâîãî íîìåðà limit äëÿ öèêëà ïåðåñ÷åòà áàðîâ
   if(prev_calculated>rates_total || prev_calculated<=0)// ïðîâåðêà íà ïåðâûé ñòàðò ðàñ÷åòà èíäèêàòîðà
      limit=rates_total-min_rates_total;   // ñòàðòîâûé íîìåð äëÿ ðàñ÷åòà âñåõ áàðîâ
   else
      limit=rates_total-prev_calculated; // ñòàðòîâûé íîìåð äëÿ ðàñ÷åòà íîâûõ áàðîâ
//--- èíäåêñàöèÿ ýëåìåíòîâ â ìàññèâàõ, êàê â òàéìñåðèÿõ
   ArraySetAsSeries(WPR,true);
   ArraySetAsSeries(open,true);
   ArraySetAsSeries(high,true);
   ArraySetAsSeries(low,true);
   ArraySetAsSeries(close,true);
//--- îñíîâíîé öèêë ðàñ÷åòà èíäèêàòîðà
   for(bar=limit; bar>=0 && !IsStopped(); bar--)
     {
      Range=0.0;
      AvgRange=0.0;
      for(count=bar; count<=bar+9; count++)
         AvgRange=AvgRange+MathAbs(high[count]-low[count]);

      Range=AvgRange/10;
      count=bar;
      TrueCount=0;

      while(count<bar+9 && TrueCount<1)
        {
         if(MathAbs(open[count]-close[count+1])>=Range*2.0)
            TrueCount++;
         count++;
        }

      if(TrueCount>=1)
         MRO1=count;
      else
         MRO1=-1;

      count=bar;
      TrueCount=0;

      while(count<bar+6 && TrueCount<1)
        {
         if(MathAbs(close[count+3]-close[count])>=Range*4.6)
            TrueCount++;
         count++;
        }

      if(TrueCount>=1)
         MRO2=count;
      else
         MRO2=-1;

      if(MRO1>-1)
        {
         value11=0;
        }
      else
        {
         value11=value10;
        }
      if(MRO2>-1)
        {
         value11=1;
        }
      else
        {
         value11=value10;
        }

      if(CopyBuffer(WPR_Handle[value11],0,bar,1,WPR)<=0)
         return(RESET);

      value2=100-MathAbs(WPR[0]); // PercentR(value11=9)

      SellBuffer[bar]=0;
      BuyBuffer[bar]=0;

      value3=0;

      if(value2<x2)
        {
         iii=1;
         while(bar+iii<rates_total)
           {
            if(CopyBuffer(WPR_Handle[value11],0,bar+iii,1,WPR)<=0)
               return(RESET);
            Vel=100-MathAbs(WPR[0]);
            if(Vel>=x2 && Vel<=x1)
               iii++;
            else
               break;
           }

         if(Vel>x1)
           {
            value3=high[bar]+Range*0.5;
            SellBuffer[bar]=value3;
           }
        }
      if(value2>x1)
        {
         iii=1;
         while(bar+iii<rates_total)
           {
            if(CopyBuffer(WPR_Handle[value11],0,bar+iii,1,WPR)<=0)
               return(RESET);
            Vel=100-MathAbs(WPR[0]);
            if(Vel>=x2 && Vel<=x1)
               iii++;
            else
               break;
           }

         if(Vel<x2)
           {
            value3=low[bar]-Range*0.5;
            BuyBuffer[bar]=value3;
           }
        }
     }
//---
   return(rates_total);
  }
//+------------------------------------------------------------------+
