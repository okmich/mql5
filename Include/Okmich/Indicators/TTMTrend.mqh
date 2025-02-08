//+------------------------------------------------------------------+
//|                                                     TTMTrend.mqh |
//|                                    Copyright 2021, Michael Enudi |
//|                                             okmich2002@yahoo.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2021, Michael Enudi"
#property link      "okmich2002@yahoo.com"
#property version   "1.00"

#include "BaseIndicator.mqh"
#include <Okmich\Common\Candle.mqh>

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
class CTTMTrend : public CBaseIndicator
  {
private :
   ENUM_TRENDSTATE    mTrendState;
   //--- indicator paramter
   int                m_Period;
   //--- indicator
   int                m_Handle;
   //--- indicator buffer
   double             m_TTmFlagBuffer[], m_TTmOpenBuffer[], m_TTmCloseBuffer[];
   //--- other variables

public:
                     CTTMTrend(string symbol, ENUM_TIMEFRAMES period, int InputPeriod=10): CBaseIndicator(symbol, period)
     {
      m_Period = InputPeriod;
     }

   virtual bool       Init();
   virtual bool       Refresh(int ShiftToUse=1);
   virtual void       Release();

   ENUM_ENTRY_SIGNAL  TradeSignal(int shift=-1);

   double             Open(int shift=0);
   double             Close(int shift=0);
  };

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
bool CTTMTrend::Init(void)
  {
   ArraySetAsSeries(m_TTmOpenBuffer, true);
   ArraySetAsSeries(m_TTmCloseBuffer, true);
   ArraySetAsSeries(m_TTmFlagBuffer, true);

   m_Handle = iCustom(m_Symbol, m_TF, "Articles/TTM Trend",m_Period);
   return m_Handle != INVALID_HANDLE;
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
bool CTTMTrend::Refresh(int ShiftToUse=1)
  {
   m_ShiftToUse = ShiftToUse;
   int copied = CopyBuffer(m_Handle, 0, 0, m_Period, m_TTmOpenBuffer);
   int copied2 = CopyBuffer(m_Handle, 1, 0, m_Period, m_TTmCloseBuffer);
   int copied3 = CopyBuffer(m_Handle, 2, 0, m_Period, m_TTmFlagBuffer);
   return copied == m_Period && copied2 == copied;
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void CTTMTrend::Release(void)
  {
   IndicatorRelease(m_Handle);
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
double    CTTMTrend::Open(int shift=0)
  {
   if(shift >= m_Period)
      return EMPTY_VALUE;

   return m_TTmOpenBuffer[shift];
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
double    CTTMTrend::Close(int shift=0)
  {
   if(shift >= m_Period)
      return EMPTY_VALUE;

   return m_TTmCloseBuffer[shift];
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
ENUM_ENTRY_SIGNAL CTTMTrend::TradeSignal(int shift=-1)
  {
  int mShift = (shift == -1) ? m_ShiftToUse : shift;
  //kind of scare to use indicator colors
   if(m_TTmFlagBuffer[mShift] == 2.0)
      return ENTRY_SIGNAL_SELL;
   else
      if(m_TTmFlagBuffer[mShift] == 1.0)
         return ENTRY_SIGNAL_BUY;
      else
         return ENTRY_SIGNAL_NONE;
  }
