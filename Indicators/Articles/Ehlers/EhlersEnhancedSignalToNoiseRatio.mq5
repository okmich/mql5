//+------------------------------------------------------------------+
//|                            Ehlers EnhancedSignalToNoiseRatio.mq5 |
//|                                Copyright 2020, Andrei Novichkov. |
//|                                               http://fxstill.com |
//|   Telegram: https://t.me/fxstill (Literature on cryptocurrencies,|
//|                                   development and code. )        |
//+------------------------------------------------------------------+

#property copyright "Copyright 2020, Andrei Novichkov."
#property link      "http://fxstill.com"
#property version   "1.00"
#property description "The Enhanced Signal To Noise Ratio:\nJohn Ehlers, \"Rocket Science for Traders.\", pg.87-88"


#property indicator_separate_window

#property indicator_level1     (double)6
#property indicator_levelstyle STYLE_SOLID

#property indicator_buffers 4
#property indicator_plots   1

#property indicator_type1   DRAW_COLOR_LINE 
#property indicator_width1  2
#property indicator_style1  STYLE_SOLID
#property indicator_color1  clrGreen, clrRed, clrLimeGreen 


double snr[];
double cf[]; 
double q3[], noise[];

int hd;
static int MINBAR = 5;

int OnInit()  {

   hd = iCustom(NULL,0,"EhlersHilbertTransform");
   if (hd == INVALID_HANDLE) {
      Print("Error while creating \"EhlersHilbertTransform\"");
      return (INIT_FAILED);
   }

   SetIndexBuffer(0,snr,INDICATOR_DATA);
   SetIndexBuffer(1,cf,INDICATOR_COLOR_INDEX);
   SetIndexBuffer(2,q3,INDICATOR_CALCULATIONS);
   SetIndexBuffer(3,noise,INDICATOR_CALCULATIONS);
   
   ArraySetAsSeries(snr,true);
   ArraySetAsSeries(cf,true);
   ArraySetAsSeries(q3, true);
   ArraySetAsSeries(noise, true);
   
   IndicatorSetString(INDICATOR_SHORTNAME,"EnhancedSignalToNoiseRatio");
   IndicatorSetInteger(INDICATOR_DIGITS,_Digits);
   
   return(INIT_SUCCEEDED);
}

double GetValue(const double& h[], const double& l[], int shift) {

   double SmoothPeriod[1], Smooth[4];
   if (CopyBuffer(hd, 2,  shift, 3, Smooth)       <= 0) return EMPTY_VALUE;
   if (CopyBuffer(hd, 13, shift, 1, SmoothPeriod) <= 0) return EMPTY_VALUE;
   double hl2 = (h[shift] + l[shift]) / 2;
   
   q3[shift] = 0.5 * (Smooth[0] - Smooth[2]) * (0.1759 * SmoothPeriod[0] + 0.4607);
   double i3 = 0.0;
   int sp = (int)MathCeil(SmoothPeriod[0] / 2);
   if (sp == 0) sp = 1;
   
   for (int i = 0; i < sp; i++) {
       i3 += q3[shift + i];
   }    
   i3 = (1.57 * i3) / sp;
   
   double signal = MathPow(i3, 2) + MathPow(q3[shift], 2);
   
   noise[shift] = 0.1 * MathPow((h[shift] - l[shift]), 2) * 0.25 + 0.9 * noise[shift + 1];
   
   if (noise[shift] != 0.0 && signal != 0) {
      double s = ZerroIfEmpty(snr[shift + 1]);
      snr[shift] = 0.33 * 10 * MathLog(signal / noise[shift]) / MathLog(10) + 0.67 * s;
   } else {
      snr[shift] = 0;
   }
   if (hl2 > Smooth[0])  cf[shift] = 2 ; 
   else
      if (hl2 < Smooth[0])  cf[shift] = 1 ;
 
   return snr[shift];
}

int OnCalculate(const int rates_total,
                const int prev_calculated,
                const datetime &time[],
                const double &open[],
                const double &high[],
                const double &low[],
                const double &close[],
                const long &tick_volume[],
                const long &volume[],
                const int &spread[]) {
      if(rates_total <= 4) return 0;
      ArraySetAsSeries(high,true);    
      ArraySetAsSeries(low,true);
      int limit = rates_total - prev_calculated;
      if (limit == 0)        {   // Пришел новый тик 
      } else if (limit == 1) {   // Образовался новый бар
         GetValue(high, low, 1);      
         return(rates_total);            
      } else if (limit > 1)  {   // Первый вызов индикатора, смена таймфрейма, подгрузка данных из истории
         ArrayInitialize(snr,   EMPTY_VALUE);
         ArrayInitialize(cf,    0);
         ArrayInitialize(q3,    0);
         ArrayInitialize(noise, 0);
         limit = rates_total - MINBAR;
         for(int i = limit; i >= 1 && !IsStopped(); i--){
            GetValue(high, low, i);
         }//for(int i = limit + 1; i >= 0 && !IsStopped(); i--)
         return(rates_total);         
      }
      GetValue(high, low, 0);          
                
   return(rates_total);
}

void OnDeinit(const int reason) {
   if (hd != INVALID_HANDLE)
      IndicatorRelease(hd);
}

double ZerroIfEmpty(double value) {
   if (value >= EMPTY_VALUE || value <= -EMPTY_VALUE) return 0.0;
   return value;
}
