//+------------------------------------------------------------------+
//|                                     SmoothedAdaptiveMomentum.mq5 |
//|                                                                  |
//| Smoothed Adaptive Momentum                                       |
//|                                                                  |
//| Algorithm taken from book                                        |
//|     "Cybernetics Analysis for Stock and Futures"                 |
//| by John F. Ehlers                                                |
//|                                                                  |
//|                                              contact@mqlsoft.com |
//|                                          http://www.mqlsoft.com/ |
//+------------------------------------------------------------------+
//---- author of the indicator
#property copyright "Coded by Witold Wozniak"
//---- author of the indicator
#property link      "www.mqlsoft.com"
//---- indicator version
#property version   "1.00"
//---- drawing the indicator in a separate window
#property indicator_separate_window
//---- one buffer is used for calculation and drawing the indicator
#property indicator_buffers 1
//---- one plot is used
#property indicator_plots   1
//+----------------------------------------------+
//|  SAM indicator drawing parameters            |
//+----------------------------------------------+
//---- drawing the indicator 1 as a line
#property indicator_type1   DRAW_LINE
//---- red color is used for the indicator line
#property indicator_color1  Red
//---- the indicator 1 line is a continuous curve
#property indicator_style1  STYLE_SOLID
//---- indicator 1 line width is equal to 1
#property indicator_width1  1
//---- displaying the indicator line label
#property indicator_label1  "Smoothed Adaptive Momentum"
//+----------------------------------------------+
//| Horizontal levels display parameters         |
//+----------------------------------------------+
#property indicator_level1 0.0
#property indicator_levelcolor Gray
#property indicator_levelstyle STYLE_DASHDOTDOT
//+----------------------------------------------+
//|  Declaration of constants                    |
//+----------------------------------------------+
#define RESET 0       // the constant for getting the command for the indicator recalculation back to the terminal
#define MAXPERIOD 100 // the constant for the maximum period limitation
//+----------------------------------------------+
//|  Indicator input parameters                  |
//+----------------------------------------------+
input double Alpha=0.07;  // Indicator ratio
input int Cutoff=8;
input int Shift=0;        // Horizontal shift of the indicator in bars 
//+----------------------------------------------+
//---- declaration of dynamic arrays that
//---- will be used as indicator buffers
double MomentumBuffer[];
//---- declaration of integer variables for the indicators handles
int CP_Handle;
//---- declaration of the integer variables for the start of data calculation
int min_rates_total;
//---- declaration of dynamic arrays that
//---- will be used as ring buffers
int Count[];
double Price[],Momentum[];
//---- declaration of global variables
double coef1,coef2,coef3,coef4;
//+------------------------------------------------------------------+
//|  Recalculation of position of the newest element in the array    |
//+------------------------------------------------------------------+   
void Recount_ArrayZeroPos(int &CoArr[],// Return the current value of the price series by the link
                          int Size)
  {
//----
   int numb,Max1,Max2;
   static int count=1;

   Max2=Size;
   Max1=Max2-1;

   count--;
   if(count<0) count=Max1;

   for(int iii=0; iii<Max2; iii++)
     {
      numb=iii+count;
      if(numb>Max1) numb-=Max2;
      CoArr[iii]=numb;
     }
//----
  }
//+------------------------------------------------------------------+
//|  Getting the difference of the price time series values          |
//+------------------------------------------------------------------+   
double Get_Price(const double  &High[],const double  &Low[],int bar)
  {
//----
   return((High[bar]+Low[bar])/2);
  }
