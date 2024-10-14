//+------------------------------------------------------------------+
//|                                      Slope Divergence of TSI.mqh |
//|                                    Copyright 2020, Michael Enudi |
//|                                             okmich2002@yahoo.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2020, Michael Enudi"
#property link      "okmich2002@yahoo.com"
#property version   "1.00"

#include "BaseIndicator.mqh"

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
class CSdTsi : public CBaseIndicator
  {
private :
   int                mBarsToCopy;
   //--- indicator paramter
   int                m_TsiPeriod,m_TsiSmooth1, m_TsiSmooth2;
   //--- indicator
   int                m_SdiHandle;
   //--- indicator buffer
   double             m_SdiBuffer[];

public:
                     CSdTsi(string symbol, ENUM_TIMEFRAMES period, int InpTsiPeriod=13, int InpTsiSmooth1=25,
          int InpTsiSmooth2=2, int historyBars=6): CBaseIndicator(symbol, period)
     {
      m_TsiPeriod = InpTsiPeriod;
      m_TsiSmooth1 = InpTsiSmooth1;
      m_TsiSmooth2 = InpTsiSmooth2;

      mBarsToCopy = historyBars;
     }

   virtual bool       Init();
   virtual bool       Refresh(int ShiftToUse=1);
   virtual void       Release();

   double             GetData(int shift=1);
   void               GetData(double &buffer[], int shift=1);

   bool               TrendFilter(int shift=1);
  };

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
bool CSdTsi::Init(void)
  {
   ArraySetAsSeries(m_SdiBuffer, true);

   m_SdiHandle = iCustom(m_Symbol, m_TF, "Okmich\\Slope Divergence of TSI", m_TsiPeriod,
                         m_TsiSmooth1, m_TsiSmooth2, m_TsiSmooth1, m_TsiSmooth2);
   return m_SdiHandle != INVALID_HANDLE;
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
bool CSdTsi::Refresh(int ShiftToUse=1)
  {
   m_ShiftToUse = ShiftToUse;
   int dataCopied = CopyBuffer(m_SdiHandle, 0, 0, mBarsToCopy, m_SdiBuffer);
   return mBarsToCopy == dataCopied;
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void CSdTsi::Release(void)
  {
   IndicatorRelease(m_SdiHandle);
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
double CSdTsi::GetData(int shift=1)
  {
   if(shift >= mBarsToCopy)
      return EMPTY_VALUE;

   return m_SdiBuffer[shift];
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void CSdTsi::GetData(double &buffer[], int shift=1)
  {
   ArraySetAsSeries(buffer, true);
   ArrayResize(buffer, ArraySize(m_SdiBuffer) - shift);
   ArrayCopy(buffer, m_SdiBuffer, 0, shift);
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
bool CSdTsi::TrendFilter(int shift=1)
  {
   if(shift >= mBarsToCopy)
      return false;

   return m_SdiBuffer[shift] != 0;
  }
//+------------------------------------------------------------------+
