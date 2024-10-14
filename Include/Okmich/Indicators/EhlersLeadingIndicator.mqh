//+------------------------------------------------------------------+
//|                                       EhlersLeadingIndicator.mqh |
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
class CEhlersLeadingIndicator : public CBaseIndicator
  {
private :
   int                mBarsToCopy;
   //--- indicator paramter
   double             m_Alpha1, m_Alpha2;
   //--- indicator handle
   int                m_Handle;
   //--- indicator buffer
   double             m_Buffer1[], m_Buffer2[];

public:
                     CEhlersLeadingIndicator(string symbol, ENUM_TIMEFRAMES period, 
                     double InputAlpha1, double InputAlpha2, 
                     int InputBarsToCopy=10): CBaseIndicator(symbol, period)
     {
      m_Alpha1 = InputAlpha1;
      m_Alpha2 = InputAlpha2;
      
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
bool CEhlersLeadingIndicator::Init(void)
  {
   ArraySetAsSeries(m_Buffer1, true);
   ArraySetAsSeries(m_Buffer2, true);

   m_Handle = iCustom(m_Symbol, m_TF, "Okmich\\Ehlers Leading Indicator",
                      m_Alpha1, m_Alpha2);

   return m_Handle != INVALID_HANDLE;
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
bool CEhlersLeadingIndicator::Refresh(int ShiftToUse=1)
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
void CEhlersLeadingIndicator::Release(void)
  {
   IndicatorRelease(m_Handle);
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
double CEhlersLeadingIndicator::GetData(int bufferIndx=0, int shift=0)
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
void CEhlersLeadingIndicator::GetData(double &buffer[], int bufferIndx=0, int shift=0)
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
ENUM_ENTRY_SIGNAL CEhlersLeadingIndicator::TradeSignal()
  {
//go long if buffer 1 crosses buffer2 upward,
   if(m_Buffer2[2] > m_Buffer1[2] && m_Buffer2[1] < m_Buffer1[1])
      return ENTRY_SIGNAL_BUY;
//go long if buffer 1 crosses buffer2 downward,
   if(m_Buffer2[2] < m_Buffer1[2] && m_Buffer2[1] > m_Buffer1[1])
      return ENTRY_SIGNAL_SELL;

   return ENTRY_SIGNAL_NONE;
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
ENUM_ENTRY_SIGNAL CEhlersLeadingIndicator::TradeFilter(void)
  {
   return (m_Buffer1[1] > m_Buffer2[1]) ? ENTRY_SIGNAL_BUY :
          (m_Buffer1[1] < m_Buffer2[1]) ? ENTRY_SIGNAL_SELL : ENTRY_SIGNAL_NONE;
  }
