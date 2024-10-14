//+------------------------------------------------------------------+
//|                                             HowLongInRsiOBOS.mq5 |
//|                                    Copyright 2024, Michael Enudi |
//|                                             okmich2002@yahoo.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2024, Michael Enudi"
#property link      "okmich2002@yahoo.com"
#property version   "1.00"


#property description "Script based on RSI indicator data displays" 
#property description "how often the market was in" 
#property description "overbought and oversold areas in the specified time interval." 
//--- display the window of input parameters when launching the script 
#property script_show_inputs 
//--- input parameters 
input int                InpMAPeriod=14;                    // Moving average period 
input ENUM_APPLIED_PRICE InpAppliedPrice=PRICE_CLOSE;       // Price type 
input double             InpOversoldValue=30.0;             // Oversold level 
input double             InpOverboughtValue=70.0;           // Overbought level 
input datetime           InpDateStart=D'2012.01.01 00:00';  // Analysis start date 
input datetime           InpDateFinish=D'2013.01.01 00:00'; // Analysis finish date 
//+------------------------------------------------------------------+ 
//| Script program start function                                    | 
//+------------------------------------------------------------------+ 
void OnStart() 
  { 
   double rsi_buff[]; // array of the indicator values 
   int    size=0;     // array size 
//--- receive RSI indicator handle 
   ResetLastError(); 
   int rsi_handle=iRSI(Symbol(),Period(),InpMAPeriod,InpAppliedPrice); 
   if(rsi_handle==INVALID_HANDLE) 
     { 
      //--- failed to receive the indicator handle 
      PrintFormat("Indicator handle receiving error. Error code = %d",GetLastError()); 
      return; 
     } 
//--- being in the loop, until the indicator calculates all its values 
   while(BarsCalculated(rsi_handle)==-1) 
     { 
      //--- exit if the indicator has forcedly completed the script's operation 
      if(IsStopped()) 
         return; 
      //--- a pause to allow the indicator to calculate all its values 
      Sleep(10); 
     } 
//--- copy the indicator values for a certain period of time 
   ResetLastError(); 
   if(CopyBuffer(rsi_handle,0,InpDateStart,InpDateFinish,rsi_buff)==-1) 
     { 
      PrintFormat("Failed to copy the indicator values. Error code = %d",GetLastError()); 
      return; 
     } 
//--- receive the array size 
   size=ArraySize(rsi_buff); 
//--- sort out the array 
   ArraySort(rsi_buff); 
//--- find out the time (in percentage terms) the market was in the oversold area 
   double ovs=(double)ArrayBsearch(rsi_buff,InpOversoldValue)*100/(double)size; 
//--- find out the time (in percentage terms) the market was in the overbought area 
   double ovb=(double)(size-ArrayBsearch(rsi_buff,InpOverboughtValue))*100/(double)size; 
//--- form the strings for displaying the data 
   string str="From "+TimeToString(InpDateStart,TIME_DATE)+" to " 
              +TimeToString(InpDateFinish,TIME_DATE)+" the market was:"; 
   string str_ovb="in overbought area "+DoubleToString(ovb,2)+"% of time"; 
   string str_ovs="in oversold area "+DoubleToString(ovs,2)+"% of time"; 
//--- display the data on the chart 
   CreateLabel("top",5,60,str,clrDodgerBlue); 
   CreateLabel("overbought",5,35,str_ovb,clrDodgerBlue); 
   CreateLabel("oversold",5,10,str_ovs,clrDodgerBlue); 
//--- redraw the chart 
   ChartRedraw(0); 
//--- pause 
   Sleep(10000); 
  } 
//+------------------------------------------------------------------+ 
//| Display comment in the bottom left corner of the chart           | 
//+------------------------------------------------------------------+ 
void CreateLabel(const string name,const int x,const int y, 
                 const string str,const color clr) 
  { 
//--- create the label 
   ObjectCreate(0,name,OBJ_LABEL,0,0,0); 
//--- bind the label to the bottom left corner 
   ObjectSetInteger(0,name,OBJPROP_CORNER,CORNER_LEFT_LOWER); 
//--- change position of the anchor point 
   ObjectSetInteger(0,name,OBJPROP_ANCHOR,ANCHOR_LEFT_LOWER); 
//--- distance from the anchor point in X-direction 
   ObjectSetInteger(0,name,OBJPROP_XDISTANCE,x); 
//--- distance from the anchor point in Y-direction 
   ObjectSetInteger(0,name,OBJPROP_YDISTANCE,y); 
//--- label text 
   ObjectSetString(0,name,OBJPROP_TEXT,str); 
//--- text color 
   ObjectSetInteger(0,name,OBJPROP_COLOR,clr); 
//--- text size 
   ObjectSetInteger(0,name,OBJPROP_FONTSIZE,12); 
  }