//+------------------------------------------------------------------+
//| Custom indicator initialization function                         |
//+------------------------------------------------------------------+  
void OnInit()
  {
//---- initialization of variables of the start of data calculation
   min_rates_total=7;

//---- getting handle of the CyclePeriod indicator
   CP_Handle=iCustom(NULL,0,"Cycle Period",Alpha);
   if(CP_Handle==INVALID_HANDLE) Print(" Failed to get handle of the CyclePeriod indicator");

//---- initialization of variables
   double pi=MathArctan(1.0)*4.0;
   double a1 = MathExp(-pi / Cutoff);
   double b1 = 2 * a1 * MathCos(MathSqrt(3.0) * pi/ Cutoff);
   double c1 = a1 * a1;
   coef2 = b1 + c1;
   coef3 = -(c1 + b1 * c1);
   coef4 = c1 * c1;
   coef1 = 1.0 - coef2 - coef3 - coef4;

//---- memory distribution for variables' arrays  
   ArrayResize(Count,MAXPERIOD);
   ArrayResize(Price,MAXPERIOD);
   ArrayResize(Momentum,MAXPERIOD);

   ArrayInitialize(Count,0);
   ArrayInitialize(Price,0);
   ArrayInitialize(Momentum,0);
   
//---- set MomentumBuffer[] dynamic array as an indicator buffer
   SetIndexBuffer(0,MomentumBuffer,INDICATOR_DATA);
//---- shifting the indicator 1 horizontally by Shift
   PlotIndexSetInteger(0,PLOT_SHIFT,Shift);
//---- performing shift of the beginning of counting of drawing the indicator 1 by min_rates_total
   PlotIndexSetInteger(0,PLOT_DRAW_BEGIN,min_rates_total);

//---- initializations of a variable for the indicator short name
   string shortname;
   StringConcatenate(shortname,"Smoothed Adaptive Momentum(",DoubleToString(Alpha,4),", ",Shift,")");
//---- creating a name for displaying in a separate sub-window and in a tooltip
   IndicatorSetString(INDICATOR_SHORTNAME,shortname);
//---- determination of accuracy of displaying the indicator values
   IndicatorSetInteger(INDICATOR_DIGITS,_Digits);
//----
  }
//+------------------------------------------------------------------+
//| Custom indicator iteration function                              |
//+------------------------------------------------------------------+
int OnCalculate(const int rates_total,    // number of bars in history at the current tick
                const int prev_calculated,// number of bars calculated at previous call
                const datetime &time[],
                const double &open[],
                const double& high[],     // price array of maximums of price for the indicator calculation
                const double& low[],      // price array of minimums of price for the indicator calculation
                const double &close[],
                const long &tick_volume[],
                const long &volume[],
                const int &spread[])
  {
//---- checking the number of bars to be enough for the calculation
   if(BarsCalculated(CP_Handle)<rates_total || rates_total<min_rates_total) return(RESET);

//---- declarations of local variables 
   double period[1];
   int first,bar,Length;

//---- calculation of the 'first' starting index for the bars recalculation loop
   if(prev_calculated>rates_total || prev_calculated<=0) // checking for the first start of the indicator calculation
      first=3;                   // starting index for calculation of all bars
   else first=prev_calculated-1; // starting index for calculation of new bars

//---- main indicator calculation loop
   for(bar=first; bar<rates_total && !IsStopped(); bar++)
     {
      Price[Count[0]]=Get_Price(high,low,bar);

      //--- copy newly appeared data in the array
      if(CopyBuffer(CP_Handle,0,rates_total-1-bar,1,period)<=0) return(RESET);

      Length=int(MathFloor(period[0]));
      Length=int(MathMax(Length,1));
      Length=int(MathMin(Length,bar));       // cutting the smoothing down to the real number of bars
      Length=int(MathMin(Length,MAXPERIOD)); // cutting the smoothing down to the maximum size of data arrays

      Momentum[Count[0]]=Price[Count[0]]-Price[Count[Length-1]];

      if(bar>8)
         MomentumBuffer[bar]=coef1*Momentum[Count[1]]+coef2*MomentumBuffer[bar-1]+coef3*MomentumBuffer[bar-2]+coef4*MomentumBuffer[bar-3];
      else MomentumBuffer[bar]=Momentum[Count[0]];

      if(bar<rates_total-1) Recount_ArrayZeroPos(Count,MAXPERIOD);
     }
//----     
   return(rates_total);
  }
//+------------------------------------------------------------------+
