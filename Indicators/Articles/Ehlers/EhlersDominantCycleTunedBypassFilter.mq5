//+------------------------------------------------------------------+
//|                         EhlersDominantCycleTunedBypassFilter.mq5 |
//|                                Copyright 2020, Andrei Novichkov. |
//|                                               http://fxstill.com |
//|   Telegram: https://t.me/fxstill (Literature on cryptocurrencies,|
//|                                   development and code. )        |
//+------------------------------------------------------------------+
#property copyright "Copyright 2020, Andrei Novichkov."
#property link      "http://fxstill.com"
#property version   "1.00"

#property description "The Dominant Cycle Tuned Bypass Filter:\nJohn Ehlers, \"Stocks & Commodities V. 26:3 (16-22)\""

#property indicator_applied_price PRICE_MEDIAN

#property indicator_separate_window

#property indicator_buffers 5
#property indicator_plots   2
//--- plot V1
#property indicator_label1  "V1"
#property indicator_type1   DRAW_LINE
#property indicator_color1  clrRed
#property indicator_style1  STYLE_SOLID
#property indicator_width1  1
//--- plot V2
#property indicator_label2  "V2"
#property indicator_type2   DRAW_LINE
#property indicator_color2  clrDodgerBlue
#property indicator_style2  STYLE_SOLID
#property indicator_width2  1
//--- input parameters
input int      minperiod=8;        //MinPeriod
input int      maxperiod=50;       //MaxPeriod
input int      hpPeriod=40;        //HpPeriod
input int      medianPeriod=10;    //MedianPeriod 
input int      decibelPeriod=20;   //DecibelPeriod
//--- indicator buffers
double         v1[];
double         v2[];
double smoothHp[], hp[], dc[];//real[], imag[], dc[], hp[], q1[];

double Q[];
double I[];
double Real[];
double Imag[];
double Ampl[];
double OldQ[];
double OldI[];
double OlderQ[];
double OlderI[];
double OldReal[];
double OldImag[];
double OlderReal[];
double OlderImag[];
double OldAmpl[];
double DB[];


static const int MINBAR = maxperiod + 1;
double a1, a2;
//+------------------------------------------------------------------+
//| Custom indicator initialization function                         |
//+------------------------------------------------------------------+
int OnInit()
  {
//--- indicator buffers mapping
   SetIndexBuffer(0,v1,INDICATOR_DATA);
   SetIndexBuffer(1,v2,INDICATOR_DATA);
   SetIndexBuffer(2,smoothHp,INDICATOR_CALCULATIONS);
//   SetIndexBuffer(3,real,INDICATOR_CALCULATIONS);
//   SetIndexBuffer(4,imag,INDICATOR_CALCULATIONS);
   SetIndexBuffer(3,dc,INDICATOR_CALCULATIONS);
   SetIndexBuffer(4,hp,INDICATOR_CALCULATIONS);
//   SetIndexBuffer(7,q1,INDICATOR_CALCULATIONS);
//SetIndexBuffer(5,dc,INDICATOR_DATA);
//SetIndexBuffer(5,dc,INDICATOR_DATA);
//SetIndexBuffer(5,dc,INDICATOR_DATA);   
   
   ArraySetAsSeries(v1,true);
   ArraySetAsSeries(v2,true);    
   ArraySetAsSeries(smoothHp,true); 
//   ArraySetAsSeries(real,true); 
//   ArraySetAsSeries(imag,true); 
   ArraySetAsSeries(dc,true); 
   ArraySetAsSeries(hp,true); 
//   ArraySetAsSeries(q1,true); 
//ArraySetAsSeries(dc,true); 
//ArraySetAsSeries(dc,true); 
//ArraySetAsSeries(dc,true);    

//---
   IndicatorSetString(INDICATOR_SHORTNAME,"EhlersDominantCycleTunedBypassFilter");
   IndicatorSetInteger(INDICATOR_DIGITS,_Digits);     

   a1 = (1 - MathSin(2 * M_PI / hpPeriod)) / MathCos(2 * M_PI / hpPeriod);
   a2 = 0.5 * (1 + a1);
   InitArrays();
   
   return(INIT_SUCCEEDED);
  }
