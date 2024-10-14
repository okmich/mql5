//+-------------------------------------------------------------------------------------+
//|                                                     Minions.3RulesMACD_Patterns.mq5 |
//| (CC) Creative Commons Attribution-NonCommercial-ShareAlike 4.0 International License|
//|                                                          http://www.MinionsLabs.com |
//|                                                  https://www.mql5.com/en/code/21280 |
//+-------------------------------------------------------------------------------------+


//+------------------------------------------------------------------+
//| Descriptors                                                      |
//+------------------------------------------------------------------+
#property copyright   "www.MinionsLabs.com"
#property link        "http://www.MinionsLabs.com"
#property version     "1.0"
#property description "Minions in the quest for ideal MACD Crossovers using 3 rules"
#property description " (Patterns visualizer)"
#property description " "
#property description "(CC) Creative Commons Attribution-NonCommercial-ShareAlike 4.0 International License"



//+------------------------------------------------------------------+
//| Indicator Settings                                               |
//+------------------------------------------------------------------+
#property indicator_separate_window
#property indicator_buffers 8
#property indicator_plots   8

#property indicator_label1  "MACD"
#property indicator_type1   DRAW_LINE
#property indicator_color1  clrMediumBlue
#property indicator_style1  STYLE_SOLID
#property indicator_width1  2

#property indicator_label2  "Signal Line"
#property indicator_type2   DRAW_LINE
#property indicator_color2  clrOrange
#property indicator_style2  STYLE_DOT
#property indicator_width2  1

#property indicator_label3  "RuleBuy#1"
#property indicator_type3   DRAW_ARROW
#property indicator_color3  clrDodgerBlue
#property indicator_style3  STYLE_SOLID
#property indicator_width3  1

#property indicator_label4  "RuleBuy#2"
#property indicator_type4   DRAW_ARROW
#property indicator_color4  clrDodgerBlue
#property indicator_style4  STYLE_SOLID
#property indicator_width4  1

#property indicator_label5  "RuleBuy#3"
#property indicator_type5   DRAW_ARROW
#property indicator_color5  clrDodgerBlue
#property indicator_style5  STYLE_SOLID
#property indicator_width5  4

#property indicator_label6  "RuleSell#1"
#property indicator_type6   DRAW_ARROW
#property indicator_color6  clrRed
#property indicator_style6  STYLE_SOLID
#property indicator_width6  1

#property indicator_label7  "RuleSell#2"
#property indicator_type7   DRAW_ARROW
#property indicator_color7  clrRed
#property indicator_style7  STYLE_SOLID
#property indicator_width7  1

#property indicator_label8  "RuleSell#3"
#property indicator_type8   DRAW_ARROW
#property indicator_color8  clrRed
#property indicator_style8  STYLE_SOLID
#property indicator_width8  4



//+------------------------------------------------------------------+
//| Inputs from User Interface                                       |
//+------------------------------------------------------------------+
input int      inpMAFast=12;      //Fast MA Period
input int      inpMASlow=26;      //Slow MA Period
input int      inpSignal=9;       //Signal Line Period


//+------------------------------------------------------------------+
//| Global Variables                                                 |
//+------------------------------------------------------------------+
int      bufferMACD_ID=0;      // put names on buffers!
int      bufferSignal_ID=1;    //
int      bufferBuy1_ID=2;      //
int      bufferBuy2_ID=3;      //
int      bufferBuy3_ID=4;      //
int      bufferSell1_ID=5;     //
int      bufferSell2_ID=6;     //
int      bufferSell3_ID=7;     //


double   bufferMACD[];         // buffers!
double   bufferSignal[];       //
double   bufferBuy1[];         //
double   bufferBuy2[];         //
double   bufferBuy3[];         //
double   bufferSell1[];        //
double   bufferSell2[];        //
double   bufferSell3[];        //

int    hiMACD;                 // handle of the iMACD indicator

int    bars_calculated=0;      // # of values in the iMACD indicator

bool   ruleBuy1=false;         // holds the rule #1 cross for BUY
bool   ruleBuy2=false;         // holds the rule #2 cross for BUY
bool   ruleSell1=false;        // holds the rule #1 cross for SELL
bool   ruleSell2=false;        // holds the rule #2 cross for SELL



