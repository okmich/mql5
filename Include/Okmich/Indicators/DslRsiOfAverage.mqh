//+------------------------------------------------------------------+
//|                                              DslRsiOfAverage.mqh |
//|                                    Copyright 2021, Michael Enudi |
//|                                             okmich2002@yahoo.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2021, Michael Enudi"
#property link      "okmich2002@yahoo.com"

#include "BaseIndicator.mqh"

enum ENUM_RSIMA_Strategies
  {
   RSIMA_AboveBelowMidLevelFilter,
   RSIMA_AboveBelowSignalLineFilter,
   RSIMA_AboveBelowAltSignalLineFilter,
   RSIMA_ContraInObOSZoneFilter,
   RSIMA_InObOSZoneFilter,
   RSIMA_DirectionalFilter
  };

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
class CDslRsiOfAverage : public CBaseIndicator
  {
private :
   int                mBarsToCopy;
   //--- indicator paramter
   int                m_RsiPeriod, m_MaPeriod, m_DslSignalPeriod;
   double             m_ObLevel, m_OsLevel;
   ENUM_MA_METHOD     m_SmoothingMethod;
   ENUM_APPLIED_PRICE m_AppliedPrice;
   bool               m_IsAnchored;
   //--- indicator
   int                m_Handle;
   //--- indicator buffer
   double             m_RsiBuffer[], m_UpLevelBuffer[], m_DownLevelBuffer[];
   double             m_SignalBuffer[];

   ENUM_ENTRY_SIGNAL  DirectionalSignal();
   ENUM_ENTRY_SIGNAL  CrossesSignalLinesSignal();
   ENUM_ENTRY_SIGNAL  CrossesAltSignalLinesSignal();
   ENUM_ENTRY_SIGNAL  Phase();
   ENUM_ENTRY_SIGNAL  AboveObOsZones();
   ENUM_ENTRY_SIGNAL  ContraAboveBelowZone();

public:
                     CDslRsiOfAverage(string symbol, ENUM_TIMEFRAMES period, int InputRsiPeriod,
                    int InputMaPeriod, ENUM_MA_METHOD InputSmoothMethod,
                    ENUM_APPLIED_PRICE InputAppPrice, int InputDslSignalPeriod,
                    bool InputUseAnchoredLevel=false, 
                    double InputOverBoughtLevel=80, double InputOverSoldLevel=20, int historyBars=12): CBaseIndicator(symbol, period)
     {
      m_RsiPeriod = InputRsiPeriod;
      m_MaPeriod = InputMaPeriod;
      m_SmoothingMethod = InputSmoothMethod;
      m_AppliedPrice = InputAppPrice;
      m_DslSignalPeriod = InputDslSignalPeriod;
      m_IsAnchored = InputUseAnchoredLevel;
      
      m_ObLevel = InputOverBoughtLevel;
      m_OsLevel = InputOverSoldLevel;

      mBarsToCopy = historyBars;
     }

   virtual bool       Init();
   virtual bool       Refresh(int ShiftToUse=1);
   virtual void       Release();

   double             GetData(int bufferIndx=0, int shift=0);
   void               GetData(double &buffer[], int bufferIndx=4, int shift=0);

   ENUM_ENTRY_SIGNAL  TradeSignal(ENUM_RSIMA_Strategies entryStrategyOption);

   ENUM_TRENDSTATE    EvaluateStrengthState(double threshold);
  };

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
bool CDslRsiOfAverage::Init(void)
  {
   ArraySetAsSeries(m_RsiBuffer, true);
   ArraySetAsSeries(m_DownLevelBuffer, true);
   ArraySetAsSeries(m_UpLevelBuffer, true);
   ArraySetAsSeries(m_SignalBuffer, true);
//---
   m_Handle = iCustom(m_Symbol, m_TF, "Articles\\DSL RSI of Average", m_RsiPeriod, m_MaPeriod, m_SmoothingMethod,
                      m_AppliedPrice, m_DslSignalPeriod, m_IsAnchored);

   return m_Handle != INVALID_HANDLE;
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
bool CDslRsiOfAverage::Refresh(int ShiftToUse=1)
  {
   m_ShiftToUse = ShiftToUse;
   int upLvlCopied = CopyBuffer(m_Handle, 0, 0, mBarsToCopy, m_UpLevelBuffer);
   int downLevelCopied = CopyBuffer(m_Handle, 1, 0, mBarsToCopy, m_DownLevelBuffer);
   int maRsiCopied = CopyBuffer(m_Handle, 2, 0, mBarsToCopy, m_RsiBuffer);
   int signalCopied = CopyBuffer(m_Handle, 4, 0, mBarsToCopy, m_SignalBuffer);

   return mBarsToCopy == upLvlCopied && upLvlCopied == downLevelCopied && downLevelCopied == maRsiCopied &&
          maRsiCopied == signalCopied;
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void CDslRsiOfAverage::Release(void)
  {
   IndicatorRelease(m_Handle);
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
double CDslRsiOfAverage::GetData(int bufferIndx=0, int shift=0)
  {
   if(shift >= mBarsToCopy || bufferIndx > 1)
      return EMPTY_VALUE;

   switch(bufferIndx)
     {
      case 1:
         return m_UpLevelBuffer[shift];
      case 2:
         return m_DownLevelBuffer[shift];
      case 3:
         return m_SignalBuffer[shift];
      case 0:
      default:
         return m_RsiBuffer[shift];
     }
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void CDslRsiOfAverage::GetData(double &buffer[], int bufferIdx=4, int shift=0)
  {
   if(shift >= mBarsToCopy || bufferIdx > 3)
      return;

   ArraySetAsSeries(buffer, true);
   ArrayResize(buffer, mBarsToCopy - shift);

   switch(bufferIdx)
     {
      case 1:
         ArrayCopy(buffer, m_UpLevelBuffer, 0, shift);
         break;
      case 2:
         ArrayCopy(buffer, m_DownLevelBuffer, 0, shift);
         break;
      case 3:
         ArrayCopy(buffer, m_SignalBuffer, 0, shift);
         break;
      case 0:
      default:
         ArrayCopy(buffer, m_RsiBuffer, 0, shift);
     }
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
ENUM_ENTRY_SIGNAL CDslRsiOfAverage::DirectionalSignal(void)
  {
   return CBaseIndicator::_DirectionalFilter(m_RsiBuffer);
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
ENUM_ENTRY_SIGNAL CDslRsiOfAverage::Phase()
  {
   return CBaseIndicator::_Phase(m_RsiBuffer, 50.0);
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
ENUM_ENTRY_SIGNAL CDslRsiOfAverage::CrossesSignalLinesSignal(void)
  {
   return CBaseIndicator::_AboveBelowSignalLinesFilter(m_RsiBuffer, m_UpLevelBuffer, m_DownLevelBuffer);
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
ENUM_ENTRY_SIGNAL CDslRsiOfAverage::CrossesAltSignalLinesSignal(void)
  {
   return m_SignalBuffer[m_ShiftToUse] > m_RsiBuffer[m_ShiftToUse] ? ENTRY_SIGNAL_SELL :
          m_SignalBuffer[m_ShiftToUse] < m_RsiBuffer[m_ShiftToUse] ? ENTRY_SIGNAL_BUY : ENTRY_SIGNAL_NONE;
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
ENUM_ENTRY_SIGNAL CDslRsiOfAverage::AboveObOsZones(void)
  {
   return CBaseIndicator::_AboveBelowObOsLinesFilter(m_RsiBuffer, m_ObLevel, m_OsLevel);
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
ENUM_ENTRY_SIGNAL CDslRsiOfAverage::ContraAboveBelowZone(void)
  {
   return CBaseIndicator::_ContraAboveBelowObOsLinesFilter(m_RsiBuffer, m_ObLevel, m_OsLevel);
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
ENUM_TRENDSTATE CDslRsiOfAverage::EvaluateStrengthState(double threshold)
  {
   double levelDiff = m_UpLevelBuffer[1] - m_DownLevelBuffer[1];
   return (levelDiff > threshold)? TS_TREND : TS_FLAT;
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
ENUM_ENTRY_SIGNAL CDslRsiOfAverage::TradeSignal(ENUM_RSIMA_Strategies entryStrategyOption)
  {
   switch(entryStrategyOption)
     {
      case RSIMA_AboveBelowMidLevelFilter:
         return Phase();
      case RSIMA_AboveBelowSignalLineFilter :
         return CrossesSignalLinesSignal();
      case RSIMA_AboveBelowAltSignalLineFilter:
         return CrossesAltSignalLinesSignal();
      case RSIMA_ContraInObOSZoneFilter:
         return ContraAboveBelowZone();
      case RSIMA_DirectionalFilter:
         return DirectionalSignal();
      case RSIMA_InObOSZoneFilter:
         return AboveObOsZones();
      default:
         return ENTRY_SIGNAL_NONE;
     }
  }
//+------------------------------------------------------------------+
