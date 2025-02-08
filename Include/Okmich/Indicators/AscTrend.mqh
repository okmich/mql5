//+------------------------------------------------------------------+
//|                                                     AscTrend.mqh |
//|                                    Copyright 2022, Michael Enudi |
//|                                             okmich2002@yahoo.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2022, Michael Enudi"
#property link      "okmich2002@yahoo.com"

#include "BaseIndicator.mqh"

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
class CAscTrend : public CBaseIndicator
  {
private :
   int                mBarsToCopy;
   ENUM_ENTRY_SIGNAL  mSignal, mLastSignal;
   //--- indicator paramter
   int                m_Risk;
   //--- indicator
   int                m_Handle;
   //--- indicator buffer
   double             m_BullBuffer[], m_BearBuffer[];

public:
                     CAscTrend(string symbol, ENUM_TIMEFRAMES period,
             int InputRisk=3, int InputBarsToCopy=25): CBaseIndicator(symbol, period)
     {
      m_Risk = InputRisk;
      mBarsToCopy = InputBarsToCopy;
     }

   virtual bool       Init();
   virtual bool       Refresh(int ShiftToUse=1);
   virtual void       Release();

   double             GetData(int buffer=0, int shift=0);
   void               GetData(double &buffer[], int buffer=0, int shift=0);

   ENUM_ENTRY_SIGNAL  TradeFilter() {return mLastSignal;};
   ENUM_ENTRY_SIGNAL  TradeSignal() {return mSignal;};
  };

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
bool CAscTrend::Init(void)
  {
   ArraySetAsSeries(m_BullBuffer, true);
   ArraySetAsSeries(m_BearBuffer, true);

   m_Handle = iCustom(m_Symbol, m_TF, "Articles\\ASCTrend", m_Risk);
   return m_Handle != INVALID_HANDLE;
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
bool CAscTrend::Refresh(int ShiftToUse=1)
  {
   m_ShiftToUse = ShiftToUse;
   int bearsCopied = CopyBuffer(m_Handle, 0, 0, mBarsToCopy, m_BearBuffer);
   int bullsCopied = CopyBuffer(m_Handle, 1, 0, mBarsToCopy, m_BullBuffer);
//resolve signal
   mSignal = ENTRY_SIGNAL_NONE;
   if(m_BearBuffer[m_ShiftToUse] == 0.0 && m_BullBuffer[m_ShiftToUse] > 0.0)
      mSignal =  ENTRY_SIGNAL_BUY;
   else
      if(m_BearBuffer[m_ShiftToUse] > 0.0 && m_BullBuffer[m_ShiftToUse] == 0.0)
         mSignal = ENTRY_SIGNAL_SELL;
   
   if (mSignal != ENTRY_SIGNAL_NONE)
      mLastSignal = mSignal;

   return mBarsToCopy == bearsCopied && bearsCopied == bullsCopied;
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void CAscTrend::Release(void)
  {
   IndicatorRelease(m_Handle);
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
double CAscTrend::GetData(int bufferIndx=0, int shift=0)
  {
   if(shift >= mBarsToCopy || bufferIndx > 1)
      return EMPTY_VALUE;

   switch(bufferIndx)
     {
      case 0:
         return m_BearBuffer[shift];
      case 1:
         return m_BullBuffer[shift];
      default:
         return EMPTY_VALUE;
     }
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void CAscTrend::GetData(double &buffer[], int bufferIndx=0, int shift=0)
  {
   if(shift >= mBarsToCopy || bufferIndx > 1)
      return;

   ArraySetAsSeries(buffer, true);
   ArrayResize(buffer, mBarsToCopy - shift);

   switch(bufferIndx)
     {
      case 0:
         ArrayCopy(buffer, m_BearBuffer, 0, shift);
         break;
      case 1:
      default:
         ArrayCopy(buffer, m_BullBuffer, 0, shift);
         break;
     }
  }
