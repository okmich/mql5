//+------------------------------------------------------------------+
//|                                                   TTMSqueeze.mqh |
//|                                    Copyright 2021, Michael Enudi |
//|                                             okmich2002@yahoo.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2020, Michael Enudi"
#property link      "okmich2002@yahoo.com"
#property version   "1.00"

#include "BaseIndicator.mqh"

enum ENUM_TTMSQZ_Strategies
  {
   TTMSqueeze_Falling_Rising,
   TTMSqueeze_CrossesZeroLine
  };

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
class CTTMSqueeze : public CBaseIndicator
  {
private :
   int                mBarsToCopy;
   ENUM_TRENDSTATE    mTrendState;
   //--- indicator paramter
   int                m_BbPeriod, m_KcPeriod;
   double             m_BbMultFactor, m_KcMultFactor;
   //--- indicator
   int                m_Handle;
   //--- indicator buffer
   double             m_SqsMomBuffer[], m_SqsSignalBuffer[];
   //--- other variables
   ENUM_ENTRY_SIGNAL  RisingOrFallingSignal();
   ENUM_ENTRY_SIGNAL  CrossesZeroLineSignal();

public:
                     CTTMSqueeze(string symbol, ENUM_TIMEFRAMES period,
               int InputBbPeriod=20, double InputBbMultFactor=2.0,
               int InputKcPeriod=20, double InputKcMultFactor=1.5): CBaseIndicator(symbol, period)
     {
      m_BbPeriod = InputBbPeriod;
      m_BbMultFactor = InputBbMultFactor;
      m_KcPeriod = InputKcPeriod;
      m_KcMultFactor = InputKcMultFactor;

      mBarsToCopy = 5;
     }

   virtual bool                   Init();
   virtual bool                   Refresh(int ShiftToUse=1);
   virtual void                   Release();

   double                         GetData(int buffer=0, int shift=0);
   void                           GetData(double &buffer[], int buffer=0, int shift=0);

   bool                           IsTrending();
   ENUM_TRENDSTATE                TrendState();

   ENUM_ENTRY_SIGNAL              TradeSignal(ENUM_TTMSQZ_Strategies strategyOption);
  };

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
bool CTTMSqueeze::Init(void)
  {
   ArraySetAsSeries(m_SqsMomBuffer, true);
   ArraySetAsSeries(m_SqsSignalBuffer, true);

   m_Handle = iCustom(m_Symbol, m_TF, "Articles/TTM Squeeze Momentum",
                      m_BbPeriod, m_BbMultFactor, m_KcPeriod, m_KcMultFactor, PRICE_CLOSE);

   return m_Handle != INVALID_HANDLE;
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
bool CTTMSqueeze::Refresh(int ShiftToUse=1)
  {
   m_ShiftToUse = ShiftToUse;
   int momCopied = CopyBuffer(m_Handle, 0, 0, mBarsToCopy, m_SqsMomBuffer);
   int signalCopied = CopyBuffer(m_Handle, 3, 0, mBarsToCopy, m_SqsSignalBuffer);
   return mBarsToCopy == momCopied && momCopied == signalCopied;
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void CTTMSqueeze::Release(void)
  {
   IndicatorRelease(m_Handle);
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
double CTTMSqueeze::GetData(int bufferIndx=0, int shift=0)
  {
   if(shift >= mBarsToCopy || bufferIndx > 1)
      return EMPTY_VALUE;

   switch(bufferIndx)
     {
      case 0:
         return m_SqsMomBuffer[shift];
      case 1:
         return m_SqsSignalBuffer[shift];
      default:
         return EMPTY_VALUE;
     }

  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void CTTMSqueeze::GetData(double &buffer[], int bufferIndx=0, int shift=0)
  {
   if(shift >= mBarsToCopy || bufferIndx > 4)
      return;

   ArraySetAsSeries(buffer, true);
   ArrayResize(buffer, mBarsToCopy - shift);

   switch(bufferIndx)
     {
      case 1:
         ArrayCopy(buffer, m_SqsSignalBuffer, 0, shift);
         break;
      case 0:
      default:
         ArrayCopy(buffer, m_SqsMomBuffer, 0, shift);
         break;
     }
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
bool CTTMSqueeze::IsTrending()
  {
   return TrendState() == TS_TREND;
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
ENUM_TRENDSTATE CTTMSqueeze::TrendState()
  {
   return (m_SqsSignalBuffer[m_ShiftToUse] == 0.0) ? TS_FLAT :
          (m_SqsSignalBuffer[m_ShiftToUse] != 0.0) ? TS_TREND : TS_FLAT;
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
ENUM_ENTRY_SIGNAL CTTMSqueeze::TradeSignal(ENUM_TTMSQZ_Strategies strategyOption)
  {
   switch(strategyOption)
     {
      case TTMSqueeze_CrossesZeroLine:
         return CrossesZeroLineSignal();
      case TTMSqueeze_Falling_Rising:
         return RisingOrFallingSignal();
      default:
         return ENTRY_SIGNAL_NONE;
     }
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
ENUM_ENTRY_SIGNAL CTTMSqueeze::CrossesZeroLineSignal(void)
  {
   double prevValue = m_SqsMomBuffer[m_ShiftToUse+1];
   double currValue = m_SqsMomBuffer[m_ShiftToUse];

   if(prevValue < 0.0 && currValue > 0.0)
      return ENTRY_SIGNAL_BUY;
   else
      if(prevValue > 0.0 && currValue < 0.0)
         return ENTRY_SIGNAL_SELL;
      else
         return ENTRY_SIGNAL_NONE;
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
ENUM_ENTRY_SIGNAL CTTMSqueeze::RisingOrFallingSignal(void)
  {
   double prevValue = m_SqsMomBuffer[m_ShiftToUse+1];
   double currValue = m_SqsMomBuffer[m_ShiftToUse];

   if(currValue > prevValue)
      return ENTRY_SIGNAL_BUY;
   else
      if(currValue < prevValue)
         return ENTRY_SIGNAL_SELL;
      else
         return ENTRY_SIGNAL_NONE;
  }
//+------------------------------------------------------------------+
