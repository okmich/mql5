//+------------------------------------------------------------------+
//|                                       DynamicTradeOscillator.mqh |
//|                                    Copyright 2022, Michael Enudi |
//|                                             okmich2002@yahoo.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2022, Michael Enudi"
#property link      "okmich2002@yahoo.com"
#property version   "1.00"

#include "BaseIndicator.mqh"

enum ENUM_DTOSC_Strategies
  {
   DTOSC_EnterOsOBLevels,
   DTOSC_ContraEnterOsOBLevels,
   DTOSC_ExitOsOBLevels,
   DTOSC_ContraExitOsOBLevels,
   DTOSC_CrossMidLevel,
   DTOSC_Directional,
   DTOSC_SignalCrossover,
   DTOSC_ObOsSignalCrossover
  };

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
class CDynamicTradeOscillator : public CBaseIndicator
  {
private :
   //--- indicator paramter
   int                m_Period, m_KPeriod, m_Slowing, m_SignalPeriod,mBarsToCopy;
   double             m_OverBoughtLevel, m_OverSoldLevel;
   //--- indicator handle
   int                m_Handle;
   //--- indicator buffer
   double             m_Buffer[], m_SignalBuffer[];
   
   ENUM_ENTRY_SIGNAL  EnterOsOBSignal();
   ENUM_ENTRY_SIGNAL  ContraEnterOsOBSignal();
   ENUM_ENTRY_SIGNAL  ExitOsOBSignal();
   ENUM_ENTRY_SIGNAL  ContraExitOsOBSignal();
   ENUM_ENTRY_SIGNAL  CrossMidSignal();
   ENUM_ENTRY_SIGNAL  DirectionalSignal();
   ENUM_ENTRY_SIGNAL  CrossoverSignal();
   ENUM_ENTRY_SIGNAL  ObOsCrossoverSignal();

public:
                     CDynamicTradeOscillator(string symbol, ENUM_TIMEFRAMES period,
                  int InputPeriod=14, int InputKPeriod=5, int InputSlowing=4, int InputSignal = 3,
                  double InptOBLevel=80, double InptOSLevel=20, int InputHistoryBars= 6): CBaseIndicator(symbol, period)
     {
      m_Period = InputPeriod;
      m_KPeriod = InputKPeriod;
      m_Slowing = InputSlowing;
      m_SignalPeriod = InputSignal;
      m_OverBoughtLevel = InptOBLevel;
      m_OverSoldLevel = InptOSLevel;
      
      mBarsToCopy = InputHistoryBars;
     }

   virtual bool       Init();
   virtual bool       Refresh(int ShiftToUse=1);
   virtual void       Release();
   
   double             GetData(int bufferIndx=0, int shift=0);
   void               GetData(double &buffer[], int bufferIndx=0, int shift=0);
   
   ENUM_ENTRY_SIGNAL  TradeSignal(ENUM_DTOSC_Strategies signalOption);
  };
//+------------------------------------------------------------------+


