//+------------------------------------------------------------------+
//|                                                     RSIofCCI.mqh |
//|                                    Copyright 2021, Michael Enudi |
//|                                             okmich2002@yahoo.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2021, Michael Enudi"
#property link      "okmich2002@yahoo.com"

#include "BaseIndicator.mqh"

enum ENUM_CCIMA_Strategies
  {
   CCIMA_AboveBelowMidLevelFilter,      //Above or Below Center Line
   CCIMA_AboveBelowDslSignalLineFilter, //Above or Below Signal Line In Phase
   CCIMA_ContraInObOSZoneFilter,        //Contra Overbought/Oversold area
   CCIMA_CrossSignalLine,               //Above or Below Signal Line
   CCIMA_DirectionalFilter,             //Direction
   CCIMA_InObOSZoneFilter               //Overbought/Oversold area
  };

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
class CDslCCIofAverage : public CBaseIndicator
  {
private :
   int                mBarsToCopy;
   //--- indicator paramter
   int                m_MaPeriod, m_CciPeriod, m_SignalPeriod, m_ObLevel;
   ENUM_MA_METHOD     m_SmoothingMethod;
   bool               m_AnchorLevels;
   //--- indicator
   int                m_Handle;
   //--- indicator buffer
   double             m_Buffer[], m_UpLevelBuffer[], m_DownLevelBuffer[], m_SignalBuffer[];

   ENUM_ENTRY_SIGNAL  DirectionalSignal();
   ENUM_ENTRY_SIGNAL  AboveBelowDslSignalLine();
   ENUM_ENTRY_SIGNAL  CrossSignalLinesSignal();
   ENUM_ENTRY_SIGNAL  Phase();
   ENUM_ENTRY_SIGNAL  AboveObOsZones();
   ENUM_ENTRY_SIGNAL  ContraAboveBelowZone();
public:
                     CDslCCIofAverage(string symbol, ENUM_TIMEFRAMES period,
                    int InputCciPeriod, int InputMaPeriod, ENUM_MA_METHOD InputAveragingMethod,
                    int InputDslSignalPeriod, bool InputUseAnchorLevel, int InputOverboughtLevel, int historyBars=12): CBaseIndicator(symbol, period)
     {
      m_CciPeriod = InputCciPeriod;
      m_MaPeriod = InputMaPeriod;
      m_SmoothingMethod = InputAveragingMethod;
      m_SignalPeriod = InputDslSignalPeriod;
      m_AnchorLevels = InputUseAnchorLevel;
      m_ObLevel = InputOverboughtLevel;
      mBarsToCopy = historyBars;
     }

   virtual bool       Init();
   virtual bool       Refresh(int ShiftToUse=1);
   virtual void       Release();

   double             GetData(int bufferIndx=0, int shift=0);
   void               GetData(double &buffer[], int bufferIndx=0, int shift=0);

   ENUM_ENTRY_SIGNAL  TradeSignal(ENUM_CCIMA_Strategies entryStrategyOption);

   ENUM_TRENDSTATE    EvaluateStrengthState(double threshold);
  };

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
bool CDslCCIofAverage::Init(void)
  {
   ArraySetAsSeries(m_Buffer, true);
   ArraySetAsSeries(m_UpLevelBuffer, true);
   ArraySetAsSeries(m_DownLevelBuffer, true);
   ArraySetAsSeries(m_SignalBuffer, true);

   m_Handle = iCustom(m_Symbol, m_TF, "Articles\\DSL CCI of Average",
                      m_CciPeriod, m_MaPeriod, m_SmoothingMethod, PRICE_CLOSE,
                      m_SignalPeriod, m_AnchorLevels);
   return m_Handle != INVALID_HANDLE;
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
bool CDslCCIofAverage::Refresh(int ShiftToUse=1)
  {
   m_ShiftToUse = ShiftToUse;
   int copied = CopyBuffer(m_Handle, 0, 0, mBarsToCopy, m_Buffer);
   int upLvlCopied = CopyBuffer(m_Handle, 2, 0, mBarsToCopy, m_UpLevelBuffer);
   int downLevelCopied = CopyBuffer(m_Handle, 3, 0, mBarsToCopy, m_DownLevelBuffer);
   int signalCopied = CopyBuffer(m_Handle, 4, 0, mBarsToCopy, m_SignalBuffer);

   return mBarsToCopy == copied && copied == upLvlCopied && copied == downLevelCopied;
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void CDslCCIofAverage::Release(void)
  {
   IndicatorRelease(m_Handle);
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
double CDslCCIofAverage::GetData(int bufferIndx=0, int shift=0)
  {
   if(shift >= mBarsToCopy || bufferIndx > 3)
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
void CDslCCIofAverage::GetData(double &buffer[], int bufferIndx=0, int shift=0)
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
ENUM_ENTRY_SIGNAL CDslCCIofAverage::DirectionalSignal(void)
  {
   return CBaseIndicator::_DirectionalFilter(m_Buffer);
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
ENUM_ENTRY_SIGNAL CDslCCIofAverage::Phase()
  {
   return CBaseIndicator::_Phase(m_Buffer, 50.0);
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
ENUM_ENTRY_SIGNAL CDslCCIofAverage::AboveBelowDslSignalLine(void)
  {
   return CBaseIndicator::_AboveBelowSignalLinesFilter(m_Buffer, m_UpLevelBuffer, m_DownLevelBuffer);
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
ENUM_ENTRY_SIGNAL CDslCCIofAverage::CrossSignalLinesSignal(void)
  {
   return m_SignalBuffer[m_ShiftToUse] > m_Buffer[m_ShiftToUse] ? ENTRY_SIGNAL_SELL :
          m_SignalBuffer[m_ShiftToUse] < m_Buffer[m_ShiftToUse] ? ENTRY_SIGNAL_BUY : ENTRY_SIGNAL_NONE;
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
ENUM_ENTRY_SIGNAL CDslCCIofAverage::AboveObOsZones(void)
  {
   return CBaseIndicator::_AboveBelowObOsLinesFilter(m_Buffer, m_ObLevel);
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
ENUM_ENTRY_SIGNAL CDslCCIofAverage::ContraAboveBelowZone(void)
  {
   return CBaseIndicator::_ContraAboveBelowObOsLinesFilter(m_Buffer, m_ObLevel);
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
ENUM_TRENDSTATE CDslCCIofAverage::EvaluateStrengthState(double threshold)
  {
   double levelDiff = m_UpLevelBuffer[1] - m_DownLevelBuffer[1];
   return (levelDiff > threshold)? TS_TREND : TS_FLAT;
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
ENUM_ENTRY_SIGNAL CDslCCIofAverage::TradeSignal(ENUM_CCIMA_Strategies entryStrategyOption)
  {
   switch(entryStrategyOption)
     {
      case CCIMA_AboveBelowMidLevelFilter:
         return Phase();
      case CCIMA_AboveBelowDslSignalLineFilter:
         return AboveBelowDslSignalLine();
      case CCIMA_ContraInObOSZoneFilter:
         return ContraAboveBelowZone();
      case CCIMA_CrossSignalLine:
         return CrossSignalLinesSignal();
      case CCIMA_DirectionalFilter:
         return DirectionalSignal();
      case CCIMA_InObOSZoneFilter:
         return AboveObOsZones();
      default:
         return ENTRY_SIGNAL_NONE;
     }
  }
//+------------------------------------------------------------------+
