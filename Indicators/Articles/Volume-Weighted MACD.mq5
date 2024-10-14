//------------------------------------------------------------------

#property copyright "mladen"
#property link      "www.forex-tsd.com"
// https://www.mql5.com/en/code/16747
//------------------------------------------------------------------

#property indicator_separate_window
#property indicator_buffers 4
#property indicator_plots   2

#property indicator_label1  "Volume-weighted MACD"
#property indicator_type1   DRAW_HISTOGRAM
#property indicator_color1  clrSilver
#property indicator_label2  "Signal"
#property indicator_type2   DRAW_LINE
#property indicator_color2  clrRed
#property indicator_style2  STYLE_DOT

input int       FastPeriod   = 12;       // Fast period
input int       SlowPeriod   = 26;       // Slow period
input int       SignalPeriod =  9;       // Signal period
input ENUM_APPLIED_VOLUME   InpAppliedVolume        = VOLUME_TICK;    // Applied Volume

double macd[];
double signal[];

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
int OnInit()
  {
   SetIndexBuffer(0,macd,INDICATOR_DATA);
   SetIndexBuffer(1,signal,INDICATOR_DATA);

   IndicatorSetString(INDICATOR_SHORTNAME," VEMA MACD ("+string(FastPeriod)+","+string(SlowPeriod)+","+string(SignalPeriod)+")");
   return(0);
  }

double vemas[][6];
#define _numf 0
#define _denf 1
#define _emaf 2
#define _nums 3
#define _dens 4
#define _emas 5

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
int OnCalculate(const int rates_total,
                const int prev_calculated,
                const datetime& time[],
                const double& open[],
                const double& high[],
                const double& low[],
                const double& close[],
                const long& tick_volume[],
                const long& volume[],
                const int& spread[])
  {
   if(ArrayRange(vemas,0)!=rates_total)
      ArrayResize(vemas,rates_total);

   double alphaf = 2.0/(1.0+FastPeriod);
   double alphas = 2.0/(1.0+SlowPeriod);
   double alphag = 2.0/(1.0+SignalPeriod);
   for(int i=(int)MathMax(prev_calculated-1,0); i<rates_total; i++)
     {
      double vol, price = close[i];
      if(InpAppliedVolume == VOLUME_REAL)
         vol = (double)volume[i];
      else
         vol = (double)tick_volume[i];
      if(i<2)
        {
         vemas[i][_numf] = (vol*price);
         vemas[i][_denf] = (vol);
         vemas[i][_nums] = (vol*price);
         vemas[i][_dens] = (vol);
         continue;
        }
      vemas[i][_numf] = vemas[i-1][_numf]+alphaf*(vol*price-vemas[i-1][_numf]);
      vemas[i][_denf] = vemas[i-1][_denf]+alphaf*(vol      -vemas[i-1][_denf]);
      vemas[i][_emaf] = vemas[i][_numf]/vemas[i][_denf];
      vemas[i][_nums] = vemas[i-1][_nums]+alphas*(vol*price-vemas[i-1][_nums]);
      vemas[i][_dens] = vemas[i-1][_dens]+alphas*(vol      -vemas[i-1][_dens]);
      vemas[i][_emas] = vemas[i][_nums]/vemas[i][_dens];

      macd[i]   = vemas[i][_emaf]-vemas[i][_emas];
      signal[i] = signal[i-1]+alphag*(macd[i]-signal[i-1]);
     }
   return(rates_total);
  }
//+------------------------------------------------------------------+
