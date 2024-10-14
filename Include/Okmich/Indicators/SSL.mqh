//+------------------------------------------------------------------+
//|                                                          SSL.mqh |
//|                                    Copyright 2021, Michael Enudi |
//|                                             okmich2002@yahoo.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2021, Michael Enudi"
#property link      "okmich2002@yahoo.com"

#include "BaseIndicator.mqh"

enum ENUM_SSL_MODE
  {
   MODE_SSL_DEMA, //Double Exponential Moving Average
   MODE_SSL_EMA,  //Exponential Moving Average
   MODE_SSL_LWMA, //Linear Weighted Moving Average
   MODE_SSL_SMA,  //Simple Moving Average
   MODE_SSL_SMMA, //Smoothed Moving Average
   MODE_SSL_TEMA, //Triple Exponential Moving Average
  };

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
class CSsl : public CBaseIndicator
  {
private :
   int                mBarsToCopy;

   double             mSslUp1, mSslUp2, mSslDown2, mSslDown1;
   //--- indicator paramter
   int                m_Period;
   ENUM_SSL_MODE      m_SmoothingMethod;
   //--- indicator
   int                m_Handle;
   //--- indicator buffer
   double             m_UpBuffer[],m_DownBuffer[], m_CloseBuffer[];

public:
                     CSsl(string symbol, ENUM_TIMEFRAMES period, int InputPeriod=10,
        ENUM_SSL_MODE InptSmoothingMethod = MODE_SSL_SMA): CBaseIndicator(symbol, period)
     {
      m_Period = InputPeriod;
      m_SmoothingMethod = InptSmoothingMethod;

      mBarsToCopy = InputPeriod;
     }

   virtual bool                   Init();
   virtual bool                   Refresh(int ShiftToUse=1);
   virtual void                   Release();

   double                         GetData(int bufferIndx=0, int shift=0);

   ENUM_ENTRY_SIGNAL              TradeSignal();
   ENUM_ENTRY_SIGNAL              TradeFilter();
   ENUM_ENTRY_SIGNAL              CheckForSignalState(int shift=0);

   double                         Slope();
   double                         StdDeviation();
   double                         ZScore();
  };

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
bool CSsl::Init(void)
  {
   ArraySetAsSeries(m_DownBuffer, true);
   ArraySetAsSeries(m_UpBuffer, true);
   ArraySetAsSeries(m_CloseBuffer, true);

   m_Handle = iCustom(m_Symbol, m_TF, "Okmich\\SSL Channel", m_Period, m_SmoothingMethod);
   return m_Handle != INVALID_HANDLE;
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
bool CSsl::Refresh(int ShiftToUse=1)
  {
   m_ShiftToUse = ShiftToUse;
   int UpCopied = CopyBuffer(m_Handle, 0, 0, mBarsToCopy, m_UpBuffer);
   int Dwncopied = CopyBuffer(m_Handle, 1, 0, mBarsToCopy, m_DownBuffer);

   mSslDown1 = m_DownBuffer[m_ShiftToUse];
   mSslDown2 = m_DownBuffer[m_ShiftToUse+1];
   mSslUp1 = m_UpBuffer[m_ShiftToUse];
   mSslUp2 = m_UpBuffer[m_ShiftToUse+1];

   return mBarsToCopy == UpCopied && UpCopied == Dwncopied;
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void CSsl::Release(void)
  {
   IndicatorRelease(m_Handle);
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
double CSsl::GetData(int bufferIndx=0, int shift=0)
  {
   if(shift >= mBarsToCopy || bufferIndx > 1)
      return EMPTY_VALUE;

   return bufferIndx == 1 ? m_DownBuffer[shift] : m_UpBuffer[shift];
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
ENUM_ENTRY_SIGNAL CSsl::TradeSignal(void)
  {
   if(mSslUp2 < mSslDown2 && mSslUp1 > mSslDown1)
      return ENTRY_SIGNAL_SELL;
   else
      if(mSslUp2 > mSslDown2 && mSslUp1 < mSslDown1)
         return ENTRY_SIGNAL_BUY;

   return ENTRY_SIGNAL_NONE;
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
ENUM_ENTRY_SIGNAL CSsl::TradeFilter(void)
  {
   return CheckForSignalState(m_ShiftToUse);
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
ENUM_ENTRY_SIGNAL CSsl::CheckForSignalState(int shift=0)
  {
   double up = m_UpBuffer[shift];
   double down = m_DownBuffer[shift];
   ENUM_ENTRY_SIGNAL mSignal = ENTRY_SIGNAL_NONE;
   if(up > down)
      return ENTRY_SIGNAL_SELL;
   else
      if(up < down)
         return ENTRY_SIGNAL_BUY;

   return ENTRY_SIGNAL_NONE;
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
double CSsl::Slope(void)
  {
   bool isUp = mSslUp1 < mSslDown1;
   if(isUp)
      return mSslDown1 - mSslDown2;
   else
      return mSslUp1 - mSslUp2;
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
double CSsl::StdDeviation(void)
  {
   int copied = CopyClose(m_Symbol, m_TF, 1, mBarsToCopy, m_CloseBuffer);
   if(copied == -1)
      return EMPTY_VALUE;

//--- variables
   double StdDev_dTmp=0.0;
//--- calcualte StdDev
   for(int i=0; i<mBarsToCopy; i++)
      StdDev_dTmp+=MathPow(m_CloseBuffer[i] - (mSslUp1 > mSslDown1 ? m_DownBuffer[i] : m_UpBuffer[i]), 2);
   StdDev_dTmp=MathSqrt(StdDev_dTmp/mBarsToCopy);
//--- return calculated value
   return(StdDev_dTmp);
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
double CSsl::ZScore(void)
  {
   return (m_CloseBuffer[1] - (mSslUp1 > mSslDown1 ? m_DownBuffer[0] : m_UpBuffer[0])) / StdDeviation();
  }
//+------------------------------------------------------------------+
