//+------------------------------------------------------------------+
//|                                                     DeMarker.mqh |
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
class CDeMarker : public CBaseIndicator
  {
private :
   //--- indicator paramter
   int                m_Period;
   double             m_OverBoughtLevel;
   double             m_OverSoldLevel;
   //--- indicator handle
   int                m_Handle;
   //--- indicator buffer
   double             m_DeMBuffer[];

public:
                     CDeMarker(string symbol, ENUM_TIMEFRAMES period,
        int InputPeriod=13,
        double InptOBLevel=70,
        double InptOSLevel=30): CBaseIndicator(symbol, period)
     {
      m_Period = InputPeriod;
      m_OverBoughtLevel = InptOBLevel;
      m_OverSoldLevel = InptOSLevel;
     }

   virtual bool                   Init();
   virtual bool                   Refresh(int ShiftToUse=1);
   virtual void                   Release();

   double                         GetData(int shift=0);
   void                           GetData(double &buffer[], int shift=0);
  };

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
bool CDeMarker::Init(void)
  {
   ArraySetAsSeries(m_DeMBuffer, true);
   m_Handle = iDeMarker(m_Symbol, m_TF, m_Period);

   return m_Handle != INVALID_HANDLE;
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
bool CDeMarker::Refresh(int ShiftToUse=1)
  {
   m_ShiftToUse = ShiftToUse;
   int valuesCopied = CopyBuffer(m_Handle, 0, 0, m_Period, m_DeMBuffer);
   return valuesCopied == m_Period;
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void CDeMarker::Release(void)
  {
   IndicatorRelease(m_Handle);
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
double CDeMarker::GetData(int shift=0)
  {
   if(shift >= m_Period)
      return EMPTY_VALUE;

   return m_DeMBuffer[shift];
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void CDeMarker::GetData(double &buffer[], int shift=0)
  {
   if(shift >= m_Period)
      return;

   ArraySetAsSeries(buffer, true);
   ArrayResize(buffer, ArraySize(m_DeMBuffer) - shift);

   ArrayCopy(buffer, m_DeMBuffer, 0, shift);
  }
//+------------------------------------------------------------------+
