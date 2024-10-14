//+------------------------------------------------------------------+
//|                                                    TrendLord.mqh |
//|                                    Copyright 2021, Michael Enudi |
//|                                             okmich2002@yahoo.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2021, Michael Enudi"
#property link      "okmich2002@yahoo.com"

#include "BaseIndicator.mqh"

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
class CSuperTrend : public CBaseIndicator
  {
private :
   int                mBarsToCopy;
   //--- indicator paramter
   int                m_Period;
   double             m_Multiplier;
   //--- indicator
   int                m_Handle;
   //--- indicator buffer
   double             m_Buffer[];

public:
                     CSuperTrend(string symbol, ENUM_TIMEFRAMES period, int InputPeriod=10,
               double InputMultiplier=3, int historyBars=10): CBaseIndicator(symbol, period)
     {
      m_Period = InputPeriod;
      m_Multiplier = InputMultiplier;
      mBarsToCopy = historyBars;
     }

   virtual bool                   Init();
   virtual bool                   Refresh(int ShiftToUse=1);
   virtual void                   Release();

   double                         GetData(int shift=0);
   void                           GetData(double &buffer[], int shift=0);

   ENUM_ENTRY_SIGNAL              TradeFilter(int shift=1);
   ENUM_ENTRY_SIGNAL              TradeSignal();
   
   ENUM_TRENDSTATE                TrendState(int shift=1);
  };

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
bool CSuperTrend::Init(void)
  {
   ArraySetAsSeries(m_Buffer, true);
   m_Handle = iCustom(m_Symbol, m_TF, "Articles\\Super Trend", m_Period, m_Multiplier);
   return m_Handle != INVALID_HANDLE;
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
bool CSuperTrend::Refresh(int ShiftToUse=1)
  {
   m_ShiftToUse = ShiftToUse;
   int copied = CopyBuffer(m_Handle, 2, 0, mBarsToCopy, m_Buffer);
   return mBarsToCopy == copied;
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void CSuperTrend::Release(void)
  {
   IndicatorRelease(m_Handle);
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
double CSuperTrend::GetData(int shift=0)
  {
   if(shift >= mBarsToCopy)
      return EMPTY_VALUE;

   return m_Buffer[shift];
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void CSuperTrend::GetData(double &buffer[], int shift=0)
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
ENUM_ENTRY_SIGNAL CSuperTrend::TradeSignal()
  {
   double closeShift1 = iClose(m_Symbol, m_TF, m_ShiftToUse);
   double closeShift2 = iClose(m_Symbol, m_TF, m_ShiftToUse+1);
   if(m_Buffer[m_ShiftToUse+1] < closeShift2 && m_Buffer[m_ShiftToUse] > closeShift1)
      return ENTRY_SIGNAL_SELL;
   else
      if(m_Buffer[m_ShiftToUse+1] > closeShift2 && m_Buffer[m_ShiftToUse] < closeShift1)
         return ENTRY_SIGNAL_BUY;
      else
         return ENTRY_SIGNAL_NONE;
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
ENUM_ENTRY_SIGNAL CSuperTrend::TradeFilter(int shift=1)
  {
   double lastClose = iClose(m_Symbol, m_TF, shift);
   if(m_Buffer[shift] > lastClose)
      return ENTRY_SIGNAL_SELL;
   else
      if(m_Buffer[shift] < lastClose)
         return ENTRY_SIGNAL_BUY;
      else
         return ENTRY_SIGNAL_NONE;
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
ENUM_TRENDSTATE CSuperTrend::TrendState(int shift=1)
  {
   if(shift >= mBarsToCopy-2)
      return TS_FLAT;

   if(m_Buffer[shift] > m_Buffer[shift+1] &&
      m_Buffer[shift+1] > m_Buffer[shift+2])
      return TS_TREND;

   if(m_Buffer[shift] < m_Buffer[shift+1] &&
      m_Buffer[shift+1] < m_Buffer[shift+2])
      return TS_TREND;

   return TS_FLAT;
  }
//+------------------------------------------------------------------+
