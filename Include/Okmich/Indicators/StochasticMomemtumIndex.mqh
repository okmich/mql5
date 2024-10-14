//+------------------------------------------------------------------+
//|                                     Stochastc Momentum Index.mqh |
//|                                    Copyright 2020, Michael Enudi |
//|                                             okmich2002@yahoo.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2020, Michael Enudi"
#property link      "okmich2002@yahoo.com"
#property version   "1.00"

#include "BaseIndicator.mqh"

enum ENUM_SMI_Strategies
  {
   SMI_AboveBelowZero,
   SMI_AboveBelowSignal,
   SMI_SmiSlope,
   SMI_SignalSlope
  };

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
class CSmi : public CBaseIndicator
  {
private :
   //--- indicator paramter
   int                m_SmiPeriod, m_Smooth1, m_Smooth2, m_Signal;
   //--- indicator
   int                m_SmiHandle;
   //--- indicator buffer
   double             m_SmiBuffer[], m_SignalBuffer[];

   ENUM_ENTRY_SIGNAL  AboveBelowZeroLine(int shift=0);
   ENUM_ENTRY_SIGNAL  AboveBelowSignalLine(int shift=0);
   ENUM_ENTRY_SIGNAL  SmiSlope(int shift=0);
   ENUM_ENTRY_SIGNAL  SignalSlope(int shift=0);

public:
                     CSmi(string symbol, ENUM_TIMEFRAMES period, int smiPeriod=13, int smooth1=25,
        int smooth2=3, int signal=5): CBaseIndicator(symbol, period)
     {
      m_SmiPeriod = smiPeriod;
      m_Smooth1 = smooth1;
      m_Smooth2 = smooth2;
      m_Signal = signal;
     }

   virtual bool       Init();
   virtual bool       Refresh(int ShiftToUse=1);
   virtual void       Release();

   double             GetData(int shift=0, int bufferIndx=0);
   void               GetData(double &buffer[], int shift=0, int bufferIndx=0);

   ENUM_ENTRY_SIGNAL  TradeFilter(ENUM_SMI_Strategies signalOption);
   ENUM_ENTRY_SIGNAL  TradeSignal(ENUM_SMI_Strategies signalOption);
  };

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
bool CSmi::Init(void)
  {
   ArraySetAsSeries(m_SmiBuffer, true);
   ArraySetAsSeries(m_SignalBuffer, true);

   m_SmiHandle = iCustom(m_Symbol, m_TF, "Okmich\\Stochastic Momentum Index", m_SmiPeriod, m_Smooth1, m_Smooth2, m_Signal, PRICE_CLOSE);
   return m_SmiHandle != INVALID_HANDLE;
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void CSmi::Release(void)
  {
   IndicatorRelease(m_SmiHandle);
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
bool CSmi::Refresh(int ShiftToUse=1)
  {
   m_ShiftToUse = ShiftToUse;
   int barsToCopy = 5;
   int dataCopied = CopyBuffer(m_SmiHandle, 0, 0, barsToCopy, m_SmiBuffer);
   int signalCopied = CopyBuffer(m_SmiHandle, 1, 0, barsToCopy, m_SignalBuffer);

   return barsToCopy == dataCopied && dataCopied == signalCopied;
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
double CSmi::GetData(int buffer=0, int shift=0)
  {
   if(shift >= 5 || buffer > 1)
      return EMPTY_VALUE;

   return buffer == 0 ? m_SmiBuffer[shift] : m_SignalBuffer[shift];
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
ENUM_ENTRY_SIGNAL CSmi::AboveBelowSignalLine(int shift=0)
  {
   if(m_SmiBuffer[shift] > m_SignalBuffer[shift])
      return ENTRY_SIGNAL_BUY;
   else
      if(m_SmiBuffer[shift] < m_SignalBuffer[shift])
         return ENTRY_SIGNAL_SELL;
      else
         return ENTRY_SIGNAL_NONE;
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
ENUM_ENTRY_SIGNAL CSmi::AboveBelowZeroLine(int shift=0)
  {
   if(m_SmiBuffer[shift] > 0)
      return ENTRY_SIGNAL_BUY;
   else
      if(m_SmiBuffer[shift] < 0)
         return ENTRY_SIGNAL_SELL;
      else
         return ENTRY_SIGNAL_NONE;
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
ENUM_ENTRY_SIGNAL CSmi::SmiSlope(int shift=0)
  {
   double slope = RegressionSlope(m_SmiBuffer, 3, shift);
   return (slope > 0) ? ENTRY_SIGNAL_BUY : (slope < 0) ? ENTRY_SIGNAL_SELL : ENTRY_SIGNAL_NONE;
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
ENUM_ENTRY_SIGNAL CSmi::SignalSlope(int shift=0)
  {
   double slope = RegressionSlope(m_SignalBuffer, 3, shift);
   return (slope > 0) ? ENTRY_SIGNAL_BUY : (slope < 0) ? ENTRY_SIGNAL_SELL : ENTRY_SIGNAL_NONE;
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
ENUM_ENTRY_SIGNAL CSmi::TradeFilter(ENUM_SMI_Strategies entryOptions)
  {
   switch(entryOptions)
     {
      case SMI_AboveBelowSignal:
         return AboveBelowSignalLine();
      case SMI_AboveBelowZero:
         return AboveBelowZeroLine();
      case SMI_SignalSlope:
         return SignalSlope();
      case SMI_SmiSlope:
         return SmiSlope();
      default:
         return ENTRY_SIGNAL_NONE;
     }
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
ENUM_ENTRY_SIGNAL CSmi::TradeSignal(ENUM_SMI_Strategies entryOptions)
  {
   ENUM_ENTRY_SIGNAL signal2, signal1;
   switch(entryOptions)
     {
      case SMI_AboveBelowSignal:
         signal1 = AboveBelowSignalLine(m_ShiftToUse);
         signal2 = AboveBelowSignalLine(m_ShiftToUse+1);
         break;
      case SMI_AboveBelowZero:
         signal1 = AboveBelowZeroLine(m_ShiftToUse);
         signal2 = AboveBelowZeroLine(m_ShiftToUse+1);
         break;
      case SMI_SignalSlope:
         signal1 = SignalSlope(m_ShiftToUse);
         signal2 = SignalSlope(m_ShiftToUse+1);
         break;
      case SMI_SmiSlope:
         signal1 = SmiSlope(m_ShiftToUse);
         signal2 = SmiSlope(m_ShiftToUse+1);
         break;
      default:
         signal1 = signal2 = ENTRY_SIGNAL_NONE;
     }

   return signal1 != signal2 ? signal1 : ENTRY_SIGNAL_NONE;
  }
//+------------------------------------------------------------------+
