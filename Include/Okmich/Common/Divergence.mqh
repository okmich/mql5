//+------------------------------------------------------------------+
//|                                                   Divergence.mqh |
//|                                    Copyright 2020, Michael Enudi |
//|                                             okmich2002@yahoo.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2020, Michael Enudi"
#property link      "okmich2002@yahoo.com"

enum ENUM_DIVERGENCE
  {
   DIV_BULL_CLASS_A,
   DIV_BULL_CLASS_B,
   DIV_BULL_CLASS_C,
   DIV_BEAR_CLASS_A,
   DIV_BEAR_CLASS_B,
   DIV_BEAR_CLASS_C,
   DIV_NONE
  };

struct DivergenceObj
  {
   ENUM_DIVERGENCE   type;
   int               shiftFrom;
   int               shiftTo;
  };

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
class CDivergence
  {
private:
   ENUM_DIVERGENCE   testDivOnHighs(double &buff[], double &highs[], int firstIdx, int secondIdx);
   ENUM_DIVERGENCE   testDivOnLows(double &buff[], double &lows[], int firstIdx, int secondIdx);

public:
                     CDivergence() {};

   bool              isPeak(double &arr[], int i);
   int               nextPeak(int i, int bar, double &buf[]);
   bool              isTrough(double &arr[], int i);
   int               nextTrough(int l,int bar,double &buf[]);
   void              findDivergenceOnHighs(double &buff[], double &highs[], DivergenceObj &results[]);
   void              findDivergenceOnLows(double &buff[], double &highs[], DivergenceObj &results[]);
  };

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void CDivergence::findDivergenceOnHighs(double &buff[], double &highs[], DivergenceObj &results[])
  {
   if(ArraySize(buff) != ArraySize(highs))
      return;

//check if the Arrays are series and make them series if they are not.
   bool isBuffSeries = ArrayGetAsSeries(buff);
   bool isHighSeries = ArrayGetAsSeries(highs);
   if(!isBuffSeries)
      ArraySetAsSeries(buff, true);
   if(!isHighSeries)
      ArraySetAsSeries(highs, true);

//-- get the number of bars
   int barCount = ArraySize(buff);
   for(int i = 2; i < barCount - 2; i++)
     {
      if(isPeak(buff, i))
        {
         int nextPeakIdx = nextPeak(i, barCount, buff);
         if(nextPeakIdx != -1)
           {
            int found = 0;
            ENUM_DIVERGENCE res = testDivOnHighs(buff, highs, i, nextPeakIdx);
            if(res != DIV_NONE)
              {
               found++;
               ArrayResize(results, found);
               DivergenceObj d;
               d.type = res;
               d.shiftFrom = nextPeakIdx;
               d.shiftTo = i;
               results[found-1] = d;
              }
           }
        }
     }

//--- reset the array series status
   if(!isBuffSeries)
      ArraySetAsSeries(buff, false);
   if(!isHighSeries)
      ArraySetAsSeries(highs, false);
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void CDivergence::findDivergenceOnLows(double &buff[], double &lows[], DivergenceObj &results[])
  {
   if(ArraySize(buff) != ArraySize(lows))
      return;

//check if the Arrays are series and make them series if they are not.
   bool isBuffSeries = ArrayGetAsSeries(buff);
   bool isLowSeries = ArrayGetAsSeries(lows);
   if(!isBuffSeries)
      ArraySetAsSeries(buff, true);
   if(!isLowSeries)
      ArraySetAsSeries(lows, true);

//-- get the number of bars
   int barCount = ArraySize(buff);
   for(int i = 2; i < barCount - 2; i++)
     {
      if(isTrough(buff, i))
        {
         int nextTroughIdx = nextTrough(i, barCount, buff);
         if(nextTroughIdx != -1)
           {
            int found = 0;
            ENUM_DIVERGENCE res = testDivOnLows(buff, lows, i, nextTroughIdx);
            if(res != DIV_NONE)
              {
               found++;
               ArrayResize(results, found);
               DivergenceObj d;
               d.type = res;
               d.shiftFrom = nextTroughIdx;
               d.shiftTo = i;
               results[found-1] = d;
              }
           }
        }
     }

//--- reset the array series status
   if(!isBuffSeries)
      ArraySetAsSeries(buff, false);
   if(!isLowSeries)
      ArraySetAsSeries(lows, false);
  }


//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
bool CDivergence::isPeak(double &arr[], int i)
  {
   return arr[i-2] < arr[i] && arr[i-1] < arr[i] &&
          arr[i+1] < arr[i] && arr[i+2] < arr[i];
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
bool CDivergence::isTrough(double &arr[], int i)
  {
   return arr[i-2] > arr[i] && arr[i-1] > arr[i] &&
          arr[i+1] > arr[i] && arr[i+2] > arr[i];
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
int CDivergence::nextPeak(int l,int bar,double &buf[])
  {
   for(int i=l+5; i<bar-2; i++)
      if(isPeak(buf, i))
         return i;
   return -1;
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
int CDivergence::nextTrough(int l,int bar,double &buf[])
  {
   for(int i=l+5; i<bar-2; i++)
      if(isTrough(buf, i))
         return i;
   return -1;
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
ENUM_DIVERGENCE CDivergence::testDivOnHighs(double &buff[],double &highs[],int firstIdx,int secondIdx)
  {
   if(buff[firstIdx] < buff[secondIdx] &&
      highs[firstIdx] > highs[secondIdx])
      //test that from firstIdx to secondIdx, highs went lower while buff was higher
      return DIV_BEAR_CLASS_A;
   else
      return DIV_NONE;
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
ENUM_DIVERGENCE CDivergence::testDivOnLows(double &buff[],double &lows[],int firstIdx,int secondIdx)
  {
   if(buff[firstIdx] < buff[secondIdx] &&
      lows[firstIdx] > lows[secondIdx])
      //test that from firstIdx to secondIdx, highs went lower while buff was higher
      return DIV_BULL_CLASS_A;
   else
      return DIV_NONE;
  }
//+------------------------------------------------------------------+
