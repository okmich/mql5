//+------------------------------------------------------------------+
//|                                               CADXOscillator.mqh |
//|                                    Copyright 2021, Michael Enudi |
//|                                             okmich2002@yahoo.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2021, Michael Enudi"
#property link      "okmich2002@yahoo.com"
#property version   "1.00"

#include "BaseIndicator.mqh"

enum ENUM_ADXOSC_Strategies
  {
   ADXOSC_AboveBelowZeroLine,
   ADXOSC_OscillatorSlope,
   ADXOSC_DMI
  };

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
class CADXOscillator : public CBaseIndicator
  {
private :
   int                mBarsToCopy, mSlopePeriod;
   double             mTrendIndx;

   //--- indicator paramter
   int                m_DmiPeriod, m_AdxPeriod;
   //--- indicator
   int                m_AdxHandle;
   //--- indicator buffer
   double             m_DpBuffer[], m_DnBuffer[], m_AdxBuffer[], m_OscBuffer[];

   ENUM_ENTRY_SIGNAL  AboveBelowZeroLine();
   ENUM_ENTRY_SIGNAL  DmiCrossSignal();
   ENUM_ENTRY_SIGNAL  OscillatorSlopeSignal();

public:
                     CADXOscillator(string symbol, ENUM_TIMEFRAMES period,
                  int InputDmiPeriod=14, int InputAdxPeriod=14, double trendThreshold=20,
                  double signficantSlope=3.0, int slopePeriod = 3,
                  int historyBars=24): CBaseIndicator(symbol, period)
     {
      m_DmiPeriod = InputDmiPeriod;
      m_AdxPeriod = InputAdxPeriod;
      mTrendIndx = trendThreshold;
      mSlopePeriod = slopePeriod;

      mBarsToCopy = historyBars;
     }

   virtual bool       Init();
   virtual bool       Refresh(int ShiftToUse=1);
   virtual void       Release();

   double             GetData(int buffer=0, int shift=0);
   void               GetData(double &buffer[], int buffer=0, int shift=0);

   ENUM_TRENDSTATE                Trend();
   bool                           IsTrending();
   double                         OscSlope(int shift=1);
   double                         ADXSlope(int shift=1);

   ENUM_ENTRY_SIGNAL  TradeSignal(ENUM_ADXOSC_Strategies signalOption);
  };

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
bool CADXOscillator::Init(void)
  {
   ArraySetAsSeries(m_AdxBuffer, true);
   ArraySetAsSeries(m_OscBuffer, true);
   ArraySetAsSeries(m_DnBuffer, true);
   ArraySetAsSeries(m_DpBuffer, true);

   m_AdxHandle = iCustom(m_Symbol, m_TF, "Okmich\\ADX Oscillator", m_DmiPeriod, m_AdxPeriod);
   return m_AdxHandle != INVALID_HANDLE;
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
bool CADXOscillator::Refresh(int ShiftToUse=1)
  {
   m_ShiftToUse = ShiftToUse;
   int adxCopied = CopyBuffer(m_AdxHandle, 0, 0, mBarsToCopy, m_AdxBuffer);
   int oscCopied = CopyBuffer(m_AdxHandle, 1, 0, mBarsToCopy, m_OscBuffer);
   CopyBuffer(m_AdxHandle, 2, 0, mBarsToCopy, m_DpBuffer);
   CopyBuffer(m_AdxHandle, 3, 0, mBarsToCopy, m_DnBuffer);

   return mBarsToCopy == adxCopied && adxCopied == oscCopied;
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void CADXOscillator::Release(void)
  {
   IndicatorRelease(m_AdxHandle);
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
double CADXOscillator::GetData(int bufferIndx=0, int shift=0)
  {
   if(shift >= mBarsToCopy || bufferIndx > 3)
      return EMPTY_VALUE;

   switch(bufferIndx)
     {
      case 0:
         return m_AdxBuffer[shift];
      case 1:
         return m_OscBuffer[shift];
      case 2:
         return m_DpBuffer[shift];
      case 3:
         return m_DnBuffer[shift];
      default:
         return EMPTY_VALUE;
     }
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void CADXOscillator::GetData(double &buffer[], int bufferIndx=0, int shift=0)
  {
   if(shift >= mBarsToCopy || bufferIndx > 3)
      return;

   ArraySetAsSeries(buffer, true);
   ArrayResize(buffer, mBarsToCopy - shift);

   switch(bufferIndx)
     {
      case 0:
         ArrayCopy(buffer, m_AdxBuffer, 0, shift);
         break;
      case 2:
         ArrayCopy(buffer, m_DpBuffer, 0, shift);
         break;
      case 3:
         ArrayCopy(buffer, m_DnBuffer, 0, shift);
         break;
      case 1:
      default:
         ArrayCopy(buffer, m_OscBuffer, 0, shift);
         break;
     }
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
ENUM_TRENDSTATE CADXOscillator::Trend()
  {
   if(m_AdxBuffer[m_ShiftToUse] >= mTrendIndx)
      return TS_TREND;

   return TS_FLAT;
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
bool CADXOscillator::IsTrending(void)
  {
   return Trend() == TS_TREND;
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
double CADXOscillator::OscSlope(int shift=1)
  {
   if(shift >= mBarsToCopy)
      return EMPTY_VALUE;

   return RegressionSlope(m_OscBuffer, mSlopePeriod, 1);
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
double CADXOscillator::ADXSlope(int shift = 1)
  {
   if(shift >= mBarsToCopy)
      return EMPTY_VALUE;

   return RegressionSlope(m_AdxBuffer, mSlopePeriod, 1);
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
ENUM_ENTRY_SIGNAL CADXOscillator::DmiCrossSignal(void)
  {
   return m_DpBuffer[m_ShiftToUse] > m_DnBuffer[m_ShiftToUse] ? ENTRY_SIGNAL_BUY :
          m_DpBuffer[m_ShiftToUse] < m_DnBuffer[m_ShiftToUse] > 0 ? ENTRY_SIGNAL_SELL : ENTRY_SIGNAL_NONE;
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
ENUM_ENTRY_SIGNAL CADXOscillator::OscillatorSlopeSignal(void)
  {
   double oscSlope = OscSlope(1);
   return oscSlope < 0 ? ENTRY_SIGNAL_SELL :
          oscSlope > 0 ? ENTRY_SIGNAL_BUY : ENTRY_SIGNAL_NONE;
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
ENUM_ENTRY_SIGNAL CADXOscillator::AboveBelowZeroLine(void)
  {
   return m_OscBuffer[m_ShiftToUse] < 0 ? ENTRY_SIGNAL_SELL :
          m_OscBuffer[m_ShiftToUse] > 0 ? ENTRY_SIGNAL_BUY : ENTRY_SIGNAL_NONE;
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
ENUM_ENTRY_SIGNAL CADXOscillator::TradeSignal(ENUM_ADXOSC_Strategies logicOption)
  {
   switch(logicOption)
     {
      case ADXOSC_AboveBelowZeroLine:
         return AboveBelowZeroLine();
      case ADXOSC_DMI:
         return DmiCrossSignal();
      case ADXOSC_OscillatorSlope:
         return OscillatorSlopeSignal();
      default:
         return ENTRY_SIGNAL_NONE;
     }
  }
//+------------------------------------------------------------------+
