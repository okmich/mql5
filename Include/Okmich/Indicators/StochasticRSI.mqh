//+------------------------------------------------------------------+
//|                                                StochasticRSI.mqh |
//|                                    Copyright 2021, Michael Enudi |
//|                                             okmich2002@yahoo.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2021, Michael Enudi"
#property link      "okmich2002@yahoo.com"
#property version   "1.00"

#include "BaseIndicator.mqh"

enum ENUM_STOCHRSI_Strategies
  {
   STOCHRSI_EnterOsOBLevels,
   STOCHRSI_ContraEnterOsOBLevels,
   STOCHRSI_ExitOsOBLevels,
   STOCHRSI_ContraExitOsOBLevels,
   STOCHRSI_SignalCrossover,
   STOCHRSI_ObOsSignalCrossover,
   STOCHRSI_CrossMidLevel,
   STOCHRSI_Directional
  };

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
class CStochasticRSI : public CBaseIndicator
  {
private :
   //--- indicator paramter
   int                m_RsiPeriod, m_KPeriod, m_Slowing, m_Signal;
   double             m_OverBoughtLevel, m_OverSoldLevel;
   //--- indicator handle
   int                mStochRSIHandle;
   //--- indicator buffer
   double             m_StochRSIBuffer[], m_SignalBuffer[];
   
   double             Signal(int shift=0);
   
   ENUM_ENTRY_SIGNAL  EnterOsOBSignal();
   ENUM_ENTRY_SIGNAL  ContraEnterOsOBSignal();
   ENUM_ENTRY_SIGNAL  ExitOsOBSignal();
   ENUM_ENTRY_SIGNAL  ContraExitOsOBSignal();
   ENUM_ENTRY_SIGNAL  CrossMidSignal();
   ENUM_ENTRY_SIGNAL  DirectionalSignal();
   ENUM_ENTRY_SIGNAL  CrossoverSignal();
   ENUM_ENTRY_SIGNAL  ObOsCrossoverSignal();

public:
                     CStochasticRSI(string symbol, ENUM_TIMEFRAMES period,
                  int InputRsiPeriod=14, int InputKPeriod=5, int InputSlowing=4, int InputSignal = 3,
                  double InptOBLevel=80, double InptOSLevel=20): CBaseIndicator(symbol, period)
     {
      m_RsiPeriod = InputRsiPeriod;
      m_KPeriod = InputKPeriod;
      m_Slowing = InputSlowing;
      m_Signal = InputSignal;
      m_OverBoughtLevel = InptOBLevel;
      m_OverSoldLevel = InptOSLevel;
     }

   virtual bool       Init();
   virtual bool       Refresh(int ShiftToUse=1);
   virtual void       Release();
   
   double             GetData(int shift=0);
   void               GetData(double &buffer[], int shift=0);
   
   ENUM_ENTRY_SIGNAL  TradeSignal(ENUM_STOCHRSI_Strategies signalOption);
  };
//+------------------------------------------------------------------+


