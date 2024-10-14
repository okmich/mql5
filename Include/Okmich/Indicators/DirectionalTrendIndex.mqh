//+------------------------------------------------------------------+
//|                                        DirectionalTrendIndex.mqh |
//|                                    Copyright 2021, Michael Enudi |
//|                                             okmich2002@yahoo.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2021, Michael Enudi"
#property link      "okmich2002@yahoo.com"
#property version   "1.00"

#include "BaseIndicator.mqh"

enum ENUM_DTI_Strategies
  {
   DTI_AboveBelowZero,
   DTI_AboveBelowSignal,
   DTI_DirectionAboveBelowZero,
   DTI_Directional
  };

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
class CDti : public CBaseIndicator
  {
private :
   int                mBarsToCopy;
   //--- indicator paramter
   int                m_DtiPeriod, m_Smoothing, m_Signal;
   bool               m_DslAnchor;
   //--- indicator
   int                m_DtiHandle;
   //--- indicator buffer
   double             m_DtiBuffer[], m_SignalBuffer[], m_ObBuffer[], m_OsBuffer[];

   ENUM_ENTRY_SIGNAL  AboveBelowZeroLine();
   ENUM_ENTRY_SIGNAL  AboveBelowSignalLine();
   ENUM_ENTRY_SIGNAL  DirectionalAboveBelowZeroFilter();
   ENUM_ENTRY_SIGNAL  DirectionalFilter();

public:
                     CDti(string symbol, ENUM_TIMEFRAMES period,
        int InputDtiPeriod=20, int InptDtiSmoothing=20, int InptSignal=7,
        bool InpDslAnchor=true, int historyBars=6): CBaseIndicator(symbol, period)
     {
      m_DtiPeriod = InputDtiPeriod;
      m_Smoothing = InptDtiSmoothing;
      m_Signal = InptSignal;
      m_DslAnchor = InpDslAnchor;
      mBarsToCopy = historyBars;
     }

   virtual bool       Init();
   virtual bool       Refresh(int ShiftToUse=1);
   virtual void       Release();

   double             GetData(int buffer=0, int shift=0);
   void               GetData(double &buffer[], int buffer=0, int shift=0);

   ENUM_ENTRY_SIGNAL  TradeFilter(ENUM_DTI_Strategies signalOption);

   ENUM_TRENDSTATE    StrengthState(double threshold);
  };

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
bool CDti::Init(void)
  {
   ArraySetAsSeries(m_DtiBuffer, true);
   ArraySetAsSeries(m_ObBuffer, true);
   ArraySetAsSeries(m_OsBuffer, true);
   ArraySetAsSeries(m_SignalBuffer, true);

   m_DtiHandle = iCustom(m_Symbol, m_TF, "Okmich\\Directional Trend Index", m_DtiPeriod, m_Smoothing, m_Signal, m_DslAnchor);
   return m_DtiHandle != INVALID_HANDLE;
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
bool CDti::Refresh(int ShiftToUse=1)
  {
   m_ShiftToUse = ShiftToUse;
   int dataCopied = CopyBuffer(m_DtiHandle, 0, 0, mBarsToCopy, m_DtiBuffer);
   int signalCopied = CopyBuffer(m_DtiHandle, 1, 0, mBarsToCopy, m_SignalBuffer);

   CopyBuffer(m_DtiHandle, 2, 0, mBarsToCopy, m_ObBuffer);
   CopyBuffer(m_DtiHandle, 3, 0, mBarsToCopy, m_OsBuffer);

   return mBarsToCopy == dataCopied && signalCopied == dataCopied;
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void CDti::Release(void)
  {
   IndicatorRelease(m_DtiHandle);
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
double CDti::GetData(int bufferIndx=0, int shift=0)
  {
   if(shift >= mBarsToCopy || bufferIndx > 3)
      return EMPTY_VALUE;

   switch(bufferIndx)
     {
      case 1:
         return m_SignalBuffer[shift];
      case 2:
         return m_ObBuffer[shift];
      case 3:
         return m_OsBuffer[shift];
      case 0:
      default:
         return m_DtiBuffer[shift];
     }
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void CDti::GetData(double &buffer[], int bufferIndx=0, int shift=0)
  {
   if(shift >= mBarsToCopy || bufferIndx > 3)
      return;

   ArraySetAsSeries(buffer, true);
   ArrayResize(buffer, ArraySize(m_DtiBuffer) - shift);

   switch(bufferIndx)
     {
      case 1:
         ArrayCopy(buffer, m_SignalBuffer, 0, shift);
         break;
      case 2:
         ArrayCopy(buffer, m_ObBuffer, 0, shift);
         break;
      case 3:
         ArrayCopy(buffer, m_OsBuffer, 0, shift);
         break;
      case 0:
      default:
         ArrayCopy(buffer, m_DtiBuffer, 0, shift);;
         break;
     }
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
ENUM_TRENDSTATE CDti::StrengthState(double threshold)
  {
   double gapArr[3];
   for(int i = 0; i < 3; i++)
      gapArr[i] = m_ObBuffer[i+1] - m_OsBuffer[i+1];
   double slope = RegressionSlope(gapArr, 3);
   return (slope > 0.02)? TS_TREND : TS_FLAT;
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
ENUM_ENTRY_SIGNAL CDti::AboveBelowSignalLine()
  {
   return m_DtiBuffer[1] > m_SignalBuffer[1] ? ENTRY_SIGNAL_BUY :
          m_DtiBuffer[1] < m_SignalBuffer[1] ? ENTRY_SIGNAL_SELL : ENTRY_SIGNAL_NONE;
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
ENUM_ENTRY_SIGNAL CDti::AboveBelowZeroLine()
  {
   return CBaseIndicator::_Phase(m_DtiBuffer, 0.0);
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
ENUM_ENTRY_SIGNAL CDti::DirectionalAboveBelowZeroFilter()
  {
   double slope = RegressionSlope(m_DtiBuffer, 3, 1);
   if(m_DtiBuffer[1] > 0 && slope > 0)
      return ENTRY_SIGNAL_BUY;
   else
      if(m_DtiBuffer[1] < 0 && slope < 0)
         return ENTRY_SIGNAL_SELL;
      else
         return ENTRY_SIGNAL_NONE;
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
ENUM_ENTRY_SIGNAL CDti::DirectionalFilter()
  {
   double slope = RegressionSlope(m_DtiBuffer, 3, 1);
   return (slope > 0) ? ENTRY_SIGNAL_BUY : ENTRY_SIGNAL_SELL;
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
ENUM_ENTRY_SIGNAL CDti::TradeFilter(ENUM_DTI_Strategies signalOption)
  {
   switch(signalOption)
     {
      case DTI_AboveBelowSignal :
         return AboveBelowSignalLine();
      case DTI_AboveBelowZero :
         return AboveBelowZeroLine();
      case DTI_DirectionAboveBelowZero:
         return DirectionalAboveBelowZeroFilter();
      case DTI_Directional :
         return DirectionalFilter();
      default:
         return ENTRY_SIGNAL_NONE;
     }
  }
//+------------------------------------------------------------------+
