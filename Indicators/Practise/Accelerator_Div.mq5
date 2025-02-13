//+------------------------------------------------------------------+
//|                                              Accelerator_Div.mq5 |
//|                        Copyright 2017, MetaQuotes Software Corp. |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2017, MetaQuotes Software Corp."
#property link      "https://www.mql5.com"
#property version   "1.00"
#property indicator_separate_window
//---- One buffer is used for calculating and drawing the indicator
#property indicator_buffers 2
//---- Only one graphical construction is used
#property indicator_plots   1
//---- The indicator is drawn as a line
#property indicator_type1   DRAW_COLOR_HISTOGRAM
//---- Blue color is used for the indicator line
#property indicator_color1  Green,Red
//----
#property indicator_width1  2
//---- The indicator line is a continuous curve
#property indicator_style1  STYLE_SOLID
//---- Displaying the indicator label
#property indicator_label1  "AC_Div"
//+------------------------------------------------------------------+
input  int     Bars_Calculated=1000;
//+------------------------------------------------------------------+
string shortname="";
double AC_buff[];
double Color_buff[];
int wid;
int Handle_AC;
//---
#define DATA_LIMIT 37
//+------------------------------------------------------------------+
//| Custom indicator initialization function                         |
//+------------------------------------------------------------------+
int OnInit()
  {
//---- Setting dynamic arrays as the indicator buffer
   SetIndexBuffer(0,AC_buff,INDICATOR_DATA);
   SetIndexBuffer(1,Color_buff,INDICATOR_COLOR_INDEX);
//---- Setting the position, from which the indicator drawing starts
   PlotIndexSetInteger(1,PLOT_DRAW_BEGIN,DATA_LIMIT);
//---- initializations of a variable for indicator short name
   shortname="Accelerator_Divergence";
//---- Creating a name for displaying in a separate subwindow and in a tooltip
   IndicatorSetString(INDICATOR_SHORTNAME,shortname);
//---- Defining the accuracy of displaying indicator values
   IndicatorSetInteger(INDICATOR_DIGITS,_Digits);
//---- Disabling drawing of empty indicator values
   PlotIndexSetDouble(0, PLOT_EMPTY_VALUE, 0.0);
   PlotIndexSetDouble(1, PLOT_EMPTY_VALUE, 0.0);
//--- Forming the handle of the Accelerator indicator
   Handle_AC=iAC(NULL,0);
//--- Indicator subwindow number
   wid=ChartWindowFind(0,shortname);
//---
   return(INIT_SUCCEEDED);
  }
//+------------------------------------------------------------------+
void OnDeinit(const int reason)
  {
   ObjectsDeleteAll(0,shortname);
   Comment("");
  }
//+------------------------------------------------------------------+
//| Custom indicator iteration function                              |
//+------------------------------------------------------------------+
int OnCalculate(
                const int rates_total,      // size of input time series
                const int prev_calculated,  // processed bars at the previous call  
                const datetime& time[],     // Time
                const double& open[],       // Open
                const double& high[],       // High
                const double& low[],        // Low
                const double& close[],      // Close
                const long& tick_volume[],  // Tick Volume
                const long& volume[],       // Real Volume
                const int& spread[]         // Spread

                )
  {
//---- Declaring local variables 
   int limit,bar,pos;
//---- Check if the number of bars is sufficient for calculations
   if(rates_total<DATA_LIMIT)
      return(0);
   int barsCalculated=MathMin(Bars_Calculated,rates_total);
//+------- Setting the array indexing direction ---------------------+
   ArraySetAsSeries(close,true);
   ArraySetAsSeries(AC_buff,true);
   ArraySetAsSeries(low,true);
   ArraySetAsSeries(high,true);
   ArraySetAsSeries(Color_buff,true);
   ArraySetAsSeries(time,true);
//+--- Determining the number of bars needed for calculation --------+
   limit=rates_total-DATA_LIMIT-1;
   if(prev_calculated>0) limit=rates_total-prev_calculated;
   pos=limit;
   if(pos>barsCalculated)pos=limit;
   int to_copy;
   if(prev_calculated>rates_total || prev_calculated<0) to_copy=rates_total;
   else
     {
      to_copy=rates_total-prev_calculated;
      if(prev_calculated>0) to_copy++;
     }
//---
   if(IsStopped()) return(0); //Checking for stop flag
//+----- Forming the main array -------------------------------------+
   if(CopyBuffer(Handle_AC,0,0,to_copy,AC_buff)<=0)
     {
      Print("getting Accelerator Handle is failed! Error",GetLastError());
      return(0);
     }
//+---------- Coloring the histogram --------------------------------+
   for(bar=limit; bar>=0 && !IsStopped(); bar--)
     {
      Color_buff[bar]=0.0;
      if(AC_buff[bar]<AC_buff[bar+1])Color_buff[bar] =1.0;
      if(AC_buff[bar]>AC_buff[bar+1])Color_buff[bar] =0.0;
     }
//+----------- Detecting UP divergences ------------------------------+
   int bars=barsCalculated;
   for(bar=pos; bar>=0 && !IsStopped(); bar--)
     {
      int l=bar+2;
      if(Extremum(AC_buff[l+1],AC_buff[l],AC_buff[l-1])<0)
        {
         int i=l;
         int counted=LastPeak(l,bars,AC_buff);
         if(counted!=-1)
           {
            if(AC_buff[i]<AC_buff[counted] && high[i]>high[counted])
              {
               DrawPriceTrendLine(time[i],time[counted],high[i],high[counted],Red,STYLE_SOLID);
               DrawIndicatorTrendLine(time[i],time[counted],AC_buff[i],AC_buff[counted],Red,STYLE_SOLID);
              }

            if(AC_buff[i]>AC_buff[counted] && high[i]<high[counted])
              {
               DrawPriceTrendLine(time[i],time[counted],high[i],high[counted],Red,STYLE_DOT);
               DrawIndicatorTrendLine(time[i],time[counted],AC_buff[i],AC_buff[counted],Red,STYLE_DOT);
              }
           }
        }
//+----------- Detecting DN divergences ------------------------------+
      if(Extremum(AC_buff[l+1],AC_buff[l],AC_buff[l-1])>0)
        {
         int i=l;
         int counted=LastTrough(l,bars,AC_buff);
         if(counted!=-1)
           {
            if(AC_buff[i]>AC_buff[counted] && low[i]<low[counted])
              {
               DrawPriceTrendLine(time[i],time[counted],low[i],low[counted],Green,STYLE_SOLID);
               DrawIndicatorTrendLine(time[i],time[counted],AC_buff[i],AC_buff[counted],Green,STYLE_SOLID);
              }
            if(AC_buff[i]<AC_buff[counted] && low[i]>low[counted])
              {
               DrawPriceTrendLine(time[i],time[counted],low[i],low[counted],Green,STYLE_DOT);
               DrawIndicatorTrendLine(time[i],time[counted],AC_buff[i],AC_buff[counted],Green,STYLE_DOT);
              }
           }
        }
     }
//--- return value of prev_calculated for next call
   return(rates_total);
  }
