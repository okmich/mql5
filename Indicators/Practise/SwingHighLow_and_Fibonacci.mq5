//+------------------------------------------------------------------+
//|               Swing High Low and Fibonacci Retracement Indicator |
//|                                       Copyright 2024, Hieu Hoang |
//+------------------------------------------------------------------+
#property copyright "Copyright 2024, hieuhoangcntt@gmail.com"
#property indicator_chart_window

const color           clr=clrWhite;
const ENUM_LINE_STYLE style=STYLE_SOLID;
const int             width=2;

const int swing_length = 5;

double c_low = DBL_MAX;
double c_high = DBL_MIN;
double tmp_high = 0;
double tmp_low = 0;
datetime tmp_time;
int current_trend = -1;
string preObjName = "";
string preObjName2 = "";
int lastIndex = swing_length;

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
bool isLow(int in, const double &low[])
  {
   for(int i=in-swing_length; i<= in+swing_length;i++)
      if(low[in]>low[i])
         return false;
   return true;
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
bool isHigh(int in, const double &high[])
  {
   for(int i=in-swing_length; i<= in+swing_length;i++)
      if(high[in]<high[i])
         return false;
   return true;
  }
//+------------------------------------------------------------------+
//| Custom indicator initialization function                         |
//+------------------------------------------------------------------+
int OnInit()
  {
   ObjectsDeleteAll(0);
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

   for(int i = lastIndex; i< rates_total - swing_length - 2; i++)
     {
      if(isHigh(i, high))
        {
         if(current_trend != 0 || high[i] > c_high)
           {
            if(current_trend == 0)
              {
               ObjectDelete(0, preObjName);
              }
            preObjName = "High " + i;
            ObjectCreate(0, preObjName, OBJ_ARROW_SELL, 0, time[i], high[i]);
            current_trend = 0;
            c_high = high[i];
            c_low = DBL_MAX;
            tmp_high = high[i];
            lastIndex = i + 1;
           }
        }
      else
         if(isLow(i, low))
           {
            if(current_trend != 1 || low[i] < c_low)
              {
               if(current_trend == 1)
                 {
                  ObjectDelete(0, preObjName);
                  ObjectSetInteger(0, preObjName2, OBJPROP_TIME, time[i]);
                 }
               if(0 != tmp_high && current_trend != 1)
                 {
                  preObjName2 = "Fibonacci Retracement " + i;
                  ObjectCreate(0,preObjName2,OBJ_FIBO,0,time[i],tmp_high,tmp_time,tmp_low);
                  ObjectSetInteger(0,preObjName2,OBJPROP_COLOR,clr);
                  ObjectSetInteger(0,preObjName2,OBJPROP_STYLE,style);
                  ObjectSetInteger(0,preObjName2,OBJPROP_WIDTH,width);
                 }
               ObjectSetInteger(0,preObjName2,OBJPROP_RAY_RIGHT,false);
               preObjName =  "Low " + i;
               ObjectCreate(0, preObjName, OBJ_ARROW_BUY, 0, time[i], low[i]);
               current_trend = 1;
               c_high = DBL_MIN;
               c_low = low[i];
               tmp_low = low[i];
               tmp_time = time[i];
               lastIndex = i + 1;
              }

           }
     }
   ObjectSetInteger(0,preObjName2,OBJPROP_RAY_RIGHT,true);
   return(rates_total);
  }
//+------------------------------------------------------------------+
