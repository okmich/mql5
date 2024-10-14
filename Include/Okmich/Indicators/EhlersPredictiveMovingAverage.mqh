//+------------------------------------------------------------------+
//|                                EhlersPredictiveMovingAverage.mqh |
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
class CEhlersPredictiveMovingAverage : public CBaseIndicator
  {
private :
   int                mBarsToCopy;
   //--- indicator paramter
   //--- indicator handle
   int                m_Handle;
   //--- indicator buffer
   double             m_Buffer1[], m_Buffer2[];

public:
                     CEhlersPredictiveMovingAverage(string symbol, ENUM_TIMEFRAMES period,  
                     int InputBarsToCopy=10): CBaseIndicator(symbol, period)
     {
      mBarsToCopy = InputBarsToCopy;
     }

   virtual bool       Init();
   virtual bool       Refresh(int ShiftToUse=1);
   virtual void       Release();

   double             GetData(int bufferIndx=0, int shift=0);
   void               GetData(double &buffer[], int bufferIndx=0, int shift=0);
   
   ENUM_ENTRY_SIGNAL  TradeSignal();
   ENUM_ENTRY_SIGNAL  TradeFilter();
  };

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
bool CEhlersPredictiveMovingAverage::Init(void)
  {
   ArraySetAsSeries(m_Buffer1, true);
   ArraySetAsSeries(m_Buffer2, true);

   m_Handle = iCustom(m_Symbol, m_TF, "Articles\\Ehlers\\EhlersPredictiveMovingAverage");

   return m_Handle != INVALID_HANDLE;
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
bool CEhlersPredictiveMovingAverage::Refresh(int ShiftToUse=1)
  {
   m_ShiftToUse = ShiftToUse;
//copy two extra shift - necessary for standard deviatio calculation
   int copied1 = CopyBuffer(m_Handle, 0, 0, mBarsToCopy, m_Buffer1);
   int copied2 = CopyBuffer(m_Handle, 1, 0, mBarsToCopy, m_Buffer2);

   return copied1 == copied2 && copied1 == mBarsToCopy;
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void CEhlersPredictiveMovingAverage::Release(void)
  {
   IndicatorRelease(m_Handle);
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
double CEhlersPredictiveMovingAverage::GetData(int bufferIndx=0, int shift=0)
  {
   if(shift >= mBarsToCopy || bufferIndx > 2)
      return EMPTY_VALUE;

   switch(bufferIndx)
     {
      case 1:
         return m_Buffer2[shift];
      case 0:
      default:
         return m_Buffer1[shift];
     }
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void CEhlersPredictiveMovingAverage::GetData(double &buffer[], int bufferIndx=0, int shift=0)
  {
   if(shift >= mBarsToCopy || bufferIndx > 2)
      return;

   ArraySetAsSeries(buffer, true);
   ArrayResize(buffer, mBarsToCopy - shift);

   switch(bufferIndx)
     {
      case 1:
         ArrayCopy(buffer, m_Buffer2, 0, shift);
         break;
      case 0:
      default:
         ArrayCopy(buffer, m_Buffer1, 0, shift);
     }
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
ENUM_ENTRY_SIGNAL CEhlersPredictiveMovingAverage::TradeSignal()
  {
//go long if buffer 1 crosses buffer2 upward,
   if(m_Buffer2[2] > m_Buffer1[2] && m_Buffer2[1] < m_Buffer1[1])
      return ENTRY_SIGNAL_SELL;
//go long if buffer 1 crosses buffer2 downward,
   if(m_Buffer2[2] < m_Buffer1[2] && m_Buffer2[1] > m_Buffer1[1])
      return ENTRY_SIGNAL_BUY;

   return ENTRY_SIGNAL_NONE;
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
ENUM_ENTRY_SIGNAL CEhlersPredictiveMovingAverage::TradeFilter(void)
  {
   return (m_Buffer1[1] > m_Buffer2[1]) ? ENTRY_SIGNAL_BUY :
          (m_Buffer1[1] < m_Buffer2[1]) ? ENTRY_SIGNAL_SELL : ENTRY_SIGNAL_NONE;
  }
