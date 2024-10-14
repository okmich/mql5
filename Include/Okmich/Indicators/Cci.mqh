//+------------------------------------------------------------------+
//|                                        CommodityChannelIndex.mqh |
//|                                    Copyright 2022, Michael Enudi |
//|                                             okmich2002@yahoo.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2022, Michael Enudi"
#property link      "okmich2002@yahoo.com"
#property version   "1.00"

#include "BaseIndicator.mqh"

enum ENUM_CCI_Strategies
  {
   CCI_EnterOsOBLevels,
   CCI_ContraEnterOsOBLevels,
   CCI_ExitOsOBLevels,
   CCI_ContraExitOsOBLevels,
   CCI_CrossMidLevel,
   CCI_Directional
  };

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
class CCci : public CBaseIndicator
  {
private :
   int                m_HistoryBars;
   //--- indicator paramter
   int                m_CciPeriod;
   double             m_ObOsLevel;
   //--- indicator handle
   int                m_Handle;
   //--- indicator buffer
   double             m_CciBuffer[];

   ENUM_ENTRY_SIGNAL  EnterOsOBSignal();
   ENUM_ENTRY_SIGNAL  ContraEnterOsOBSignal();
   ENUM_ENTRY_SIGNAL  ExitOsOBSignal();
   ENUM_ENTRY_SIGNAL  ContraExitOsOBSignal();
   ENUM_ENTRY_SIGNAL  CrossMidSignal();
   ENUM_ENTRY_SIGNAL  DirectionalSignal();

public:
                     CCci(string symbol, ENUM_TIMEFRAMES period,
        int InputCciPeriod=14, double InptObOsLevel=100, int historyBars=6): CBaseIndicator(symbol, period)
     {
      m_CciPeriod = InputCciPeriod;
      m_ObOsLevel = InptObOsLevel;
      m_HistoryBars = historyBars;
     }

   virtual bool       Init();
   virtual bool       Refresh(int ShiftToUse=1);
   virtual void       Release();

   double             GetData(int shift=0);
   void               GetData(double &buffer[], int shift=0);

   ENUM_ENTRY_SIGNAL  TradeSignal(ENUM_CCI_Strategies signalOption);
  };
//+------------------------------------------------------------------+


//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
bool CCci::Init(void)
  {
   ArraySetAsSeries(m_CciBuffer, true);
   m_Handle = iCCI(m_Symbol, m_TF, m_CciPeriod, PRICE_TYPICAL);

   return m_Handle != INVALID_HANDLE;
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
bool CCci::Refresh(int ShiftToUse=1)
  {
   m_ShiftToUse = ShiftToUse;
   int copied = CopyBuffer(m_Handle, 0, 0, m_HistoryBars, m_CciBuffer);
   return copied == m_HistoryBars;
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void CCci::Release(void)
  {
   IndicatorRelease(m_Handle);
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
double CCci::GetData(int shift=0)
  {
   if(shift >= m_CciPeriod)
      return EMPTY_VALUE;

   return m_CciBuffer[shift];
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void CCci::GetData(double &buffer[], int shift=0)
  {
   if(shift >= m_CciPeriod)
      return;

   ArraySetAsSeries(buffer, true);
   ArrayResize(buffer, ArraySize(m_CciBuffer) - shift);

   ArrayCopy(buffer, m_CciBuffer, 0, shift);
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
ENUM_ENTRY_SIGNAL CCci::EnterOsOBSignal(void)
  {
   return CBaseIndicator::_EnterOsOBSignal(m_CciBuffer, m_ObOsLevel, -m_ObOsLevel);
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
ENUM_ENTRY_SIGNAL CCci::ContraEnterOsOBSignal(void)
  {
   ENUM_ENTRY_SIGNAL signal = EnterOsOBSignal();
   return signal == ENTRY_SIGNAL_BUY ? ENTRY_SIGNAL_SELL :
          (signal == ENTRY_SIGNAL_SELL) ? ENTRY_SIGNAL_BUY : ENTRY_SIGNAL_NONE;
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
ENUM_ENTRY_SIGNAL CCci::ExitOsOBSignal(void)
  {
   return CBaseIndicator::_ExitOsOBSignal(m_CciBuffer, m_ObOsLevel, -m_ObOsLevel);
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
ENUM_ENTRY_SIGNAL CCci::ContraExitOsOBSignal(void)
  {
   ENUM_ENTRY_SIGNAL signal = ExitOsOBSignal();
   return signal == ENTRY_SIGNAL_BUY ? ENTRY_SIGNAL_SELL :
          (signal == ENTRY_SIGNAL_SELL) ? ENTRY_SIGNAL_BUY : ENTRY_SIGNAL_NONE;
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
ENUM_ENTRY_SIGNAL CCci::CrossMidSignal(void)
  {
   return CBaseIndicator::_CrossMidSignal(m_CciBuffer, 0);
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
ENUM_ENTRY_SIGNAL CCci::DirectionalSignal(void)
  {
   return CBaseIndicator::_DirectionalSignal(m_CciBuffer);
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
ENUM_ENTRY_SIGNAL CCci::TradeSignal(ENUM_CCI_Strategies signalOption)
  {
   switch(signalOption)
     {
      case CCI_ContraEnterOsOBLevels:
         return ContraEnterOsOBSignal();
      case CCI_ContraExitOsOBLevels:
         return ContraExitOsOBSignal();
      case CCI_CrossMidLevel:
         return CrossMidSignal();
      case CCI_Directional:
         return DirectionalSignal();
      case CCI_EnterOsOBLevels:
         return EnterOsOBSignal();
      case CCI_ExitOsOBLevels:
         return ExitOsOBSignal();
      default:
         return ENTRY_SIGNAL_NONE;
     }
  }
//+------------------------------------------------------------------+
