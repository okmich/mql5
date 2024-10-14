//+------------------------------------------------------------------+
//|                                                  CyclePeriod.mq5 |
//|                                                                  |
//| Cycle Period                                                     |
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
//---- 1 buffer is used for calculation and drawing the indicator
#property indicator_buffers 1
//---- one plot is used
#property indicator_plots   1
//+----------------------------------------------+
//|  Cycle Period indicator drawing parameters   |
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
#property indicator_label1  "Cycle Period"
//+----------------------------------------------+
//|  Indicator input parameters                  |
//+----------------------------------------------+
input double Alpha=0.07;    // Indicator ratio 
//+----------------------------------------------+
//---- declaration of dynamic arrays that
//---- will be used as indicator buffers
double CPeriodBuffer[];
//---- declaration of the integer variables for the start of data calculation
int min_rates_total;
//---- declaration of global variables
bool med2;
int median,median2;
double InstPeriod_,CPeriod_;
//---- declaration of dynamic arrays that
//---- will be used as ring buffers
int Count1[],Count2[];
double K0,K1,K2,K3,F0,F1,F2,F3;
double Smooth[],Cycle[],Q1[],I1[],DeltaPhase[],M[],Price[];
//+------------------------------------------------------------------+
//|  Recalculation of position of the newest element in the array    |
//+------------------------------------------------------------------+   
void Recount_ArrayZeroPos1(int &CoArr[]) // Return the current value of the price series by the link
  {
//----
   int numb,Max1,Max2;
   static int count=1;

   Max2=7;
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
//|  Recalculation of position of the newest element in the array    |
//+------------------------------------------------------------------+   
void Recount_ArrayZeroPos2(int &CoArr[]) // Return the current value of the price series by the link
  {
//----
   int numb,Max1,Max2;
   static int count=1;

   Max2=median;
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
//| Custom indicator initialization function                         |
//+------------------------------------------------------------------+  
void OnInit()
  {
//---- initialization of variables
   K0=MathPow((1.0 - 0.5*Alpha),2);
   K1=2.0;
   K2=K1 *(1.0 - Alpha);
   K3=MathPow((1.0 - Alpha),2);
   F0=0.0962;
   F1=0.5769;
   F2=0.5;
   F3=0.08;
   median=5;
   median2=median/2;
   if(median%2==0) med2=true;
   else            med2=false;

//---- memory distribution for variables' arrays  
   ArrayResize(Count1,7);
   ArrayResize(Smooth,7);
   ArrayResize(Cycle,7);
   ArrayResize(Q1,7);
   ArrayResize(I1,7);
   ArrayResize(Price,7);
   ArrayResize(Count2,median);
   ArrayResize(DeltaPhase,median);
   ArrayResize(M,median);

//---- initialization of the variables arrays
   ArrayInitialize(Count1,0);
   ArrayInitialize(Smooth,0);
   ArrayInitialize(Cycle,0);
   ArrayInitialize(Q1,0);
   ArrayInitialize(I1,0);
   ArrayInitialize(Price,0);
   ArrayInitialize(Count2,0);
   ArrayInitialize(DeltaPhase,0);
   ArrayInitialize(M,0);

//---- initialization of variables of the start of data calculation
   min_rates_total=median+16;

//---- set CPeriodBuffer[] dynamic array as an indicator buffer
   SetIndexBuffer(0,CPeriodBuffer,INDICATOR_DATA);
//---- performing the shift of the beginning of the indicator drawing
   PlotIndexSetInteger(0,PLOT_DRAW_BEGIN,min_rates_total);
//---- setting the indicator values that won't be visible on a chart
   PlotIndexSetDouble(0,PLOT_EMPTY_VALUE,0.0);

//---- initializations of a variable for the indicator short name
   string shortname;
   StringConcatenate(shortname,"Cycle Period(",DoubleToString(Alpha,4),")");
//---- creating a name for displaying in a separate sub-window and in a tooltip
   IndicatorSetString(INDICATOR_SHORTNAME,shortname);
//---- determination of accuracy of displaying the indicator values
   IndicatorSetInteger(INDICATOR_DIGITS,_Digits+2);
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
   if(rates_total<min_rates_total) return(0);

//---- declarations of local variables 
   int first,bar,bar0,bar1,bar2,bar3,bar4,bar6;
   double CPeriod,InstPeriod,MedianDelta,DC;

//---- calculation of the 'first' starting index for the bars recalculation loop
   if(prev_calculated>rates_total || prev_calculated<=0) // checking for the first start of the indicator calculation
     {
      first=0; // starting index for calculation of all bars
      CPeriod_=1.0;
      InstPeriod_=1.0;
      CPeriodBuffer[0]=1.0;
     }
   else first=prev_calculated-1; // starting index for calculation of new bars

//---- restore values of the variables
   InstPeriod=InstPeriod_;
   CPeriod=CPeriod_;

//---- main indicator calculation loop
   for(bar=first; bar<rates_total && !IsStopped(); bar++)
     {
      //---- store values of the variables before running at the current bar
      if(rates_total!=prev_calculated && bar==rates_total-1)
        {
         CPeriod_=CPeriod;
         InstPeriod_=InstPeriod;
        }

      bar0=Count1[0];
      bar1=Count1[1];
      bar2=Count1[2];
      bar3=Count1[3];
      bar4=Count1[4];
      bar6=Count1[6];

      Price[bar0]=(high[bar]+low[bar])/2.0;
      Smooth[bar0]=(Price[bar0]+2.0*Price[bar1]+2.0*Price[bar2]+Price[bar3])/6.0;

      if(bar<6) Cycle[bar0]=(Price[bar0]-2.0*Price[bar1]+Price[bar2])/4.0;
      else Cycle[bar0]=K0*(Smooth[bar0]-K1*Smooth[bar1]+Smooth[bar2])+K2*Cycle[bar1]-K3*Cycle[bar2];

      Q1[bar0]=(F0*Cycle[bar0]+F1*Cycle[bar2]-F1*Cycle[bar4]-F0*Cycle[bar6])*(F2+F3*InstPeriod);
      I1[bar0]= Cycle[Count1[3]];

      if(Q1[bar0] && Q1[bar1])
         DeltaPhase[Count2[0]]=(I1[bar0]/Q1[bar0]-I1[bar1]/Q1[bar1])/(1.0+I1[bar0]*I1[bar1]/(Q1[bar0]*Q1[bar1]));

      bar0=Count2[0];
      DeltaPhase[bar0]=MathMax(0.1,DeltaPhase[bar0]);
      DeltaPhase[bar0]=MathMin(1.1,DeltaPhase[bar0]);

      ArrayCopy(M,DeltaPhase,0,0,WHOLE_ARRAY);
      ArraySort(M);

      if(med2) MedianDelta=(M[median2]+M[median2+1])/2.0;
      else     MedianDelta=M[median2];

      if(!MedianDelta) DC=15.0;
      else             DC=6.28318/MedianDelta+0.5;

      InstPeriod=0.67*InstPeriod+0.33*DC;
      CPeriod=0.85*CPeriod+0.15*InstPeriod;
      CPeriodBuffer[bar]=CPeriod;

      if(bar<rates_total-1)
        {
         Recount_ArrayZeroPos1(Count1);
         Recount_ArrayZeroPos2(Count2);
        }
     }
//----     
   return(rates_total);
  }
//+------------------------------------------------------------------+
