//+------------------------------------------------------------------+
//|                                               FibonacciRange.mqh |
//|                                    Copyright 2022, Michael Enudi |
//|                                             okmich2002@yahoo.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2022, Michael Enudi"
#property link      "okmich2002@yahoo.com"
#property version   "1.00"

#include "BaseIndicator.mqh"

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
class CFibonacciRange : public CBaseIndicator
  {
private :
   int               mHistoryBars;
   //--- indicator paramter
   //--- indicator
   //--- indicator buffer
   double            m_HighBuffer[], m_LowBuffer[];
   //--- other variables

public:
                     CFibonacciRange(string symbol, ENUM_TIMEFRAMES period, int HistoryBars=10): CBaseIndicator(symbol, period)
     {
      mHistoryBars = HistoryBars+13;
     }

   virtual bool       Init();
   virtual bool       Refresh(int ShiftToUse=1);
   virtual void       Release();

   ENUM_ENTRY_SIGNAL  TradeFilter();
  };

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
bool CFibonacciRange::Init(void)
  {
   ArraySetAsSeries(m_HighBuffer, true);
   ArraySetAsSeries(m_LowBuffer, true);

   return true;
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
bool CFibonacciRange::Refresh(int ShiftToUse=1)
  {
   m_ShiftToUse = ShiftToUse;
   int copied = CopyHigh(m_Symbol, m_TF, 0, mHistoryBars, m_HighBuffer);
   int copied2 = CopyLow(m_Symbol, m_TF, 0, mHistoryBars, m_LowBuffer);

   return copied == copied2 && copied2 == mHistoryBars;
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void CFibonacciRange::Release(void)
  {
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
ENUM_ENTRY_SIGNAL CFibonacciRange::TradeFilter()
  {
   int i = m_ShiftToUse;
   if(m_HighBuffer[i] > m_LowBuffer[i+2] &&
      m_HighBuffer[i] > m_LowBuffer[i+3] &&
      m_HighBuffer[i] > m_LowBuffer[i+5] &&
      m_HighBuffer[i] > m_LowBuffer[i+8] &&
      m_HighBuffer[i] > m_LowBuffer[i+13])
      return ENTRY_SIGNAL_BUY;
   else
      if(m_LowBuffer[i] < m_HighBuffer[i+2] &&
         m_LowBuffer[i] < m_HighBuffer[i+3] &&
         m_LowBuffer[i] < m_HighBuffer[i+5] &&
         m_LowBuffer[i] < m_HighBuffer[i+8] &&
         m_LowBuffer[i] < m_HighBuffer[i+13])
         return ENTRY_SIGNAL_SELL;
      else
         return ENTRY_SIGNAL_NONE;
  }
//+------------------------------------------------------------------+
