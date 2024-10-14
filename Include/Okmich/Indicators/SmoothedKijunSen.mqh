//+------------------------------------------------------------------+
//|                                                     KijunSen.mqh |
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
class CSmoothedKijunSen : public CBaseIndicator
  {
private :
   int                mBarsToCopy;
   int                mTrendIndx;
   //--- indicator paramter
   int                m_KijunSen;
   int                m_Smoothing;
   ENUM_MA_METHOD     m_MaMethod;
   //--- indicator
   int                m_SksHandle;
   //--- indicator buffer
   double             m_SksBuffer[];

public:
                     CSmoothedKijunSen(string symbol, ENUM_TIMEFRAMES period, int InpKijunPeriod=26, int InpSmooth=5,
                     ENUM_MA_METHOD smoothMethod=MODE_SMA, int historyBars=10): CBaseIndicator(symbol, period)
     {
      m_KijunSen = InpKijunPeriod;
      m_Smoothing = InpSmooth;
      m_MaMethod = smoothMethod;
      mBarsToCopy = historyBars;
     }

   virtual bool                   Init();
   virtual bool                   Refresh(int ShiftToUse=1);
   virtual void                   Release();

   double                         GetData(int shift=0);
   void                           GetData(double &buffer[], int shift=0);
   ENUM_ENTRY_SIGNAL              TradeSignal();
  };
//+------------------------------------------------------------------+


//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
bool CSmoothedKijunSen::Init(void)
  {
   ArraySetAsSeries(m_SksBuffer, true);

   m_SksHandle = iCustom(m_Symbol, m_TF, "Okmich\\Smoothed Kijun-Sen", m_KijunSen, m_Smoothing, m_MaMethod);
   return m_SksHandle != INVALID_HANDLE;
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
ENUM_ENTRY_SIGNAL CSmoothedKijunSen::TradeSignal()
  {
   double closeShift1 = iClose(m_Symbol, m_TF, 1);

   if(closeShift1 > m_SksBuffer[1] && m_SksBuffer[1] > m_SksBuffer[2])
      return ENTRY_SIGNAL_BUY;
  
   if(closeShift1 < m_SksBuffer[1] && m_SksBuffer[1] < m_SksBuffer[2])
      return ENTRY_SIGNAL_SELL;
  
   return ENTRY_SIGNAL_NONE;
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
bool CSmoothedKijunSen::Refresh(int ShiftToUse=1)
  {
   m_ShiftToUse = ShiftToUse;
   int barsToCopy = 6;
   int dataCopied = CopyBuffer(m_SksHandle, 0, 0, barsToCopy, m_SksBuffer);

   return barsToCopy == dataCopied ;
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void CSmoothedKijunSen::Release(void)
  {
   IndicatorRelease(m_SksHandle);
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
double CSmoothedKijunSen::GetData(int shift=0)
  {
   if(shift >= mBarsToCopy)
      return EMPTY_VALUE;

   return m_SksBuffer[shift];
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void CSmoothedKijunSen::GetData(double &buffer[], int shift=0)
  {
   if(shift >= mBarsToCopy)
      return;

   ArraySetAsSeries(buffer, true);
   ArrayResize(buffer, mBarsToCopy - shift);

   ArrayCopy(buffer, m_SksBuffer, 0, shift);

  }
//+------------------------------------------------------------------+
