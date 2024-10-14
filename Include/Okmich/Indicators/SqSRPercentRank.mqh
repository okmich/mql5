//+------------------------------------------------------------------+
//|                                              SqSRPercentRank.mqh |
//|                                                    Michael Enudi |
//|                                             okmich2002@yahoo.com |
//+------------------------------------------------------------------+
#property copyright "Michael Enudi"
#property link      "okmich2002@yahoo.com"

#include "BaseIndicator.mqh"

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
class CSRPercentRank : public CBaseIndicator
  {
private :
   int               mBarsToCopy;
   //--- indicator paramter
   int                m_AtrPeriod, m_Mode, m_Length;
   //--- indicator
   int                m_Handle;
   //--- indicator buffer
   double             m_Buffer[];
   //--- other variables

public:
                     CSRPercentRank(string symbol, ENUM_TIMEFRAMES period,
                  int InptMode=2, int InputLengthPeriod=100, int InputAtrPeriod=100,
                  int InptHistoryBars=6): CBaseIndicator(symbol, period)
     {
      m_Mode = InptMode;
      m_Length = InputLengthPeriod;
      m_AtrPeriod = InputAtrPeriod;

      mBarsToCopy = InptHistoryBars;
     }

   virtual bool       Init();
   virtual bool       Refresh(int ShiftToUse=1);
   virtual void       Release();

   double             ValueAt(int shift=1);

   bool               BelowThresholdNTimes(int n, double threshold);
  };

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
bool CSRPercentRank::Init(void)
  {
   ArraySetAsSeries(m_Buffer, true);

   m_Handle = iCustom(m_Symbol, m_TF, "Articles\\SqSRPercentRank",
                      m_Mode, m_Length, m_AtrPeriod);

   return m_Handle != INVALID_HANDLE;
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void CSRPercentRank::Release(void)
  {
   IndicatorRelease(m_Handle);
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
bool CSRPercentRank::Refresh(int ShiftToUse=1)
  {
   m_ShiftToUse = ShiftToUse;
   int copied = CopyBuffer(m_Handle, 0, 0, mBarsToCopy, m_Buffer);
   return copied == mBarsToCopy;
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
double CSRPercentRank::ValueAt(int shift=1)
  {
   if(shift >= 5)
      return EMPTY_VALUE;

   return m_Buffer[shift];
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
bool CSRPercentRank::BelowThresholdNTimes(int n, double threshold)
  {
   if(n > mBarsToCopy || (n+m_ShiftToUse) > mBarsToCopy)
      return false;
      
   bool returnFlag = n >= m_ShiftToUse;
   int end = n + m_ShiftToUse;
   for(int i = m_ShiftToUse; i< end; i++)
      returnFlag = returnFlag && m_Buffer[i] <= threshold;

   return returnFlag;
  }
//+------------------------------------------------------------------+
