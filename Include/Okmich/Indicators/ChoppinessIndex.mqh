//+------------------------------------------------------------------+
//|                                              ChoppinessIndex.mqh |
//|                                                    Michael Enudi |
//|                                             okmich2002@yahoo.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2022, Michael Enudi"
#property link      "okmich2002@yahoo.com"
#property version   "1.00"

#include "BaseIndicator.mqh"

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
class CChoppinessIndex : public CBaseIndicator
  {
private :
   //--- indicator paramter
   int                m_Period, m_ThreshLevel;
   //--- indicator handle
   int                mHandle;
   //--- indicator buffer
   double             m_Buffer[];

public:
                     CChoppinessIndex(string symbol, ENUM_TIMEFRAMES period,
                    int InputPeriod=14, int InptMidLevel=50): CBaseIndicator(symbol, period)
     {
      m_Period = InputPeriod;
      m_ThreshLevel = InptMidLevel;
     }

   virtual bool       Init();
   virtual bool       Refresh(int ShiftToUse=1);
   virtual void       Release();

   double             GetData(int shift=0);
   void               GetData(double &buffer[], int shift=0);

   bool               IsChoppy();
  };

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
bool CChoppinessIndex::Init(void)
  {
   ArraySetAsSeries(m_Buffer, true);
   mHandle = iCustom(m_Symbol, m_TF, "Articles\\Choppiness Index", m_Period);

   return mHandle != INVALID_HANDLE;
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
bool CChoppinessIndex::Refresh(int ShiftToUse=1)
  {
   m_ShiftToUse = ShiftToUse;
   int copied = CopyBuffer(mHandle, 0, 0, m_Period, m_Buffer);
   return copied == m_Period;
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void CChoppinessIndex::Release(void)
  {
   IndicatorRelease(mHandle);
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
double CChoppinessIndex::GetData(int shift=0)
  {
   if(shift >= m_Period)
      return EMPTY_VALUE;

   return m_Buffer[shift];
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void CChoppinessIndex::GetData(double &buffer[], int shift=0)
  {
   if(shift >= m_Period)
      return;

   ArraySetAsSeries(buffer, true);
   ArrayResize(buffer, ArraySize(m_Buffer) - shift);

   ArrayCopy(buffer, m_Buffer, 0, shift);
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
bool CChoppinessIndex::IsChoppy(void)
  {
   return m_Buffer[m_ShiftToUse] > m_ThreshLevel;
  }
//+------------------------------------------------------------------+
