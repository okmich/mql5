//+------------------------------------------------------------------+
//|                                   MarketFacilitationIndex v1.mq5 |
//|                                    Copyright 2020, Michael Enudi |
//|                                             okmich2002@yahoo.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2020, Michael Enudi"
#property link      "okmich2002@yahoo.com"
#property description "Adaptation of Bill Williams Market Facilitation Index for Automated Trading."
#property description "This indicator defines a low volumn from the historical context and not candle-to-candle"
#property description "MFI up and Volume up (green) => 0"
#property description "MFI down and Volume up (pink) => 1"
#property description "MFI up and Volume down (blue) => 2"
#property description "MFI down and Volume down (brown) => 3"
#property version   "1.00"

#include <Okmich\Common\LogNormalSeries.mqh>

//--- indicator settings
#property indicator_separate_window
#property indicator_buffers 5
#property indicator_plots   2
#property indicator_type1   DRAW_COLOR_HISTOGRAM
#property indicator_color1  Lime,Pink,Blue,SaddleBrown
#property indicator_width1  2
//--- input parameter
input ENUM_APPLIED_VOLUME InpVolumeType=VOLUME_TICK; // Volumes
input int      MAPeriod=90; //Period
input double   MAProbs=0.4; //Volume Threashold (0-1)
//--- indicator buffers
double         ExtMFIBuffer[];
double         ExtColorCatBuffer[];
double         ExtColorBuffer[];
double         VolumeBuffer[];
double         VMABuffer[];
//--- other variables
CLogNormalSeries<double> mLogNormalSeries(MAPeriod);
//+------------------------------------------------------------------+
//| Custom indicator initialization function                         |
//+------------------------------------------------------------------+
int OnInit()
  {
//--- indicator buffers mapping
   SetIndexBuffer(0,ExtMFIBuffer,INDICATOR_DATA);
   SetIndexBuffer(1,ExtColorCatBuffer,INDICATOR_DATA);
   SetIndexBuffer(2,ExtColorBuffer,INDICATOR_COLOR_INDEX);
   SetIndexBuffer(3,VolumeBuffer,INDICATOR_CALCULATIONS);
   SetIndexBuffer(4,VMABuffer,INDICATOR_CALCULATIONS);
//--- indicator short name
   IndicatorSetString(INDICATOR_SHORTNAME, "MFI");

//---- creating label to display in DataWindow
   PlotIndexSetString(0, PLOT_LABEL, "MFI");
   PlotIndexSetString(1, PLOT_LABEL, "Class");

   PlotIndexSetInteger(0,PLOT_DRAW_BEGIN,MAPeriod);

   IndicatorSetInteger(INDICATOR_DIGITS, 3);
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
   if(rates_total < MAPeriod)
      return 0;

   int begin=0;
   if(prev_calculated>MAPeriod)
      begin=prev_calculated-1;
//get volume sorted
   for(int i = begin; i< ArraySize(tick_volume); i++)
     {
      VolumeBuffer[i] = (double)tick_volume[i];
      mLogNormalSeries.Refresh(VolumeBuffer, i, MAPeriod);
      VMABuffer[i] = mLogNormalSeries.QuantileDistribution(MAProbs);
     }

//--- calculate with tick or real volumes
   if(InpVolumeType==VOLUME_TICK)
      CalculateMFI(begin,rates_total,high,low,tick_volume);
   else
      CalculateMFI(begin,rates_total,high,low,volume);

//--- normalize last mfi value
   if(rates_total>1)
     {
      datetime ctm=TimeTradeServer(),lasttm=time[rates_total-1],nexttm=lasttm+datetime(PeriodSeconds());
      if(ctm<nexttm && ctm>=lasttm && nexttm!=lasttm)
        {
         double correction_koef=double(1+ctm-lasttm)/double(nexttm-lasttm);
         ExtMFIBuffer[rates_total-1]*=correction_koef;
        }
     }
   return(rates_total);
  }
//+------------------------------------------------------------------+


//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void CalculateMFI(const int start,const int rates_total,
                  const double &high[],
                  const double &low[],
                  const long &volume[])
  {
   int  i=start;
   bool mfi_up=true,vol_up=true;
//--- calculate first values of mfi_up and vol_up
   if(i>0)
     {
      int n=i;
      while(n>0)
        {
         if(ExtMFIBuffer[n]>ExtMFIBuffer[n-1])
           {
            mfi_up=true;
            break;
           }
         if(ExtMFIBuffer[n]<ExtMFIBuffer[n-1])
           {
            mfi_up=false;
            break;
           }
         //--- if mfi values are equal continue
         n--;
        }
      n=i;
      while(n>0)
        {
         if(VolumeBuffer[n]>VMABuffer[n])
           {
            vol_up=true;
            break;
           }
         if(VolumeBuffer[n]<VMABuffer[n])
           {
            vol_up=false;
            break;
           }
         //--- if real volumes are equal continue
         n--;
        }
     }
//---
   while(i<rates_total && !IsStopped())
     {
      if(volume[i]==0)
         ExtMFIBuffer[i]= i > 0 ? ExtMFIBuffer[i-1] : 0;
      else
         ExtMFIBuffer[i]=(high[i]-low[i])/_Point/volume[i];

      //--- calculate changes
      if(i>0)
        {
         mfi_up=ExtMFIBuffer[i]>ExtMFIBuffer[i-1];
         vol_up=VolumeBuffer[i]>VMABuffer[i];
        }
      //--- set colors
      if(mfi_up && vol_up)
         ExtColorBuffer[i]=0.0;
      if(!mfi_up && vol_up)
         ExtColorBuffer[i]=1.0;
      if(mfi_up && !vol_up)
         ExtColorBuffer[i]=2.0;
      if(!mfi_up && !vol_up)
         ExtColorBuffer[i]=3.0;

      ExtColorCatBuffer[i] = ExtColorBuffer[i];

      i++;
     }
  }
//+------------------------------------------------------------------+
//Lime,Pink,Blue,SaddleBrown