//+------------------------------------------------------------------+
//| Custom indicator initialization function                         |
//+------------------------------------------------------------------+
int OnInit()
  {
   // assignment of arrays to indicator buffers
   SetIndexBuffer(bufferMACD_ID,    bufferMACD,   INDICATOR_DATA);
   SetIndexBuffer(bufferSignal_ID,  bufferSignal, INDICATOR_DATA);
   SetIndexBuffer(bufferBuy1_ID,    bufferBuy1,   INDICATOR_DATA);
   SetIndexBuffer(bufferBuy2_ID,    bufferBuy2,   INDICATOR_DATA);
   SetIndexBuffer(bufferBuy3_ID,    bufferBuy3,   INDICATOR_DATA);
   SetIndexBuffer(bufferSell1_ID,   bufferSell1,  INDICATOR_DATA);
   SetIndexBuffer(bufferSell2_ID,   bufferSell2,  INDICATOR_DATA);
   SetIndexBuffer(bufferSell3_ID,   bufferSell3,  INDICATOR_DATA);
   
   // prepare the rounded numbers for the patterns...
   PlotIndexSetInteger(bufferBuy1_ID, PLOT_ARROW, 129);  // number "1"
   PlotIndexSetInteger(bufferBuy2_ID, PLOT_ARROW, 130);  // number "2"
   PlotIndexSetInteger(bufferBuy3_ID, PLOT_ARROW, 131);  // number "3"
   PlotIndexSetInteger(bufferBuy1_ID, PLOT_ARROW_SHIFT, 15);
   PlotIndexSetInteger(bufferBuy2_ID, PLOT_ARROW_SHIFT, 15);
   PlotIndexSetInteger(bufferBuy3_ID, PLOT_ARROW_SHIFT, 15);
   
   PlotIndexSetInteger(bufferSell1_ID, PLOT_ARROW, 129);  // number "1"
   PlotIndexSetInteger(bufferSell2_ID, PLOT_ARROW, 130);  // number "2"
   PlotIndexSetInteger(bufferSell3_ID, PLOT_ARROW, 131);  // number "3"
   PlotIndexSetInteger(bufferSell1_ID, PLOT_ARROW_SHIFT, -15);
   PlotIndexSetInteger(bufferSell2_ID, PLOT_ARROW_SHIFT, -15);
   PlotIndexSetInteger(bufferSell3_ID, PLOT_ARROW_SHIFT, -15);


   // create hiMACD of the indicator
   hiMACD=iMACD( _Symbol, _Period, inpMAFast, inpMASlow, inpSignal, PRICE_CLOSE );

   // if the hiMACD is not created
   if(hiMACD==INVALID_HANDLE)
     {
      //--- tell about the failure and output the error code
      PrintFormat("Failed to create hiMACD of the iMACD indicator for the symbol %s/%s, error code %d", _Symbol, EnumToString(_Period), GetLastError());
      return(INIT_FAILED);
     }

   // show the indicator information on the sub window
   IndicatorSetString(INDICATOR_SHORTNAME, StringFormat("3 Rules MACD(%s,%d,%d,%d,%s)", EnumToString(_Period), inpMAFast,inpMASlow,inpSignal,EnumToString(PRICE_CLOSE)));

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

   int values_to_copy;                       // number of values copied from the iMACD indicator
   int calculated=BarsCalculated(hiMACD);    // determine the number of values calculated in the indicator
   if (calculated<=0) { return(0); }
   
   // if it is the first start of calculation of the indicator or if the number of values in the iMACD indicator changed
   // or if it is necessary to calculated the indicator for two or more bars (it means something has changed in the price history)
   if(prev_calculated==0 || calculated!=bars_calculated || rates_total>prev_calculated+1)
     {
      // if the bufferMACD array is greater than the number of values in the iMACD indicator for symbol/period, then we don't copy everything 
      // otherwise, we copy less than the size of indicator buffers
      if(calculated>rates_total) values_to_copy=rates_total;
      else                       values_to_copy=calculated;
     }
   else
     {
      // it means that it's not the first time of the indicator calculation, and since the last call of OnCalculate()
      // for calculation not more than one bar is added
      values_to_copy=(rates_total-prev_calculated)+1;
     }
     
   // fill the arrays with values of the iMACD indicator
   // if FillArraysFromBuffer returns false, it means the information is nor ready yet, quit operation
   if(!FillArraysFromBuffers( bufferMACD, bufferSignal, hiMACD, values_to_copy)) return(0);


   // processes the BUY and SELL signals
   for (int i=1;i<rates_total ;i++) {
      
      // by default, cleans all numbers for the candle...
      bufferBuy1[i]=bufferBuy2[i]=bufferBuy3[i]=EMPTY_VALUE;
      bufferSell1[i]=bufferSell2[i]=bufferSell3[i]=EMPTY_VALUE;
      
      // start of the BUY signal - RULE #1...
      if (bufferMACD[i-1]>bufferSignal[i-1] && bufferMACD[i]<bufferSignal[i]) {  //MACD crosses below Signal
         ruleBuy1=true; ruleBuy2=false;
         bufferBuy1[i]=bufferMACD[i];
      }
      // RULE BUY #2...
      if (bufferMACD[i-1]>0 && bufferMACD[i]<0 && ruleBuy1) {  //MACD crosses below Zero Line
         ruleBuy2 = true;
         bufferBuy2[i]=bufferMACD[i];
      }
      // RULE BUY #3...
      if (bufferMACD[i-1]<bufferSignal[i-1] && bufferMACD[i]>bufferSignal[i] && ruleBuy1 && ruleBuy2) {
         bufferBuy3[i]=bufferMACD[i];
         ruleBuy1 = ruleBuy2 = false;
      }


      // start of the SELL signal - RULE #1...
      if (bufferMACD[i-1]<bufferSignal[i-1] && bufferMACD[i]>bufferSignal[i]) {  //MACD crosses above Signal
         ruleSell1=true; ruleSell2=false;
         bufferSell1[i]=bufferMACD[i];  
      }
      // RULE SELL #2...
      if (bufferMACD[i-1]<0 && bufferMACD[i]>0 && ruleSell1) {  //MACD crosses above Zero Line
         ruleSell2 = true;
         bufferSell2[i]=bufferMACD[i];
      }
      // RULE SELL #3...
      if (bufferMACD[i-1]>bufferSignal[i-1] && bufferMACD[i]<bufferSignal[i] && ruleSell1 && ruleSell2) {
         bufferSell3[i]=bufferMACD[i];
         ruleSell1 = ruleSell2 = false;  //prepare to the next Sell signal
      }
      
   }

   bars_calculated=calculated;   // memorize the number of values in the iMACD

   return(rates_total);     // return the prev_calculated value for the next call
  }
  
  
  
