//+------------------------------------------------------------------+
//|                                               VolumeMacd.mqh.mqh |
//|                                    Copyright 2022, Michael Enudi |
//|                                             okmich2002@yahoo.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2022, Michael Enudi"
#property link      "okmich2002@yahoo.com"

#include "BaseIndicator.mqh"

enum ENUM_VMACD_Strategies
  {
   VMACD_OsMA,
   VMACD_ZeroLineCrossover
  };

enum ENUM_VMACD_CALC_MODE
  {
   VMACD_CALC_ADJUSTED,
   VMACD_CALC_WEIGHTED
  };

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
class CVolumeMacd : public CBaseIndicator
  {
private :
   int                mBarsToCopy;
   //--- indicator paramter
   int                mFastMaPeriod, mSlowMaPeriod, mSignalPeriod;
   ENUM_APPLIED_VOLUME mAppliedVolume;
   ENUM_VMACD_CALC_MODE              mVMacdCalcMode;
   //--- indicator
   int                m_Handle;
   //--- indicator buffer
   double             m_HistBuffer[], m_SignalBuffer[];

   double             OsMA();
   ENUM_ENTRY_SIGNAL  OsMAEntrySignal();
   ENUM_ENTRY_SIGNAL  CrossoverSignal();

public:
                     CVolumeMacd(string symbol, ENUM_TIMEFRAMES period,
               int InputFastMaPeriod, int InputSlowMaPeriod, int InputSignalPeriod,
               ENUM_VMACD_CALC_MODE InputCalcMode=VMACD_CALC_ADJUSTED,
               ENUM_APPLIED_VOLUME InputAppliedVolume = VOLUME_TICK,
               int historyBars=6): CBaseIndicator(symbol, period)
     {
      mFastMaPeriod = InputFastMaPeriod;
      mSlowMaPeriod = InputSlowMaPeriod;
      mSignalPeriod = InputSignalPeriod;

      mAppliedVolume = InputAppliedVolume;

      mVMacdCalcMode = InputCalcMode;
      mBarsToCopy = historyBars;
     }

   virtual bool       Init();
   virtual bool       Refresh(int ShiftToUse=1);
   virtual void       Release();

   double             GetData(int bufferIndx, int shift=1);
   void               GetData(int bufferIndx, double &buffer[], int shift);

   ENUM_ENTRY_SIGNAL  TradeSignal(ENUM_VMACD_Strategies entryStrategyOption);

   ENUM_ENTRY_SIGNAL  OsmaFilter(int shift=1);
   ENUM_ENTRY_SIGNAL  HistZeroFilter(int shift=1);
  };

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
bool CVolumeMacd::Init(void)
  {
   ArraySetAsSeries(m_HistBuffer, true);
   ArraySetAsSeries(m_SignalBuffer, true);
   if(mVMacdCalcMode == VMACD_CALC_ADJUSTED)
      m_Handle = iCustom(m_Symbol, m_TF, "Articles\\Volume-Adjusted MACD",
                         mFastMaPeriod, mSlowMaPeriod, mSignalPeriod, mAppliedVolume);
   else
      if(mVMacdCalcMode == VMACD_CALC_WEIGHTED)
         m_Handle = iCustom(m_Symbol, m_TF, "Articles\\Volume-Weighted MACD",
                            mFastMaPeriod, mSlowMaPeriod, mSignalPeriod, mAppliedVolume);
      else
         m_Handle = INVALID_HANDLE;

   return m_Handle != INVALID_HANDLE;
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
bool CVolumeMacd::Refresh(int ShiftToUse=1)
  {
   m_ShiftToUse = ShiftToUse;
   int histCopied = CopyBuffer(m_Handle, 0, 0, mBarsToCopy, m_HistBuffer);
   int signCopied = CopyBuffer(m_Handle, 1, 0, mBarsToCopy, m_SignalBuffer);

   return mBarsToCopy == histCopied && histCopied == signCopied;
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void CVolumeMacd::Release(void)
  {
   IndicatorRelease(m_Handle);
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
double CVolumeMacd::GetData(int bufferIndx, int shift=1)
  {
   if(bufferIndx > 1 || shift >= mBarsToCopy)
      return EMPTY_VALUE;

   if(bufferIndx ==0)
      return m_HistBuffer[shift];
   else
      if(bufferIndx == 1)
         return m_SignalBuffer[shift];
      else
         return EMPTY_VALUE;
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void CVolumeMacd::GetData(int bufferIndx, double &buffer[], int shift)
  {
   if(bufferIndx > 1 || shift >= mBarsToCopy)
      return;

   ArraySetAsSeries(buffer, true);
   ArrayResize(buffer, mBarsToCopy - shift);

   if(bufferIndx == 0)
      ArrayCopy(buffer, m_HistBuffer, 0, shift);
   else
      if(bufferIndx == 1)
         ArrayCopy(buffer, m_SignalBuffer, 0, shift);
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
ENUM_ENTRY_SIGNAL CVolumeMacd::TradeSignal(ENUM_VMACD_Strategies entryStrategyOption)
  {
   switch(entryStrategyOption)
     {
      case VMACD_OsMA:
         return OsMAEntrySignal();
      case VMACD_ZeroLineCrossover :
         return CrossoverSignal();
      default:
         return ENTRY_SIGNAL_NONE;
     }
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
ENUM_ENTRY_SIGNAL CVolumeMacd::CrossoverSignal()
  {
   ENUM_ENTRY_SIGNAL prevFilter = HistZeroFilter(m_ShiftToUse+1);
   ENUM_ENTRY_SIGNAL currFilter = HistZeroFilter(m_ShiftToUse);
   if(prevFilter != ENTRY_SIGNAL_BUY && currFilter == ENTRY_SIGNAL_BUY)
      return ENTRY_SIGNAL_BUY;
   else
      if(prevFilter != ENTRY_SIGNAL_SELL && currFilter == ENTRY_SIGNAL_SELL)
         return ENTRY_SIGNAL_SELL;
      else
         return ENTRY_SIGNAL_NONE;
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
ENUM_ENTRY_SIGNAL CVolumeMacd::OsMAEntrySignal()
  {
   ENUM_ENTRY_SIGNAL prevFilter = OsmaFilter(m_ShiftToUse+1);
   ENUM_ENTRY_SIGNAL currFilter = OsmaFilter(m_ShiftToUse);
   if(prevFilter != ENTRY_SIGNAL_BUY && currFilter == ENTRY_SIGNAL_BUY)
      return ENTRY_SIGNAL_BUY;
   else
      if(prevFilter != ENTRY_SIGNAL_SELL && currFilter == ENTRY_SIGNAL_SELL)
         return ENTRY_SIGNAL_SELL;
      else
         return ENTRY_SIGNAL_NONE;
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
ENUM_ENTRY_SIGNAL CVolumeMacd::OsmaFilter(int shift=1)
  {
   if(m_HistBuffer[shift] > m_SignalBuffer[shift])
      return ENTRY_SIGNAL_BUY;
   else
      if
      (m_HistBuffer[shift] < m_SignalBuffer[shift])
         return ENTRY_SIGNAL_SELL;
   return ENTRY_SIGNAL_NONE;
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
ENUM_ENTRY_SIGNAL CVolumeMacd::HistZeroFilter(int shift=1)
  {
   if(m_HistBuffer[shift] > 0)
      return ENTRY_SIGNAL_BUY;
   else
      if
      (m_HistBuffer[shift] < 0)
         return ENTRY_SIGNAL_SELL;
   return ENTRY_SIGNAL_NONE;
  }
//+------------------------------------------------------------------+