//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
bool CStochasticRSI::Init(void)
  {
   ArraySetAsSeries(m_StochRSIBuffer, true);
   ArraySetAsSeries(m_SignalBuffer, true);
   
   mStochRSIHandle = iCustom(m_Symbol, m_TF, "Okmich\\Stochastic RSI",
                             m_RsiPeriod, m_KPeriod, m_Slowing);

   return mStochRSIHandle != INVALID_HANDLE;
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
bool CStochasticRSI::Refresh(int ShiftToUse=1)
  {
   m_ShiftToUse = ShiftToUse;
   int stockRsiCopied = CopyBuffer(mStochRSIHandle, 0, 0, m_RsiPeriod, m_StochRSIBuffer);
   int signalCopied = CopyBuffer(mStochRSIHandle, 1, 0, m_RsiPeriod, m_SignalBuffer);
   return stockRsiCopied == m_RsiPeriod;
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void CStochasticRSI::Release(void)
  {
   IndicatorRelease(mStochRSIHandle);
   ArrayFree(m_StochRSIBuffer);
   ArrayFree(m_SignalBuffer);
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
double CStochasticRSI::GetData(int shift=0)
  {
   if(shift >= m_RsiPeriod)
      return EMPTY_VALUE;

   return m_StochRSIBuffer[shift];
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void CStochasticRSI::GetData(double &buffer[], int shift=0)
  {
   if(shift >= m_RsiPeriod)
      return;

   ArraySetAsSeries(buffer, true);
   ArrayResize(buffer, ArraySize(m_StochRSIBuffer) - shift);

   ArrayCopy(buffer, m_StochRSIBuffer, 0, shift);
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
double CStochasticRSI::Signal(int shift=0)
  {
   if(shift >= m_RsiPeriod)
      return EMPTY_VALUE;

   return m_SignalBuffer[shift];
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
ENUM_ENTRY_SIGNAL CStochasticRSI::EnterOsOBSignal(void)
  {
   return CBaseIndicator::_EnterOsOBSignal(m_StochRSIBuffer, m_OverBoughtLevel, m_OverSoldLevel);
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
ENUM_ENTRY_SIGNAL CStochasticRSI::ContraEnterOsOBSignal(void)
  {
   ENUM_ENTRY_SIGNAL signal = EnterOsOBSignal();
   return signal == ENTRY_SIGNAL_BUY ? ENTRY_SIGNAL_SELL :
          (signal == ENTRY_SIGNAL_SELL) ? ENTRY_SIGNAL_BUY : ENTRY_SIGNAL_NONE;
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
ENUM_ENTRY_SIGNAL CStochasticRSI::ExitOsOBSignal(void)
  {
   return CBaseIndicator::_ExitOsOBSignal(m_StochRSIBuffer, m_OverBoughtLevel, m_OverSoldLevel);
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
ENUM_ENTRY_SIGNAL CStochasticRSI::ContraExitOsOBSignal(void)
  {
   ENUM_ENTRY_SIGNAL signal = ExitOsOBSignal();
   return signal == ENTRY_SIGNAL_BUY ? ENTRY_SIGNAL_SELL :
          (signal == ENTRY_SIGNAL_SELL) ? ENTRY_SIGNAL_BUY : ENTRY_SIGNAL_NONE;
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
ENUM_ENTRY_SIGNAL CStochasticRSI::CrossMidSignal(void)
  {
   return CBaseIndicator::_CrossMidSignal(m_StochRSIBuffer, (m_OverBoughtLevel + m_OverSoldLevel)/2);
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
ENUM_ENTRY_SIGNAL CStochasticRSI::DirectionalSignal(void)
  {
   return CBaseIndicator::_DirectionalSignal(m_StochRSIBuffer);
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
ENUM_ENTRY_SIGNAL CStochasticRSI::CrossoverSignal(void)
  {
   double signalShift1 = Signal(1);
   double signalShift2 = Signal(2);
   if(m_StochRSIBuffer[2] > signalShift2 && m_StochRSIBuffer[1] < signalShift1)
      return ENTRY_SIGNAL_SELL;
   else
      if(m_StochRSIBuffer[2] < signalShift2 && m_StochRSIBuffer[1] > signalShift1)
         return ENTRY_SIGNAL_BUY;

   return ENTRY_SIGNAL_NONE;
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
ENUM_ENTRY_SIGNAL CStochasticRSI::ObOsCrossoverSignal(void)
  {
   double signalShift1 = Signal(m_ShiftToUse);
   double signalShift2 = Signal(m_ShiftToUse+1);
//at least shift2 of stochrsi must have been overbought
   if(m_StochRSIBuffer[m_ShiftToUse+1] > m_OverBoughtLevel)
     {
      if(m_StochRSIBuffer[m_ShiftToUse+1] > signalShift2 && m_StochRSIBuffer[m_ShiftToUse] < signalShift1)
         return ENTRY_SIGNAL_SELL;
      else
         return ENTRY_SIGNAL_NONE;
     }
//at least shift2 of stochrsi must have been oversold
   if(m_StochRSIBuffer[m_ShiftToUse+1] < m_OverSoldLevel)
     {
      if(m_StochRSIBuffer[m_ShiftToUse+1] < signalShift2 && m_StochRSIBuffer[m_ShiftToUse] > signalShift1)
         return ENTRY_SIGNAL_BUY;
      else
         return ENTRY_SIGNAL_NONE;
     }

   return ENTRY_SIGNAL_NONE;
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
ENUM_ENTRY_SIGNAL CStochasticRSI::TradeSignal(ENUM_STOCHRSI_Strategies signalOption)
  {
   switch(signalOption)
     {
      case STOCHRSI_ContraEnterOsOBLevels:
         return ContraEnterOsOBSignal();
      case STOCHRSI_ContraExitOsOBLevels:
         return ContraExitOsOBSignal();
      case STOCHRSI_CrossMidLevel:
         return CrossMidSignal();
      case STOCHRSI_Directional:
         return DirectionalSignal();
      case STOCHRSI_EnterOsOBLevels:
         return EnterOsOBSignal();
      case STOCHRSI_ExitOsOBLevels:
         return ExitOsOBSignal();
      case STOCHRSI_ObOsSignalCrossover :
         return ObOsCrossoverSignal();
      case STOCHRSI_SignalCrossover :
         return CrossoverSignal();
      default:
         return ENTRY_SIGNAL_NONE;
     }
  }
//+------------------------------------------------------------------+
