//+------------------------------------------------------------------+
//|                                            TrueStrengthIndex.mqh |
//|                                    Copyright 2020, Michael Enudi |
//|                                             okmich2002@yahoo.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2020, Michael Enudi"
#property link      "okmich2002@yahoo.com"
#property version   "1.00"

#include "BaseIndicator.mqh"

enum ENUM_TSI_Strategies
  {
   TSI_AboveBelowZero,
   TSI_AboveBelowSignal,
   TSI_TsiSlope,
   TSI_SignalSlope,
  };

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
class CTrueStrengthIndex : public CBaseIndicator
  {
private :
   int                mBarsToCopy;
   //--- indicator paramter
   int                m_TsiPeriod,m_Smooth1, m_Smooth2, m_Signal;
   //--- indicator
   int                m_TsiHandle;
   //--- indicator buffer
   double             m_TsiBuffer[], m_SignalBuffer[];

   ENUM_ENTRY_SIGNAL  AboveBelowZeroLine();
   ENUM_ENTRY_SIGNAL  AboveBelowSignalLine();
   ENUM_ENTRY_SIGNAL  TsiSlope();
   ENUM_ENTRY_SIGNAL  SignalSlope();

public:
                     CTrueStrengthIndex(string symbol, ENUM_TIMEFRAMES period, int InptTsiPeriod,
                      int InpSmooth1, int InpSmooth2, int InpSignal): CBaseIndicator(symbol, period)
     {
      m_TsiPeriod = InptTsiPeriod;
      m_Smooth1 = InpSmooth1;
      m_Smooth2 = InpSmooth2;
      m_Signal = InpSignal;

      mBarsToCopy = InptTsiPeriod;
     }

   virtual bool       Init();
   virtual bool       Refresh(int ShiftToUse=1);
   virtual void       Release();

   double             GetData(int shift=0, int bufferIndx=0);
   void               GetData(double &buffer[], int shift=0, int bufferIndx=0);
   
   ENUM_ENTRY_SIGNAL  TradeFilter(ENUM_TSI_Strategies signalOption);
  };

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
bool CTrueStrengthIndex::Init(void)
  {
   ArraySetAsSeries(m_TsiBuffer, true);
   ArraySetAsSeries(m_SignalBuffer, true);

   m_TsiHandle = iCustom(m_Symbol, m_TF, "Okmich\\True Strength Index", m_TsiPeriod, m_Smooth1, m_Smooth2, m_Signal);
   return m_TsiHandle != INVALID_HANDLE;
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
bool CTrueStrengthIndex::Refresh(int ShiftToUse=1)
  {
   m_ShiftToUse = ShiftToUse;
   int dataCopied = CopyBuffer(m_TsiHandle, 0, 0, mBarsToCopy, m_TsiBuffer);
   CopyBuffer(m_TsiHandle, 1, 0, mBarsToCopy, m_SignalBuffer);

   return mBarsToCopy == dataCopied;
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void CTrueStrengthIndex::Release(void)
  {
   IndicatorRelease(m_TsiHandle);
  }


//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
double CTrueStrengthIndex::GetData(int shift=0, int bufferIndx=0)
  {
   if(shift >= mBarsToCopy || bufferIndx > 1)
      return EMPTY_VALUE;

   switch(bufferIndx)
     {
      case 0:
         return m_TsiBuffer[shift];
      case 1:
         return m_SignalBuffer[shift];
      default:
         return EMPTY_VALUE;
     }
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void CTrueStrengthIndex::GetData(double &buffer[], int shift=0, int bufferIndx=0)
  {
   if(shift >= mBarsToCopy || bufferIndx > 1)
      return;

   ArraySetAsSeries(buffer, true);
   ArrayResize(buffer, mBarsToCopy - shift);

   switch(bufferIndx)
     {
      case 0:
         ArrayCopy(buffer, m_TsiBuffer, 0, shift);
         break;
      case 1:
         ArrayCopy(buffer, m_SignalBuffer, 0, shift);
         break;
      default:
         break;
     }
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
ENUM_ENTRY_SIGNAL CTrueStrengthIndex::AboveBelowSignalLine()
  {
   if(m_TsiBuffer[1] > m_SignalBuffer[1])
      return ENTRY_SIGNAL_BUY;
   else
      if(m_TsiBuffer[1] < m_SignalBuffer[1])
         return ENTRY_SIGNAL_SELL;
      else
         return ENTRY_SIGNAL_NONE;
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
ENUM_ENTRY_SIGNAL CTrueStrengthIndex::AboveBelowZeroLine()
  {
   if(m_TsiBuffer[1] > 0)
      return ENTRY_SIGNAL_BUY;
   else
      if(m_TsiBuffer[1] < 0)
         return ENTRY_SIGNAL_SELL;
      else
         return ENTRY_SIGNAL_NONE;
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
ENUM_ENTRY_SIGNAL CTrueStrengthIndex::TsiSlope()
  {
   double slope = RegressionSlope(m_TsiBuffer, 3, 1);
   return (slope > 0) ? ENTRY_SIGNAL_BUY : (slope < 0) ? ENTRY_SIGNAL_SELL : ENTRY_SIGNAL_NONE;
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
ENUM_ENTRY_SIGNAL CTrueStrengthIndex::SignalSlope()
  {
   double slope = RegressionSlope(m_SignalBuffer, 3, 1);
   return (slope > 0) ? ENTRY_SIGNAL_BUY : (slope < 0) ? ENTRY_SIGNAL_SELL : ENTRY_SIGNAL_NONE;
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
ENUM_ENTRY_SIGNAL CTrueStrengthIndex::TradeFilter(ENUM_TSI_Strategies entryOptions)
  {
   switch(entryOptions)
     {
      case TSI_AboveBelowSignal:
         return AboveBelowSignalLine();
      case TSI_AboveBelowZero:
         return AboveBelowZeroLine();
      case TSI_SignalSlope:
         return SignalSlope();
      case TSI_TsiSlope:
         return TsiSlope();
      default:
         return ENTRY_SIGNAL_NONE;
     }
  }
//+------------------------------------------------------------------+
