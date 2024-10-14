//+------------------------------------------------------------------+
//|                                             SlopeCalculation.mq5 |
//|                                    Copyright 2023, Michael Enudi |
//|                                             okmich2002@yahoo.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2023, Michael Enudi"
#property link      "okmich2002@yahoo.com"
#property version   "1.00"

#include <Okmich/Common/Common.mqh>

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
double SlopeInDegrees(const double& data[], int startIndex, int count)
  {
// Check if startIndex is valid
   if(startIndex < 0 || startIndex >= ArraySize(data))
     {
      Print("Error: Invalid startIndex.");
      return 0;
     }
// Check if there are enough values from startIndex to the end of the array
   if(startIndex + count > ArraySize(data))
     {
      Print("Error: Not enough values in the array from startIndex.");
      return 0;
     }
// Calculate the mean of x and y
   double sumX = 0;
   double sumY = 0;
   double meanX, meanY;
   for(int i = startIndex; i < startIndex + count; ++i)
     {
      sumX += i - startIndex;
      // x-values are indices relative to startIndex
      sumY += data[i];
      // y-values are the actual data points
     }
   meanX = sumX / count;
   meanY = sumY / count;
// Calculate the numerator and denominator of the slope formula
   double numerator = 0;
   double denominator = 0;
   for(int i = startIndex; i < startIndex + count; ++i)
     {
      double x = i - startIndex;
      // x-values are indices relative to startIndex
      double y = data[i];
      // y-values are the actual data points
      numerator += (x - meanX) * (y - meanY);
      denominator += (x - meanX) * (x - meanX);
     }
   double slope = numerator / denominator;
   double slopeInDegrees = MathArctan(slope) * 180 / M_PI;
   
   return slopeInDegrees;
  }


//+------------------------------------------------------------------+
//| Script program start function                                    |
//+------------------------------------------------------------------+
void OnStart()
  {
//---
   LinReg lreg;
   int length = 20;
   double lastFivePrices[];
   ArraySetAsSeries(lastFivePrices, false);
   string message="";
//   for(int i=0; i<10; i++)
//     {
//      
//      lreg = CalculateLinearRegression(lastFivePrices, length, 0);
//      message += StringFormat("slope %d is %.2f. Raw slope is %.2f, Intercept is %f\n",
//                              i, lreg.slope, lreg.rawSlope, lreg.intercept);
//     }
//     Print("Using second method");
   for(int i=0; i<40; i++)
     {
      CopyClose(_Symbol, _Period, i, length, lastFivePrices);
      double slope = SlopeInDegrees(lastFivePrices, 0, length);
      message += StringFormat("slope %d is %.2f.\n",
                              i, slope);
     }
     

   Comment(message);
  }
//+------------------------------------------------------------------+
