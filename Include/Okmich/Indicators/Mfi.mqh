//+------------------------------------------------------------------+
//|                                               MoneyFlowIndex.mqh |
//|                                    Copyright 2022, Michael Enudi |
//|                                             okmich2002@yahoo.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2022, Michael Enudi"
#property link      "okmich2002@yahoo.com"
#property version   "1.00"

#include "BaseIndicator.mqh"

enum ENUM_MFI_Strategies
  {
   MFI_EnterOsOBLevels,
   MFI_ContraEnterOsOBLevels,
   MFI_ExitOsOBLevels,
   MFI_ContraExitOsOBLevels,
   MFI_CrossMidLevel,
   MFI_Directional,
   MFI_AboveBelowSignal
  };

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
class CMfi : public CBaseIndicator
  {
private :
   int                m_HistoryBars;
   //--- indicator paramter
   int                m_Period, m_SignalPeriod;
   double             m_ObLevel, m_OsLevel;
   bool               m_UseSignal;
   ENUM_MA_METHOD     m_SignalMethod;
   //--- indicator handle
   int                m_Handle;
   //--- indicator buffer
   double             m_MfiBuffer[], m_MaBuffer[];

   ENUM_ENTRY_SIGNAL  AboveBelowSignal();
   ENUM_ENTRY_SIGNAL  EnterOsOBSignal();
   ENUM_ENTRY_SIGNAL  ContraEnterOsOBSignal();
   ENUM_ENTRY_SIGNAL  ExitOsOBSignal();
   ENUM_ENTRY_SIGNAL  ContraExitOsOBSignal();
   ENUM_ENTRY_SIGNAL  CrossMidSignal();
   ENUM_ENTRY_SIGNAL  DirectionalSignal();

public:
                     CMfi(string symbol, ENUM_TIMEFRAMES period,
        int InputPeriod=14, double InptOBLevel=80, double InptOSLevel=20,
        bool InputUseSignalLine = false, ENUM_MA_METHOD InputSignalMethod = MODE_EMA,
        int InputSignalPeriod=7): CBaseIndicator(symbol, period)
     {
      m_Period = InputPeriod;
      m_ObLevel = InptOBLevel;
      m_OsLevel = InptOSLevel;

      m_UseSignal = InputUseSignalLine;
      m_SignalMethod = InputSignalMethod;
      m_SignalPeriod = InputSignalPeriod;

      m_HistoryBars = InputPeriod;
     }

   virtual bool       Init();
   virtual bool       Refresh(int ShiftToUse=1);
   virtual void       Release();

   double             GetData(int shift=0);
   void               GetData(double &buffer[], int shift=0);

   ENUM_ENTRY_SIGNAL  TradeSignal(ENUM_MFI_Strategies signalOption);
  };
//+------------------------------------------------------------------+


