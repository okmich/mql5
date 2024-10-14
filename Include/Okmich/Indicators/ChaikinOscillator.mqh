//+------------------------------------------------------------------+
//|                                            ChaikinOscillator.mqh |
//|                                    Copyright 2021, Michael Enudi |
//|                                             okmich2002@yahoo.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2021, Michael Enudi"
#property link      "okmich2002@yahoo.com"

#include "BaseIndicator.mqh"

enum ENUM_CHKOSC_Strategies
  {
   CHKOSC_OsMA,
   CHKOSC_SLOPE,
   CHKOSC_ZeroLineCrossover
  };

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
class CChaikinOscillator : public CBaseIndicator
  {
private :
   int                mBarsToCopy;
   //--- indicator paramter
   int                mFastMaPeriod, mSlowMaPeriod, mSignalPeriod;
   ENUM_MA_METHOD      mSmoothingMethod;
   ENUM_APPLIED_VOLUME mAppliedVolume;
   //--- indicator
   int                m_Handle;
   //--- indicator buffer
   double             m_MainBuffer[], m_SignalBuffer[];

   double             OsMA(int shift=1);
   ENUM_ENTRY_SIGNAL  OsMAEntrySignal();
   ENUM_ENTRY_SIGNAL  MainSlopeSignal();
   ENUM_ENTRY_SIGNAL  ZeroLineCrossoverSignal();

public:
                     CChaikinOscillator(string symbol, ENUM_TIMEFRAMES period,
                      int InputFastMaPeriod, int InputSlowMaPeriod, int InputSignalPeriod,
                      ENUM_MA_METHOD InputSmoothingMethed = MODE_EMA,
                      ENUM_APPLIED_VOLUME InputAppliedVolume = VOLUME_TICK,
                      int InpBarsToCopy=12): CBaseIndicator(symbol, period)
     {
      mFastMaPeriod = InputFastMaPeriod;
      mSlowMaPeriod = InputSlowMaPeriod;
      mSignalPeriod = InputSignalPeriod;
      mSmoothingMethod = InputSmoothingMethed;
      mAppliedVolume = InputAppliedVolume;

      mBarsToCopy = InpBarsToCopy;
     }

   virtual bool       Init();
   virtual bool       Refresh(int ShiftToUse=1);
   virtual void       Release();

   double             GetData(int bufferIndx, int shift=1);
   void               GetData(int bufferIndx, double &buffer[], int shift);

   ENUM_ENTRY_SIGNAL  TradeSignal(ENUM_CHKOSC_Strategies filterOption);
   ENUM_ENTRY_SIGNAL  TradeFilter(ENUM_CHKOSC_Strategies filterOption);
  };

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
bool CChaikinOscillator::Init(void)
  {
   ArraySetAsSeries(m_MainBuffer, true);

   m_Handle = iCustom(m_Symbol, m_TF, "Okmich\\Chaikin Oscillator",
                      mFastMaPeriod, mSlowMaPeriod, mSignalPeriod,
                      mSmoothingMethod, mAppliedVolume);
   return m_Handle != INVALID_HANDLE;
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
bool CChaikinOscillator::Refresh(int ShiftToUse=1)
  {
   m_ShiftToUse = ShiftToUse;
   int histCopied = CopyBuffer(m_Handle, 0, 0, mBarsToCopy, m_MainBuffer);
   int signCopied = CopyBuffer(m_Handle, 1, 0, mBarsToCopy, m_SignalBuffer);

   return mBarsToCopy == histCopied && histCopied == signCopied;
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void CChaikinOscillator::Release(void)
  {
   IndicatorRelease(m_Handle);
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
double CChaikinOscillator::GetData(int bufferIndx, int shift=1)
  {
   if(bufferIndx > 1 || shift >= mBarsToCopy)
      return EMPTY_VALUE;

   if(bufferIndx ==0)
      return m_MainBuffer[shift];
   else
      if(bufferIndx == 1)
         return m_SignalBuffer[shift];
      else
         return EMPTY_VALUE;
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void CChaikinOscillator::GetData(int bufferIndx, double &buffer[], int shift)
  {
   if(bufferIndx > 1 || shift >= mBarsToCopy)
      return;

   ArraySetAsSeries(buffer, true);
   ArrayResize(buffer, mBarsToCopy - shift);

   if(bufferIndx == 0)
      ArrayCopy(buffer, m_MainBuffer, 0, shift);
   else
      if(bufferIndx == 1)
         ArrayCopy(buffer, m_SignalBuffer, 0, shift);
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
double CChaikinOscillator::OsMA(int shift=1)
  {
   if(shift >= mBarsToCopy)
      return EMPTY_VALUE;

   return m_MainBuffer[shift] - m_SignalBuffer[shift];
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
ENUM_ENTRY_SIGNAL CChaikinOscillator::OsMAEntrySignal()
  {
   double osmaShift1 = OsMA(1);
   double osmaShift2 = OsMA(2);

   return (osmaShift2 < 0 && osmaShift1 > 0)
          ? ENTRY_SIGNAL_BUY :
          (osmaShift2 > 0 && osmaShift1 < 0) ? ENTRY_SIGNAL_SELL :
          ENTRY_SIGNAL_NONE;
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
ENUM_ENTRY_SIGNAL CChaikinOscillator::MainSlopeSignal()
  {
   int periodToUse = mFastMaPeriod/2;
   double slope = RegressionSlope(m_MainBuffer, periodToUse, 1);
   return (slope > 0) ? ENTRY_SIGNAL_BUY : (slope < 0) ? ENTRY_SIGNAL_SELL : ENTRY_SIGNAL_NONE;
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
ENUM_ENTRY_SIGNAL CChaikinOscillator::ZeroLineCrossoverSignal()
  {
   if(m_MainBuffer[2] < 0 && m_MainBuffer[1] > 0)
      return ENTRY_SIGNAL_BUY;
   else
      if
      (m_MainBuffer[2] > 0 && m_MainBuffer[1] < 0)
         return ENTRY_SIGNAL_SELL;
   return ENTRY_SIGNAL_NONE;
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
ENUM_ENTRY_SIGNAL CChaikinOscillator::TradeSignal(ENUM_CHKOSC_Strategies entryStrategyOption)
  {
   switch(entryStrategyOption)
     {
      case CHKOSC_OsMA:
         return OsMAEntrySignal();
      case CHKOSC_SLOPE :
         return MainSlopeSignal();
      case CHKOSC_ZeroLineCrossover :
         return ZeroLineCrossoverSignal();
      default:
         return ENTRY_SIGNAL_NONE;
     }
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
ENUM_ENTRY_SIGNAL CChaikinOscillator::TradeFilter(ENUM_CHKOSC_Strategies entryStrategyOption)
  {
   switch(entryStrategyOption)
     {
      case CHKOSC_OsMA:
         return (m_MainBuffer[1] > m_SignalBuffer[1]) ? ENTRY_SIGNAL_BUY :
                (m_MainBuffer[1] < m_SignalBuffer[1]) ? ENTRY_SIGNAL_SELL : ENTRY_SIGNAL_NONE;
      case CHKOSC_ZeroLineCrossover :
         return (m_MainBuffer[1] > 0) ? ENTRY_SIGNAL_BUY :
                (m_MainBuffer[1] < 0) ? ENTRY_SIGNAL_SELL : ENTRY_SIGNAL_NONE;
      default:
         return ENTRY_SIGNAL_NONE;
     }
  }
//+------------------------------------------------------------------+
