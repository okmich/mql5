//+------------------------------------------------------------------+
//|                                                        HLine.mq5 |
//|                                    Copyright 2020, Michael Enudi |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2020, Michael Enudi"
#property link      "https://www.mql5.com"
#property version   "1.00"
//+------------------------------------------------------------------+
//| Script program start function                                    |
//+------------------------------------------------------------------+
void OnStart()
  {
   //int hist = (int)ChartGetInteger(0, CHART_VISIBLE_BARS);
   int hist = 120;
   double highs[];
   double lows[];
   
   ArraySetAsSeries(highs, true);
   ArraySetAsSeries(lows, true);
   
   int highsCopied = CopyHigh(_Symbol, _Period, 0, hist, highs);
   int lowsCopied = CopyLow(_Symbol, _Period, 0, hist, lows);

   double top = highs[ArrayMaximum(highs, 0)];
   double bottom = lows[ArrayMinimum(lows, 0)]; 
   
   //--- draw support and resistance
   drawHLine(0, "Support", 0, bottom, clrBlue, STYLE_SOLID, 2, false, true, true, false, 0);
   drawHLine(0, "Resistance", 0, top, clrLime, STYLE_SOLID, 2, false, true, false, false, 0);
   
   Comment("The channel is ", ((top-bottom)/_Point));
   double max_price=ChartGetDouble(0,CHART_PRICE_MAX); 
   double min_price=ChartGetDouble(0,CHART_PRICE_MIN); 
   
   Print("max_price " , max_price);
   Print("min_price " , min_price);
  }
//+------------------------------------------------------------------+

bool drawHLine(const long            chart_ID=0,        // chart's ID 
               const string          name="VLine",      // line name 
               const int             sub_window=0,      // subwindow index 
               double                price=0,            // line time 
               const color           clr=clrRed,        // line color 
               const ENUM_LINE_STYLE style=STYLE_SOLID, // line style 
               const int             width=1,           // line width 
               const bool            back=false,        // in the background 
               const bool            selection=true,    // highlight to move 
               const bool            ray=true,          // line's continuation down 
               const bool            hidden=true,       // hidden in the object list 
               const long            z_order=0)         // priority for mouse click 
  { 
  //--- clear errors
   ResetLastError(); 
   //--- create a vertical line 
   bool didDraw = ObjectCreate(chart_ID,name,OBJ_HLINE,sub_window,0,price);
   //--- check the success of the draw operation
   if(!didDraw) { 
      Print(__FUNCTION__, 
            ": failed to create a vertical line! Error code = ",GetLastError()); 
      return(false); 
   } 

   ObjectSetInteger(chart_ID,name,OBJPROP_COLOR,clr); //--- set line color 
   ObjectSetInteger(chart_ID,name,OBJPROP_STYLE,style); //--- set line display style 
   ObjectSetInteger(chart_ID,name,OBJPROP_WIDTH,width);  //--- set line width 
   ObjectSetInteger(chart_ID,name,OBJPROP_BACK,back); //--- display in the foreground (false) or background (true) 
   //--- enable (true) or disable (false) the mode of moving the line by mouse 
   //--- when creating a graphical object using ObjectCreate function, the object cannot be 
   //--- highlighted and moved by default. Inside this method, selection parameter 
   //--- is true by default making it possible to highlight and move the object 
   ObjectSetInteger(chart_ID,name,OBJPROP_SELECTABLE,selection); 
   ObjectSetInteger(chart_ID,name,OBJPROP_SELECTED,selection); 
   ObjectSetInteger(chart_ID,name,OBJPROP_RAY_LEFT,ray); //--- Ray goes to the left
   ObjectSetInteger(chart_ID,name,OBJPROP_RAY_RIGHT,ray); //--- Ray goes to the right
   ObjectSetInteger(chart_ID,name,OBJPROP_HIDDEN,hidden); //--- hide (true) or display (false) graphical object name in the object list 
   ObjectSetInteger(chart_ID,name,OBJPROP_ZORDER,z_order); 
   return(true); 
} 
