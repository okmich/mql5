//+------------------------------------------------------------------+
//|                                                          Roc.mqh |
//|                                    Copyright 2023, Michael Enudi |
//|                                             okmich2002@yahoo.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2023, Michael Enudi"
#property link      "okmich2002@yahoo.com"
#property version   "1.00"

#include "BaseIndicator.mqh"

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
class CRoc : public CBaseIndicator
  {
private:
   int                mBarsToCopy;
   //--- indicator
   int                m_Period;
   bool               m_IsSmoothed;
   //--- indicator handle
   int                m_Handle;
   //--- indicator buffer
   double             m_Buffer[];

public:
                     CRoc(string symbol, ENUM_TIMEFRAMES period, int InputPeriod=14,
        bool InputIsSmoothed=true, int InputBarsToCopy = 5): CBaseIndicator(symbol, period)
     {
      m_Period = InputPeriod;
      m_IsSmoothed = InputIsSmoothed;
      mBarsToCopy = InputBarsToCopy;
     }

   virtual bool       Init();
   virtual bool       Refresh(int ShiftToUse=1);
   virtual void       Release();

   double             GetData(int shift=0);
   void               GetData(double &buffer[], int shift=0);

   ENUM_ENTRY_SIGNAL  TradeSignal();
   ENUM_ENTRY_SIGNAL  Filter();
  };
//+------------------------------------------------------------------+


//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
bool CRoc::Init(void)
  {
   ArraySetAsSeries(m_Buffer, true);

   m_Handle = iCustom(m_Symbol, m_TF, "Okmich/ROC", m_Period, m_IsSmoothed);

   return m_Handle != INVALID_HANDLE;
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
bool CRoc::Refresh(int ShiftToUse=1)
  {
   m_ShiftToUse = ShiftToUse;
   int maCopied = CopyBuffer(m_Handle, 0, 0,mBarsToCopy, m_Buffer);
   return true;
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void CRoc::Release(void)
  {
   IndicatorRelease(m_Handle);
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
double CRoc::GetData(int shift=0)
  {
   if(shift >= mBarsToCopy)
      return EMPTY_VALUE;

   return m_Buffer[shift];
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void CRoc::GetData(double &buffer[], int shift=0)
  {
   if(shift >= mBarsToCopy)
      return;

   ArraySetAsSeries(buffer, true);
   ArrayResize(buffer, ArraySize(m_Buffer) - shift);

   ArrayCopy(buffer, m_Buffer, 0, shift);
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
ENUM_ENTRY_SIGNAL CRoc::TradeSignal()
  {
//go long if roc crosses the zero line upward,
   if(m_Buffer[m_ShiftToUse+1] < 0 && m_Buffer[m_ShiftToUse] > 0)
      return ENTRY_SIGNAL_BUY;
//go short if price cross ma downwards
   if(m_Buffer[m_ShiftToUse+1] > 0 && m_Buffer[m_ShiftToUse] < 0)
      return ENTRY_SIGNAL_SELL;

   return ENTRY_SIGNAL_NONE;
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
ENUM_ENTRY_SIGNAL CRoc::Filter(void)
  {
   return (m_Buffer[m_ShiftToUse] > 0) ? ENTRY_SIGNAL_BUY :
          (m_Buffer[m_ShiftToUse] < 0) ? ENTRY_SIGNAL_SELL : ENTRY_SIGNAL_NONE;
  }
//+------------------------------------------------------------------+
