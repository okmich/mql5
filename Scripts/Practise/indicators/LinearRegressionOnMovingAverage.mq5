//+------------------------------------------------------------------+
//|                              LinearRegressionOnMovingAverage.mq5 |
//|                                    Copyright 2021, Michael Enudi |
//|                                             okmich2002@yahoo.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2021, Michael Enudi"
#property link      "okmich2002@yahoo.com"
#property version   "1.00"

#include <Indicators\Trend.mqh>
#include <Okmich\Common\Common.mqh>

//+------------------------------------------------------------------+
//| Script program start function                                    |
//+------------------------------------------------------------------+
void OnStart()
  {
   int barsToCopy = 180;
   int regressionPeriod = 10;
   CiMA              m_ShortCiMA, m_LongCiMA;
   m_ShortCiMA.Create(_Symbol, _Period, 20, 0, MODE_EMA, PRICE_CLOSE);
   m_LongCiMA.Create(_Symbol, _Period, 90, 0, MODE_EMA, PRICE_CLOSE);

   m_ShortCiMA.Refresh();
   m_LongCiMA.Refresh();

   double shortBuffer[], longBuffer[];
   ArraySetAsSeries(shortBuffer, true);
   ArraySetAsSeries(longBuffer, true);

   m_LongCiMA.GetData(1, barsToCopy, 0, longBuffer);
   m_ShortCiMA.GetData(1, barsToCopy, 0, shortBuffer);
   double longSlope, shortSlope, shortIntercept, longIntercept;
   datetime shiftTime;
   LinReg shortReg, longReg;
   for(int i = 1; i <= barsToCopy - regressionPeriod -1 ; i++)
     {
      longReg = CalculateLinearRegression(longBuffer, regressionPeriod, i);
      shortReg = CalculateLinearRegression(shortBuffer, regressionPeriod, i);
      
      longSlope = longReg.slope; longIntercept = longReg.intercept;
      shortSlope = shortReg.slope; shortIntercept = shortReg.intercept;
      
      shiftTime = iTime(_Symbol, _Period, i);

      Print("Shift ", formatDateToStringISO(shiftTime), ": short slope=> ", NormalizeDouble(shortSlope, _Digits),
            " long slope=> ", NormalizeDouble(longSlope, _Digits),
            "| short intrcpt=> ", NormalizeDouble(shortIntercept, _Digits),
            " long intrcpt=> ", NormalizeDouble(longIntercept, _Digits));
     }
  }
//+------------------------------------------------------------------+
