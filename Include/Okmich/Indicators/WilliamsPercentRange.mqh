//+------------------------------------------------------------------+
//|                                         WilliamsPercentRange.mqh |
//|                                    Copyright 2022, Michael Enudi |
//|                                             okmich2002@yahoo.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2022, Michael Enudi"
#property link      "okmich2002@yahoo.com"
#property version   "1.00"

#include "BaseIndicator.mqh"

enum ENUM_WPR_Strategies
  {
   WPR_EnterOsOBLevels,
   WPR_ContraEnterOsOBLevels,
   WPR_ExitOsOBLevels,
   WPR_ContraExitOsOBLevels,
   WPR_CrossMidLevel,
   WPR_Directional
  };

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
class CWpr : public CBaseIndicator
  {
private :
   //--- indicator paramter
   int                m_WprPeriod, m_WprSmoothing;
   double             m_ObLevel,m_OsLevel;
   //--- indicator handle
   int                mWprHandle;
   //--- indicator buffer
   double             m_WprBuffer[];
   
   ENUM_ENTRY_SIGNAL  EnterOsOBSignal();
   ENUM_ENTRY_SIGNAL  ContraEnterOsOBSignal();
   ENUM_ENTRY_SIGNAL  ExitOsOBSignal();
   ENUM_ENTRY_SIGNAL  ContraExitOsOBSignal();
   ENUM_ENTRY_SIGNAL  CrossMidSignal();
   ENUM_ENTRY_SIGNAL  DirectionalSignal();

public:
                     CWpr(string symbol, ENUM_TIMEFRAMES period,
        int InputWprPeriod=14, double InptOBLevel=70, double InptOSLevel=30): CBaseIndicator(symbol, period)
     {
      m_WprPeriod = InputWprPeriod;
      m_ObLevel = InptOBLevel;
      m_OsLevel = InptOSLevel;
     }

   virtual bool       Init();
   virtual bool       Refresh(int ShiftToUse=1);
   virtual void       Release();

   double             GetData(int shift=0);
   void               GetData(double &buffer[], int shift=0);

   ENUM_ENTRY_SIGNAL  TradeSignal(ENUM_WPR_Strategies signalOption);
  };

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
bool CWpr::Init(void)
  {
   ArraySetAsSeries(m_WprBuffer, true);
   mWprHandle = iWPR(m_Symbol, m_TF, m_WprPeriod);

   return mWprHandle != INVALID_HANDLE;
  }
  
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
bool CWpr::Refresh(int ShiftToUse=1)
  {
   m_ShiftToUse = ShiftToUse;
   int copied = CopyBuffer(mWprHandle, 0, 0, m_WprPeriod, m_WprBuffer);
   return copied == m_WprPeriod;
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void CWpr::Release(void)
  {
   IndicatorRelease(mWprHandle);
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
double CWpr::GetData(int shift=0)
  {
   if(shift >= m_WprPeriod)
      return EMPTY_VALUE;

   return m_WprBuffer[shift];
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void CWpr::GetData(double &buffer[], int shift=0)
  {
   if(shift >= m_WprPeriod)
      return;

   ArraySetAsSeries(buffer, true);
   ArrayResize(buffer, ArraySize(m_WprBuffer) - shift);

   ArrayCopy(buffer, m_WprBuffer, 0, shift);
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
ENUM_ENTRY_SIGNAL CWpr::EnterOsOBSignal(void)
  {
   return CBaseIndicator::_EnterOsOBSignal(m_WprBuffer, m_ObLevel, m_OsLevel);
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
ENUM_ENTRY_SIGNAL CWpr::ContraEnterOsOBSignal(void)
  {
   ENUM_ENTRY_SIGNAL signal = EnterOsOBSignal();
   return signal == ENTRY_SIGNAL_BUY ? ENTRY_SIGNAL_SELL :
          (signal == ENTRY_SIGNAL_SELL) ? ENTRY_SIGNAL_BUY : ENTRY_SIGNAL_NONE;
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
ENUM_ENTRY_SIGNAL CWpr::ExitOsOBSignal(void)
  {
   return CBaseIndicator::_ExitOsOBSignal(m_WprBuffer, m_ObLevel, m_OsLevel);
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
ENUM_ENTRY_SIGNAL CWpr::ContraExitOsOBSignal(void)
  {
   ENUM_ENTRY_SIGNAL signal = ExitOsOBSignal();
   return signal == ENTRY_SIGNAL_BUY ? ENTRY_SIGNAL_SELL :
          (signal == ENTRY_SIGNAL_SELL) ? ENTRY_SIGNAL_BUY : ENTRY_SIGNAL_NONE;
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
ENUM_ENTRY_SIGNAL CWpr::CrossMidSignal(void)
  {
   return CBaseIndicator::_CrossMidSignal(m_WprBuffer, (m_ObLevel + m_OsLevel)/2);
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
ENUM_ENTRY_SIGNAL CWpr::DirectionalSignal(void)
  {
   return CBaseIndicator::_DirectionalSignal(m_WprBuffer);
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
ENUM_ENTRY_SIGNAL CWpr::TradeSignal(ENUM_WPR_Strategies signalOption)
  {
   switch(signalOption)
     {
      case WPR_ContraEnterOsOBLevels:
         return ContraEnterOsOBSignal();
      case WPR_ContraExitOsOBLevels:
         return ContraExitOsOBSignal();
      case WPR_CrossMidLevel:
         return CrossMidSignal();
      case WPR_Directional:
         return DirectionalSignal();
      case WPR_EnterOsOBLevels:
         return EnterOsOBSignal();
      case WPR_ExitOsOBLevels:
         return ExitOsOBSignal();
      default:
         return ENTRY_SIGNAL_NONE;
     }
  }
//+------------------------------------------------------------------+
