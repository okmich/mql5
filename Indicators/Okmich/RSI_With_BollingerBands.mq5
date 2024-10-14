//+------------------------------------------------------------------+
//|                                      RSI_With_BollingerBands.mq5 |
//|                                    Copyright 2023, Michael Enudi |
//|                                             okmich2002@yahoo.com |
//+------------------------------------------------------------------+
#property copyright   "Copyright 2023, Michael Enudi"
#property link        "okmich2002@yahoo.com"
#property description "Rsi With Bollinger Bands"
//---
#property indicator_separate_window
#property indicator_buffers 5
#property indicator_plots   5
#property indicator_type1   DRAW_LINE
#property indicator_color1  clrDodgerBlue
#property indicator_width1  2
#property indicator_type2   DRAW_LINE
#property indicator_color2  LightSeaGreen
#property indicator_type3   DRAW_LINE
#property indicator_color3  LightSeaGreen
#property indicator_type4   DRAW_LINE
#property indicator_color4  LightSeaGreen
#property indicator_type5   DRAW_LINE
#property indicator_style5  STYLE_DOT
#property indicator_color5  clrSilver
#property indicator_label1  "RSI"
#property indicator_label2  "Bands middle"
#property indicator_label3  "Bands upper"
#property indicator_label4  "Bands lower"
#property indicator_label5  "RSI MA"
#property indicator_level1 30
#property indicator_level2 70
//--- input parametrs
input int     InpRsiPeriod=14;         //RSI Period
input int     InpBandsPeriod=20;       // BB Period
input double  InpBandsDeviations=2.0;  // BB Deviation
input int     InpRsiMaPeriod=7;      // RSI Signal
//--- global variables
int           ExtRsiPeriod, ExtBandsPeriod, ExtRsiMaPeriod;
double        ExtBandsDeviations;
int           ExtPlotBegin=0;
//--- indicator buffer
double        ExtRSIBuffer[], ExtTLBuffer[], ExtMLBuffer[], ExtBLBuffer[], ExtRsiSignalBuffer[];

int           RsiHandle, BBHandle;
double        alphaSignal;
//+------------------------------------------------------------------+
//| Custom indicator initialization function                         |
//+------------------------------------------------------------------+
void OnInit()
  {
//--- check for input values
   if(InpRsiPeriod<2)
     {
      ExtRsiPeriod=14;
      PrintFormat("Incorrect value for input variable InpRsiPeriod=%d. Indicator will use value=%d for calculations.",InpRsiPeriod,ExtRsiPeriod);
     }
   else
      ExtRsiPeriod=InpRsiPeriod;
   if(InpBandsPeriod<2)
     {
      ExtBandsPeriod=20;
      PrintFormat("Incorrect value for input variable InpBandsPeriod=%d. Indicator will use value=%d for calculations.",InpBandsPeriod,ExtBandsPeriod);
     }
   else
      ExtBandsPeriod=InpBandsPeriod;
   if(InpBandsDeviations==0.0)
     {
      ExtBandsDeviations=2.0;
      PrintFormat("Incorrect value for input variable InpBandsDeviations=%f. Indicator will use value=%f for calculations.",InpBandsDeviations,ExtBandsDeviations);
     }
   else
      ExtBandsDeviations=InpBandsDeviations;
   if(InpRsiMaPeriod <= 0.0)
     {
      ExtRsiMaPeriod=2.0;
      PrintFormat("Incorrect value for input variable InpRsiMaPeriod=%f. Indicator will use value=%f for calculations.",InpRsiMaPeriod,ExtRsiMaPeriod);
     }
   else
      ExtRsiMaPeriod=InpRsiMaPeriod;
//--- define buffers
   SetIndexBuffer(0,ExtRSIBuffer);
   SetIndexBuffer(1,ExtTLBuffer);
   SetIndexBuffer(2,ExtMLBuffer);
   SetIndexBuffer(3,ExtBLBuffer);
   SetIndexBuffer(4, ExtRsiSignalBuffer);

//--- set index labels
   PlotIndexSetString(0,PLOT_LABEL,"RSI("+string(ExtRsiPeriod)+")");
   PlotIndexSetString(1,PLOT_LABEL,"Bands("+string(ExtBandsPeriod)+") Upper");
   PlotIndexSetString(2,PLOT_LABEL,"Bands("+string(ExtBandsPeriod)+") Middle");
   PlotIndexSetString(3,PLOT_LABEL,"Bands("+string(ExtBandsPeriod)+") Lower");
   PlotIndexSetString(4,PLOT_LABEL,"RSI MA("+string(ExtRsiMaPeriod)+")");
//--- indicator name
   IndicatorSetString(INDICATOR_SHORTNAME,"RSI+Bollinger Bands");
//--- indexes draw begin settings
   ExtPlotBegin=ExtBandsPeriod+ExtRsiPeriod+ExtRsiMaPeriod;
   PlotIndexSetInteger(0,PLOT_DRAW_BEGIN,ExtPlotBegin);
   PlotIndexSetInteger(1,PLOT_DRAW_BEGIN,ExtPlotBegin);
   PlotIndexSetInteger(2,PLOT_DRAW_BEGIN,ExtPlotBegin);
   PlotIndexSetInteger(3,PLOT_DRAW_BEGIN,ExtPlotBegin);
   PlotIndexSetInteger(4,PLOT_DRAW_BEGIN,ExtPlotBegin);
//--- number of digits of indicator value
   IndicatorSetInteger(INDICATOR_DIGITS,2);

   alphaSignal = 2.0/(1.0+ExtRsiMaPeriod);
   RsiHandle = iRSI(_Symbol, _Period, ExtRsiPeriod, _AppliedTo);
   BBHandle = iBands(_Symbol, _Period, ExtBandsPeriod, 0, ExtBandsDeviations, RsiHandle);
  }
