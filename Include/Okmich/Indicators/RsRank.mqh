//+------------------------------------------------------------------+
//|                                                       RsRank.mqh |
//|                                    Copyright 2023, Michael Enudi |
//|                                             okmich2002@yahoo.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2023, Michael Enudi"
#property link      "okmich2002@yahoo.com"

#include "BaseIndicator.mqh"

enum ENUM_RSRNK_Strategies
  {
   RSRNK_CrossMidLevel,
   RSRNK_CrossSignal,
   RSRNK_SignalSlope
  };
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
class CRsRank : public CBaseIndicator
  {
private :
   int                mBarsToCopy;
   //--- indicator paramter
   int                mSmoothingPeriod;
   bool               mUseFibSeq;
   ENUM_MA_METHOD     mSmoothingMethod;
   //--- indicator handle
   int                mHandle;
   //--- indicator buffer
   double             m_Buffer[], m_SignalBuffer[];

public:
                     CRsRank(string symbol, ENUM_TIMEFRAMES period,
           int InputUseFibSeq=true, int InputSmoothingPeriod=13, ENUM_MA_METHOD InputSmoothingMethod=MODE_SMA,
           int historyBars=14): CBaseIndicator(symbol, period)
     {
      mUseFibSeq = InputUseFibSeq;
      mSmoothingPeriod = InputSmoothingPeriod;
      mSmoothingMethod = InputSmoothingMethod;
      mBarsToCopy = historyBars;
     }

   virtual bool       Init();
   virtual bool       Refresh(int ShiftToUse=1);
   virtual void       Release();

   double             GetData(int bufferIdx = 0, int shift=0);
   void               GetData(double &buffer[], int bufferIdx = 0, int shift=0);

   ENUM_ENTRY_SIGNAL  TradeFilter(ENUM_RSRNK_Strategies filterStrategy);
  };
//+------------------------------------------------------------------+


//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
bool CRsRank::Init(void)
  {
   ArraySetAsSeries(m_Buffer, true);
   ArraySetAsSeries(m_SignalBuffer, true);

   mHandle = iCustom(m_Symbol, m_TF, "Okmich\\RS_Rank", mUseFibSeq, mSmoothingPeriod, mSmoothingMethod);

   return mHandle != INVALID_HANDLE;
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
bool CRsRank::Refresh(int ShiftToUse=1)
  {
   m_ShiftToUse = ShiftToUse;
   int mainCopied = CopyBuffer(mHandle, 0, 0, mBarsToCopy, m_Buffer);
   int siglCopied = CopyBuffer(mHandle, 1, 0, mBarsToCopy, m_SignalBuffer);

   return mainCopied == mBarsToCopy && mainCopied == siglCopied;
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void CRsRank::Release(void)
  {
   IndicatorRelease(mHandle);
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
double CRsRank::GetData(int bufferIdx = 0, int shift=0)
  {
   if(shift >= mBarsToCopy || bufferIdx > 1)
      return EMPTY_VALUE;

   switch(bufferIdx)
     {
      case 0:
         return m_Buffer[shift];
      case 1:
         return m_SignalBuffer[shift];
      default:
         return EMPTY_VALUE;
     }
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void CRsRank::GetData(double &buffer[], int bufferIdx = 0, int shift=0)
  {
   if(shift >= mBarsToCopy || bufferIdx > 3)
      return;

   ArraySetAsSeries(buffer, true);
   ArrayResize(buffer, mBarsToCopy - shift);

   switch(bufferIdx)
     {
      case 0:
         ArrayCopy(buffer, m_Buffer, 0, shift);
         break;
      case 1:
         ArrayCopy(buffer, m_SignalBuffer, 0, shift);
         break;
     }
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
ENUM_ENTRY_SIGNAL CRsRank::TradeFilter(ENUM_RSRNK_Strategies filterStrategy)
  {
   switch(filterStrategy)
     {
      case RSRNK_CrossMidLevel:
         return (m_Buffer[m_ShiftToUse] > 0) ? ENTRY_SIGNAL_BUY :
                (m_Buffer[m_ShiftToUse] < 0) ? ENTRY_SIGNAL_SELL : ENTRY_SIGNAL_NONE;
         break;
      case RSRNK_CrossSignal:
         if(m_Buffer[m_ShiftToUse+1] < m_SignalBuffer[m_ShiftToUse+1] &&
            m_Buffer[m_ShiftToUse] > m_SignalBuffer[m_ShiftToUse])
            return ENTRY_SIGNAL_BUY;
         else
            if(m_Buffer[m_ShiftToUse+1] > m_SignalBuffer[m_ShiftToUse+1] &&
               m_Buffer[m_ShiftToUse] < m_SignalBuffer[m_ShiftToUse])
               return ENTRY_SIGNAL_SELL;
            else
               return ENTRY_SIGNAL_NONE;
      case RSRNK_SignalSlope:
        {
         return (m_SignalBuffer[m_ShiftToUse+1] < m_SignalBuffer[m_ShiftToUse]) ? ENTRY_SIGNAL_BUY :
                (m_SignalBuffer[m_ShiftToUse+1] > m_SignalBuffer[m_ShiftToUse]) ? ENTRY_SIGNAL_SELL : ENTRY_SIGNAL_NONE;
        }
     }
   return ENTRY_SIGNAL_NONE;
  }
//+------------------------------------------------------------------+
