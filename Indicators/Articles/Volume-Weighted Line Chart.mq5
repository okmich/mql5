//+------------------------------------------------------------------+
//|                                                  VWLineChart.mq5 |
//|                        Volume-Weighted Line Chart with Smoothing |
//|                       Source: https://www.mql5.com/en/code/53468 |
//+------------------------------------------------------------------+
#property indicator_chart_window
#property indicator_buffers 3
#property indicator_plots   3

#property indicator_label1 "VW Line Chart"
#property indicator_type1  DRAW_LINE
#property indicator_color1 clrDodgerBlue
#property indicator_width1  2

input int SmoothingPeriod = 5; // Smoothing period
input double SmoothingFactor = 2.0; // Smoothing factor
input ENUM_APPLIED_VOLUME VolumeOption = VOLUME_TICK; // Volume type
input bool UseDynamicSmoothing = true; // Use dynamic smoothing factor
input int ATRPeriod = 14;   // ATR period for dynamic smoothing factor

double MaxSmoothingFactor = 5.0; // Maximum smoothing factor
double MinSmoothingFactor = 2.0; // Minimum smoothing factor

double smoothingFactor = 0;

double VWLineBuffer[];
double atr_buf[];

int atr_handle = INVALID_HANDLE;

//+------------------------------------------------------------------+
//| Custom initialization function                                   |
//+------------------------------------------------------------------+
int OnInit()
  {
   SetIndexBuffer(0, VWLineBuffer, INDICATOR_DATA);
   atr_handle = iATR(Symbol(), 0, ATRPeriod);
   if(atr_handle == INVALID_HANDLE)
     {
      Print("Unable to initialize ATR Indicator");
      return INIT_FAILED;
     }
   ArraySetAsSeries(atr_buf, true);
   return INIT_SUCCEEDED;
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
   int start = prev_calculated > 0 ? prev_calculated - 1 : SmoothingPeriod;

   if(CopyBuffer(atr_handle, 0, 0, 1, atr_buf) < 0)
     {
      Print("Failed to copy ATR values!");
      return 0;
     }

   double atr = atr_buf[0];

   if(UseDynamicSmoothing)
     {
      smoothingFactor = MinSmoothingFactor + (MaxSmoothingFactor - MinSmoothingFactor) * (atr / close[rates_total-1]);
     }
   else
     {
      smoothingFactor = SmoothingFactor;
     }

   double alpha = smoothingFactor / (SmoothingPeriod + 1);

   for(int i = start; i < rates_total; i++)
     {
      // Calculate Volume-Weighted Price
      double vwPrice = 0.0;
      double totalVolume = 0.0;

      for(int j = i - SmoothingPeriod + 1; j <= i; j++)
        {
         if(j < 0)
            continue;

         double currentVolume = (VolumeOption == VOLUME_TICK) ? (double)tick_volume[j] : (double)volume[j];

         vwPrice += close[j] * currentVolume;
         totalVolume += currentVolume;
        }

      if(totalVolume != 0)
         vwPrice /= totalVolume; // sum of (closes * current volume) / current volume

      // Exponential Smoothing
      if(i == start)
         VWLineBuffer[i] = vwPrice;
      else
         VWLineBuffer[i] = VWLineBuffer[i - 1] + alpha * (vwPrice - VWLineBuffer[i - 1]);
     }

   return rates_total;
  }
//+------------------------------------------------------------------+
