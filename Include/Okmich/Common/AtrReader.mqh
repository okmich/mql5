//+------------------------------------------------------------------+
//|                                                    AtrReader.mqh |
//|                                    Copyright 2020, Michael Enudi |
//|                                             okmich2002@yahoo.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2020, Michael Enudi"
#property description "A utility class for calculating ATR values and returning values necessary for describing volatility"
#property link      "okmich2002@yahoo.com"

#include <Math\Stat\Math.mqh>
#include <Okmich\Common\Common.mqh>
#include <Okmich\Common\LogNormalSeries.mqh>
//+------------------------------------------------------------------+
//| AtrReader                                                        |
//+------------------------------------------------------------------+
class CAtrReader
  {
private:
   string            mSymbol;
   ENUM_TIMEFRAMES   mTimeFrame;
   int               mPeriod;
   double            mProbThreshold;
   int               mHistoryBars;
   MqlRates          mPriceSeries[];
   double            mATRBuffer[];
   double            currentAtrThreshold;

   bool              processAtr();

public:
                     CAtrReader(string symbol, ENUM_TIMEFRAMES timeFrame,
              int atrPeriod = 14, int InpHistoryPeriod = 90, double InpProbThreshold = 0.4)
     {
      mSymbol = symbol;
      mTimeFrame = timeFrame;
      mPeriod = atrPeriod;
      mHistoryBars = InpHistoryPeriod;
      mProbThreshold = InpProbThreshold;
      ArraySetAsSeries(mPriceSeries, false);
      ArraySetAsSeries(mATRBuffer, false);
     };

   double            GetCurrentThreshold() {return currentAtrThreshold;}
   double            atr(int shift=0);
   double            atrPoints(int shift=0);
   ENUM_HIGHLOW      classifyATR(int shift=0);
  };

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
double CAtrReader::atr(int shift=0)
  {
   int bars = mPeriod + 1;
   int copied = CopyRates(mSymbol, mTimeFrame, shift, bars, mPriceSeries);
   if(copied < bars)
      return EMPTY_VALUE;

   double _TRBuffer[];
   ArrayResize(_TRBuffer, mPeriod);

//--- filling out the array of True Range values
   for(int i=1; i < bars; i++)
      _TRBuffer[i-1]=MathMax(mPriceSeries[i].high,  mPriceSeries[i-1].close) -
                     MathMin(mPriceSeries[i].low, mPriceSeries[i-1].close);

   return MathMean(_TRBuffer);
  }


//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
double CAtrReader::atrPoints(int shift=0)
  {
   double atrValue = atr(shift);
   if(atrValue == EMPTY_VALUE)
      return EMPTY_VALUE;
   else
     {
      double symPoint = SymbolInfoDouble(mSymbol, SYMBOL_POINT);
      return atrValue/symPoint;
     }
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
bool CAtrReader::processAtr()
  {
   int bars = mHistoryBars + mPeriod + 1;
   int copied = CopyRates(mSymbol, mTimeFrame, 0, bars, mPriceSeries);
   if(copied < bars)
      return false;

   double iTRBuffer[];
   ArrayResize(iTRBuffer, bars - 1);
   ArrayResize(mATRBuffer, mHistoryBars);

//--- filling out the array of True Range values
   for(int i=1; i < bars; i++)
     {
      iTRBuffer[i-1]=MathMax(mPriceSeries[i].high,  mPriceSeries[i-1].close) -
                     MathMin(mPriceSeries[i].low, mPriceSeries[i-1].close);
      if(i == mPeriod + 1) //first index of mATRBuffer
        {
         double sum = 0;
         for(int j = 0; j < mPeriod; j++)
            sum += iTRBuffer[j];

         mATRBuffer[i - (mPeriod + 1)] = sum/mPeriod;
        }
      else
         if(i > mPeriod + 1)
            mATRBuffer[i - (mPeriod + 1)] = mATRBuffer[i - (mPeriod + 2)]+
                                            (iTRBuffer[i-1]-iTRBuffer[i-(mPeriod+1)])/mPeriod;
     }
   return true;
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
ENUM_HIGHLOW CAtrReader::classifyATR(int shift=0)
  {
   processAtr();
   double atrValue = mATRBuffer[ArraySize(mATRBuffer) - shift - 1];

   CLogNormalSeries<double> cLogNormalSeries(mHistoryBars);
   cLogNormalSeries.Refresh(mATRBuffer);
   currentAtrThreshold = cLogNormalSeries.QuantileDistribution(mProbThreshold);

   if(atrValue > currentAtrThreshold)
      return HIGHLOW_HIGH;
   else
      if(atrValue < currentAtrThreshold)
         return HIGHLOW_LOW;
      else
         return HIGHLOW_NA;
  }
//+------------------------------------------------------------------+
