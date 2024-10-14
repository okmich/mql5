//+------------------------------------------------------------------+
//|                                     Ehlers Leading Indicator.mq5 |
//|                                                    Michael Enudi |
//|                                             okmich2002@yahoo.com |
//+------------------------------------------------------------------+
#property copyright "Michael Enudi"
#property link      "okmich2002@yahoo.com"
#property version   "1.00"
#property description "The Leading Indicator:\nJohn Ehlers, \"Cybernetic Analysis For Stocks And Futures\", pg.235"

#property indicator_chart_window
#property indicator_buffers 3
#property indicator_plots   2
//--- plot NetLead
#property indicator_label1  "NetLead"
#property indicator_type1   DRAW_LINE
#property indicator_color1  clrRoyalBlue
#property indicator_style1  STYLE_SOLID
#property indicator_width1  2
//--- plot Ema
#property indicator_label2  "Ema"
#property indicator_type2   DRAW_LINE
#property indicator_color2  clrRed
#property indicator_style2  STYLE_SOLID
#property indicator_width2  1
//--- input parameters
input double   alpha1=0.25;
input double   alpha2=0.33;
//--- indicator buffers
double         NetLeadBuffer[], EmaBuffer[];
double         LeadBuffer[];
//+------------------------------------------------------------------+
//| Custom indicator initialization function                         |
//+------------------------------------------------------------------+
int OnInit()
  {
//--- indicator buffers mapping
   SetIndexBuffer(0,NetLeadBuffer,INDICATOR_DATA);
   SetIndexBuffer(1,EmaBuffer,INDICATOR_DATA);
   SetIndexBuffer(2,LeadBuffer,INDICATOR_DATA);


//---- initializations of variable for indicator short name
   string shortname;
   StringConcatenate(shortname, "Ehler Leading Indicator(", alpha1, ", ", alpha2, ")");
//---- creating name for displaying in a separate sub-window and in a tooltip
   IndicatorSetString(INDICATOR_SHORTNAME,shortname);

   IndicatorSetInteger(INDICATOR_DIGITS, _Digits);
   //begin showing plots after 12 candles
   PlotIndexSetInteger(0,PLOT_DRAW_BEGIN,12);
   PlotIndexSetInteger(1,PLOT_DRAW_BEGIN,12);
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
//---
   if(rates_total < 2)
      return (0);

   int start = 0;
   if(prev_calculated > 0)
      start = prev_calculated - 1;

   double prevPrice=0, price=0;
   if(start == 0) //first call ever
     {
      LeadBuffer[0] = 0;
      NetLeadBuffer[0] = 0;
      EmaBuffer[0] = 0;
      start++;
     }

   for(int i = start; i < rates_total && !IsStopped(); i++)
     {
      prevPrice = (high[i-1]+low[i-1])/2;
      price = (high[i]+low[i])/2;
      LeadBuffer[i] = 2 * price + (alpha1 - 2) * prevPrice + (1 - alpha1) * LeadBuffer[i-1];
      NetLeadBuffer[i] = alpha2 * LeadBuffer[i] + (1 - alpha2) * NetLeadBuffer[i-1];
      EmaBuffer[i] = 0.5 * price + 0.5 * EmaBuffer[i-1];
     }
//--- return value of prev_calculated for next call
   return(rates_total);
  }
//+------------------------------------------------------------------+
