//+------------------------------------------------------------------+
//|                                                  TestOnChart.mq5 |
//|                                    Copyright 2020, Michael Enudi |
//|                                             okmich2002@yahoo.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2020, Michael Enudi"
#property link      "okmich2002@yahoo.com"
#property version   "1.00"
//+------------------------------------------------------------------+
//| Script program start function                                    |
//+------------------------------------------------------------------+
void OnStart()
  {
   writeResultToChart("XXXXX", "Hello world");
   writeResultToChart("XXXXX", "Who is there");
  }
//+------------------------------------------------------------------+
void writeResultToChart(string symbol, string value)
  {
   string label_name=symbol;
   if(ObjectFind(0,label_name) >= 0)
     {
      ObjectDelete(0, label_name);
     }
   if(ObjectFind(0,label_name)<0)
     {
      Print("Object ",label_name," not found. Error code = ",GetLastError());
      //--- create Label object
      ObjectCreate(0,label_name,OBJ_LABEL,0,0,0);
      //--- set X coordinate
      ObjectSetInteger(0,label_name,OBJPROP_XDISTANCE,200);
      //--- set Y coordinate
      ObjectSetInteger(0,label_name,OBJPROP_YDISTANCE,300);
      //--- define text color
      ObjectSetInteger(0,label_name,OBJPROP_COLOR,clrWhite);
      //--- define text for object Label
      ObjectSetString(0,label_name,OBJPROP_TEXT,value);
      //--- define font
      ObjectSetString(0,label_name,OBJPROP_FONT,"Times New Roman");
      //--- define font size
      ObjectSetInteger(0,label_name,OBJPROP_FONTSIZE,10);
      //--- 45 degrees rotation clockwise
      ObjectSetDouble(0,label_name,OBJPROP_ANGLE,0);
      //--- disable for mouse selecting
      ObjectSetInteger(0,label_name,OBJPROP_SELECTABLE,true);
      //--- draw it on the chart
      ChartRedraw(0);
     }
  }
//+------------------------------------------------------------------+
