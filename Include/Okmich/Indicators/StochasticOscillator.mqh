//+------------------------------------------------------------------+
//|                                         StochasticOscillator.mqh |
//|                                    Copyright 2021, Michael Enudi |
//|                                             okmich2002@yahoo.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2021, Michael Enudi"
#property link      "okmich2002@yahoo.com"
#property version   "1.00"

#include "BaseIndicator.mqh"

enum ENUM_STOCH_Strategies
  {
   STOCH_EnterOsOBLevels,
   STOCH_ContraEnterOsOBLevels,
   STOCH_ExitOsOBLevels,
   STOCH_ContraExitOsOBLevels,
   STOCH_CrossMidLevel,
   STOCH_Directional,
   STOCH_SignalCrossover,
   STOCH_ObOsSignalCrossover
  };

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
class CStochastic : public CBaseIndicator
  {
private :
   //--- indicator paramter
   int                m_KPeriod, m_DPeriod, m_Slowing;
   double             m_OverBoughtLevel;
   double             m_OverSoldLevel;
   ENUM_STO_PRICE     m_PriceFieldType;
   ENUM_MA_METHOD     m_SmoothingMethod;
   //--- indicator handle
   int                mHandle;
   //--- indicator buffer
   double             m_StochBuffer[], m_StochSignalBuffer[];
   
   ENUM_ENTRY_SIGNAL  EnterOsOBSignal();
   ENUM_ENTRY_SIGNAL  ContraEnterOsOBSignal();
   ENUM_ENTRY_SIGNAL  ExitOsOBSignal();
   ENUM_ENTRY_SIGNAL  ContraExitOsOBSignal();
   ENUM_ENTRY_SIGNAL  CrossMidSignal();
   ENUM_ENTRY_SIGNAL  DirectionalSignal();
   ENUM_ENTRY_SIGNAL  CrossoverSignal();
   ENUM_ENTRY_SIGNAL  ObOsCrossoverSignal();

public:
                     CStochastic(string symbol, ENUM_TIMEFRAMES period,
               int InputKPeriod=5,
               int InputDPeriod=3,
               int InputSlowing=3,
               ENUM_STO_PRICE InptFieldType = STO_LOWHIGH,
               ENUM_MA_METHOD InptSmoothing = MODE_SMA,
               double InptOBLevel=80,
               double InptOSLevel=20): CBaseIndicator(symbol, period)
     {
      m_KPeriod = InputKPeriod;
      m_DPeriod = InputDPeriod;
      m_Slowing = InputSlowing;
      m_PriceFieldType = InptFieldType;
      m_SmoothingMethod = InptSmoothing;
      m_OverBoughtLevel = InptOBLevel;
      m_OverSoldLevel = InptOSLevel;
     }

   virtual bool       Init();
   virtual bool       Refresh(int ShiftToUse=1);
   virtual void       Release();
   
   double             GetData(int bufferIndx=0, int shift=0);
   void               GetData(double &buffer[], int bufferIndx=0, int shift=0);
   
   ENUM_ENTRY_SIGNAL  TradeSignal(ENUM_STOCH_Strategies signalOption);
  };

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
bool CStochastic::Init(void)
  {
   ArraySetAsSeries(m_StochBuffer, true);
   ArraySetAsSeries(m_StochSignalBuffer, true);
   mHandle = iStochastic(m_Symbol, m_TF,m_KPeriod,m_DPeriod,m_Slowing,m_SmoothingMethod,m_PriceFieldType);

   return mHandle != INVALID_HANDLE;
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
bool CStochastic::Refresh(int ShiftToUse=1)
  {
   m_ShiftToUse = ShiftToUse;
   int stochCopied = CopyBuffer(mHandle, 0, 0, m_KPeriod, m_StochBuffer);
   int signalCopied = CopyBuffer(mHandle, 1, 0, m_KPeriod, m_StochSignalBuffer);

   return stochCopied == signalCopied && signalCopied == m_KPeriod;
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void CStochastic::Release(void)
  {
   IndicatorRelease(mHandle);
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
double CStochastic::GetData(int bufferIndx=0, int shift=0)
  {
   if(shift >= m_KPeriod || bufferIndx > 1)
      return EMPTY_VALUE;

   return bufferIndx == 0 ? m_StochBuffer[shift] : m_StochSignalBuffer[shift];
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void CStochastic::GetData(double &buffer[], int bufferIndx=0, int shift=0)
  {
   if(shift >= m_KPeriod || bufferIndx > 1)
      return;

   ArraySetAsSeries(buffer, true);
   ArrayResize(buffer, ArraySize(m_StochBuffer) - shift);

   if(bufferIndx ==0)
      ArrayCopy(buffer, m_StochBuffer, 0, shift);
   else
      ArrayCopy(buffer, m_StochSignalBuffer, 0, shift);
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
ENUM_ENTRY_SIGNAL CStochastic::EnterOsOBSignal(void)
  {
   return CBaseIndicator::_EnterOsOBSignal(m_StochBuffer, m_OverBoughtLevel, m_OverSoldLevel);
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
ENUM_ENTRY_SIGNAL CStochastic::ContraEnterOsOBSignal(void)
  {
   ENUM_ENTRY_SIGNAL signal = EnterOsOBSignal();
   return signal == ENTRY_SIGNAL_BUY ? ENTRY_SIGNAL_SELL :
          (signal == ENTRY_SIGNAL_SELL) ? ENTRY_SIGNAL_BUY : ENTRY_SIGNAL_NONE;
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
ENUM_ENTRY_SIGNAL CStochastic::ExitOsOBSignal(void)
  {
   return CBaseIndicator::_ExitOsOBSignal(m_StochBuffer, m_OverBoughtLevel, m_OverSoldLevel);
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
ENUM_ENTRY_SIGNAL CStochastic::ContraExitOsOBSignal(void)
  {
   ENUM_ENTRY_SIGNAL signal = ExitOsOBSignal();
   return signal == ENTRY_SIGNAL_BUY ? ENTRY_SIGNAL_SELL :
          (signal == ENTRY_SIGNAL_SELL) ? ENTRY_SIGNAL_BUY : ENTRY_SIGNAL_NONE;
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
ENUM_ENTRY_SIGNAL CStochastic::CrossMidSignal(void)
  {
   return CBaseIndicator::_CrossMidSignal(m_StochBuffer, (m_OverBoughtLevel + m_OverSoldLevel)/2);
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
ENUM_ENTRY_SIGNAL CStochastic::DirectionalSignal(void)
  {
   return CBaseIndicator::_DirectionalSignal(m_StochBuffer);
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
ENUM_ENTRY_SIGNAL CStochastic::CrossoverSignal(void)
  {
   if(m_StochBuffer[2] > m_StochSignalBuffer[2] && m_StochBuffer[1] < m_StochSignalBuffer[1])
      return ENTRY_SIGNAL_SELL;
   else
      if(m_StochBuffer[2] < m_StochSignalBuffer[2] && m_StochBuffer[1] > m_StochSignalBuffer[1])
         return ENTRY_SIGNAL_BUY;

   return ENTRY_SIGNAL_NONE;
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
ENUM_ENTRY_SIGNAL CStochastic::ObOsCrossoverSignal(void)
  {
//at least shift2 of STOCH must have been overbought
   if(m_StochBuffer[2] > m_OverBoughtLevel)
     {
      if(m_StochBuffer[2] > m_StochSignalBuffer[2] && m_StochBuffer[1] < m_StochSignalBuffer[1])
         return ENTRY_SIGNAL_SELL;
      else
         return ENTRY_SIGNAL_NONE;
     }
//at least shift2 of STOCH must have been oversold
   if(m_StochBuffer[2] < m_OverSoldLevel)
     {
      if(m_StochBuffer[2] < m_StochSignalBuffer[2] && m_StochBuffer[1] > m_StochSignalBuffer[1])
         return ENTRY_SIGNAL_BUY;
      else
         return ENTRY_SIGNAL_NONE;
     }

   return ENTRY_SIGNAL_NONE;
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
ENUM_ENTRY_SIGNAL CStochastic::TradeSignal(ENUM_STOCH_Strategies signalOption)
  {
   switch(signalOption)
     {
      case STOCH_ContraEnterOsOBLevels:
         return ContraEnterOsOBSignal();
      case STOCH_ContraExitOsOBLevels:
         return ContraExitOsOBSignal();
      case STOCH_CrossMidLevel:
         return CrossMidSignal();
      case STOCH_Directional:
         return DirectionalSignal();
      case STOCH_EnterOsOBLevels:
         return EnterOsOBSignal();
      case STOCH_ExitOsOBLevels:
         return ExitOsOBSignal();
      case STOCH_ObOsSignalCrossover :
         return ObOsCrossoverSignal();
      case STOCH_SignalCrossover :
         return CrossoverSignal();
      default:
         return ENTRY_SIGNAL_NONE;
     }
  }
//+------------------------------------------------------------------+
