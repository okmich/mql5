//+------------------------------------------------------------------+
//|                                Ehlers2PoleButterworthFilter.mq5  |
//|                                Copyright 2020, Andrei Novichkov. |
//|   Site:     http://fxstill.com                                   |
//|   Telegram: https://t.me/fxstill (Literature on cryptocurrencies,| 
//|                                   development and code. )        |
//|  Instagram: https://www.instagram.com/andreifx2020/              |
//+------------------------------------------------------------------+

#property copyright "Copyright 2020, Andrei Novichkov."
#property link      "http://fxstill.com"
#property version   "1.00"
#property icon      "ehlers1.ico"
#property description "The 2 Pole Butterworth Filter:\nJohn Ehlers, \"Cybernetic Analysis For Stocks And Futures\", pg.192 \n \"Cycle Analytics for Traders Advanced Technical Trading Concepts\", pg.32" 

#include "common.mqh"

#property indicator_chart_window


#property indicator_applied_price PRICE_MEDIAN

#property indicator_buffers 2
#property indicator_plots   1

#property indicator_type1   DRAW_COLOR_LINE 
#property indicator_width1  2
#property indicator_style1  STYLE_SOLID
#property indicator_color1  clrGreen, clrRed, clrLimeGreen 

enum STATE {
   Cycle,
   Cybernetic
};

input int length = 15;
input STATE status = Cycle;

double bf[];
double cf[]; 

static const int MINBAR = 5;

double a, b, c1, c2, c3;
int OnInit() {

   SetIndexBuffer(0,bf,INDICATOR_DATA);
   SetIndexBuffer(1,cf,INDICATOR_COLOR_INDEX); 
   ArraySetAsSeries(bf,true);
   ArraySetAsSeries(cf,true); 
   
   IndicatorSetString(INDICATOR_SHORTNAME,"Ehlers2PoleButterworthFilter");
   IndicatorSetInteger(INDICATOR_DIGITS,_Digits);

   switch (status) {
      case Cybernetic:
         a = MathExp(-M_SQRT2 * M_PI / length);
         b = 2 * a * MathCos(M_SQRT2 * M_PI / length);
         c2 = b;
         c3 = - MathPow(a, 2);
         c1 = (1 - c2 - c3) / 4;
         break;
      case Cycle:
         a = MathExp(-M_SQRT2 * M_PI / length);
         b = 2 * a * MathCos(1.25 * M_SQRT2 * M_PI / length);      
         c2 = b;
         c3 = - MathPow(a, 2);
         c1 = 1 - c2 - c3;
         break;   
   }
   
   return(INIT_SUCCEEDED);
}

void GetValue(const double& price[], int shift) {

   double b1 = ZerroIfEmpty(bf[shift + 1]);
   double b2 = ZerroIfEmpty(bf[shift + 2]);
   
   switch (status) {
      case Cybernetic:
         bf[shift] = c1 * (price[shift] + 2 * price[shift + 1] + price[shift + 3]) + 
                     c2 * b1 + c3 * b2;      
         break;
      case Cycle:
         bf[shift] = c1 * price[shift] + c2 * b1 + c3 * b2;
         break;   
   }   
               
   if (bf[shift] < price[shift]) cf[shift] = 2 ; 
   else
      if (bf[shift] > price[shift]) cf[shift] = 1 ;
               
}

int OnCalculate(const int rates_total,
                const int prev_calculated,
                const int begin,
                const double &price[])  {
      if(rates_total <= MINBAR) return 0;
      ArraySetAsSeries(price,true);    
      int limit = rates_total - prev_calculated;
      if (limit == 0)        {   // Пришел новый тик 
      } else if (limit == 1) {   // Образовался новый бар
         GetValue(price, 1);  
         return(rates_total);   
      } else if (limit > 1)  {   // Первый вызов индикатора, смена таймфрейма, подгрузка данных из истории
         ArrayInitialize(bf,EMPTY_VALUE);
         ArrayInitialize(cf,0);
         limit = rates_total - MINBAR;
         for(int i = limit; i >= 1 && !IsStopped(); i--){
            GetValue(price, i);
         }//for(int i = limit + 1; i >= 0 && !IsStopped(); i--)
         return(rates_total);         
      }
      GetValue(price, 0);          
      return(rates_total);
}
