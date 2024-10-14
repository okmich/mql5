//+------------------------------------------------------------------+
//|                                                      Squeeze.mqh |
//|                                    Copyright 2021, Michael Enudi |
//|                                             okmich2002@yahoo.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2020, Michael Enudi"
#property link      "okmich2002@yahoo.com"
#property version   "1.00"

#include "BaseIndicator.mqh"

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
class CSqueeze : public CBaseIndicator
  {
private :
   int                mBarsToCopy;
   ENUM_TRENDSTATE    mTrendState;
   //--- indicator paramter
   int                m_Period;
   //--- indicator
   int                m_Handle;
   //--- indicator buffer
   double             m_Buffer[];
   //--- other variables

public:
                     CSqueeze(string symbol, ENUM_TIMEFRAMES period, int InputPeriod=25): CBaseIndicator(symbol, period)
     {
      m_Period = InputPeriod;
      mBarsToCopy = 10;
     }

   virtual bool                   Init();
   virtual bool                   Refresh(int ShiftToUse=1);
   virtual void                   Release();

   double                         GetData(int shift=0);
   void                           GetData(double &buffer[], int shift=0);

   bool                           IsTrending();
   ENUM_TRENDSTATE                TrendState();

   ENUM_ENTRY_SIGNAL              TradeSignal();
  };

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
bool CSqueeze::Init(void)
  {
   ArraySetAsSeries(m_Buffer, true);

   m_Handle = iCustom(m_Symbol, m_TF, "Articles/Squeeze", m_Period, 1, 1);

   return m_Handle != INVALID_HANDLE;
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
ENUM_ENTRY_SIGNAL CSqueeze::TradeSignal(void)
  {
   if(m_Buffer[1] > 0)
      return ENTRY_SIGNAL_BUY;
   else
      if(m_Buffer[1] < 0)
         return ENTRY_SIGNAL_SELL;
   return ENTRY_SIGNAL_NONE;
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
bool CSqueeze::Refresh(int ShiftToUse=1)
  {
   m_ShiftToUse = ShiftToUse;
   int copied = CopyBuffer(m_Handle, 0, 0, mBarsToCopy, m_Buffer);
   return mBarsToCopy == copied;
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void CSqueeze::Release(void)
  {
   IndicatorRelease(m_Handle);
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
double CSqueeze::GetData(int shift=0)
  {
   if(shift >= mBarsToCopy)
      return EMPTY_VALUE;

   return m_Buffer[shift];
  }


//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void CSqueeze::GetData(double &buffer[], int shift=0)
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
bool CSqueeze::IsTrending()
  {
   return m_Buffer[1] != 0;
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
ENUM_TRENDSTATE CSqueeze::TrendState()
  {
   return (m_Buffer[1] == 0.0) ? TS_FLAT : TS_TREND;
  }
//+------------------------------------------------------------------+
