//+------------------------------------------------------------------+
//|                                                    ADXWilder.mqh |
//|                                    Copyright 2020, Michael Enudi |
//|                                             okmich2002@yahoo.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2020, Michael Enudi"
#property link      "okmich2002@yahoo.com"
#property version   "1.00"

#include "BaseIndicator.mqh"

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
class CADXWilder : public CBaseIndicator
  {
private :
   double             mAdxValue, mAdxSlope;
   double             mDmiPlusValue, mDmiPlusSlope;
   double             mDmiMinusValue, mDmiMinusSlope;

   int                mBarsToCopy;
   //--- indicator paramter
   int                m_DmiPeriod;
   int                m_AdxPeriod;
   double             m_SignfSlope;
   double             mTrendIndx;
   double             mRangeIndx;
   //--- indicator
   int                m_AdxHandle;
   //--- indicator buffer
   double            mAdxBuffer[];
   double            mDmiMinusBuffer[], mDmiPlusBuffer[];

public:
                     CADXWilder(string symbol, ENUM_TIMEFRAMES period, int InputDmiPeriod=13,
              int InputAdxPeriod=8, double trendThreshold=25, double significantSlope=15,
              double rangeThreshold=20, int historyBars=10): CBaseIndicator(symbol, period)
     {
      m_DmiPeriod = InputDmiPeriod;
      m_AdxPeriod = InputAdxPeriod;
      m_SignfSlope = significantSlope;
      mTrendIndx = trendThreshold;
      mRangeIndx = rangeThreshold;
      mBarsToCopy = historyBars;
     }

   virtual bool       Init();
   virtual bool       Refresh(int ShiftToUse=1);
   virtual void       Release();

   double             GetData(int buffer=0, int shift=0);
   void               GetData(double &buffer[], int buffer=0, int shift=0);

   ENUM_TRENDSTATE    TrendState();
   bool               IsTrending();
   int                DmState(); //+1, -1 or 0
   int                Dominance(int shift = 1, int threshold = -1); //+1, -1 or 0
   int                DmContractionExtraction(); // +1 => expansion, -1, contraction, 0 - align
   int                Shape(); // +1 => expansion, -1, contraction, 0 - align

   ENUM_ENTRY_SIGNAL  DominantCrossOverWithRisingDX(int threshold = -1);
  };

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
bool CADXWilder::Init(void)
  {
   ArraySetAsSeries(mAdxBuffer, true);
   ArraySetAsSeries(mDmiMinusBuffer, true);
   ArraySetAsSeries(mDmiPlusBuffer, true);

   m_AdxHandle = iCustom(m_Symbol, m_TF, "Okmich\\Average Directional Movement Index Wilder",
                         m_DmiPeriod, m_AdxPeriod);

   return m_AdxHandle != INVALID_HANDLE;
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
bool CADXWilder::Refresh(int ShiftToUse=1)
  {
   m_ShiftToUse = ShiftToUse;
   int adxCopied = CopyBuffer(m_AdxHandle, 0, 0, mBarsToCopy, mAdxBuffer);
   int dmpCopied = CopyBuffer(m_AdxHandle, 1, 0, mBarsToCopy, mDmiPlusBuffer);
   int dmmCopied = CopyBuffer(m_AdxHandle, 2, 0, mBarsToCopy, mDmiMinusBuffer);

//--- copy data from buffers
   mAdxValue = mAdxBuffer[m_ShiftToUse];
   mAdxSlope = RegressionSlope(mAdxBuffer, 3, m_ShiftToUse);
   mDmiPlusValue = mDmiPlusBuffer[m_ShiftToUse];
   mDmiPlusSlope = RegressionSlope(mDmiPlusBuffer, 3, m_ShiftToUse);
   mDmiMinusValue = mDmiMinusBuffer[m_ShiftToUse];
   mDmiMinusSlope = RegressionSlope(mDmiMinusBuffer, 3, m_ShiftToUse);

   return mBarsToCopy == adxCopied && dmpCopied == adxCopied && dmpCopied == dmmCopied;
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void CADXWilder::Release(void)
  {
   IndicatorRelease(m_AdxHandle);
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
double CADXWilder::GetData(int bufferIndx=0, int shift=0)
  {
   if(shift >= mBarsToCopy || bufferIndx > 2)
      return EMPTY_VALUE;

   switch(bufferIndx)
     {
      case 0:
         return mAdxBuffer[shift];
      case 1:
         return mDmiPlusBuffer[shift];
      case 2:
         return mDmiMinusBuffer[shift];
      default:
         return EMPTY_VALUE;
     }
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void CADXWilder::GetData(double &buffer[], int bufferIndx=0, int shift=0)
  {
   if(shift >= mBarsToCopy || bufferIndx > 1)
      return;

   ArraySetAsSeries(buffer, true);
   ArrayResize(buffer, mBarsToCopy - shift);

   switch(bufferIndx)
     {
      case 0:
         ArrayCopy(buffer, mAdxBuffer, 0, shift);
         break;
      case 1:
         ArrayCopy(buffer, mDmiPlusBuffer, 0, shift);
         break;
      case 2:
         ArrayCopy(buffer, mDmiMinusBuffer, 0, shift);
         break;
      default:
         break;
     }
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
ENUM_TRENDSTATE CADXWilder::TrendState()
  {
//   double _maxDmiValue = MathMax(mDmiMinusValue, mDmiPlusValue);
//   double _minDmiValue = MathMin(mDmiMinusValue, mDmiPlusValue);
//
////TREND - when adx is above 25 and domainant dmi is above mTrendIndx
//   if(mAdxValue >= mTrendIndx && _maxDmiValue > mTrendIndx)
//      return TS_TREND;
//
//TREND - when adx crosses threshold from above. However
//there is a DMI crossover in the previous candle
//and the dominant index is above threshold
   int shift2Dominance = Dominance(2);
   int shift1Dominance = Dominance(1);
   if(mAdxBuffer[2] > mTrendIndx &&
      -shift2Dominance == shift1Dominance && shift2Dominance != 0) //flipped dominance
      return TS_TREND;

//TREND - when adx is above 25 and sloping upward
   if(mAdxValue >= mTrendIndx && mAdxSlope > 0)
      return TS_TREND;

//TREND - when adx is greater than significant-slope
   if(mAdxSlope > m_SignfSlope)
      return TS_TREND;

//TREND - when adx is greater than 25 but sloping less than m_SignfSlope
   if(mAdxValue > mTrendIndx && mAdxSlope > -1.5 * m_SignfSlope)
      return TS_TREND;

   return TS_FLAT;
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
bool CADXWilder::IsTrending(void)
  {
   return TrendState() == TS_TREND;
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
int CADXWilder::Dominance(int shift = 1, int threshold = -1)
  {
   double thresh = (threshold == -1) ? mTrendIndx : threshold;
//both dmi are below mTrendIndx
   if(mDmiPlusBuffer[shift] < thresh && mDmiMinusBuffer[shift] < thresh)
      return 0;
//di+ is above mTrendIndx and greater than di-
   if(mDmiPlusBuffer[shift] > thresh && mDmiPlusBuffer[shift] > mDmiMinusBuffer[shift])
      return 1;
//di- is above mTrendIndx and greater than di+
   if(mDmiMinusBuffer[shift] > thresh && mDmiMinusBuffer[shift] > mDmiPlusBuffer[shift])
      return -1;

   return 0;
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
int CADXWilder::DmState(void)
  {
   return (mDmiPlusValue > mDmiMinusValue) ? 1 : (mDmiPlusValue < mDmiMinusValue) ? -1 : 0;
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
int CADXWilder::DmContractionExtraction(void)
  {
//-- 1 for expansion
   if((mDmiPlusValue > mDmiMinusValue) &&
      (mDmiPlusSlope > 0 && mDmiMinusSlope < 0))
      return 1;
   else
      if((mDmiMinusValue > mDmiPlusValue) &&
         (mDmiMinusSlope > 0 && mDmiPlusSlope < 0))
         return 1;

//-- -1 for contraction
   if((mDmiPlusValue > mDmiMinusValue) &&
      (mDmiPlusSlope < 0 && mDmiMinusSlope > 0))
      return -1;
   else
      if((mDmiMinusValue > mDmiPlusValue) &&
         (mDmiMinusSlope < 0 && mDmiPlusSlope > 0))
         return -1;

//-- flat
   return 0;
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
ENUM_ENTRY_SIGNAL CADXWilder::DominantCrossOverWithRisingDX(int threshold = -1)
  {
   int dominance = Dominance(m_ShiftToUse, threshold);
   if(dominance == 0)
      return ENTRY_SIGNAL_NONE;

   double dmmSlope = mDmiMinusBuffer[m_ShiftToUse] - mDmiMinusBuffer[m_ShiftToUse+1];
   double dmpSlope =  mDmiPlusBuffer[m_ShiftToUse] - mDmiPlusBuffer[m_ShiftToUse+1];
   double adxSlope =  mAdxBuffer[m_ShiftToUse] - mAdxBuffer[m_ShiftToUse+1];

   if(dominance == 1 && adxSlope > 0 && dmpSlope > 0&& dmmSlope < 0)
      return ENTRY_SIGNAL_BUY;
   else
      if(dominance == -1 && adxSlope > 0 && dmpSlope < 0 && dmmSlope > 0)
         return ENTRY_SIGNAL_SELL;

   return ENTRY_SIGNAL_NONE;
  }
//+------------------------------------------------------------------+
