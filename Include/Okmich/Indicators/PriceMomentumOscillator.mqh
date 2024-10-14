//+------------------------------------------------------------------+
//|                                      PriceMomentumOscillator.mqh |
//|                                    Copyright 2022, Michael Enudi |
//|                                             okmich2002@yahoo.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2022, Michael Enudi"
#property link      "okmich2002@yahoo.com"

#include "BaseIndicator.mqh"

enum ENUM_PMO_Strategies
  {
   PMO_Strategies_Crossover,
   PMO_Strategies_SlopeChange,
   PMO_Strategies_Zeroline,
  };

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
class CPriceMomentumOscillator : public CBaseIndicator
  {
private :
   int                mBarsToCopy;
   //--- indicator paramter
   int                m_Period,m_Period2, m_Signal, m_SlopePeriod;
   //--- indicator
   int                m_Handle;
   //--- indicator buffer
   double             m_Buffer[], m_SignalBuffer[];
   
   ENUM_ENTRY_SIGNAL  SignalCrossoverSignal();
   ENUM_ENTRY_SIGNAL  SlopeChangeSignal();
   ENUM_ENTRY_SIGNAL  ZeroLineCrossoverSignal();

public:
                     CPriceMomentumOscillator(string symbol, ENUM_TIMEFRAMES period,
                            int InptPeriod, int InptPeriod2, int InptSignal,
                            int InptSlopePeriod=3): CBaseIndicator(symbol, period)
     {
      m_Period = InptPeriod;
      m_Period2 = InptPeriod2;
      m_Signal = InptSignal;
      m_SlopePeriod = InptSlopePeriod;

      mBarsToCopy = InptSlopePeriod*3;
     }

   virtual bool       Init();
   virtual bool       Refresh(int ShiftToUse=1);
   virtual void       Release();
   
   double             GetData(int shift=0, int bufferIndx=0);
   void               GetData(double &buffer[], int shift=0, int bufferIndx=0);
   
   ENUM_ENTRY_SIGNAL  TradeSignal(ENUM_PMO_Strategies entryStrategyOption);
   
   ENUM_TRENDSTATE    VolatilityState(void);
  };

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
bool CPriceMomentumOscillator::Init(void)
  {
   ArraySetAsSeries(m_Buffer, true);
   ArraySetAsSeries(m_SignalBuffer, true);

   m_Handle = iCustom(m_Symbol, m_TF, "Articles\\Price Momentum Oscillator", m_Period, m_Period2, m_Signal, PRICE_CLOSE);
   return m_Handle != INVALID_HANDLE;
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
bool CPriceMomentumOscillator::Refresh(int ShiftToUse=1)
  {
   m_ShiftToUse = ShiftToUse;
   int dataCopied = CopyBuffer(m_Handle, 0, 0, mBarsToCopy, m_Buffer);
   int signalCopied = CopyBuffer(m_Handle, 1, 0, mBarsToCopy, m_SignalBuffer);

   return mBarsToCopy == dataCopied && dataCopied == signalCopied;
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void CPriceMomentumOscillator::Release(void)
  {
   IndicatorRelease(m_Handle);
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
double CPriceMomentumOscillator::GetData(int shift=0, int bufferIndx=0)
  {
   if(shift >= mBarsToCopy || bufferIndx > 1)
      return EMPTY_VALUE;

   switch(bufferIndx)
     {
      case 0:
         return m_Buffer[shift];
      case 1:
         return m_SignalBuffer[shift];
      default:
         return EMPTY_VALUE;
     }
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void CPriceMomentumOscillator::GetData(double &buffer[], int shift=0, int bufferIndx=0)
  {
   if(shift >= mBarsToCopy || bufferIndx > 1)
      return;

   ArraySetAsSeries(buffer, true);
   ArrayResize(buffer, mBarsToCopy - shift);

   switch(bufferIndx)
     {
      case 0:
         ArrayCopy(buffer, m_Buffer, 0, shift);
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
ENUM_ENTRY_SIGNAL CPriceMomentumOscillator::SignalCrossoverSignal(void)
  {
   if(m_Buffer[2] > m_SignalBuffer[2] && m_Buffer[1] < m_SignalBuffer[1])
      return ENTRY_SIGNAL_SELL;
   else
      if(m_Buffer[2] < m_SignalBuffer[2] && m_Buffer[1] > m_SignalBuffer[1])
         return ENTRY_SIGNAL_BUY;
      else
         return ENTRY_SIGNAL_NONE;
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
ENUM_ENTRY_SIGNAL CPriceMomentumOscillator::SlopeChangeSignal(void)
  {
   double previousSlope = RegressionSlope(m_Buffer, m_SlopePeriod, 2);
   double currentSlope = RegressionSlope(m_Buffer, m_SlopePeriod, 1);

   if(previousSlope <= 0 && currentSlope > 0)
      return ENTRY_SIGNAL_BUY;
   else
      if(previousSlope >= 0 && currentSlope < 0)
         return ENTRY_SIGNAL_SELL;
      else
         return ENTRY_SIGNAL_NONE;
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
ENUM_ENTRY_SIGNAL CPriceMomentumOscillator::ZeroLineCrossoverSignal(void)
  {
   if(m_Buffer[2] > 0 && m_Buffer[1] < 0)
      return ENTRY_SIGNAL_SELL;
   else
      if(m_Buffer[2] < 0 && m_Buffer[1] > 0)
         return ENTRY_SIGNAL_BUY;
      else
         return ENTRY_SIGNAL_NONE;
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
ENUM_ENTRY_SIGNAL CPriceMomentumOscillator::TradeSignal(ENUM_PMO_Strategies entryStrategyOption)
  {
   switch(entryStrategyOption)
     {
      case PMO_Strategies_Crossover:
         return SignalCrossoverSignal();
      case PMO_Strategies_SlopeChange:
         return SlopeChangeSignal();
      case PMO_Strategies_Zeroline:
         return ZeroLineCrossoverSignal();
      default:
         return ENTRY_SIGNAL_NONE;
     }
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
ENUM_TRENDSTATE CPriceMomentumOscillator::VolatilityState(void)
  {
   double mainSlope = RegressionSlope(m_Buffer, m_SlopePeriod * 2 + 1);
   double signalSlope = RegressionSlope(m_SignalBuffer, m_SlopePeriod * 2 + 1);
   return ((mainSlope > 0 && signalSlope < 0) || (mainSlope < 0 && signalSlope > 0)) ? TS_FLAT : TS_TREND;
  }
//+------------------------------------------------------------------+
