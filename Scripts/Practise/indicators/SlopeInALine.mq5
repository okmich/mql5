//+------------------------------------------------------------------+
//|                                                 SlopeInALine.mq5 |
//|                                    Copyright 2020, Michael Enudi |
//|                                             okmich2002@yahoo.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2020, Michael Enudi"
#property link      "okmich2002@yahoo.com"
#property version   "1.00"
//+------------------------------------------------------------------+
//| Script program start function                                    |
//+------------------------------------------------------------------+
#include <Indicators\Oscilators.mqh>
#include <Okmich\Common\Common.mqh>

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void OnStart()
  {
   CiATR ciATR;
   bool wasCreated = ciATR.Create(_Symbol, _Period, 14);
   double atr[];
   int period = 5;
   ArraySetAsSeries(atr, true);

   ciATR.Refresh(); //always call this method before GetData() or Main()
   double rawSlope=0, slope=0;
   LinReg linReg;
   for(int i = 0; i < 90; i++)
     {
      ciATR.GetData(i, period, 0, atr);
      linReg = CalculateLinearRegression(atr, period,0);
      slope = RadToDegrees(MathArctan(rawSlope));
      ArrayPrint(atr, 4, ",");
      Print(i, " -> intercept ", linReg.intercept, "  -- > rawSlope  ", linReg.rawSlope, "  -- > Slope  ", linReg.slope);
     }

//
//   double data[];
//   ArraySetAsSeries(data, false);
//   ArrayResize(data, 5);
//   data[0] = 0.01007;
//   data[1] = 0.01033;
//   data[2] = 0.01007;
//   data[3] = 0.01030;
//   data[4] = 0.01042;
//
//   LinReg linReg = CalculateLinearRegression(data, 5, 0);
//   Comment(linReg.rawSlope, " ============ ",linReg.intercept, " ==== ", linReg.slope);
  }
//+------------------------------------------------------------------+