void InitArrays(){
   ArrayResize(Q, maxperiod + 1);
   ArraySetAsSeries(Q, true); 
   ArrayInitialize(Q, 0);
   ArrayResize(I, maxperiod + 1);
   ArraySetAsSeries(I, true);
   ArrayInitialize(I, 0);    
   ArrayResize(Real, maxperiod + 1);
   ArraySetAsSeries(Real, true);
   ArrayInitialize(Real, 0);    
   ArrayResize(Imag, maxperiod + 1);
   ArraySetAsSeries(Imag, true);
   ArrayInitialize(Imag, 0);    
   ArrayResize(Ampl, maxperiod + 1);
   ArraySetAsSeries(Ampl, true);
   ArrayInitialize(Ampl, 0);    
   ArrayResize(OldQ, maxperiod + 1);
   ArraySetAsSeries(OldQ, true);
   ArrayInitialize(OldQ, 0);    
   ArrayResize(OldI, maxperiod + 1);
   ArraySetAsSeries(OldI, true);
   ArrayInitialize(OldI, 0);    
   ArrayResize(OlderQ, maxperiod + 1);
   ArraySetAsSeries(OlderQ, true);
   ArrayInitialize(OlderQ, 0);    
   ArrayResize(OlderI, maxperiod + 1);
   ArraySetAsSeries(OlderI, true);
   ArrayInitialize(OlderI, 0);    
   ArrayResize(OldReal, maxperiod + 1);
   ArraySetAsSeries(OldReal, true);
   ArrayInitialize(OldReal, 0);    
   ArrayResize(OldImag, maxperiod + 1);
   ArraySetAsSeries(OldImag, true);
   ArrayInitialize(OldImag, 0);    
   ArrayResize(OlderReal, maxperiod + 1);
   ArraySetAsSeries(OlderReal, true);
   ArrayInitialize(OlderReal, 0);    
   ArrayResize(OlderImag, maxperiod + 1);
   ArraySetAsSeries(OlderImag, true);
   ArrayInitialize(OlderImag, 0);    
   ArrayResize(OldAmpl, maxperiod + 1);
   ArraySetAsSeries(OldAmpl, true);
   ArrayInitialize(OldAmpl, 0);    
   ArrayResize(DB, maxperiod + 1);
   ArraySetAsSeries(DB, true);
   ArrayInitialize(DB, 0);    
}  
void GetValue(const double& price[], int shift) {

   hp[shift] =  a2 * (price[shift] - price[shift + 1]) + a1 * hp[shift + 1];
   smoothHp[shift] = (hp[shift] + 2 * hp[shift + 1] + 3 * hp[shift + 2] +        
                  3 * hp[shift + 3] + 2 * hp[shift + 4] + hp[shift + 5]) / 12;
   double delta = -0.015 * shift + 0.5;
   if (delta < 0.15) delta =  0.15;
   
   double /*ampl = 0.0, db = 0.0, */num = 0.0, denom = 0.0; 
   double maxAmpl = 0.0;
   double s1 = smoothHp[shift] - smoothHp[shift + 1];
   double beta, gamma, alpha;
   for (int n = minperiod; n <= maxperiod; n++) {
      beta = MathCos(2 * M_PI / n);
      gamma = 1 / MathCos(4 * M_PI * delta / n);
      alpha = gamma - MathSqrt(MathPow(gamma, 2) - 1);
      Q[n] = (n / 6.283185) * s1;
      I[n] = smoothHp[shift];
      Real[n] = 0.5 * (1 - alpha) * (I[n] - OlderI[n]) + beta * (1+ alpha) * OldReal[n] - alpha * OlderReal[n];
      Imag[n] = 0.5 * (1 - alpha)  * (Q[n] - OlderQ[n]) + beta * (1 + alpha) * OldImag[n] - alpha * OlderImag[n];
      Ampl[n] = MathPow(Real[n], 2) + MathPow(Imag[n], 2);   
   }//for (int n = minperiod; n <= maxperiod; n++)  
   
   double   MaxAmpl = Ampl[medianPeriod];
   for (int n = minperiod; n <= maxperiod; n++) {
      OlderI[n] = OldI[n];
      OldI[n] = I[n];
      OlderQ[n] = OldQ[n];
      OldQ[n] = Q[n];
      OlderReal[n] = OldReal[n];
      OldReal[n] = Real[n];
      OlderImag[n] = OldImag[n];
      OldImag[n] = Imag[n];
      OldAmpl[n] = Ampl[n];
      if(Ampl[n] > MaxAmpl) MaxAmpl = Ampl[n];
   }    
   for(int n = minperiod; n <= maxperiod; n++) {
      if(MaxAmpl != 0 && (Ampl[n] / MaxAmpl) > 0)
         DB[n] = -medianPeriod * MathLog(.01 / (1 - 0.99 * Ampl[n] / MaxAmpl)) / MathLog(10);
      if(DB[n] > decibelPeriod) DB[n] = decibelPeriod;
      
      if(DB[n] <= 3) {
         num   = num   + n * (decibelPeriod - DB[n]);
         denom = denom +     (decibelPeriod - DB[n]);
      }
            
   } 
   if(denom != 0) dc[shift] = num / denom;  
   double domCyc = MathMedian(dc, shift, medianPeriod);
   if (domCyc < minperiod) domCyc = decibelPeriod;
   beta = MathCos(2 * M_PI / domCyc);
   gamma = 1 / MathCos(4 * M_PI * delta / domCyc);
   alpha = gamma - MathSqrt(MathPow(gamma, 2) - 1);
   
   double va1 = ZerroIfEmpty(v1[shift + 1]);
   double va2 = ZerroIfEmpty(v1[shift + 2]);

   v1[shift] = 0.5 * (1 - alpha) * (smoothHp[shift] - smoothHp[shift + 1]) + 
              beta * (1 + alpha) * va1 - alpha * va2;
   v2[shift] = (domCyc / 6.28) * (v1[shift] - va1);     
}  

  
//+------------------------------------------------------------------+
//| Custom indicator iteration function                              |
//+------------------------------------------------------------------+
int OnCalculate(const int rates_total,
                const int prev_calculated,
                const int begin,
                const double &price[])
  {
      if(rates_total < MINBAR) return 0;
      ArraySetAsSeries(price,true); 
      int limit = rates_total - prev_calculated;
      if (limit == 0)        {   // Пришел новый тик 
      } else if (limit == 1) {   // Образовался новый бар
         GetValue(price, 1);
         return(rates_total);         
      } else if (limit > 1)  {   // Первый вызов индикатора, смена таймфрейма, подгрузка данных из истории
         ArrayInitialize(v1,   EMPTY_VALUE);
         ArrayInitialize(v2,   EMPTY_VALUE);
         ArrayInitialize(smoothHp,    0);
         ArrayInitialize(dc, 0);
         ArrayInitialize(hp, 0);
         limit = rates_total - MINBAR;
         for(int i = limit; i >= 1 && !IsStopped(); i--){
            GetValue(price, i);
         }//for(int i = limit + 1; i >= 0 && !IsStopped(); i--)
         return(rates_total);         
      }
      GetValue(price, 0);          

   return(rates_total);
  }

double ZerroIfEmpty(double value) {
   if (value >= EMPTY_VALUE || value <= -EMPTY_VALUE) return 0.0;
   return value;
}

double MathMedian(double &array[], int start, int count = WHOLE_ARRAY) {
   int size = ArraySize(array);
   if(size < count) return EMPTY_VALUE;
   double sorted_values[];
   if(ArrayCopy(sorted_values, array, 0, start, count) != count)   return EMPTY_VALUE;
   
   ArraySort(sorted_values);
   size = ArraySize(sorted_values);
   if(size % 2 == 1)
      return(sorted_values[size / 2]);
   else
   return (0.5 * (sorted_values[(size - 1) / 2] + sorted_values[(size + 1) / 2]));
}// double MathMedian(double &array[], int start, int count = WHOLE_ARRAY)