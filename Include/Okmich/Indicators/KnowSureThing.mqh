//+------------------------------------------------------------------+
//|                                                KnowSureThing.mqh |
//|                                    Copyright 2022, Michael Enudi |
//|                                             okmich2002@yahoo.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2022, Michael Enudi"
#property link      "okmich2002@yahoo.com"
#property version   "1.00"

#include "BaseIndicator.mqh"

enum ENUM_KST_Strategies
  {
   KST_AboveBelowZero,
   KST_AboveBelowSignal,
   KST_SmiSlope,
   KST_SignalSlope
  };

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
class CKst : public CBaseIndicator
  {
private :
   int               mBarsToCopy;
   //--- indicator paramter
   int                m_Roc1Period, m_Roc2Period, m_Roc3Period, m_Roc4Period, m_Signal;
   int                m_RocMa1Period, m_RocMa2Period, m_RocMa3Period, m_RocMa4Period;
   //--- indicator
   int                m_Handle;
   //--- indicator buffer
   double             m_KstBuffer[], m_SignalBuffer[];

   ENUM_ENTRY_SIGNAL  AboveBelowZeroLine();
   ENUM_ENTRY_SIGNAL  AboveBelowSignalLine();
   ENUM_ENTRY_SIGNAL  SmiSlope();
   ENUM_ENTRY_SIGNAL  SignalSlope();

public:
                     CKst(string symbol, ENUM_TIMEFRAMES period,
        int roc1Period=10, int roc2Period=15, int roc3Period=20, int roc4Period=30,
        int rocMa1Period=10, int rocMa2Period=10, int rocMa3Period=10, int rocMa4Period=15,
        int signal=5): CBaseIndicator(symbol, period)
     {
      m_Roc1Period = roc1Period;
      m_Roc2Period = roc2Period;
      m_Roc3Period = roc3Period;
      m_Roc4Period = roc4Period;
      m_RocMa1Period = rocMa1Period;
      m_RocMa2Period = rocMa2Period;
      m_RocMa3Period = rocMa3Period;
      m_RocMa4Period = rocMa4Period;
      m_Signal = signal;

      mBarsToCopy = roc1Period;
     }

   virtual bool       Init();
   virtual bool       Refresh(int ShiftToUse=1);
   virtual void       Release();

   double             GetData(int shift=0, int bufferIndx=0);
   void               GetData(double &buffer[], int shift=0, int bufferIndx=0);

   ENUM_ENTRY_SIGNAL  TradeFilter(ENUM_KST_Strategies signalOption);
  };

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
bool CKst::Init(void)
  {
   ArraySetAsSeries(m_KstBuffer, true);
   ArraySetAsSeries(m_SignalBuffer, true);

   m_Handle = iCustom(m_Symbol, m_TF, "Okmich\\Know Sure Thing",
                      m_Roc1Period, m_RocMa1Period,
                      m_Roc2Period, m_RocMa2Period,
                      m_Roc3Period, m_RocMa3Period,
                      m_Roc4Period, m_RocMa4Period,
                      m_Signal);
   return m_Handle != INVALID_HANDLE;
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void CKst::Release(void)
  {
   IndicatorRelease(m_Handle);
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
bool CKst::Refresh(int ShiftToUse=1)
  {
   m_ShiftToUse = ShiftToUse;
   int dataCopied = CopyBuffer(m_Handle, 0, 0, mBarsToCopy, m_KstBuffer);
   int signalCopied = CopyBuffer(m_Handle, 1, 0, mBarsToCopy, m_SignalBuffer);

   return mBarsToCopy == dataCopied && dataCopied == signalCopied;
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
double CKst::GetData(int buffer=0, int shift=0)
  {
   if(shift >= mBarsToCopy || buffer > 1)
      return EMPTY_VALUE;

   return buffer == 0 ? m_KstBuffer[shift] : m_SignalBuffer[shift];
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
ENUM_ENTRY_SIGNAL CKst::AboveBelowSignalLine()
  {
   if(m_KstBuffer[1] > m_SignalBuffer[1])
      return ENTRY_SIGNAL_BUY;
   else
      if(m_KstBuffer[1] < m_SignalBuffer[1])
         return ENTRY_SIGNAL_SELL;
      else
         return ENTRY_SIGNAL_NONE;
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
ENUM_ENTRY_SIGNAL CKst::AboveBelowZeroLine()
  {
   if(m_KstBuffer[1] > 0)
      return ENTRY_SIGNAL_BUY;
   else
      if(m_KstBuffer[1] < 0)
         return ENTRY_SIGNAL_SELL;
      else
         return ENTRY_SIGNAL_NONE;
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
ENUM_ENTRY_SIGNAL CKst::SmiSlope()
  {
   double slope = RegressionSlope(m_KstBuffer, 3, 1);
   return (slope > 0) ? ENTRY_SIGNAL_BUY : (slope < 0) ? ENTRY_SIGNAL_SELL : ENTRY_SIGNAL_NONE;
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
ENUM_ENTRY_SIGNAL CKst::SignalSlope()
  {
   double slope = RegressionSlope(m_SignalBuffer, 3, 1);
   return (slope > 0) ? ENTRY_SIGNAL_BUY : (slope < 0) ? ENTRY_SIGNAL_SELL : ENTRY_SIGNAL_NONE;
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
ENUM_ENTRY_SIGNAL CKst::TradeFilter(ENUM_KST_Strategies entryOptions)
  {
   switch(entryOptions)
     {
      case KST_AboveBelowSignal:
         return AboveBelowSignalLine();
      case KST_AboveBelowZero:
         return AboveBelowZeroLine();
      case KST_SignalSlope:
         return SignalSlope();
      case KST_SmiSlope:
         return SmiSlope();
      default:
         return ENTRY_SIGNAL_NONE;
     }
  }
//+------------------------------------------------------------------+
