//+------------------------------------------------------------------+
//|                                              CongestionIndex.mqh |
//|                                                    Michael Enudi |
//|                                             okmich2002@yahoo.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2022, Michael Enudi"
#property link      "okmich2002@yahoo.com"
#property version   "1.00"

#include "BaseIndicator.mqh"

enum ENUM_CGSIDX_Strategies
  {
   CGSIDX_CrossMidLevel,
   CGSIDX_SignalCrossover
  };

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
class CCongestionIndex : public CBaseIndicator
  {
private :
   //--- indicator paramter
   int                m_Period, m_SmoothingPeriod, m_SignalPeriod;
   ENUM_APPLIED_PRICE m_AppliedPrice;
   //--- indicator handle
   int                mHandle;
   //--- indicator buffer
   double             m_Buffer[], m_SignalBuffer[];

   ENUM_ENTRY_SIGNAL  CrossesMidLevelSignal();
   ENUM_ENTRY_SIGNAL  DirectionalSignal();
   ENUM_ENTRY_SIGNAL  CrossesOverSignal();

public:
                     CCongestionIndex(string symbol, ENUM_TIMEFRAMES period,
                    int InputPeriod, ENUM_APPLIED_PRICE InputAppPrice,
                    int InputSmoothingPeriod, int InputSignalPeriod): CBaseIndicator(symbol, period)
     {
      m_Period = InputPeriod;
      m_AppliedPrice = InputAppPrice;
      m_SmoothingPeriod = InputSmoothingPeriod;
      m_SignalPeriod = InputSignalPeriod;
     }

   virtual bool       Init();
   virtual bool       Refresh(int ShiftToUse=1);
   virtual void       Release();

   double             GetData(int bufferIdx=0, int shift=0);
   void               GetData(double &buffer[], int bufferIdx=0, int shift=0);

   ENUM_ENTRY_SIGNAL  TradeSignal(ENUM_CGSIDX_Strategies entryOption);
  };

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
bool CCongestionIndex::Init(void)
  {
   ArraySetAsSeries(m_Buffer, true);
   ArraySetAsSeries(m_SignalBuffer, true);

   mHandle = iCustom(m_Symbol, m_TF, "Articles\\Congestion Index", m_Period, m_AppliedPrice, m_SmoothingPeriod, m_SignalPeriod);

   return mHandle != INVALID_HANDLE;
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
bool CCongestionIndex::Refresh(int ShiftToUse=1)
  {
   m_ShiftToUse = ShiftToUse;

   int copied = CopyBuffer(mHandle, 0, 0, m_SignalPeriod, m_Buffer);
   int SignalCopied = CopyBuffer(mHandle, 1, 0, m_SignalPeriod, m_SignalBuffer);

   return copied == m_SignalPeriod && m_SignalPeriod == SignalCopied;
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void CCongestionIndex::Release(void)
  {
   IndicatorRelease(mHandle);
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
double CCongestionIndex::GetData(int bufferIdx=0, int shift=0)
  {
   if(shift >= m_Period && bufferIdx > 1)
      return EMPTY_VALUE;

   return (bufferIdx == 0) ? m_Buffer[shift] : ((bufferIdx == 1) ? m_SignalBuffer[shift] : EMPTY_VALUE);
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void CCongestionIndex::GetData(double &buffer[], int bufferIdx=0, int shift=0)
  {
   if(shift >= m_Period && bufferIdx > 1)
      return;

   ArraySetAsSeries(buffer, true);
   ArrayResize(buffer, ArraySize(m_Buffer) - shift);

   switch(bufferIdx)
     {
      case 0:
         ArrayCopy(buffer, m_Buffer, 0, shift);
         break;
      case 1:
      default:
         ArrayCopy(buffer, m_SignalBuffer, 0, shift);
         break;
     }
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
ENUM_ENTRY_SIGNAL CCongestionIndex::CrossesMidLevelSignal(void)
  {
   if(m_Buffer[m_ShiftToUse+1] < 0.0 && m_Buffer[m_ShiftToUse] > 0.0)
      return ENTRY_SIGNAL_BUY;
   else
      if(m_Buffer[m_ShiftToUse+1] > 0.0 && m_Buffer[m_ShiftToUse] < 0.0)
         return ENTRY_SIGNAL_SELL;
      else
         return ENTRY_SIGNAL_NONE;
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
ENUM_ENTRY_SIGNAL CCongestionIndex::CrossesOverSignal(void)
  {
   if(m_Buffer[m_ShiftToUse+1] < m_SignalBuffer[m_ShiftToUse+1] &&
      (m_Buffer[m_ShiftToUse] > m_SignalBuffer[m_ShiftToUse]))
      return ENTRY_SIGNAL_BUY;
   else
      if(m_Buffer[m_ShiftToUse+1] > m_SignalBuffer[m_ShiftToUse+1] &&
         (m_Buffer[m_ShiftToUse] < m_SignalBuffer[m_ShiftToUse]))
         return ENTRY_SIGNAL_SELL;
      else
         return ENTRY_SIGNAL_NONE;
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
ENUM_ENTRY_SIGNAL CCongestionIndex::TradeSignal(ENUM_CGSIDX_Strategies entryOption)
  {
   switch(entryOption)
     {
      case CGSIDX_CrossMidLevel:
         return CrossesMidLevelSignal();
      case CGSIDX_SignalCrossover:
         return CrossesOverSignal();
      default:
         return ENTRY_SIGNAL_NONE;
     }
  }
//+------------------------------------------------------------------+
