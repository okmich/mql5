//+------------------------------------------------------------------+
//|                                          TrendIntensityIndex.mqh |
//|                                    Copyright 2021, Michael Enudi |
//|                                             okmich2002@yahoo.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2021, Michael Enudi"
#property link      "okmich2002@yahoo.com"
#property version   "1.00"

#include "BaseIndicator.mqh"

enum ENUM_CTTI_Stategies
  {
   TTI_Stategies_EnterObOsLevels,
   TTI_Stategies_ContraEnterObOsLevels,
   TTI_Stategies_ExitObOsLevels,
   TTI_Stategies_Crossover,
   TTI_Stategies_ObOsCrossover
  };

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
class CTrendIntensityIndex : public CBaseIndicator
  {
private :
   //--- indicator paramter
   int                m_TtiPeriod, m_SignalPeriod;
   double             m_OverBoughtLevel, m_OverSoldLevel;
   //--- indicator handle
   int                m_Handle;
   //--- indicator buffer
   double             m_TtiBuffer[],  m_SignalBuffer[];

public:
                     CTrendIntensityIndex(string symbol, ENUM_TIMEFRAMES period,
                        int InputPeriod=20, int InputSignal = 5,
                        double InptOBLevel=0.85, double InptOSLevel=0.15): CBaseIndicator(symbol, period)
     {
      m_TtiPeriod = InputPeriod;
      m_SignalPeriod = InputSignal;
      m_OverBoughtLevel = InptOBLevel;
      m_OverSoldLevel = InptOSLevel;
     }

   virtual bool                   Init();
   virtual bool                   Refresh(int ShiftToUse=1);
   virtual void                   Release();

   double                         GetData(int bufferIdx=0, int shift=1);
   void                           GetData(double &buffer[], int bufferIdx=0, int shift=0);

   ENUM_ENTRY_SIGNAL              TradeSignal(ENUM_CTTI_Stategies logicOption);
   ENUM_ENTRY_SIGNAL              EnterObOsLevelsSignal();
   ENUM_ENTRY_SIGNAL              ContraEnterObOsLevelsSignal();
   ENUM_ENTRY_SIGNAL              ExitObOsLevelsSignal();
   ENUM_ENTRY_SIGNAL              CrossoverSignal();
   ENUM_ENTRY_SIGNAL              ObOsCrossoverSignal();
  };

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
bool CTrendIntensityIndex::Init(void)
  {
   ArraySetAsSeries(m_TtiBuffer, true);
   ArraySetAsSeries(m_SignalBuffer, true);
   m_Handle = iCustom(m_Symbol, m_TF, "Okmich\\Trend Intensity Index",
                      m_TtiPeriod, m_SignalPeriod);

   return m_Handle != INVALID_HANDLE;
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
ENUM_ENTRY_SIGNAL CTrendIntensityIndex::EnterObOsLevelsSignal(void)
  {
   if(m_TtiBuffer[2] < m_OverBoughtLevel && m_TtiBuffer[1] >= m_OverBoughtLevel)
      return ENTRY_SIGNAL_SELL;
   else
      if(m_TtiBuffer[2] > m_OverSoldLevel && m_TtiBuffer[1] <= m_OverSoldLevel)
         return ENTRY_SIGNAL_BUY;
      else
         return ENTRY_SIGNAL_NONE;
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
ENUM_ENTRY_SIGNAL CTrendIntensityIndex::ContraEnterObOsLevelsSignal(void)
  {
   if(m_TtiBuffer[2] < m_OverBoughtLevel && m_TtiBuffer[1] >= m_OverBoughtLevel)
      return ENTRY_SIGNAL_BUY;
   else
      if(m_TtiBuffer[2] > m_OverSoldLevel && m_TtiBuffer[1] <= m_OverSoldLevel)
         return ENTRY_SIGNAL_SELL;
      else
         return ENTRY_SIGNAL_NONE;
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
ENUM_ENTRY_SIGNAL CTrendIntensityIndex::ExitObOsLevelsSignal(void)
  {
   if(m_TtiBuffer[2] > m_OverBoughtLevel && m_TtiBuffer[1] <= m_OverBoughtLevel)
      return ENTRY_SIGNAL_SELL;
   else
      if(m_TtiBuffer[2] < m_OverSoldLevel && m_TtiBuffer[1] >= m_OverSoldLevel)
         return ENTRY_SIGNAL_BUY;
      else
         return ENTRY_SIGNAL_NONE;
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
ENUM_ENTRY_SIGNAL CTrendIntensityIndex::CrossoverSignal(void)
  {
   if(m_SignalBuffer[2] <= m_TtiBuffer[2] && m_SignalBuffer[1] > m_TtiBuffer[1])
      return ENTRY_SIGNAL_SELL;
   else
      if(m_SignalBuffer[2] >= m_TtiBuffer[2] && m_SignalBuffer[1] < m_TtiBuffer[1])
         return ENTRY_SIGNAL_BUY;
      else
         return ENTRY_SIGNAL_NONE;
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
ENUM_ENTRY_SIGNAL CTrendIntensityIndex::ObOsCrossoverSignal(void)
  {
   ENUM_ENTRY_SIGNAL signal;
   if(m_TtiBuffer[2] >= m_OverBoughtLevel && m_SignalBuffer[2] >= m_OverBoughtLevel)
     {
      signal = CrossoverSignal();
      return signal == ENTRY_SIGNAL_SELL ? signal : ENTRY_SIGNAL_NONE;
     }
   else
      if(m_TtiBuffer[2] <= m_OverSoldLevel && m_SignalBuffer[2] <= m_OverSoldLevel)
        {
         signal = CrossoverSignal();
         return signal == ENTRY_SIGNAL_BUY ? signal : ENTRY_SIGNAL_NONE;
        }
   return ENTRY_SIGNAL_NONE;
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
ENUM_ENTRY_SIGNAL CTrendIntensityIndex::TradeSignal(ENUM_CTTI_Stategies logicOption)
  {
   switch(logicOption)
     {
      case TTI_Stategies_ContraEnterObOsLevels:
         return ContraEnterObOsLevelsSignal();
      case TTI_Stategies_EnterObOsLevels:
         return EnterObOsLevelsSignal();
      case TTI_Stategies_ExitObOsLevels:
         return ExitObOsLevelsSignal();
      case TTI_Stategies_Crossover:
         return CrossoverSignal();
      case TTI_Stategies_ObOsCrossover:
         return ObOsCrossoverSignal();
      default:
         return ENTRY_SIGNAL_NONE;
     }
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
bool CTrendIntensityIndex::Refresh(int ShiftToUse=1)
  {
   m_ShiftToUse = ShiftToUse;
   int mainCopied = CopyBuffer(m_Handle, 0, 0, 4, m_TtiBuffer);
   int signalCopied = CopyBuffer(m_Handle, 0, 0, 4, m_SignalBuffer);
   return mainCopied == signalCopied && mainCopied == 4;
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void CTrendIntensityIndex::Release(void)
  {
   IndicatorRelease(m_Handle);
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
double CTrendIntensityIndex::GetData(int bufferIdx=0, int shift=1)
  {
   if(shift >= 4 || bufferIdx > 1)
      return EMPTY_VALUE;

   return bufferIdx == 1 ? m_SignalBuffer[shift] : m_TtiBuffer[shift];
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void CTrendIntensityIndex::GetData(double &buffer[], int bufferIdx=0, int shift=0)
  {
   if(shift >= 4|| bufferIdx > 1)
      return;

   ArraySetAsSeries(buffer, true);
   ArrayResize(buffer, ArraySize(m_TtiBuffer) - shift);

   if(bufferIdx == 1)
      ArrayCopy(buffer, m_SignalBuffer, 0, shift);
   else
      ArrayCopy(buffer, m_TtiBuffer, 0, shift);
  }
//+------------------------------------------------------------------+
