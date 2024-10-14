//+------------------------------------------------------------------+
//|                                                    RSIofHull.mqh |
//|                                    Copyright 2021, Michael Enudi |
//|                                             okmich2002@yahoo.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2021, Michael Enudi"
#property link      "okmich2002@yahoo.com"

#include "BaseIndicator.mqh"

enum ENUM_RSIHULL_Strategies
  {
   RSIHULL_AboveBelowMidLevelFilter,
   RSIHULL_AboveBelowSignalLineFilter,
   RSIHULL_AboveBelowAltSignalLineFilter,
   RSIHULL_ContraInObOSZoneFilter,
   RSIHULL_DirectionalFilter,
   RSIHULL_InObOSZoneFilter
  };

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
class CDslRsiHull : public CBaseIndicator
  {
private :
   int                mBarsToCopy;
   //--- indicator paramter
   int                m_RsiPeriod, m_MaPeriod, m_DslSignalPeriod, m_ObLevel;
   ENUM_MA_METHOD     m_SmoothingMethod;
   bool               m_AnchorLevels;
   //--- indicator
   int                m_Handle;
   //--- indicator buffer
   double             m_Buffer[], m_UpLevelBuffer[], m_DownLevelBuffer[], m_SignalBuffer[];

   ENUM_ENTRY_SIGNAL  DirectionalSignal();
   ENUM_ENTRY_SIGNAL  CrossesSignalLinesSignal();
   ENUM_ENTRY_SIGNAL  CrossesAltSignalLinesSignal();
   ENUM_ENTRY_SIGNAL  Phase();
   ENUM_ENTRY_SIGNAL  AboveObOsZones();
   ENUM_ENTRY_SIGNAL  ContraAboveBelowZone();

public:
                     CDslRsiHull(string symbol, ENUM_TIMEFRAMES period, int InputRsiPeriod, int InputMaPeriod, int InptDslSignal,
               bool InputUseAnchorLevel, int InputObLevel, int historyBars=12): CBaseIndicator(symbol, period)
     {
      m_RsiPeriod = InputRsiPeriod;
      m_MaPeriod = InputMaPeriod;
      m_DslSignalPeriod = InptDslSignal;
      m_AnchorLevels = InputUseAnchorLevel;
      m_ObLevel = InputObLevel;

      mBarsToCopy= historyBars;
     }

   virtual bool       Init();
   virtual bool       Refresh(int ShiftToUse=1);
   virtual void       Release();

   double             GetData(int bufferIndx=0, int shift=0);
   void               GetData(double &buffer[], int bufferIndx=0, int shift=0);

   ENUM_ENTRY_SIGNAL  TradeSignal(ENUM_RSIHULL_Strategies entryStrategyOption);

   ENUM_TRENDSTATE    EvaluateStrengthState(double threshold);
  };

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
bool CDslRsiHull::Init(void)
  {
   ArraySetAsSeries(m_Buffer, true);
   ArraySetAsSeries(m_UpLevelBuffer, true);
   ArraySetAsSeries(m_DownLevelBuffer, true);
   ArraySetAsSeries(m_SignalBuffer, true);

   m_Handle = iCustom(m_Symbol, m_TF, "Articles\\DSL RSI of Hull", m_RsiPeriod, m_MaPeriod, m_DslSignalPeriod, PRICE_CLOSE, m_AnchorLevels);
   return m_Handle != INVALID_HANDLE;
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
bool CDslRsiHull::Refresh(int ShiftToUse=1)
  {
   m_ShiftToUse = ShiftToUse;
   int copied = CopyBuffer(m_Handle, 0, 0, mBarsToCopy, m_Buffer);
   int upLvlCopied = CopyBuffer(m_Handle, 2, 0, mBarsToCopy, m_UpLevelBuffer);
   int downLevelCopied = CopyBuffer(m_Handle, 3, 0, mBarsToCopy, m_DownLevelBuffer);
   CopyBuffer(m_Handle, 4, 0, mBarsToCopy, m_SignalBuffer);

   return mBarsToCopy == copied && copied == upLvlCopied && copied == downLevelCopied;
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void CDslRsiHull::Release(void)
  {
   IndicatorRelease(m_Handle);
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
double CDslRsiHull::GetData(int bufferIndx=0, int shift=0)
  {
   if(shift >= mBarsToCopy || bufferIndx > 2)
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
         return m_Buffer[shift];
     }
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void CDslRsiHull::GetData(double &buffer[], int bufferIndx=0, int shift=0)
  {
   if(shift >= mBarsToCopy || bufferIndx > 3)
      return;

   ArraySetAsSeries(buffer, true);
   ArrayResize(buffer, mBarsToCopy - shift);

   switch(bufferIndx)
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
         ArrayCopy(buffer, m_Buffer, 0, shift);
     }
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
ENUM_ENTRY_SIGNAL CDslRsiHull::DirectionalSignal(void)
  {
   return CBaseIndicator::_DirectionalFilter(m_Buffer);
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
ENUM_ENTRY_SIGNAL CDslRsiHull::Phase()
  {
   return CBaseIndicator::_Phase(m_Buffer, 50.0);
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
ENUM_ENTRY_SIGNAL CDslRsiHull::CrossesAltSignalLinesSignal(void)
  {
   return m_SignalBuffer[m_ShiftToUse] > m_Buffer[m_ShiftToUse] ? ENTRY_SIGNAL_SELL :
          m_SignalBuffer[m_ShiftToUse] < m_Buffer[m_ShiftToUse] ? ENTRY_SIGNAL_BUY : ENTRY_SIGNAL_NONE;
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
ENUM_ENTRY_SIGNAL CDslRsiHull::CrossesSignalLinesSignal(void)
  {
   return CBaseIndicator::_AboveBelowSignalLinesFilter(m_Buffer, m_UpLevelBuffer, m_DownLevelBuffer);
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
ENUM_ENTRY_SIGNAL CDslRsiHull::AboveObOsZones(void)
  {
   return CBaseIndicator::_AboveBelowObOsLinesFilter(m_Buffer, m_ObLevel);
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
ENUM_ENTRY_SIGNAL CDslRsiHull::ContraAboveBelowZone(void)
  {
   return CBaseIndicator::_ContraAboveBelowObOsLinesFilter(m_Buffer, m_ObLevel);
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
ENUM_TRENDSTATE CDslRsiHull::EvaluateStrengthState(double threshold)
  {
   double levelDiff = m_UpLevelBuffer[1] - m_DownLevelBuffer[1];
   return (levelDiff > threshold)? TS_TREND : TS_FLAT;
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
ENUM_ENTRY_SIGNAL CDslRsiHull::TradeSignal(ENUM_RSIHULL_Strategies entryStrategyOption)
  {
   switch(entryStrategyOption)
     {
      case RSIHULL_AboveBelowMidLevelFilter:
         return Phase();
      case RSIHULL_AboveBelowAltSignalLineFilter :
         return CrossesAltSignalLinesSignal();
      case RSIHULL_AboveBelowSignalLineFilter :
         return CrossesSignalLinesSignal();
      case RSIHULL_ContraInObOSZoneFilter:
         return ContraAboveBelowZone();
      case RSIHULL_DirectionalFilter:
         return DirectionalSignal();
      case RSIHULL_InObOSZoneFilter:
         return AboveObOsZones();
      default:
         return ENTRY_SIGNAL_NONE;
     }
  }
//+------------------------------------------------------------------+
