//+------------------------------------------------------------------+
//|                                                    ConnorRsi.mqh |
//|                                    Copyright 2021, Michael Enudi |
//|                                             okmich2002@yahoo.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2021, Michael Enudi"
#property link      "okmich2002@yahoo.com"
#property version   "1.00"

#include "BaseIndicator.mqh"

enum ENUM_CNRRSI_Strategies
  {
   CNRRSI_EnterOsOBLevels,
   CNRRSI_ContraEnterOsOBLevels,
   CNRRSI_ExitOsOBLevels,
   CNRRSI_ContraExitOsOBLevels,
   CNRRSI_CrossMidLevel,
   CNRRSI_Directional
  };

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
class CConnorRsi : public CBaseIndicator
  {
private :
   //--- indicator paramter
   int                m_RsiPeriod, m_StreakPeriod, m_PercentRankPeriod;
   double             m_OverBoughtLevel;
   double             m_OverSoldLevel;
   //--- indicator handle
   int                mCConnorRsiHandle;
   //--- indicator buffer
   double             m_CConnorRsiBuffer[];

   ENUM_ENTRY_SIGNAL  EnterOsOBSignal();
   ENUM_ENTRY_SIGNAL  ContraEnterOsOBSignal();
   ENUM_ENTRY_SIGNAL  ExitOsOBSignal();
   ENUM_ENTRY_SIGNAL  ContraExitOsOBSignal();
   ENUM_ENTRY_SIGNAL  CrossMidSignal();
   ENUM_ENTRY_SIGNAL  DirectionalSignal();
public:
                     CConnorRsi(string symbol, ENUM_TIMEFRAMES period,
              int InputRsiPeriod=3, int InputCStrkPeriod=2, int InputCPRnkPeriod=100,
              double InptOBLevel=80, double InptOSLevel=20): CBaseIndicator(symbol, period)
     {
      m_RsiPeriod = InputRsiPeriod;
      m_StreakPeriod = InputCStrkPeriod;
      m_PercentRankPeriod = InputCPRnkPeriod;
      m_OverBoughtLevel = InptOBLevel;
      m_OverSoldLevel = InptOSLevel;
     }

   virtual bool        Init();
   virtual bool        Refresh(int ShiftToUse=1);
   virtual void        Release();

   double              GetData(int shift=0);
   void                GetData(double &buffer[], int shift=0);
   
   ENUM_ENTRY_SIGNAL   TradeSignal(ENUM_CNRRSI_Strategies signalOption);
  };


//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
bool CConnorRsi::Init(void)
  {
   ArraySetAsSeries(m_CConnorRsiBuffer, true);
   mCConnorRsiHandle= iCustom(m_Symbol, m_TF, "Articles\\Connors RSI", m_RsiPeriod,
                              m_StreakPeriod, m_PercentRankPeriod, PRICE_CLOSE);

   return mCConnorRsiHandle != INVALID_HANDLE;
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
bool CConnorRsi::Refresh(int ShiftToUse=1)
  {
   m_ShiftToUse = ShiftToUse;
   int rsiCopied = CopyBuffer(mCConnorRsiHandle, 0, 0, 6, m_CConnorRsiBuffer);
   return rsiCopied == 6;
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void CConnorRsi::Release(void)
  {
   IndicatorRelease(mCConnorRsiHandle);
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
double CConnorRsi::GetData(int shift=0)
  {
   if(shift >= m_RsiPeriod)
      return EMPTY_VALUE;

   return m_CConnorRsiBuffer[shift];
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void CConnorRsi::GetData(double &buffer[], int shift=0)
  {
   if(shift >= m_RsiPeriod)
      return;

   ArraySetAsSeries(buffer, true);
   ArrayResize(buffer, ArraySize(m_CConnorRsiBuffer) - shift);

   ArrayCopy(buffer, m_CConnorRsiBuffer, 0, shift);
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
ENUM_ENTRY_SIGNAL CConnorRsi::EnterOsOBSignal(void)
  {
   return CBaseIndicator::_EnterOsOBSignal(m_CConnorRsiBuffer, m_OverBoughtLevel, m_OverSoldLevel);
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
ENUM_ENTRY_SIGNAL CConnorRsi::ContraEnterOsOBSignal(void)
  {
   ENUM_ENTRY_SIGNAL signal = EnterOsOBSignal();
   return signal == ENTRY_SIGNAL_BUY ? ENTRY_SIGNAL_SELL :
          (signal == ENTRY_SIGNAL_SELL) ? ENTRY_SIGNAL_BUY : ENTRY_SIGNAL_NONE;
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
ENUM_ENTRY_SIGNAL CConnorRsi::ExitOsOBSignal(void)
  {
   return CBaseIndicator::_ExitOsOBSignal(m_CConnorRsiBuffer, m_OverBoughtLevel, m_OverSoldLevel);
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
ENUM_ENTRY_SIGNAL CConnorRsi::ContraExitOsOBSignal(void)
  {
   ENUM_ENTRY_SIGNAL signal = ExitOsOBSignal();
   return signal == ENTRY_SIGNAL_BUY ? ENTRY_SIGNAL_SELL :
          (signal == ENTRY_SIGNAL_SELL) ? ENTRY_SIGNAL_BUY : ENTRY_SIGNAL_NONE;
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
ENUM_ENTRY_SIGNAL CConnorRsi::CrossMidSignal(void)
  {
   return CBaseIndicator::_CrossMidSignal(m_CConnorRsiBuffer, (m_OverBoughtLevel + m_OverSoldLevel)/2);
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
ENUM_ENTRY_SIGNAL CConnorRsi::DirectionalSignal(void)
  {
   return CBaseIndicator::_DirectionalSignal(m_CConnorRsiBuffer);
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
ENUM_ENTRY_SIGNAL CConnorRsi::TradeSignal(ENUM_CNRRSI_Strategies signalOption)
  {
   switch(signalOption)
     {
      case CNRRSI_ContraEnterOsOBLevels:
         return ContraEnterOsOBSignal();
      case CNRRSI_ContraExitOsOBLevels:
         return ContraExitOsOBSignal();
      case CNRRSI_CrossMidLevel:
         return CrossMidSignal();
      case CNRRSI_Directional:
         return DirectionalSignal();
      case CNRRSI_EnterOsOBLevels:
         return EnterOsOBSignal();
      case CNRRSI_ExitOsOBLevels:
         return ExitOsOBSignal();
      default:
         return ENTRY_SIGNAL_NONE;
     }
  }
//+------------------------------------------------------------------+
