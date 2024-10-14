///////////////////////////////////////////////////////////////////////////////////////////////
//      This is a job done by developer (User ID : helptotraders) on MQL5.com
//      Seller Profile  : https://www.mql5.com/en/users/helptotraders/seller
//      Order Num       : 145819
//      Job Name        : Convert Indicator from MQL4 to MQL5
//      Date            : 2021.04.27
//      User (Customer) : okmich
//      User (Developer): HelpToTraders (Ismail Hakki Delibas)
///////////////////////////////////////////////////////////////////////////////////////////////
#property copyright "Copyright, helptotraders. "
#property link   "https://www.mql5.com/en/users/helptotraders/seller"
#property version   "1.0"
#property strict


#property indicator_separate_window
#property indicator_buffers 3
#property indicator_plots 1
//#property indicator_type1 DRAW_LINE
//#property indicator_type1 DRAW_LINE
//#property indicator_type1 DRAW_LINE
#property indicator_color1 Yellow
#property indicator_color2 Lime
#property indicator_color3 OrangeRed
#property indicator_level1  -0.9
#property indicator_level2   0
#property indicator_level3   0.9
#property indicator_minimum -1.05
#property indicator_maximum  1.05
#property indicator_width1 2
#property indicator_width2 2
#property indicator_width3 2

input int  Nbars=89;          
input int  MA_Period =9;
input int  MaxBars=300;
input ENUM_MA_METHOD  MA_Method = MODE_SMA;

double Value[];
double MA[];
double iFish[];


