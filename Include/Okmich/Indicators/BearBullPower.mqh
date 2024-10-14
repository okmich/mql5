//+------------------------------------------------------------------+
//|                                                BearBullPower.mqh |
//|                                                    Michael Enudi |
//|                                             okmich2002@yahoo.com |
//+------------------------------------------------------------------+
#property copyright "Michael Enudi"
#property link      "okmich2002@yahoo.com"
#property copyright "Copyright 2022, Michael Enudi"
#property link      "okmich2002@yahoo.com"

#include "BaseIndicator.mqh"

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
class CBearBullBalance : public CBaseIndicator
  {
private :
   int                mBarsToCopy;
   //--- indicator paramter
   int                m_Period, m_SmoothingPeriod;
   ENUM_MA_METHOD     m_Method, m_SmoothingMethod;
   //--- indicator
   int                m_Handle;
   //--- indicator buffer
   double             m_Buffer[];

public:
                     CBearBullBalance(string symbol, ENUM_TIMEFRAMES period,
                    int InputPeriod, ENUM_MA_METHOD InputMethod,
                    int InputSmoothingPeriod, ENUM_MA_METHOD InputSmoothingMethod): CBaseIndicator(symbol, period)
     {
      m_Period = InputPeriod;
      m_Method = InputMethod;
      m_SmoothingPeriod = InputSmoothingPeriod;
      m_SmoothingMethod = InputSmoothingMethod;
      
      mBarsToCopy = m_SmoothingPeriod;
     }

   virtual bool        Init();
   virtual bool        Refresh(int ShiftToUse=1);
   virtual void        Release();

   double              GetData(int shift=0);
   void                GetData(double &buffer[], int shift=0);

   ENUM_ENTRY_SIGNAL   TradeSignal();
  };

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
bool CBearBullBalance::Init(void)
  {
   ArraySetAsSeries(m_Buffer, true);

   m_Handle = iCustom(m_Symbol, m_TF, "Articles\\Bull and Bear Power Balance", m_Period, m_Method, m_SmoothingPeriod, m_SmoothingMethod);
   return m_Handle != INVALID_HANDLE;
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
bool CBearBullBalance::Refresh(int ShiftToUse=1)
  {
   m_ShiftToUse = ShiftToUse;
   int copied = CopyBuffer(m_Handle, 0, 0, mBarsToCopy, m_Buffer);

   return mBarsToCopy == copied;
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void CBearBullBalance::Release(void)
  {
   IndicatorRelease(m_Handle);
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
double CBearBullBalance::GetData(int shift=0)
  {
   if(shift >= mBarsToCopy)
      return EMPTY_VALUE;

   return m_Buffer[shift];
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void CBearBullBalance::GetData(double &buffer[], int shift=0)
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
ENUM_ENTRY_SIGNAL CBearBullBalance::TradeSignal()
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
