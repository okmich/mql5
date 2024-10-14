//+------------------------------------------------------------------+
//|                                        RelativeStrengthIndex.mqh |
//|                                    Copyright 2021, Michael Enudi |
//|                                             okmich2002@yahoo.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2021, Michael Enudi"
#property link      "okmich2002@yahoo.com"
#property version   "1.00"

#include "BaseIndicator.mqh"

enum ENUM_RSI_Strategies
  {
   RSI_EnterOsOBLevels,
   RSI_ContraEnterOsOBLevels,
   RSI_ExitOsOBLevels,
   RSI_ContraExitOsOBLevels,
   RSI_CrossMidLevel,
   RSI_Directional
  };

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
class CRsi : public CBaseIndicator
  {
private :
   int                m_HistoryBars;
   //--- indicator paramter
   int                m_RsiPeriod;
   double             m_ObLevel, m_OsLevel;
   //--- indicator handle
   int                mRsiHandle;
   //--- indicator buffer
   double             m_RsiBuffer[];
   
   ENUM_ENTRY_SIGNAL  EnterOsOBSignal();
   ENUM_ENTRY_SIGNAL  ContraEnterOsOBSignal();
   ENUM_ENTRY_SIGNAL  ExitOsOBSignal();
   ENUM_ENTRY_SIGNAL  ContraExitOsOBSignal();
   ENUM_ENTRY_SIGNAL  CrossMidSignal();
   ENUM_ENTRY_SIGNAL  DirectionalSignal();

public:
                     CRsi(string symbol, ENUM_TIMEFRAMES period,
        int InputRsiPeriod=14, double InptOBLevel=70, double InptOSLevel=30,
        int historyBars=14): CBaseIndicator(symbol, period)
     {
      m_RsiPeriod = InputRsiPeriod;
      m_ObLevel = InptOBLevel;
      m_OsLevel = InptOSLevel;

      m_HistoryBars = historyBars;
     }

   virtual bool       Init();
   virtual bool       Refresh(int ShiftToUse=1);
   virtual void       Release();

   double             GetData(int shift=0);
   void               GetData(double &buffer[], int shift=0);
   
   ENUM_ENTRY_SIGNAL  TradeSignal(ENUM_RSI_Strategies signalOption);
  };
//+------------------------------------------------------------------+


//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
bool CRsi::Init(void)
  {
   ArraySetAsSeries(m_RsiBuffer, true);
   mRsiHandle = iRSI(m_Symbol, m_TF, m_RsiPeriod, PRICE_CLOSE);

   return mRsiHandle != INVALID_HANDLE;
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
bool CRsi::Refresh(int ShiftToUse=1)
  {
   m_ShiftToUse = ShiftToUse;
   int rsiCopied = CopyBuffer(mRsiHandle, 0, 0, m_HistoryBars, m_RsiBuffer);
   return rsiCopied == m_HistoryBars;
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void CRsi::Release(void)
  {
   IndicatorRelease(mRsiHandle);
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
double CRsi::GetData(int shift=0)
  {
   if(shift >= m_RsiPeriod)
      return EMPTY_VALUE;

   return m_RsiBuffer[shift];
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void CRsi::GetData(double &buffer[], int shift=0)
  {
   if(shift >= m_RsiPeriod)
      return;

   ArraySetAsSeries(buffer, true);
   ArrayResize(buffer, ArraySize(m_RsiBuffer) - shift);

   ArrayCopy(buffer, m_RsiBuffer, 0, shift);
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
ENUM_ENTRY_SIGNAL CRsi::EnterOsOBSignal(void)
  {
   return CBaseIndicator::_EnterOsOBSignal(m_RsiBuffer, m_ObLevel, m_OsLevel);
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
ENUM_ENTRY_SIGNAL CRsi::ContraEnterOsOBSignal(void)
  {
   ENUM_ENTRY_SIGNAL signal = EnterOsOBSignal();
   return signal == ENTRY_SIGNAL_BUY ? ENTRY_SIGNAL_SELL :
          (signal == ENTRY_SIGNAL_SELL) ? ENTRY_SIGNAL_BUY : ENTRY_SIGNAL_NONE;
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
ENUM_ENTRY_SIGNAL CRsi::ExitOsOBSignal(void)
  {
   return CBaseIndicator::_ExitOsOBSignal(m_RsiBuffer, m_ObLevel, m_OsLevel);
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
ENUM_ENTRY_SIGNAL CRsi::ContraExitOsOBSignal(void)
  {
   ENUM_ENTRY_SIGNAL signal = ExitOsOBSignal();
   return signal == ENTRY_SIGNAL_BUY ? ENTRY_SIGNAL_SELL :
          (signal == ENTRY_SIGNAL_SELL) ? ENTRY_SIGNAL_BUY : ENTRY_SIGNAL_NONE;
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
ENUM_ENTRY_SIGNAL CRsi::CrossMidSignal(void)
  {
   return CBaseIndicator::_CrossMidSignal(m_RsiBuffer, (m_ObLevel + m_OsLevel)/2);
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
ENUM_ENTRY_SIGNAL CRsi::DirectionalSignal(void)
  {
   return CBaseIndicator::_DirectionalSignal(m_RsiBuffer);
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
ENUM_ENTRY_SIGNAL CRsi::TradeSignal(ENUM_RSI_Strategies signalOption)
  {
   switch(signalOption)
     {
      case RSI_ContraEnterOsOBLevels:
         return ContraEnterOsOBSignal();
      case RSI_ContraExitOsOBLevels:
         return ContraExitOsOBSignal();
      case RSI_CrossMidLevel:
         return CrossMidSignal();
      case RSI_Directional:
         return DirectionalSignal();
      case RSI_EnterOsOBLevels:
         return EnterOsOBSignal();
      case RSI_ExitOsOBLevels:
         return ExitOsOBSignal();
      default:
         return ENTRY_SIGNAL_NONE;
     }
  }
//+------------------------------------------------------------------+
