//+------------------------------------------------------------------+
//|                                                  TrendFilter.mqh |
//|                                    Copyright 2021, Michael Enudi |
//|                                             okmich2002@yahoo.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2021, Michael Enudi"
#property link      "okmich2002@yahoo.com"

#include "BaseIndicator.mqh"

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
class CTrendFilter : public CBaseIndicator
  {
private :
   int                mScore;
   int                mBarsToCopy;

   double             mTfValue, mTfSlope;
   //--- indicator paramter
   int                m_Bars, m_MaPeriod;
   //--- indicator
   int                m_Handle;
   //--- indicator buffer
   double             m_Buffer[];

public:
                     CTrendFilter(string symbol, ENUM_TIMEFRAMES period, int InputBars=32, int InputPeriod=32,
                int historyBars=24): CBaseIndicator(symbol, period)
     {
      m_Bars = InputBars;
      m_MaPeriod = InputPeriod;
      mBarsToCopy = historyBars;
     }

   virtual bool                   Init();
   virtual bool                   Refresh(int ShiftToUse=1);
   virtual void                   Release();

   double                         GetData(int shift=0);
   void                           GetData(double &buffer[], int shift=0);

   ENUM_TRENDSTATE                Trend();
   bool                           IsTrending();
   double                         Slope(int shift=1);

   ENUM_ENTRY_SIGNAL              TradeSignal();
  };

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
bool CTrendFilter::Init(void)
  {
   ArraySetAsSeries(m_Buffer, true);

   m_Handle = iCustom(m_Symbol, m_TF, "Okmich\\Trend Filter", m_Bars, m_MaPeriod);
   return m_Handle != INVALID_HANDLE;
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
bool CTrendFilter::Refresh(int ShiftToUse=1)
  {
   m_ShiftToUse = ShiftToUse;
   int copied = CopyBuffer(m_Handle, 0, 0, mBarsToCopy, m_Buffer);

   mTfValue = m_Buffer[1];
   mTfSlope = m_Buffer[1] - m_Buffer[2];

   return mBarsToCopy == copied;
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
ENUM_ENTRY_SIGNAL CTrendFilter::TradeSignal(void)
  {
   ENUM_ENTRY_SIGNAL mSignal = ENTRY_SIGNAL_NONE;

   if(mTfValue > -0.9 && m_Buffer[3] < -0.9 && mTfSlope > 0)
      return ENTRY_SIGNAL_BUY;

   if(mTfValue < 0.9  && m_Buffer[3] > 0.9 && mTfSlope < 0)
      return ENTRY_SIGNAL_SELL;

   return mTfValue < -0.9 ? ENTRY_SIGNAL_SELL : mTfValue > 0.9 ? ENTRY_SIGNAL_BUY : ENTRY_SIGNAL_NONE;
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void CTrendFilter::Release(void)
  {
   IndicatorRelease(m_Handle);
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
double CTrendFilter::GetData(int shift=0)
  {
   if(shift >= mBarsToCopy)
      return EMPTY_VALUE;

   return m_Buffer[shift];
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void CTrendFilter::GetData(double &buffer[], int shift=0)
  {
   if(shift >= mBarsToCopy)
      return;

   ArraySetAsSeries(buffer, true);
   ArrayResize(buffer, mBarsToCopy - shift);

   ArrayCopy(buffer, m_Buffer, 0, shift);
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
ENUM_TRENDSTATE CTrendFilter::Trend()
  {
   return TradeSignal() != ENTRY_SIGNAL_NONE ? TS_TREND : TS_FLAT;
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
bool CTrendFilter::IsTrending(void)
  {
   return Trend() != TS_FLAT;
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
double CTrendFilter::Slope(int shift=1)
  {
   if(shift >= mBarsToCopy)
      return EMPTY_VALUE;

   return m_Buffer[shift] - m_Buffer[shift+1];
  }
//+------------------------------------------------------------------+
