//+------------------------------------------------------------------+
//|                                           RelativeVigorIndex.mqh |
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
class CRvi : public CBaseIndicator
  {
private :
   //--- indicator paramter
   int                m_RviPeriod;
   //--- indicator handle
   int                mRviHandle;
   //--- indicator buffer
   double             m_RviBuffer[];

public:
                     CRvi(string symbol, ENUM_TIMEFRAMES period, int InputRviPeriod=14): CBaseIndicator(symbol, period)
     {
      m_RviPeriod = InputRviPeriod;
     }

   virtual bool                   Init();
   virtual bool                   Refresh(int ShiftToUse=1);
   virtual void                   Release();

   double                         GetData(int shift=0);
   void                           GetData(double &buffer[], int shift=0);

   ENUM_ENTRY_SIGNAL              TradeSignal();
  };
//+------------------------------------------------------------------+


//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
bool CRvi::Init(void)
  {
   ArraySetAsSeries(m_RviBuffer, true);
   mRviHandle = iRVI(m_Symbol, m_TF, m_RviPeriod);

   return mRviHandle != INVALID_HANDLE;
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
ENUM_ENTRY_SIGNAL CRvi::TradeSignal()
  {

   return ENTRY_SIGNAL_NONE;
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
bool CRvi::Refresh(int ShiftToUse=1)
  {
   m_ShiftToUse = ShiftToUse;
   int rviCopied = CopyBuffer(mRviHandle, 0, 0, m_RviPeriod, m_RviBuffer);
   return rviCopied == m_RviPeriod;
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void CRvi::Release(void)
  {
   IndicatorRelease(mRviHandle);
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
double CRvi::GetData(int shift=0)
  {
   if(shift >= m_RviPeriod)
      return EMPTY_VALUE;

   return m_RviBuffer[shift];
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void CRvi::GetData(double &buffer[], int shift=0)
  {
   if(shift >= m_RviPeriod)
      return;

   ArraySetAsSeries(buffer, true);
   ArrayResize(buffer, ArraySize(m_RviBuffer) - shift);

   ArrayCopy(buffer, m_RviBuffer, 0, shift);
  }
//+------------------------------------------------------------------+
