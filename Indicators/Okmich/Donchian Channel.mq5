//+------------------------------------------------------------------+
//|                                             Donchian Channel.mq5 |
//|                                   Copyright 2022, Michael Enudi. |
//|                                             okmich2002@yahoo.com |
//+------------------------------------------------------------------+
#property copyright     "Copyright 2022, Michael Enudi"
#property link          "okmich2002@yahoo.com"
#property description   "Implementation of Donchian Channel"

#property indicator_chart_window
#property indicator_buffers 3
#property indicator_plots   3

#property indicator_label1  "Highest high"
#property indicator_type1   DRAW_LINE
#property indicator_color1  clrMediumSeaGreen
#property indicator_label2  "Lowest low"
#property indicator_type2   DRAW_LINE
#property indicator_color2  clrOrangeRed
#property indicator_label3  "Middle Line"
#property indicator_type3   DRAW_LINE
#property indicator_color3  clrSilver
#property indicator_style3  STYLE_DOT

enum ENUM_MODE_DC_CALCULATION
  {
   MODE_CLOSECLOSE,    // Close
   MODE_HIGHLOW        // High/Low
  };

//
//--- input parameters
//
input int inpChannelPeriod=20; // Period
input ENUM_MODE_DC_CALCULATION inpMode = MODE_HIGHLOW; //Calc Mode

//
//--- indicator buffers
//
double valh[], vall[], valm[];

//------------------------------------------------------------------
//
//------------------------------------------------------------------
//
//
//

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
int OnInit()
  {
//
//--- indicator buffers mapping
//
   SetIndexBuffer(0,valh,INDICATOR_DATA);
   SetIndexBuffer(1,vall,INDICATOR_DATA);
   SetIndexBuffer(2,valm,INDICATOR_DATA);

   IndicatorSetInteger(INDICATOR_DIGITS, _Digits);
   
   return(INIT_SUCCEEDED);
  }

//------------------------------------------------------------------
//
//------------------------------------------------------------------
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
   static int    prev_i = -1;
   
   int i = prev_calculated;
   for(; i<rates_total && !_StopFlag; i++)
     {
      if(prev_i != i)
        {
         int start = i-inpChannelPeriod;
         if(start<0)
            start=0;

         switch(inpMode)
           {
            case MODE_CLOSECLOSE:
               valh[i] = low [ArrayMaximum(close,start,inpChannelPeriod)] ;
               vall[i] = low [ArrayMinimum(close,start,inpChannelPeriod)];
               break;
            case MODE_HIGHLOW:
            default:
               valh[i] = high[ArrayMaximum(high,start,inpChannelPeriod)];
               vall[i] = low [ArrayMinimum(low,start,inpChannelPeriod)];
           }
        }

      valm[i]=(valh[i]+vall[i])/2;
     }
   return(i);
  }
//------------------------------------------------------------------
//+------------------------------------------------------------------+
