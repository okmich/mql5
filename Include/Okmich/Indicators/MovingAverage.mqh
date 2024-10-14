//+------------------------------------------------------------------+
//|                                                MovingAverage.mqh |
//|                                    Copyright 2021, Michael Enudi |
//|                                             okmich2002@yahoo.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2021, Michael Enudi"
#property link      "okmich2002@yahoo.com"
#property version   "1.00"

#include "BaseIndicator.mqh"

enum ENUM_MA_FILTER
  {
   MA_FILTER_DIRECTIONAL,
   MA_FILTER_PRICE,
   MA_FILTER_SLOPE,
  };


//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
int getIndicatorHandle(string sym, ENUM_TIMEFRAMES tf, int period, ENUM_MA_TYPE maMethod, int shift, ENUM_APPLIED_PRICE appPrice)
  {
   int handle = INVALID_HANDLE;
   switch(maMethod)
     {
      case MA_TYPE_DEMA:
         handle = iDEMA(sym, tf, period, shift, appPrice);
         break;
      case MA_TYPE_TEMA:
         handle = iTEMA(sym, tf, period, shift, appPrice);
         break;
      case MA_TYPE_VMMA:
         handle = iCustom(sym, tf, "Okmich\\VWAP", period, shift);
         break;
      default:
        {
         ENUM_MA_METHOD method = MODE_SMA;
         if(maMethod == MA_TYPE_EMA)
            method = MODE_EMA;
         else
            if(maMethod == MA_TYPE_LWMA)
               method = MODE_LWMA;
            else
               if(maMethod == MA_TYPE_SMMA)
                  method = MODE_SMMA;
         handle = iMA(sym, tf, period, shift, method, appPrice);
        }
     }
   return handle;
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
class CMa : public CBaseIndicator
  {
private :
   int                mBarsToCopy;
   //--- indicator paramtemBarsToCopyr
   int                m_MaPeriod, m_Shift, m_SlopePeriod;
   ENUM_MA_TYPE       m_MaMethod;
   ENUM_APPLIED_PRICE m_AppliedPrice;
   double             m_SlopeThreshold;
   //--- indicator handle
   int                m_MaHandle;
   //--- indicator buffer
   double             m_MaBuffer[];
   double             m_CloseBuffer[];

public:
                     CMa(string symbol, ENUM_TIMEFRAMES period, int InputMaPeriod=14,
       ENUM_MA_TYPE InputMaMethod = MA_TYPE_SMA, ENUM_APPLIED_PRICE InputAppliedPrice = PRICE_CLOSE,
       int InputShift=0, int InputSlopePeriod = 5, double InputSlopeFilterThreshold = 0.0): CBaseIndicator(symbol, period)
     {
      m_MaPeriod = InputMaPeriod;
      m_MaMethod = InputMaMethod;
      m_AppliedPrice = InputAppliedPrice;
      m_Shift = InputShift;
      m_SlopePeriod = InputSlopePeriod;
      m_SlopeThreshold = InputSlopeFilterThreshold;

      mBarsToCopy = InputSlopePeriod+2;
     }

   virtual bool       Init();
   virtual bool       Refresh(int ShiftToUse=1);
   virtual void       Release();

   double             GetData(int shift=0);
   void               GetData(double &buffer[], int shift=0);

   ENUM_ENTRY_SIGNAL  TradeSignal();
   ENUM_ENTRY_SIGNAL  TradeFilter(ENUM_MA_FILTER filterType);
   double             Slope();
  };
//+------------------------------------------------------------------+


//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
bool CMa::Init(void)
  {
   ArraySetAsSeries(m_MaBuffer, true);
   ArraySetAsSeries(m_CloseBuffer, true);
   m_MaHandle = getIndicatorHandle(m_Symbol, m_TF, m_MaPeriod, m_MaMethod, m_Shift, m_AppliedPrice);

   return m_MaHandle != INVALID_HANDLE;
  }


//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
bool CMa::Refresh(int ShiftToUse=1)
  {
   m_ShiftToUse = ShiftToUse;
//copy two extra shift - necessary for standard deviatio calculation
   int maCopied = CopyBuffer(m_MaHandle, 0, m_ShiftToUse, mBarsToCopy+2, m_MaBuffer);
   int closeCopied = CopyClose(m_Symbol, m_TF, m_ShiftToUse, mBarsToCopy+2, m_CloseBuffer);

   return maCopied == closeCopied;
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void CMa::Release(void)
  {
   IndicatorRelease(m_MaHandle);
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
double CMa::GetData(int shift=0)
  {
   if(shift >= m_MaPeriod)
      return EMPTY_VALUE;

   return m_MaBuffer[shift];
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void CMa::GetData(double &buffer[], int shift=0)
  {
   if(shift >= m_MaPeriod)
      return;

   ArraySetAsSeries(buffer, true);
   ArrayResize(buffer, ArraySize(m_MaBuffer) - shift);

   ArrayCopy(buffer, m_MaBuffer, 0, shift);
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
ENUM_ENTRY_SIGNAL CMa::TradeSignal()
  {
//go long if price cross ma upward,
   if(m_MaBuffer[m_ShiftToUse+1] > m_CloseBuffer[m_ShiftToUse+1] &&
      m_MaBuffer[m_ShiftToUse] < m_CloseBuffer[m_ShiftToUse])
      return ENTRY_SIGNAL_BUY;
//go short if price cross ma downwards
   if(m_MaBuffer[m_ShiftToUse+1] < m_CloseBuffer[m_ShiftToUse+1] &&
      m_MaBuffer[m_ShiftToUse] > m_CloseBuffer[m_ShiftToUse])
      return ENTRY_SIGNAL_SELL;

   return ENTRY_SIGNAL_NONE;
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
double CMa::Slope(void)
  {
   return RegressionSlope(m_MaBuffer, m_SlopePeriod, m_ShiftToUse);
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
ENUM_ENTRY_SIGNAL CMa::TradeFilter(ENUM_MA_FILTER filterType)
  {
   switch(filterType)
     {
      case MA_FILTER_DIRECTIONAL:
         return (m_MaBuffer[m_ShiftToUse] > m_MaBuffer[m_ShiftToUse+1]) ? ENTRY_SIGNAL_BUY :
                (m_MaBuffer[m_ShiftToUse] < m_MaBuffer[m_ShiftToUse+1]) ? ENTRY_SIGNAL_SELL : ENTRY_SIGNAL_NONE;
         break;
      case MA_FILTER_SLOPE:
        {
         double slope = Slope();
         return (slope > m_SlopeThreshold) ? ENTRY_SIGNAL_BUY :
                (slope < -m_SlopeThreshold) ? ENTRY_SIGNAL_SELL : ENTRY_SIGNAL_NONE;
        }
      case MA_FILTER_PRICE:
      default:
         return (m_CloseBuffer[m_ShiftToUse] > m_MaBuffer[m_ShiftToUse]) ? ENTRY_SIGNAL_BUY :
                (m_CloseBuffer[m_ShiftToUse] < m_MaBuffer[m_ShiftToUse]) ? ENTRY_SIGNAL_SELL : ENTRY_SIGNAL_NONE;
     }
  }
//+------------------------------------------------------------------+