//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
bool CDynamicTradeOscillator::Init(void)
  {
   ArraySetAsSeries(m_Buffer, true);
   ArraySetAsSeries(m_SignalBuffer, true);
   
   m_Handle = iCustom(m_Symbol, m_TF, "Articles\\Dynamic Trader Oscillator",
                             m_Period, m_KPeriod, m_Slowing, m_SignalPeriod);

   return m_Handle != INVALID_HANDLE;
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
bool CDynamicTradeOscillator::Refresh(int ShiftToUse=1)
  {
   m_ShiftToUse = ShiftToUse;
   int stockRsiCopied = CopyBuffer(m_Handle, 0, 0, m_Period, m_Buffer);
   return stockRsiCopied == m_Period;
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void CDynamicTradeOscillator::Release(void)
  {
   IndicatorRelease(m_Handle);
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
double CDynamicTradeOscillator::GetData(int bufferIndx=0, int shift=0)
  {
   if(shift >= mBarsToCopy || bufferIndx > 1)
      return EMPTY_VALUE;

   switch(bufferIndx)
     {
      case 1:
         return m_SignalBuffer[shift];
      case 0:
      default:
         return m_Buffer[shift];
     }
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void CDynamicTradeOscillator::GetData(double &buffer[], int bufferIndx=0, int shift=0)
  {
   if(shift >= mBarsToCopy || bufferIndx > 1)
      return;

   ArraySetAsSeries(buffer, true);
   ArrayResize(buffer, ArraySize(m_Buffer) - shift);

   switch(bufferIndx)
     {
      case 1:
         ArrayCopy(buffer, m_SignalBuffer, 0, shift);
         break;
      case 0:
      default:
         ArrayCopy(buffer, m_Buffer, 0, shift);;
         break;
     }
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
ENUM_ENTRY_SIGNAL CDynamicTradeOscillator::EnterOsOBSignal(void)
  {
   return CBaseIndicator::_EnterOsOBSignal(m_Buffer, m_OverBoughtLevel, m_OverSoldLevel);
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
ENUM_ENTRY_SIGNAL CDynamicTradeOscillator::ContraEnterOsOBSignal(void)
  {
   ENUM_ENTRY_SIGNAL signal = EnterOsOBSignal();
   return signal == ENTRY_SIGNAL_BUY ? ENTRY_SIGNAL_SELL :
          (signal == ENTRY_SIGNAL_SELL) ? ENTRY_SIGNAL_BUY : ENTRY_SIGNAL_NONE;
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
ENUM_ENTRY_SIGNAL CDynamicTradeOscillator::ExitOsOBSignal(void)
  {
   return CBaseIndicator::_ExitOsOBSignal(m_Buffer, m_OverBoughtLevel, m_OverSoldLevel);
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
ENUM_ENTRY_SIGNAL CDynamicTradeOscillator::ContraExitOsOBSignal(void)
  {
   ENUM_ENTRY_SIGNAL signal = ExitOsOBSignal();
   return signal == ENTRY_SIGNAL_BUY ? ENTRY_SIGNAL_SELL :
          (signal == ENTRY_SIGNAL_SELL) ? ENTRY_SIGNAL_BUY : ENTRY_SIGNAL_NONE;
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
ENUM_ENTRY_SIGNAL CDynamicTradeOscillator::CrossMidSignal(void)
  {
   return CBaseIndicator::_CrossMidSignal(m_Buffer, (m_OverBoughtLevel + m_OverSoldLevel)/2);
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
ENUM_ENTRY_SIGNAL CDynamicTradeOscillator::DirectionalSignal(void)
  {
   return CBaseIndicator::_DirectionalSignal(m_Buffer);
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
ENUM_ENTRY_SIGNAL CDynamicTradeOscillator::CrossoverSignal(void)
  {
   double signalShift1 = m_SignalBuffer[1];
   double signalShift2 = m_SignalBuffer[2];
   if(m_Buffer[2] > signalShift2 && m_Buffer[1] < signalShift1)
      return ENTRY_SIGNAL_SELL;
   else
      if(m_Buffer[2] < signalShift2 && m_Buffer[1] > signalShift1)
         return ENTRY_SIGNAL_BUY;

   return ENTRY_SIGNAL_NONE;
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
ENUM_ENTRY_SIGNAL CDynamicTradeOscillator::ObOsCrossoverSignal(void)
  {
   double signalShift1 = m_SignalBuffer[1];
   double signalShift2 = m_SignalBuffer[2];
//at least shift2 of stochrsi must have been overbought
   if(m_Buffer[2] > m_OverBoughtLevel)
     {
      if(m_Buffer[2] > signalShift2 && m_Buffer[1] < signalShift1)
         return ENTRY_SIGNAL_SELL;
      else
         return ENTRY_SIGNAL_NONE;
     }
//at least shift2 of stochrsi must have been oversold
   if(m_Buffer[2] < m_OverSoldLevel)
     {
      if(m_Buffer[2] < signalShift2 && m_Buffer[1] > signalShift1)
         return ENTRY_SIGNAL_BUY;
      else
         return ENTRY_SIGNAL_NONE;
     }

   return ENTRY_SIGNAL_NONE;
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
ENUM_ENTRY_SIGNAL CDynamicTradeOscillator::TradeSignal(ENUM_DTOSC_Strategies signalOption)
  {
   switch(signalOption)
     {
      case DTOSC_ContraEnterOsOBLevels:
         return ContraEnterOsOBSignal();
      case DTOSC_ContraExitOsOBLevels:
         return ContraExitOsOBSignal();
      case DTOSC_CrossMidLevel:
         return CrossMidSignal();
      case DTOSC_Directional:
         return DirectionalSignal();
      case DTOSC_EnterOsOBLevels:
         return EnterOsOBSignal();
      case DTOSC_ExitOsOBLevels:
         return ExitOsOBSignal();
      case DTOSC_ObOsSignalCrossover :
         return ObOsCrossoverSignal();
      case DTOSC_SignalCrossover :
         return CrossoverSignal();
      default:
         return ENTRY_SIGNAL_NONE;
     }
  }
//+------------------------------------------------------------------+
