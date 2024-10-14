//+------------------------------------------------------------------+
//|                                         StochasticOscillator.mqh |
//|                                    Copyright 2021, Michael Enudi |
//|                                             okmich2002@yahoo.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2021, Michael Enudi"
#property link      "okmich2002@yahoo.com"
#property version   "1.00"

#include "BaseIndicator.mqh"

enum ENUM_STOCHCG_Strategies
  {
   STOCHCG_EnterOsOBLevels,
   STOCHCG_ContraEnterOsOBLevels,
   STOCHCG_ExitOsOBLevels,
   STOCHCG_ContraExitOsOBLevels,
   STOCHCG_CrossMidLevel,
   STOCHCG_Directional,
   STOCHCG_SignalCrossover,
   STOCHCG_ObOsSignalCrossover
  };

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
class CStochCGOscillator : public CBaseIndicator
  {
private :
   //--- indicator paramter
   int                m_Period;
   double             m_OverBoughtLevel, m_OverSoldLevel;
   //--- indicator handle
   int                mHandle;
   //--- indicator buffer
   double             m_CgBuffer[], m_SignalBuffer[];
   
   ENUM_ENTRY_SIGNAL  EnterOsOBSignal();
   ENUM_ENTRY_SIGNAL  ContraEnterOsOBSignal();
   ENUM_ENTRY_SIGNAL  ExitOsOBSignal();
   ENUM_ENTRY_SIGNAL  ContraExitOsOBSignal();
   ENUM_ENTRY_SIGNAL  CrossMidSignal();
   ENUM_ENTRY_SIGNAL  DirectionalSignal();
   ENUM_ENTRY_SIGNAL  CrossoverSignal();
   ENUM_ENTRY_SIGNAL  ObOsCrossoverSignal();

public:
                     CStochCGOscillator(string symbol, ENUM_TIMEFRAMES period, int InputPeriod,
                      double InptOBLevel, double InptOSLevel): CBaseIndicator(symbol, period)
     {
      m_Period = InputPeriod;
      m_OverBoughtLevel = InptOBLevel;
      m_OverSoldLevel = InptOSLevel;
     }

   virtual bool       Init();
   virtual bool       Refresh(int ShiftToUse=1);
   virtual void       Release();

   double             GetData(int bufferIndx=0, int shift=0);
   void               GetData(double &buffer[], int bufferIndx=0, int shift=0);
   
   ENUM_ENTRY_SIGNAL  TradeSignal(ENUM_STOCHCG_Strategies signalOption);
  };

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
bool CStochCGOscillator::Init(void)
  {
   ArraySetAsSeries(m_CgBuffer, true);
   ArraySetAsSeries(m_SignalBuffer, true);
   mHandle = iCustom(m_Symbol, m_TF, "Okmich\\Stochastic Center of Gravity", m_Period);

   return mHandle != INVALID_HANDLE;
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
bool CStochCGOscillator::Refresh(int ShiftToUse=1)
  {
   m_ShiftToUse = ShiftToUse;
   int stochCopied = CopyBuffer(mHandle, 0, 0, m_Period, m_CgBuffer);
   int signalCopied = CopyBuffer(mHandle, 1, 0, m_Period, m_SignalBuffer);

   return stochCopied == signalCopied && signalCopied == m_Period;
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void CStochCGOscillator::Release(void)
  {
   IndicatorRelease(mHandle);
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
double CStochCGOscillator::GetData(int bufferIndx=0, int shift=0)
  {
   if(shift >= m_Period || bufferIndx > 1)
      return EMPTY_VALUE;

   return bufferIndx == 0 ? m_CgBuffer[shift] : m_SignalBuffer[shift];
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void CStochCGOscillator::GetData(double &buffer[], int bufferIndx=0, int shift=0)
  {
   if(shift >= m_Period || bufferIndx > 1)
      return;

   ArraySetAsSeries(buffer, true);
   ArrayResize(buffer, ArraySize(m_CgBuffer) - shift);

   if(bufferIndx ==0)
      ArrayCopy(buffer, m_CgBuffer, 0, shift);
   else
      ArrayCopy(buffer, m_SignalBuffer, 0, shift);
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
ENUM_ENTRY_SIGNAL CStochCGOscillator::EnterOsOBSignal(void)
  {
   return CBaseIndicator::_EnterOsOBSignal(m_CgBuffer, m_OverBoughtLevel, m_OverSoldLevel);
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
ENUM_ENTRY_SIGNAL CStochCGOscillator::ContraEnterOsOBSignal(void)
  {
   ENUM_ENTRY_SIGNAL signal = EnterOsOBSignal();
   return signal == ENTRY_SIGNAL_BUY ? ENTRY_SIGNAL_SELL :
          (signal == ENTRY_SIGNAL_SELL) ? ENTRY_SIGNAL_BUY : ENTRY_SIGNAL_NONE;
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
ENUM_ENTRY_SIGNAL CStochCGOscillator::ExitOsOBSignal(void)
  {
   return CBaseIndicator::_ExitOsOBSignal(m_CgBuffer, m_OverBoughtLevel, m_OverSoldLevel);
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
ENUM_ENTRY_SIGNAL CStochCGOscillator::ContraExitOsOBSignal(void)
  {
   ENUM_ENTRY_SIGNAL signal = ExitOsOBSignal();
   return signal == ENTRY_SIGNAL_BUY ? ENTRY_SIGNAL_SELL :
          (signal == ENTRY_SIGNAL_SELL) ? ENTRY_SIGNAL_BUY : ENTRY_SIGNAL_NONE;
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
ENUM_ENTRY_SIGNAL CStochCGOscillator::CrossMidSignal(void)
  {
   return CBaseIndicator::_CrossMidSignal(m_CgBuffer, (m_OverBoughtLevel + m_OverSoldLevel)/2);
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
ENUM_ENTRY_SIGNAL CStochCGOscillator::DirectionalSignal(void)
  {
   return CBaseIndicator::_DirectionalSignal(m_CgBuffer);
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
ENUM_ENTRY_SIGNAL CStochCGOscillator::CrossoverSignal(void)
  {
   if(m_CgBuffer[2] > m_SignalBuffer[2] && m_CgBuffer[1] < m_SignalBuffer[1])
      return ENTRY_SIGNAL_SELL;
   else
      if(m_CgBuffer[2] < m_SignalBuffer[2] && m_CgBuffer[1] > m_SignalBuffer[1])
         return ENTRY_SIGNAL_BUY;

   return ENTRY_SIGNAL_NONE;
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
ENUM_ENTRY_SIGNAL CStochCGOscillator::ObOsCrossoverSignal(void)
  {
//at least shift2 of STOCH must have been overbought
   if(m_CgBuffer[2] > m_OverBoughtLevel)
     {
      if(m_CgBuffer[2] > m_SignalBuffer[2] && m_CgBuffer[1] < m_SignalBuffer[1])
         return ENTRY_SIGNAL_SELL;
      else
         return ENTRY_SIGNAL_NONE;
     }
//at least shift2 of STOCH must have been oversold
   if(m_CgBuffer[2] < m_OverSoldLevel)
     {
      if(m_CgBuffer[2] < m_SignalBuffer[2] && m_CgBuffer[1] > m_SignalBuffer[1])
         return ENTRY_SIGNAL_BUY;
      else
         return ENTRY_SIGNAL_NONE;
     }

   return ENTRY_SIGNAL_NONE;
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
ENUM_ENTRY_SIGNAL CStochCGOscillator::TradeSignal(ENUM_STOCHCG_Strategies signalOption)
  {
   switch(signalOption)
     {
      case STOCHCG_ContraEnterOsOBLevels:
         return ContraEnterOsOBSignal();
      case STOCHCG_ContraExitOsOBLevels:
         return ContraExitOsOBSignal();
      case STOCHCG_CrossMidLevel:
         return CrossMidSignal();
      case STOCHCG_Directional:
         return DirectionalSignal();
      case STOCHCG_EnterOsOBLevels:
         return EnterOsOBSignal();
      case STOCHCG_ExitOsOBLevels:
         return ExitOsOBSignal();
      case STOCHCG_ObOsSignalCrossover :
         return ObOsCrossoverSignal();
      case STOCHCG_SignalCrossover :
         return CrossoverSignal();
      default:
         return ENTRY_SIGNAL_NONE;
     }
  }
//+------------------------------------------------------------------+
