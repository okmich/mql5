//+------------------------------------------------------------------+
//|                         EhlersMotherOfAdaptiveMovingAverages.mq5 |
//|                                Copyright 2020, Andrei Novichkov. |
//|  Main Site: http://fxstill.com                                   |
//|  Telegram:  https://t.me/fxstill (Literature on cryptocurrencies,|
//|                                   development and code. )        |
//+------------------------------------------------------------------+
#property copyright "Copyright 2020, Andrei Novichkov."
#property link      "http://fxstill.com"
#property version   "1.00"
#property description "Telegram Channel: https://t.me/fxstill\n"
#property description "The Mother Of Adaptive Moving Averages:\nJohn Ehlers, \"Rocket Science For Traders\", pg.182-183"

#property indicator_chart_window
#property indicator_applied_price PRICE_MEDIAN

#property indicator_buffers 4
#property indicator_plots   2
//--- plot mama
#property indicator_label1  "mama"
#property indicator_type1   DRAW_COLOR_LINE
#property indicator_color1  clrGreen,clrRed,clrLimeGreen
#property indicator_style1  STYLE_SOLID
#property indicator_width1  2
//--- plot fama
#property indicator_label2  "fama"
#property indicator_type2   DRAW_LINE
#property indicator_color2  clrIndigo
#property indicator_style2  STYLE_SOLID
#property indicator_width2  2
//--- input parameters
input double   FastLimit = 0.5;
input double   SlowLimit = 0.05;
//--- indicator buffers
double         mb[];
double         mc[];
double         fb[];
double         phase[];

static const int MINBAR = 5;

int h;
//+------------------------------------------------------------------+
//| Custom indicator initialization function                         |
//+------------------------------------------------------------------+
int OnInit()
  {

   h = iCustom(NULL,0,"EhlersHilbertTransform");
   if(h == INVALID_HANDLE)
     {
      Print("Error while creating \"EhlersHilbertTransform\"");
      return (INIT_FAILED);
     }
//--- indicator buffers mapping
   SetIndexBuffer(0,mb,INDICATOR_DATA);
   SetIndexBuffer(1,mc,INDICATOR_COLOR_INDEX);
   SetIndexBuffer(2,fb,INDICATOR_DATA);
   SetIndexBuffer(3,phase,INDICATOR_CALCULATIONS);

   ArraySetAsSeries(mb,true);
   ArraySetAsSeries(mc,true);
   ArraySetAsSeries(fb,true);
   ArraySetAsSeries(phase, true);

   IndicatorSetString(INDICATOR_SHORTNAME,"EhlersMotherOfAdaptiveMovingAverages");
   IndicatorSetInteger(INDICATOR_DIGITS,_Digits);

//---
   return INIT_SUCCEEDED;
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void GetValue(const double& price[], int shift)
  {
   double q1[1], i1[1];
   if(CopyBuffer(h, 4, shift, 1, i1) <= 0)
      return;
   if(CopyBuffer(h, 5, shift, 1, q1) <= 0)
      return;

   phase[shift] = (i1[0] != 0)? MathArctan(q1[0] / i1[0]) : 0;
   double deltaPhase = phase[shift + 1] - phase[shift];
   deltaPhase = (deltaPhase < 1)? 1 : deltaPhase;

   double alpha = FastLimit / deltaPhase;
   alpha = (alpha < SlowLimit)? SlowLimit : alpha;

   double m = ZerroIfEmpty(mb[shift + 1]);
   double f = ZerroIfEmpty(fb[shift + 1]);

   mb[shift] = alpha * price[shift] + (1 - alpha) * m;
   fb[shift] = 0.5 * alpha * mb[shift] + (1 - 0.5 * alpha) * f;

   if(mb[shift] < fb[shift])
      mc[shift] = 1 ;
   else
      if(mb[shift] > fb[shift])
         mc[shift] = 2 ;
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
double ZerroIfEmpty(double value)
  {
   if(value >= EMPTY_VALUE || value <= -EMPTY_VALUE)
      return 0.0;
   return value;
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void OnDeinit(const int reason)
  {
   if(h != INVALID_HANDLE)
      IndicatorRelease(h);
  }

//+------------------------------------------------------------------+
//| Custom indicator iteration function                              |
//+------------------------------------------------------------------+
int OnCalculate(const int rates_total,
                const int prev_calculated,
                const int begin,
                const double &price[])
  {
   if(rates_total <= MINBAR)
      return 0;
   ArraySetAsSeries(price,true);
   int limit = rates_total - prev_calculated;
   if(limit == 0)             // Пришел новый тик
     {
     }
   else
      if(limit == 1)      // Образовался новый бар
        {
         GetValue(price, 1);
         return(rates_total);
        }
      else
         if(limit > 1)       // Первый вызов индикатора, смена таймфрейма, подгрузка данных из истории
           {
            ArrayInitialize(mb,   EMPTY_VALUE);
            ArrayInitialize(mc,   0);
            ArrayInitialize(fb,   EMPTY_VALUE);
            ArrayInitialize(phase, 0);
            limit = rates_total - MINBAR;
            for(int i = limit; i >= 1 && !IsStopped(); i--)
              {
               GetValue(price, i);
              }//for(int i = limit + 1; i >= 0 && !IsStopped(); i--)
            return(rates_total);
           }
   GetValue(price, 0);

   return(rates_total);
  }
//+------------------------------------------------------------------+