//+----- Search for the second UP extremum --------------------------+
int LastPeak(int l,int bar,double &buf[]) 
  {
   for(int i=l+5; i<bar-2; i++)
      if(Extremum(buf[i+1],buf[i],buf[i-1])<0)return (i);
   return (-1);
  }
//+----- Search for the second DN extremum --------------------------+
int LastTrough(int l,int bar,double &buf[])
  {
   for(int i=l+5; i<bar-2; i++)
      if(Extremum(buf[i+1],buf[i],buf[i-1])> 0)return (i);
   return (-1);
  }
//+-- Search for extrema -------------------------------------------+
int Extremum(double a,double b,double c)
  {
   if((a-b)*(b-c)<0)
     {
      if(c>b && b<0) return(1); //DN extremum
      if(c<b && b>0) return(-1);//UP extremum
     }
   return(0);
  }
//+------ Creating objects on the price chart -----------------------+
void DrawPriceTrendLine(datetime T_0,
                        datetime T_1,
                        double P_0,
                        double P_1,
                        color color_0,
                        int style)
  {
   string name_2=shortname+DoubleToString(T_0,0);
   string name_0;
   name_0=shortname+"Line_Sn"+ColorToString(color_0);
//--- 
   if(ObjectFind(0,name_2)<0)
      drawLineS(name_2,T_0,T_1,P_0,P_1,color_0,style,0,true,false,0);
//+-----------+
   if(style==STYLE_DOT)
      drawLineS(name_0,T_1,T_0,P_1,P_0,clrAqua,0,3,true,true,0);
  }
//+------ Creating objects in the indicator window ------------------+
void DrawIndicatorTrendLine(datetime T_0,
                            datetime T_1,
                            double P_0,
                            double P_1,
                            color color_0,
                            int style)
  {
   string name_1,name_0;
   int window= wid;
   name_1 = shortname+DoubleToString(T_0+wid,0);
   if(ObjectFind(0,name_1)<0)
      drawLineS(name_1,T_0,T_1,P_0,P_1,color_0,style,0,false,false,window);
//---
   if(style==STYLE_SOLID)
     {
      name_0=shortname+"Line_Pn"+ColorToString(color_0);
      drawLineS(name_0,T_1,T_0,P_1,P_0,clrMagenta,style,2,true,true,window);
     }
  }
//+------------------------------------------------------------------+
void drawLineS(string name,
               datetime t0,
               datetime t1,
               double p0,
               double p1,
               color clr,
               int style,
               int width,
               bool back,
               bool ray,
               int window)
  {
   ObjectDelete(0,name);
   ObjectCreate(0,name,OBJ_TREND,window,t0,p0,t1,p1,0,0);
   ObjectSetInteger(0,name,OBJPROP_RAY_RIGHT,ray);
   ObjectSetInteger(0,name,OBJPROP_COLOR,clr);
   ObjectSetInteger(0,name,OBJPROP_STYLE,style);
   ObjectSetInteger(0,name,OBJPROP_WIDTH,width);
   ObjectSetInteger(0,name,OBJPROP_SELECTABLE,false);
   ObjectSetInteger(0,name,OBJPROP_BACK,back);
  }
//+------------------------------------------------------------------+
