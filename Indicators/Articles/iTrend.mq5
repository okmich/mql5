//+------------------------------------------------------------------+
//|                                                      i_Trend.mq5 |
//|                                          Copyright 2012, Integer |
//|                          https://login.mql5.com/ru/users/Integer |
//|                                https://www.mql5.com/en/code/1115 |
//+------------------------------------------------------------------+
#property copyright "Integer"
#property link "https://login.mql5.com/ru/users/Integer"
#property description ""
#property version   "1.00"

#property description "Expert rewritten from MQL4, author is unknown, published on mql4.com by Scriptor (http://www.mql4.com/ru/users/Scriptor), link - http://codebase.mql4.com/ru/1712"

#property indicator_separate_window
#property indicator_buffers 6
#property indicator_plots   2
//--- plot Label1
#property indicator_label1  "Label1"
#property indicator_type1   DRAW_LINE
#property indicator_color1  clrLimeGreen
#property indicator_style1  STYLE_SOLID
#property indicator_width1  1
//--- plot Label2
#property indicator_label2  "Label2"
#property indicator_type2   DRAW_LINE
#property indicator_color2  clrRed
#property indicator_style2  STYLE_SOLID
#property indicator_width2  1

enum EBBLine
  {
   Base=BASE_LINE,
   Upper=UPPER_BAND,
   Lower=LOWER_BAND
  };

input ENUM_APPLIED_PRICE               Price             =  PRICE_CLOSE; /*Price*/               // type of price at which the calculated amount of price and Bollinger Bands
input int                              BBPeriod          =  20;          /*BBPeriod*/            // BB period
input int                              BBShift           =  0;             /*BBShift*/             // BB shift
input double                           BBDeviation       =  2;             /*BBDeviation*/         // BB deviation
input ENUM_APPLIED_PRICE               BBPrice           =  PRICE_CLOSE; /*BBPrice*/             // BB price
input EBBLine                          BBLine            =  BASE_LINE;     /*BBLine*/              // used line of the Bollinger Bands
input int                              BullsBearsPeriod  =  14;          /*BullsBearsPeriod*/    // Bulls Bears Power period



//--- indicator buffers
double         Label1Buffer[];
double         Label2Buffer[];

double         BufBB[];
double         BufBu[];
double         BufBe[];
double         BufMA[];

int BBHand=INVALID_HANDLE;
int BullsHand=INVALID_HANDLE;
int BearsHand=INVALID_HANDLE;
int MAHand=INVALID_HANDLE;
//+------------------------------------------------------------------+
//| Custom indicator initialization function                         |
//+------------------------------------------------------------------+
int OnInit()
  {

   BBHand=iBands(NULL,PERIOD_CURRENT,BBPeriod,BBShift,BBDeviation,BBPrice);
   BullsHand=iBullsPower(NULL,PERIOD_CURRENT,BullsBearsPeriod);
   BearsHand=iBearsPower(NULL,PERIOD_CURRENT,BullsBearsPeriod);
   MAHand=iMA(NULL,PERIOD_CURRENT,1,0,0,Price);

   if(BBHand==INVALID_HANDLE || BullsHand==INVALID_HANDLE || BearsHand==INVALID_HANDLE || MAHand==INVALID_HANDLE)
     {
      Alert("Failed to loading the indicator, try again");
      return(-1);
     }

//--- indicator buffers mapping
   SetIndexBuffer(0,Label1Buffer,INDICATOR_DATA);
   SetIndexBuffer(1,Label2Buffer,INDICATOR_DATA);
   SetIndexBuffer(2,BufBB,INDICATOR_CALCULATIONS);
   SetIndexBuffer(3,BufBu,INDICATOR_CALCULATIONS);
   SetIndexBuffer(4,BufBe,INDICATOR_CALCULATIONS);
   SetIndexBuffer(5,BufMA,INDICATOR_CALCULATIONS);

   PlotIndexSetInteger(0,PLOT_DRAW_BEGIN,BBPeriod+BBShift);
   PlotIndexSetInteger(1,PLOT_DRAW_BEGIN,BullsBearsPeriod);

//---
   return(0);
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void OnInit(const int reason)
  {
   if(BBHand!=INVALID_HANDLE)
      IndicatorRelease(BBHand);
   if(BullsHand!=INVALID_HANDLE)
      IndicatorRelease(BullsHand);
   if(BearsHand!=INVALID_HANDLE)
      IndicatorRelease(BearsHand);
   if(MAHand!=INVALID_HANDLE)
      IndicatorRelease(MAHand);
  }
//+------------------------------------------------------------------+
//| Custom indicator iteration function                              |
//+------------------------------------------------------------------+
int OnCalculate(const int rates_total,
                const int prev_calculated,
                const datetime & time[],
                const double & open[],
                const double & high[],
                const double & low[],
                const double & close[],
                const long & tick_volume[],
                const long & volume[],
                const int & spread[]
               )
  {
   static bool error=true;
   int start;
   if(prev_calculated==0)
     {
      error=true;
     }
   if(error)
     {
      start=0;
      error=false;
     }
   else
     {
      start=prev_calculated-1;
     }
   if(
      CopyBuffer(BBHand,BBLine,0,rates_total-start,BufBB)==-1 ||
      CopyBuffer(BullsHand,0,0,rates_total-start,BufBu)==-1 ||
      CopyBuffer(BearsHand,0,0,rates_total-start,BufBe)==-1 ||
      CopyBuffer(MAHand,0,0,rates_total-start,BufMA)==-1
   )
     {
      error=true;
      return(0);
     }
   for(int i=start; i<rates_total; i++)
     {
      Label1Buffer[i]=BufMA[i]-BufBB[i];
      Label2Buffer[i]=-(BufBe[i]+BufBu[i]);
     }
   return(rates_total);
  }

//+------------------------------------------------------------------+
