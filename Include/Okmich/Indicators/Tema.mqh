//+------------------------------------------------------------------+
//|                                                         Tema.mqh |
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
class CTema : public CBaseIndicator
  {
private:
   int                mBarsToCopy;
   //--- indicator paramtemBarsToCopyr
   int                m_Period, m_SlopePeriod;
   ENUM_APPLIED_PRICE m_AppliedPrice;
   //--- indicator handle
   int                m_Handle;
   //--- indicator buffer
   double             m_Buffer[];
   double             m_CloseBuffer[];

public:
                     CTema(string symbol, ENUM_TIMEFRAMES period, int InputPeriod=14,
         ENUM_APPLIED_PRICE InputAppliedPrice = PRICE_CLOSE,
         int InputSlopePeriod = 5): CBaseIndicator(symbol, period)
     {
      m_Period = InputPeriod;
      m_AppliedPrice = InputAppliedPrice;
      m_SlopePeriod = InputSlopePeriod;

      mBarsToCopy = InputSlopePeriod+2;
     }

   virtual bool       Init();
   virtual bool       Refresh(int ShiftToUse=1);
   virtual void       Release();

   double             GetData(int shift=0);
   void               GetData(double &buffer[], int shift=0);

   ENUM_ENTRY_SIGNAL  TradeSignal();
   ENUM_ENTRY_SIGNAL  PriceFilter();
   ENUM_ENTRY_SIGNAL  SlopeFilter();
   double             MovingAverage();
   double             Slope();
  };
//+------------------------------------------------------------------+


//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
bool CTema::Init(void)
  {
   ArraySetAsSeries(m_Buffer, true);
   ArraySetAsSeries(m_CloseBuffer, true);

   m_Handle = iTEMA(m_Symbol, m_TF, m_Period, 0, m_AppliedPrice);

   return m_Handle != INVALID_HANDLE;
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
bool CTema::Refresh(int ShiftToUse=1)
  {
   m_ShiftToUse = ShiftToUse;
//copy two extra shift - necessary for standard deviatio calculation
   int maCopied = CopyBuffer(m_Handle, 0, 0,mBarsToCopy, m_Buffer);
   int closeCopied = CopyClose(m_Symbol, m_TF, 0, mBarsToCopy, m_CloseBuffer);

   return maCopied == closeCopied;
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void CTema::Release(void)
  {
   IndicatorRelease(m_Handle);
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
double CTema::GetData(int shift=0)
  {
   if(shift >= mBarsToCopy)
      return EMPTY_VALUE;

   return m_Buffer[shift];
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void CTema::GetData(double &buffer[], int shift=0)
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
ENUM_ENTRY_SIGNAL CTema::TradeSignal()
  {
//go long if price cross ma upward,
   if(m_Buffer[m_ShiftToUse+1] > m_CloseBuffer[m_ShiftToUse+1] &&
      m_Buffer[m_ShiftToUse] < m_CloseBuffer[m_ShiftToUse])
      return ENTRY_SIGNAL_BUY;
//go short if price cross ma downwards
   if(m_Buffer[m_ShiftToUse+1] < m_CloseBuffer[m_ShiftToUse+1] &&
      m_Buffer[m_ShiftToUse] > m_CloseBuffer[m_ShiftToUse])
      return ENTRY_SIGNAL_SELL;

   return ENTRY_SIGNAL_NONE;
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
ENUM_ENTRY_SIGNAL CTema::PriceFilter(void)
  {
   return (m_CloseBuffer[m_ShiftToUse] > m_Buffer[m_ShiftToUse]) ? ENTRY_SIGNAL_BUY :
          (m_CloseBuffer[m_ShiftToUse] < m_Buffer[m_ShiftToUse]) ? ENTRY_SIGNAL_SELL : ENTRY_SIGNAL_NONE;
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
ENUM_ENTRY_SIGNAL CTema::SlopeFilter(void)
  {
   double slope = Slope();
   return (slope > 0) ? ENTRY_SIGNAL_BUY :
          (slope < 0) ? ENTRY_SIGNAL_SELL : ENTRY_SIGNAL_NONE;
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
double CTema::MovingAverage(void)
  {
   return GetData(1);
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
double CTema::Slope(void)
  {
   return RegressionSlope(m_Buffer, m_SlopePeriod, m_ShiftToUse);
  }
//+------------------------------------------------------------------+
