//+------------------------------------------------------------------+
//|                                                   TrendLines.mq5 |
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
   int hist = (int)ChartGetInteger(0, CHART_VISIBLE_BARS);
   double highs[];
   double lows[];
   datetime times[];

   ArraySetAsSeries(highs, true);
   ArraySetAsSeries(lows, true);
   ArraySetAsSeries(times, true);

   int highsCopied = CopyHigh(_Symbol, _Period, 0, hist, highs);
   int lowsCopied = CopyLow(_Symbol, _Period, 0, hist, lows);
   CopyTime(_Symbol, _Period, 0, hist, times);

   int lastTopIdx = ArrayMaximum(highs, hist - 5, 5);
   int lastBottomIdx = ArrayMinimum(lows, hist - 5, 5);

   int nextHighIdx;
   for(int barIndx = 595; barIndx >= 2; barIndx--)
     {
      //find the next highs
      if(isLocalTop(highs, barIndx))
        {
         //draw trend line from lastTopIdx to nextHighIdx
         drawLine(0, "Line_" + IntegerToString(barIndx), 0, times[lastTopIdx], highs[lastTopIdx],
                  times[barIndx], highs[barIndx],
                  clrRed, STYLE_DOT, 1, false, true, true, false);
          lastTopIdx = barIndx;
        }

      //find lows


     }

  }
//+------------------------------------------------------------------+

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
bool isLocalTop(double& prices[], int indx)
  {   
   double nowPrice = prices[indx];   
   return nowPrice > prices[indx - 2] && nowPrice > prices[indx - 1] &&
    nowPrice > prices[indx + 1] && nowPrice > prices[indx + 2] ;
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
bool drawLine(long            chart_ID=0,
              string          name="Line",
              int             sub_window=0,
              datetime        time1=0,
              double          price1=0,
              datetime        time2=0,
              double          price2=0,
              color           clr=clrRed,
              ENUM_LINE_STYLE style=STYLE_SOLID,
              int             width=1,
              bool            back=false,
              bool            selectable=false,
              bool            ray=true,
              bool            hidden=false,
              long            z_order=0)
  {
   ResetLastError();
   if(!ObjectCreate(chart_ID,name,OBJ_TREND,sub_window,time1,price1,time2, price2))
     {
      Print(__FUNCTION__,
            ": failed to create a trend line! Error code = ",GetLastError());
      return(false);
     }

   ObjectSetInteger(chart_ID,name,OBJPROP_COLOR,clr); //--- set line color
   ObjectSetInteger(chart_ID,name,OBJPROP_STYLE,style); //--- set line display style
   ObjectSetInteger(chart_ID,name,OBJPROP_WIDTH,width);  //--- set line width
   ObjectSetInteger(chart_ID,name,OBJPROP_BACK,back); //--- display in the foreground (false) or background (true)
   ObjectSetInteger(chart_ID,name,OBJPROP_SELECTABLE,selectable);
   ObjectSetInteger(chart_ID,name,OBJPROP_SELECTED,false);
   ObjectSetInteger(chart_ID,name,OBJPROP_RAY_LEFT,false); //--- Ray goes to the left
   ObjectSetInteger(chart_ID,name,OBJPROP_RAY_RIGHT,false); //--- Ray goes to the right
   ObjectSetInteger(chart_ID,name,OBJPROP_HIDDEN,hidden); //--- hide (true) or display (false) graphical object name in the object list
   ObjectSetInteger(chart_ID,name,OBJPROP_ZORDER,z_order);
   return true;
  }
//+------------------------------------------------------------------+
