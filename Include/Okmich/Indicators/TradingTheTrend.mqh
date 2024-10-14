//+------------------------------------------------------------------+
//|                                                      TTTrend.mqh |
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
class CTTrend : public CBaseIndicator
  {
private :
   ENUM_TRENDSTATE    mTrendState;
   //--- indicator paramter
   int                m_Period;
   double             m_Multiplier;
   //--- indicator
   int                m_Handle;
   //--- indicator buffer
   double             m_LineBuffer[];
   //--- other variables

public:
                     CTTrend(string symbol, ENUM_TIMEFRAMES period,
            int InputLookBackPeriod=20,
            double InputMultiplier=3.0): CBaseIndicator(symbol, period)
     {
      m_Period = InputLookBackPeriod;
      m_Multiplier = InputMultiplier;
     }

   virtual bool                   Init();
   virtual bool                   Refresh(int ShiftToUse=1);
   virtual void                   Release();
   
   double                         GetData(int shift=0);

   ENUM_ENTRY_SIGNAL              TradeFilter(int shift=1);
   ENUM_ENTRY_SIGNAL              TradeSignal();
   
   ENUM_TRENDSTATE                TrendState(int shift=1);
  };

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
bool CTTrend::Init(void)
  {
   ArraySetAsSeries(m_LineBuffer, true);
   m_Handle = iCustom(m_Symbol, m_TF, "Articles/Trading The Trend",m_Period, m_Multiplier, 0);
   return m_Handle != INVALID_HANDLE;
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
bool CTTrend::Refresh(int ShiftToUse=1)
  {
   m_ShiftToUse = ShiftToUse;
   int copied = CopyBuffer(m_Handle, 5, 0, m_Period, m_LineBuffer);
   return copied == m_Period;
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void CTTrend::Release(void)
  {
   IndicatorRelease(m_Handle);
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
double CTTrend::GetData(int shift=0)
  {
   if(shift >= m_Period)
      return EMPTY_VALUE;

   return m_LineBuffer[shift];
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
ENUM_ENTRY_SIGNAL CTTrend::TradeFilter(int shift=1)
  {
   if(shift >= m_Period - 1)
      return ENTRY_SIGNAL_NONE;
   double lastClose = iClose(m_Symbol, m_TF, shift);
//BULL if the line if below the close
   if(m_LineBuffer[shift] < lastClose)
      return ENTRY_SIGNAL_BUY;

//BEAR if the line if below the close
   if(m_LineBuffer[shift] > lastClose)
      return ENTRY_SIGNAL_SELL;

   return ENTRY_SIGNAL_NONE;
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
ENUM_ENTRY_SIGNAL CTTrend::TradeSignal()
  {
//happens when there is a switch from bull state to bear state or vice versa
   ENUM_ENTRY_SIGNAL filter = TradeFilter(1);
   if(filter != TradeFilter(2))
      return filter;

   return ENTRY_SIGNAL_NONE;
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
ENUM_TRENDSTATE CTTrend::TrendState(int shift=1)
  {
   if(shift >= m_Period - 3)
      return TS_FLAT;

   if(m_LineBuffer[shift] > m_LineBuffer[shift+1] &&
      m_LineBuffer[shift+1] > m_LineBuffer[shift+2])
      return TS_TREND;

   if(m_LineBuffer[shift] < m_LineBuffer[shift+1] &&
      m_LineBuffer[shift+1] < m_LineBuffer[shift+2])
      return TS_TREND;

   return TS_FLAT;
  }
//+------------------------------------------------------------------+