//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
int OnInit()
  {
//IndicatorBuffers(5);
   SetIndexBuffer(0, iFish,INDICATOR_DATA);
//SetIndexStyle(0,DRAW_LINE);

   SetIndexBuffer(1, Value,INDICATOR_CALCULATIONS);
   SetIndexBuffer(2, MA,INDICATOR_CALCULATIONS);

   PlotIndexSetInteger(0,PLOT_DRAW_TYPE,DRAW_LINE);
   PlotIndexSetInteger(1,PLOT_DRAW_TYPE,DRAW_LINE);
   PlotIndexSetInteger(2,PLOT_DRAW_TYPE,DRAW_LINE);
   PlotIndexSetInteger(3,PLOT_DRAW_TYPE,DRAW_NONE);
   PlotIndexSetInteger(4,PLOT_DRAW_TYPE,DRAW_NONE);

   PlotIndexSetDouble(0,PLOT_EMPTY_VALUE,0);
   PlotIndexSetDouble(1,PLOT_EMPTY_VALUE,0);
   PlotIndexSetDouble(2,PLOT_EMPTY_VALUE,0);
   PlotIndexSetDouble(3,PLOT_EMPTY_VALUE,0);
   PlotIndexSetDouble(4,PLOT_EMPTY_VALUE,0);




//?IndicatorShortName("TREND FILTER ("+Nbars+","+MA_Period+")" );

   return(0);
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void OnDeinit(const int reason)
  {
  }


//+------------------------------------------------------------------+
//|                                                                  |
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
   int counted_bars = prev_calculated, i;
//if (counted_bars < 0) return(-1);
   if(counted_bars > 0)
      counted_bars--;
//int limit=Bars(Symbol(),Period()) - counted_bars+2*Nbars;
   int limit=rates_total - counted_bars-2*Nbars;
   double up,dn,osc;

   if(prev_calculated==0)
      limit=MaxBars;
   else
      limit=2*Nbars;

//  if( prev_calculated==0 )
//  {
// ArrayInitialize(iFish,EMPTY_VALUE);
// ArrayInitialize(Buy,EMPTY_VALUE);
// ArrayInitialize(Sell,EMPTY_VALUE);
// ArrayInitialize(Value,EMPTY_VALUE);
// ArrayInitialize(MA,EMPTY_VALUE);
//}

   ArraySetAsSeries(high,true);
   ArraySetAsSeries(low,true);
   ArraySetAsSeries(close,true);

   ArraySetAsSeries(iFish,true);
   ArraySetAsSeries(Value,true);
   ArraySetAsSeries(MA,true);

   for(i = limit; i >= 0; i--)
     {
      //Print(iHighest(NULL,0,MODE_HIGH,Nbars,i));
      up = iHigh(Symbol(),Period(),iHighest(NULL,0,MODE_HIGH,Nbars,i));
      dn = iLow(Symbol(),Period(),iLowest(NULL,0,MODE_LOW,Nbars,i));

      if(up>dn)
         osc = 100*(iClose(Symbol(),Period(),i)-dn)/(up-dn);
      else
         osc = 0;
      if(osc < 0)
         osc = 0.1;
      if(osc > 100)
         osc = 99.9;
      //Print(i,"  ",rates_total);
      Value[i]=0.1*(osc-50.0);
     }
     
   for(i = limit; i >= 0; i--)
     {
      MA[i]=iMAOnArrayMQL4(Value,0,MA_Period,0,MA_Method,i);
      //Print(MA[i]);
      iFish[i]=(MathExp(2.0*MA[i])-1.0)/(MathExp(2.0*MA[i])+1.0);
     }

   return(rates_total);
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
double iMAOnArrayMQL4(double &array[],
                      int total,
                      int period,
                      int ma_shift,
                      int ma_method,
                      int shift)
  {
   double buf[],arr[];
   if(total==0)
      total=ArraySize(array);
   if(total>0 && total<=period)
      return(0);
   if(shift>total-period-ma_shift)
      return(0);
   switch(ma_method)
     {
      case MODE_SMA :
        {
         total=ArrayCopy(arr,array,0,shift+ma_shift,period);
         if(ArrayResize(buf,total)<0)
            return(0);
         double sum=0;
         int    i,pos=total-1;
         for(i=1; i<period; i++,pos--)
            sum+=arr[pos];
         while(pos>=0)
           {
            sum+=arr[pos];
            buf[pos]=sum/period;
            sum-=arr[pos+period-1];
            pos--;
           }
         return(buf[0]);
        }
      case MODE_EMA :
        {
         if(ArrayResize(buf,total)<0)
            return(0);
         double pr=2.0/(period+1);
         int    pos=total-2;
         while(pos>=0)
           {
            if(pos==total-2)
               buf[pos+1]=array[pos+1];
            buf[pos]=array[pos]*pr+buf[pos+1]*(1-pr);
            pos--;
           }
         return(buf[shift+ma_shift]);
        }
      case MODE_SMMA :
        {
         if(ArrayResize(buf,total)<0)
            return(0);
         double sum=0;
         int    i,k,pos;
         pos=total-period;
         while(pos>=0)
           {
            if(pos==total-period)
              {
               for(i=0,k=pos; i<period; i++,k++)
                 {
                  sum+=array[k];
                  buf[k]=0;
                 }
              }
            else
               sum=buf[pos+1]*(period-1)+array[pos];
            buf[pos]=sum/period;
            pos--;
           }
         return(buf[shift+ma_shift]);
        }
      case MODE_LWMA :
        {
         if(ArrayResize(buf,total)<0)
            return(0);
         double sum=0.0,lsum=0.0;
         double price;
         int    i,weight=0,pos=total-1;
         for(i=1; i<=period; i++,pos--)
           {
            price=array[pos];
            sum+=price*i;
            lsum+=price;
            weight+=i;
           }
         pos++;
         i=pos+period;
         while(pos>=0)
           {
            buf[pos]=sum/weight;
            if(pos==0)
               break;
            pos--;
            i--;
            price=array[pos];
            sum=sum-lsum+price*period;
            lsum-=array[i];
            lsum+=price;
           }
         return(buf[shift+ma_shift]);
        }
      default:
         return(0);
     }
   return(0);
  }
//+------------------------------------------------------------------+
