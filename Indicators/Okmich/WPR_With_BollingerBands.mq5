//+------------------------------------------------------------------+
//|                                      WPR_With_BollingerBands.mq5 |
//|                             Copyright 2023, okmich2002@yahoo.com |
//|                               https://www.mql5.com/en/code/32695 |
//+------------------------------------------------------------------+
#property copyright "Copyright 2023, okmich2002@yahoo.com"
#property link      "https://www.mql5.com/en/code/32695"
#property version   "1.00"
#property indicator_separate_window
//---
#property indicator_separate_window
#property indicator_buffers 4
#property indicator_plots   4
#property indicator_type1   DRAW_LINE
#property indicator_color1  clrAqua
#property indicator_width1  2
#property indicator_type2   DRAW_LINE
#property indicator_color2  LightSeaGreen
#property indicator_type3   DRAW_LINE
#property indicator_color3  LightSeaGreen
#property indicator_type4   DRAW_LINE
#property indicator_color4  LightSeaGreen
#property indicator_label1  "WPR"
#property indicator_label2  "Bands middle"
#property indicator_label3  "Bands upper"
#property indicator_label4  "Bands lower"
#property indicator_level1 -20
#property indicator_level2 -80
//--- input parametrs
input int     InpWprPeriod=14;         //WPR Period
input int     InpBandsPeriod=20;       //BB Period
input double  InpBandsDeviations=2.0;  //BB Deviation
//--- global variables
int           ExtWprPeriod, ExtBandsPeriod;
double        ExtBandsDeviations;
int           ExtPlotBegin=0;
//--- indicator buffer
double        ExtWPRBuffer[], ExtTLBuffer[], ExtMLBuffer[], ExtBLBuffer[];

int           WprHandle, BBHandle;
double        alphaSignal;
//+------------------------------------------------------------------+
//| Custom indicator initialization function                         |
//+------------------------------------------------------------------+
void OnInit()
  {
//--- check for input values
   if(InpWprPeriod<2)
     {
      ExtWprPeriod=14;
      PrintFormat("Incorrect value for input variable InpWprPeriod=%d. Indicator will use value=%d for calculations.",InpWprPeriod,ExtWprPeriod);
     }
   else
      ExtWprPeriod=InpWprPeriod;
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
//--- define buffers
   SetIndexBuffer(0,ExtWPRBuffer);
   SetIndexBuffer(1,ExtTLBuffer);
   SetIndexBuffer(2,ExtMLBuffer);
   SetIndexBuffer(3,ExtBLBuffer);

//--- set index labels
   PlotIndexSetString(0,PLOT_LABEL,"RSI("+string(ExtWprPeriod)+")");
   PlotIndexSetString(1,PLOT_LABEL,"Bands("+string(ExtBandsPeriod)+") Middle");
   PlotIndexSetString(2,PLOT_LABEL,"Bands("+string(ExtBandsPeriod)+") Upper");
   PlotIndexSetString(3,PLOT_LABEL,"Bands("+string(ExtBandsPeriod)+") Lower");
//--- indicator name
   IndicatorSetString(INDICATOR_SHORTNAME,"RSI+Bollinger Bands");
//--- indexes draw begin settings
   ExtPlotBegin=ExtBandsPeriod+ExtWprPeriod;
   PlotIndexSetInteger(0,PLOT_DRAW_BEGIN,ExtPlotBegin);
   PlotIndexSetInteger(1,PLOT_DRAW_BEGIN,ExtPlotBegin);
   PlotIndexSetInteger(2,PLOT_DRAW_BEGIN,ExtPlotBegin);
   PlotIndexSetInteger(3,PLOT_DRAW_BEGIN,ExtPlotBegin);
//--- number of digits of indicator value
   IndicatorSetInteger(INDICATOR_DIGITS,2);

   WprHandle = iWPR(_Symbol, _Period, ExtWprPeriod);
   BBHandle = iBands(_Symbol, _Period, ExtBandsPeriod, 0, ExtBandsDeviations, WprHandle);
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

   if(!FillArrayFromBuffer(ExtWPRBuffer,0,WprHandle,limit,0))
      return(rates_total);
   if(!FillArrayFromBuffer(ExtMLBuffer,0,BBHandle,limit,0))
      return(rates_total);
   if(!FillArrayFromBuffer(ExtTLBuffer,0,BBHandle,limit,1))
      return(rates_total);
   if(!FillArrayFromBuffer(ExtBLBuffer,0,BBHandle,limit,2))
      return(rates_total);

//--- OnCalculate done. Return new prev_calculated.
   return(rates_total);
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
bool IndicatorsOk(int rates)
  {
   if(BarsCalculated(WprHandle)<rates)
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
