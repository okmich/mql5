//+------------------------------------------------------------------+
//|                                   Tick Volume Momemtum Index.mqh |
//|                                    Copyright 2020, Michael Enudi |
//|                                             okmich2002@yahoo.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2020, Michael Enudi"
#property link      "okmich2002@yahoo.com"
#property version   "1.00"

#include "BaseIndicator.mqh"

enum ENUM_TVI_Strategies
  {
   TVI_AboveBelowZero,
   TVI_AboveBelowSignal,
   TVI_TviSlope,
   TVI_SignalSlope,
  };

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
class CTvi : public CBaseIndicator
  {
private :
   int                mBarsToCopy;
   //--- indicator paramter
   int                m_TviPeriod, m_Smooth1, m_Signal;
   //--- indicator
   int                m_TviHandle;
   //--- indicator buffer
   double             m_TviBuffer[], m_SignalBuffer[];

   ENUM_ENTRY_SIGNAL  AboveBelowZeroLine();
   ENUM_ENTRY_SIGNAL  AboveBelowSignalLine();
   ENUM_ENTRY_SIGNAL  TviSlope();
   ENUM_ENTRY_SIGNAL  SignalSlope();

public:
                     CTvi(string symbol, ENUM_TIMEFRAMES period, int InptTviPeriod, int InptSmooth1,
        int InptSignal): CBaseIndicator(symbol, period)
     {
      m_TviPeriod = InptTviPeriod;
      m_Smooth1 = InptSmooth1;
      m_Signal = InptSignal;

      mBarsToCopy = 6;
     }

   virtual bool                   Init();
   virtual bool                   Refresh(int ShiftToUse=1);
   virtual void                   Release();

   double                         GetData(int buffer=0, int shift=0);
   void                           GetData(double &buffer[], int buffer=0, int shift=0);
   
   ENUM_ENTRY_SIGNAL  TradeFilter(ENUM_TVI_Strategies signalOption);
  };

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
bool CTvi::Init(void)
  {
   ArraySetAsSeries(m_TviBuffer, true);
   ArraySetAsSeries(m_SignalBuffer, true);

   m_TviHandle = iCustom(m_Symbol, m_TF, "Okmich\\Tick Volume Indicator", m_TviPeriod, m_Smooth1, m_Signal);
   return m_TviHandle != INVALID_HANDLE;
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
bool CTvi::Refresh(int ShiftToUse=1)
  {
   m_ShiftToUse = ShiftToUse;
   int dataCopied = CopyBuffer(m_TviHandle, 0, 0, mBarsToCopy, m_TviBuffer);
   int signalCopied = CopyBuffer(m_TviHandle, 1, 0, mBarsToCopy, m_SignalBuffer);

   return mBarsToCopy == dataCopied && dataCopied == signalCopied;
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void CTvi::Release(void)
  {
   IndicatorRelease(m_TviHandle);
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
double CTvi::GetData(int bufferIndx=0, int shift=0)
  {
   if(shift >= mBarsToCopy || bufferIndx > 1)
      return EMPTY_VALUE;

   switch(bufferIndx)
     {
      case 1:
         return m_SignalBuffer[shift];
      case 0:
      default:
         return m_TviBuffer[shift];
     }
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void CTvi::GetData(double &buffer[], int bufferIndx=0, int shift=0)
  {
   if(shift >= mBarsToCopy || bufferIndx > 1)
      return;

   ArraySetAsSeries(buffer, true);
   ArrayResize(buffer, ArraySize(m_TviBuffer) - shift);

   switch(bufferIndx)
     {
      case 1:
         ArrayCopy(buffer, m_SignalBuffer, 0, shift);
         break;
      case 0:
      default:
         ArrayCopy(buffer, m_TviBuffer, 0, shift);;
         break;
     }
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
ENUM_ENTRY_SIGNAL CTvi::AboveBelowSignalLine()
  {
   if(m_TviBuffer[1] > m_SignalBuffer[1])
      return ENTRY_SIGNAL_BUY;
   else
      if(m_TviBuffer[1] < m_SignalBuffer[1])
         return ENTRY_SIGNAL_SELL;
      else
         return ENTRY_SIGNAL_NONE;
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
ENUM_ENTRY_SIGNAL CTvi::AboveBelowZeroLine()
  {
  return CBaseIndicator::_Phase(m_TviBuffer, 0);
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
ENUM_ENTRY_SIGNAL CTvi::TviSlope()
  {
   double slope = RegressionSlope(m_TviBuffer, 3, 1);
   return (slope > 0) ? ENTRY_SIGNAL_BUY : (slope < 0) ? ENTRY_SIGNAL_SELL : ENTRY_SIGNAL_NONE;
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
ENUM_ENTRY_SIGNAL CTvi::SignalSlope()
  {
   double slope = RegressionSlope(m_SignalBuffer, 3, 1);
   return (slope > 0) ? ENTRY_SIGNAL_BUY : (slope < 0) ? ENTRY_SIGNAL_SELL : ENTRY_SIGNAL_NONE;
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
ENUM_ENTRY_SIGNAL CTvi::TradeFilter(ENUM_TVI_Strategies entryOptions)
  {
   switch(entryOptions)
     {
      case TVI_AboveBelowSignal:
         return AboveBelowSignalLine();
      case TVI_AboveBelowZero:
         return AboveBelowZeroLine();
      case TVI_SignalSlope:
         return SignalSlope();
      case TVI_TviSlope:
         return TviSlope();
      default:
         return ENTRY_SIGNAL_NONE;
     }
  }
//+------------------------------------------------------------------+