//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
bool CMfi::Init(void)
  {
   ArraySetAsSeries(m_MfiBuffer, true);
   m_Handle = iMFI(m_Symbol, m_TF, m_Period, VOLUME_TICK);

   return m_Handle != INVALID_HANDLE;
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
bool CMfi::Refresh(int ShiftToUse=1)
  {
   m_ShiftToUse = ShiftToUse;
   int copied = CopyBuffer(m_Handle, 0, 0, m_HistoryBars, m_MfiBuffer);
   return copied == m_HistoryBars;
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void CMfi::Release(void)
  {
   IndicatorRelease(m_Handle);
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
double CMfi::GetData(int shift=0)
  {
   if(shift >= m_Period)
      return EMPTY_VALUE;

   return m_MfiBuffer[shift];
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void CMfi::GetData(double &buffer[], int shift=0)
  {
   if(shift >= m_Period)
      return;

   ArraySetAsSeries(buffer, true);
   ArrayResize(buffer, ArraySize(m_MfiBuffer) - shift);

   ArrayCopy(buffer, m_MfiBuffer, 0, shift);
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
ENUM_ENTRY_SIGNAL CMfi::AboveBelowSignal(void)
  {
   if(!m_UseSignal)
      return ENTRY_SIGNAL_NONE;

//calculate signal values for m_ShiftToUse and m_ShiftToUse+1
   double maShift1=EMPTY_VALUE, maShift2=EMPTY_VALUE;
   switch(m_SignalMethod)
     {
      case MODE_LWMA:
         maShift2 = LinearWeightedMA(m_ShiftToUse+1, m_SignalPeriod, m_MfiBuffer);
         maShift1 = LinearWeightedMA(m_ShiftToUse, m_SignalPeriod, m_MfiBuffer);
         break;
      case MODE_SMA:
         maShift2 = SimpleMA(m_ShiftToUse+1, m_SignalPeriod, m_MfiBuffer);
         maShift1 = SimpleMA(m_ShiftToUse, m_SignalPeriod, m_MfiBuffer);
         break;
      case MODE_SMMA:
        {
         double maShift3 = SimpleMA(m_ShiftToUse+2, m_SignalPeriod, m_MfiBuffer);
         maShift2 = SmoothedMA(m_ShiftToUse+1, m_SignalPeriod, maShift3, m_MfiBuffer);
         maShift1 = SmoothedMA(m_ShiftToUse, m_SignalPeriod, maShift2, m_MfiBuffer);
        }
      case MODE_EMA:
      default:
        {
         double maShift3 = SimpleMA(m_ShiftToUse+2, m_SignalPeriod, m_MfiBuffer);
         maShift2 = ExponentialMA(m_ShiftToUse+1, m_SignalPeriod, maShift3, m_MfiBuffer);
         maShift1 = ExponentialMA(m_ShiftToUse, m_SignalPeriod, maShift2, m_MfiBuffer);
        }
     }

   if((maShift2 > m_MfiBuffer[m_ShiftToUse+1]) && (maShift1 < m_MfiBuffer[m_ShiftToUse]))
      return ENTRY_SIGNAL_BUY;
   else
      if((maShift2 < m_MfiBuffer[m_ShiftToUse+1]) && (maShift1 > m_MfiBuffer[m_ShiftToUse]))
         return ENTRY_SIGNAL_SELL;

   return ENTRY_SIGNAL_NONE;
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
ENUM_ENTRY_SIGNAL CMfi::EnterOsOBSignal(void)
  {
   return CBaseIndicator::_EnterOsOBSignal(m_MfiBuffer, m_ObLevel, m_OsLevel);
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
ENUM_ENTRY_SIGNAL CMfi::ContraEnterOsOBSignal(void)
  {
   ENUM_ENTRY_SIGNAL signal = EnterOsOBSignal();
   return signal == ENTRY_SIGNAL_BUY ? ENTRY_SIGNAL_SELL :
          (signal == ENTRY_SIGNAL_SELL) ? ENTRY_SIGNAL_BUY : ENTRY_SIGNAL_NONE;
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
ENUM_ENTRY_SIGNAL CMfi::ExitOsOBSignal(void)
  {
   return CBaseIndicator::_ExitOsOBSignal(m_MfiBuffer, m_ObLevel, m_OsLevel);
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
ENUM_ENTRY_SIGNAL CMfi::ContraExitOsOBSignal(void)
  {
   ENUM_ENTRY_SIGNAL signal = ExitOsOBSignal();
   return signal == ENTRY_SIGNAL_BUY ? ENTRY_SIGNAL_SELL :
          (signal == ENTRY_SIGNAL_SELL) ? ENTRY_SIGNAL_BUY : ENTRY_SIGNAL_NONE;
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
ENUM_ENTRY_SIGNAL CMfi::CrossMidSignal(void)
  {
   return CBaseIndicator::_CrossMidSignal(m_MfiBuffer, (m_ObLevel + m_OsLevel)/2);
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
ENUM_ENTRY_SIGNAL CMfi::DirectionalSignal(void)
  {
   return CBaseIndicator::_DirectionalSignal(m_MfiBuffer);
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
ENUM_ENTRY_SIGNAL CMfi::TradeSignal(ENUM_MFI_Strategies signalOption)
  {
   switch(signalOption)
     {
      case MFI_ContraEnterOsOBLevels:
         return ContraEnterOsOBSignal();
      case MFI_ContraExitOsOBLevels:
         return ContraExitOsOBSignal();
      case MFI_CrossMidLevel:
         return CrossMidSignal();
      case MFI_Directional:
         return DirectionalSignal();
      case MFI_EnterOsOBLevels:
         return EnterOsOBSignal();
      case MFI_ExitOsOBLevels:
         return ExitOsOBSignal();
      case MFI_AboveBelowSignal:
         return AboveBelowSignal();
      default:
         return ENTRY_SIGNAL_NONE;
     }
  }
//+------------------------------------------------------------------+
