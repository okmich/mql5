//+------------------------------------------------------------------+
//|                                                         Macd.mqh |
//|                                    Copyright 2021, Michael Enudi |
//|                                             okmich2002@yahoo.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2021, Michael Enudi"
#property link      "okmich2002@yahoo.com"

#include "BaseIndicator.mqh"

enum ENUM_MACD_Strategies
  {
   MACD_Divergence,
   MACD_OsMA,
   MACD_ZeroLineCrossover
  };

enum enum_nematype
  {
   nematype_dema, //Double EMA
   nematype_tema, //Triple EMA
   nematype_vama, //Volume Adjusted MA
   nematype_vwma  //Volume Weighted MA
  };

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
class CNemaMacd : public CBaseIndicator
  {
private :
   int                mDivergencePeriod, mBarsToCopy;
   //--- indicator paramter
   int                mFastMaPeriod, mSlowMaPeriod, mSignalPeriod;
   enum_nematype      mNType;
   //--- indicator
   int                m_Handle;
   //--- indicator buffer
   double             m_HistBuffer[], m_SignalBuffer[];

   double             OsMA();
   ENUM_ENTRY_SIGNAL  OsMAEntrySignal();
   ENUM_ENTRY_SIGNAL  CrossoverSignal();

   ENUM_ENTRY_SIGNAL  Divergence(int shift=1);

public:
                     CNemaMacd(string symbol, ENUM_TIMEFRAMES period,
             enum_nematype InptNType, int InputFastMaPeriod, int InputSlowMaPeriod, int InputSignalPeriod,
             int InputDivergenceLookback=10): CBaseIndicator(symbol, period)
     {
      mNType = InptNType;
      mFastMaPeriod = InputFastMaPeriod;
      mSlowMaPeriod = InputSlowMaPeriod;
      mSignalPeriod = InputSignalPeriod;

      mDivergencePeriod = InputDivergenceLookback;
      mBarsToCopy = mDivergencePeriod+3;
     }

   virtual bool       Init();
   virtual bool       Refresh(int ShiftToUse=1);
   virtual void       Release();

   double             GetData(int bufferIndx, int shift=1);
   void               GetData(int bufferIndx, double &buffer[], int shift);

   ENUM_ENTRY_SIGNAL  TradeSignal(ENUM_MACD_Strategies entryStrategyOption);

   ENUM_ENTRY_SIGNAL  OsmaFilter(int shift=1);
   ENUM_ENTRY_SIGNAL  HistZeroFilter(int shift=1);
  };

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
bool CNemaMacd::Init(void)
  {
   ArraySetAsSeries(m_HistBuffer, true);
   ArraySetAsSeries(m_SignalBuffer, true);
   if(mNType == nematype_dema || mNType == nematype_tema)
      m_Handle = iCustom(m_Symbol, m_TF, "Articles\\NEMA MACD", mNType,
                         mFastMaPeriod, mSlowMaPeriod, mSignalPeriod, PRICE_CLOSE);
   else
      if(mNType == nematype_vama)
         m_Handle = iCustom(m_Symbol, m_TF, "Articles\\Volume-Adjusted MACD",
                            mFastMaPeriod, mSlowMaPeriod, mSignalPeriod, VOLUME_TICK);
      else
         if(mNType == nematype_vwma)
            m_Handle = iCustom(m_Symbol, m_TF, "Articles\\Volume-Weighted MACD",
                               mFastMaPeriod, mSlowMaPeriod, mSignalPeriod, VOLUME_TICK);
         else
            return false;

   return m_Handle != INVALID_HANDLE;
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
bool CNemaMacd::Refresh(int ShiftToUse=1)
  {
   m_ShiftToUse = ShiftToUse;
   int histCopied = CopyBuffer(m_Handle, 0, 0, mBarsToCopy, m_HistBuffer);
   int signCopied = CopyBuffer(m_Handle, 1, 0, mBarsToCopy, m_SignalBuffer);

   return mBarsToCopy == histCopied && histCopied == signCopied;
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void CNemaMacd::Release(void)
  {
   IndicatorRelease(m_Handle);
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
double CNemaMacd::GetData(int bufferIndx, int shift=1)
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
void CNemaMacd::GetData(int bufferIndx, double &buffer[], int shift)
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
ENUM_ENTRY_SIGNAL CNemaMacd::TradeSignal(ENUM_MACD_Strategies entryStrategyOption)
  {
   switch(entryStrategyOption)
     {
      case MACD_Divergence:
         return Divergence(m_ShiftToUse);
      case MACD_OsMA:
         return OsMAEntrySignal();
      case MACD_ZeroLineCrossover :
         return CrossoverSignal();
      default:
         return ENTRY_SIGNAL_NONE;
     }
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
ENUM_ENTRY_SIGNAL CNemaMacd::CrossoverSignal()
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
ENUM_ENTRY_SIGNAL CNemaMacd::OsMAEntrySignal()
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
ENUM_ENTRY_SIGNAL CNemaMacd::OsmaFilter(int shift=1)
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
ENUM_ENTRY_SIGNAL CNemaMacd::HistZeroFilter(int shift=1)
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
//|                                                                  |
//+------------------------------------------------------------------+
ENUM_ENTRY_SIGNAL CNemaMacd::Divergence(int shift=1)
  {
   double currentLow = iLow(m_Symbol, m_TF, shift);
   double highestLow = iLow(m_Symbol, m_TF, iHighest(m_Symbol, m_TF, MODE_LOW, mDivergencePeriod, shift+1));
   double lowestMacd = ArrayMin(m_HistBuffer, mDivergencePeriod, shift+1);

   if(m_HistBuffer[shift] < 0 && (currentLow > highestLow) &&
      (m_HistBuffer[shift] < lowestMacd))
      return ENTRY_SIGNAL_BUY;

   double currentHigh = iHigh(m_Symbol, m_TF, shift);
   double lowestHigh = iHigh(m_Symbol, m_TF, iLowest(m_Symbol, m_TF, MODE_HIGH, mDivergencePeriod, shift+1));
   double highestMacd = ArrayMin(m_HistBuffer, mDivergencePeriod, shift+1);

   if(m_HistBuffer[shift] > 0 && (currentHigh < lowestHigh) &&
      (m_HistBuffer[shift] > highestMacd))
      return ENTRY_SIGNAL_SELL;
   else
      return ENTRY_SIGNAL_NONE;
  }
//+------------------------------------------------------------------+