//+------------------------------------------------------------------+
//| Bollinger Bands                                                  |
//+------------------------------------------------------------------+
int OnCalculate(const int rates_total,
                const int prev_calculated,
                const int begin,
                const double &price[])
  {
   if(rates_total < ExtPlotBegin)
      return(0);

   if(!SymbolIsSynchronized(_Symbol) || rates_total<0 || !IndicatorsOk(rates_total))
      return(0);

   int limit = MathMin(rates_total-prev_calculated+1,rates_total-1);

   if(!FillArrayFromBuffer(ExtRSIBuffer,0,RsiHandle,limit,0))
      return(rates_total);
   if(!FillArrayFromBuffer(ExtMLBuffer,0,BBHandle,limit,0))
      return(rates_total);
   if(!FillArrayFromBuffer(ExtTLBuffer,0,BBHandle,limit,1))
      return(rates_total);
   if(!FillArrayFromBuffer(ExtBLBuffer,0,BBHandle,limit,2))
      return(rates_total);

//signal line
   int start = (prev_calculated == 0) ? ExtPlotBegin : prev_calculated - 1;
   for(int i = limit; i < rates_total && !IsStopped(); i++)
     {
      ExtRsiSignalBuffer[i] = (i == ExtPlotBegin) ? ExtRSIBuffer[i] :
                              ExtRsiSignalBuffer[i-1] + alphaSignal * (ExtRSIBuffer[i] - ExtRsiSignalBuffer[i-1]);
     }

//--- OnCalculate done. Return new prev_calculated.
   return(rates_total);
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
bool IndicatorsOk(int rates)
  {
   if(BarsCalculated(RsiHandle)<rates)
      return(false);
   if(BarsCalculated(BBHandle)<rates)
      return(false);
   return(true);
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
bool FillArrayFromBuffer(double &values[],   // indicator buffer of indicator values
                         int shift,          // shift
                         int ind_handle,     // handle of the indicator
                         int amount,         // number of copied values
                         int buffer          // buffer number
                        )
  {
   ResetLastError();
   if(CopyBuffer(ind_handle,buffer,shift,amount,values)<0)
     {
      PrintFormat("Failed to copy data from the indicator handle, error code %d",GetLastError());
      return(false);
     }
   return(true);
  }
//+------------------------------------------------------------------+