//+------------------------------------------------------------------+
//| Filling indicator buffers from the iMACD indicator               |
//+------------------------------------------------------------------+
bool FillArraysFromBuffers(double &macd_buffer[],    // indicator buffer of MACD values
                           double &signal_buffer[],  // indicator buffer of the signal line of MACD 
                           int ind_hiMACD,           // hiMACD of the hiMACD indicator
                           int amount                // number of copied values
                           )
  {
   
   ResetLastError();  // reset error code
   
   // fill a part of the ibufferMACD array with values from the indicator buffer that has 0 index
   if(CopyBuffer(ind_hiMACD,0,0,amount,macd_buffer)<0)
     {
      // if the copying fails, tell the error code
      PrintFormat("Failed to copy data from the iMACD indicator, error code %d",GetLastError());
      return(false);  // quit with zero result - it means that the indicator is considered as not calculated
     }
 
   // fill a part of the bufferSignal array with values from the indicator buffer that has index 1
   if(CopyBuffer(ind_hiMACD,1,0,amount,signal_buffer)<0)
     {
      // if the copying fails, tell the error code
      PrintFormat("Failed to copy data from the iMACD indicator, error code %d",GetLastError());
      return(false);   // quit with zero result - it means that the indicator is considered as not calculated
     }

   return(true);
  }
  


//+------------------------------------------------------------------+
//| indicator exit... freeing memory...                              |
//+------------------------------------------------------------------+
void OnDeinit(const int reason) {
   IndicatorRelease(hiMACD);
   Comment(" ");
}
  
//+------------------------------------------------------------------+