//+------------------------------------------------------------------+
//|                                      MarketFacilitationIndex.mqh |
//|                                    Copyright 2021, Michael Enudi |
//|                                             okmich2002@yahoo.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2021, Michael Enudi"
#property link      "okmich2002@yahoo.com"
#property version   "1.00"

#include "BaseIndicator.mqh"

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
class CMarketFacilitationIndex : public CBaseIndicator
  {
private :
   //--- indicator paramter
   ENUM_APPLIED_VOLUME  mAppliedVolume;
   int                  mLookupPeriod;
   double               mVolumeThreshold;
   //--- indicator
   int                m_IndHandle;
   //--- indicator buffer
   double             mIndBuffer[], mMfiClassBuffer[];

public:
                     CMarketFacilitationIndex(string symbol, ENUM_TIMEFRAMES period,
                            ENUM_APPLIED_VOLUME appliedVol = VOLUME_TICK,
                            int InpPeriod=90, double InpVolumeThreshold = 0.33): CBaseIndicator(symbol, period)
     {
      mAppliedVolume = appliedVol;
      mLookupPeriod = InpPeriod;
      mVolumeThreshold = InpVolumeThreshold;
     }

   virtual bool                   Init();
   virtual bool                   Refresh(int ShiftToUse=1);
   virtual void                   Release();

   double                         GetData(int buffer=0, int shift=0);
   void                           GetData(double &buffer[], int buffer=0, int shift=0);
  };

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
bool CMarketFacilitationIndex::Init(void)
  {
   ArraySetAsSeries(mIndBuffer, true);
   ArraySetAsSeries(mMfiClassBuffer, true);

   m_IndHandle = iCustom(m_Symbol, m_TF, "Okmich\\Market Facilitation Index", mAppliedVolume, mLookupPeriod, mVolumeThreshold);
   return m_IndHandle != INVALID_HANDLE;
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
bool CMarketFacilitationIndex::Refresh(int ShiftToUse=1)
  {
   m_ShiftToUse = ShiftToUse;
   int bars = 5;
   int dataCopied = CopyBuffer(m_IndHandle, 0, 0, bars, mIndBuffer);
   int clzCopied  = CopyBuffer(m_IndHandle, 1, 0, bars, mMfiClassBuffer);

   return bars == dataCopied && dataCopied == clzCopied;
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void CMarketFacilitationIndex::Release(void)
  {
   IndicatorRelease(m_IndHandle);
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
double CMarketFacilitationIndex::GetData(int buffer=0, int shift=0)
  {
   if(shift >= 5 || buffer > 1)
      return EMPTY_VALUE;

   return buffer == 0 ? mIndBuffer[shift] : mMfiClassBuffer[shift];
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void CMarketFacilitationIndex::GetData(double &buffer[], int bufferIndx=0, int shift=0)
  {
   if(shift >= 5 || bufferIndx > 1)
      return;

   ArraySetAsSeries(buffer, true);
   ArrayResize(buffer, ArraySize(mIndBuffer) - shift);

   if(bufferIndx ==0)
      ArrayCopy(buffer, mIndBuffer, 0, shift);
   else
      ArrayCopy(buffer, mMfiClassBuffer, 0, shift);
  }
