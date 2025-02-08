//+------------------------------------------------------------------+
//|                                                          Atr.mqh |
//|                                    Copyright 2023, Michael Enudi |
//|                                             okmich2002@yahoo.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2023, Michael Enudi"
#property link      "okmich2002@yahoo.com"

#include "BaseIndicator.mqh"
#include <MovingAverages.mqh>

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
class CAtr : public CBaseIndicator
  {
private :
   int                mBarsToCopy;
   //--- indicator paramter
   int                m_Period, m_PercentRankPeriod;
   //--- indicator
   int                m_Handle;
   //--- indicator buffer
   double             m_Buffer[];

public:
                     CAtr(string symbol, ENUM_TIMEFRAMES period, int InputPeriod=14, int historyBars=10, bool usePercentRank=false, int InputRankPeriod=100): CBaseIndicator(symbol, period)
     {
      m_Period = InputPeriod;
      mBarsToCopy = historyBars*2;
      m_PercentRankPeriod = usePercentRank ? InputRankPeriod : -1;
     }

   virtual bool                   Init();
   virtual bool                   Refresh(int ShiftToUse=1);
   virtual void                   Release();

   double                         GetData(int shift=0);
   void                           GetData(double &buffer[], int shift=0);
   double                         CalculateMAofATR(int period, int i);
  };

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
bool CAtr::Init(void)
  {
   ArraySetAsSeries(m_Buffer, true);
   if(m_PercentRankPeriod == -1)
      m_Handle = iATR(m_Symbol, m_TF, m_Period);
   else
      m_Handle = iCustom(m_Symbol, m_TF, "Okmich\\ATRPercent", m_Period, m_PercentRankPeriod);
   return m_Handle != INVALID_HANDLE;
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
bool CAtr::Refresh(int ShiftToUse=1)
  {
   m_ShiftToUse = ShiftToUse;
   int copied = CopyBuffer(m_Handle, 0, 0, mBarsToCopy, m_Buffer);

   return mBarsToCopy == copied;
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void CAtr::Release(void)
  {
   IndicatorRelease(m_Handle);
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
double CAtr::GetData(int shift=0)
  {
   if(shift >= mBarsToCopy)
      return EMPTY_VALUE;

   return m_Buffer[shift];
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void CAtr::GetData(double &buffer[], int shift=0)
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
double CAtr::CalculateMAofATR(int period, int i)
  {
   if(i+period >= mBarsToCopy)
      return EMPTY_VALUE;
   return SimpleMA(i, period, m_Buffer);
  }
//+------------------------------------------------------------------+
