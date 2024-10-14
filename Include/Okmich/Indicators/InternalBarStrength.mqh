//+------------------------------------------------------------------+
//|                                          InternalBarStrength.mqh |
//|                                    Copyright 2022, Michael Enudi |
//|                                             okmich2002@yahoo.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2022, Michael Enudi"
#property link      "okmich2002@yahoo.com"
#property version   "1.00"

#include "BaseIndicator.mqh"

enum ENUM_IBS_Strategies
  {
   IBS_EnterOsOBLevels,
   IBS_ContraEnterOsOBLevels,
   IBS_ExitOsOBLevels,
   IBS_ContraExitOsOBLevels,
  };

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
class CIbs : public CBaseIndicator
  {
private :
   int                m_HistoryBars;
   //--- indicator paramter
   double             m_ObLevel, m_OsLevel;
   int                m_SmoothPeriod;
   //--- indicator handle
   int                mHandle;
   //--- indicator buffer

   ENUM_ENTRY_SIGNAL  EnterOsOBSignal();
   ENUM_ENTRY_SIGNAL  ContraEnterOsOBSignal();
   ENUM_ENTRY_SIGNAL  ExitOsOBSignal();
   ENUM_ENTRY_SIGNAL  ContraExitOsOBSignal();

public:
                     CIbs(string symbol, ENUM_TIMEFRAMES period,
        double InptOBLevel=0.8, double InptOSLevel=0.2,
        bool InptSmoothing=false, int InptSmoothingPeriod=2): CBaseIndicator(symbol, period)
     {
      m_ObLevel = InptOBLevel;
      m_OsLevel = InptOSLevel;

      m_HistoryBars = InptSmoothingPeriod;
      m_SmoothPeriod = InptSmoothing ? InptSmoothingPeriod : -1;
     }

   virtual bool       Init();
   virtual bool       Refresh(int ShiftToUse=1);
   virtual void       Release();

   double             IBS(int shift=0);
   double             GetData(int shift=0);

   ENUM_ENTRY_SIGNAL  TradeSignal(ENUM_IBS_Strategies signalOption);
  };


//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
bool CIbs::Init(void)
  {
   if(m_SmoothPeriod != -1 && m_SmoothPeriod < 2)
     {
      SetUserError(1001); //IBS period cannot be less than 2 when smoothing is enabled
      return false;
     }
   return true;
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
bool CIbs::Refresh(int ShiftToUse=1)
  {
   m_ShiftToUse = ShiftToUse;
   return true;
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void CIbs::Release(void)
  {
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
double CIbs::IBS(int shift=0)
  {
   double closeShift = iClose(m_Symbol, m_TF, shift);
   double highShift = iHigh(m_Symbol, m_TF, shift);
   double lowShift = iLow(m_Symbol, m_TF, shift);

   double range = highShift - lowShift;
   return range <= 0 ? 0 : (closeShift-lowShift)/range;
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
double CIbs::GetData(int shift=0)
  {
   double ibsShift1 = EMPTY_VALUE;
   if(m_SmoothPeriod == -1)   // no smoothing
     {
      ibsShift1 = IBS(m_ShiftToUse);
     }
   else
     {
      double sum = 0;
      for(int i = m_ShiftToUse; i < m_HistoryBars+m_ShiftToUse; i++)
         sum += IBS(i);

      ibsShift1 = sum/m_HistoryBars;
     }
     return ibsShift1;
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
ENUM_ENTRY_SIGNAL CIbs::EnterOsOBSignal()
  {
   double ibsShift1 = GetData(m_ShiftToUse);
   if(ibsShift1 > m_ObLevel)
      return ENTRY_SIGNAL_SELL;
   else
      if(ibsShift1 < m_OsLevel)
         return ENTRY_SIGNAL_BUY;
      else
         return ENTRY_SIGNAL_NONE;
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
ENUM_ENTRY_SIGNAL CIbs::ContraEnterOsOBSignal(void)
  {
   ENUM_ENTRY_SIGNAL signal = EnterOsOBSignal();
   if(signal == ENTRY_SIGNAL_NONE)
      return signal;
   else
      return signal == ENTRY_SIGNAL_BUY ? ENTRY_SIGNAL_SELL : ENTRY_SIGNAL_BUY;
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
ENUM_ENTRY_SIGNAL CIbs::ExitOsOBSignal()
  {
   double ibsShift1 = GetData(m_ShiftToUse);
   double ibsShift2 = GetData(m_ShiftToUse+1);
   if(ibsShift1 > m_ObLevel && ibsShift2 < m_ObLevel)
      return ENTRY_SIGNAL_SELL;
   else
      if(ibsShift1 < m_OsLevel && ibsShift1 > m_OsLevel)
         return ENTRY_SIGNAL_BUY;
      else
         return ENTRY_SIGNAL_NONE;
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
ENUM_ENTRY_SIGNAL CIbs::ContraExitOsOBSignal(void)
  {
   ENUM_ENTRY_SIGNAL signal = ExitOsOBSignal();
   if(signal == ENTRY_SIGNAL_NONE)
      return signal;
   else
      return signal == ENTRY_SIGNAL_BUY ? ENTRY_SIGNAL_SELL : ENTRY_SIGNAL_BUY;
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
ENUM_ENTRY_SIGNAL CIbs::TradeSignal(ENUM_IBS_Strategies signalOption)
  {
   switch(signalOption)
     {
      case IBS_ContraEnterOsOBLevels:
         return ContraEnterOsOBSignal();
      case IBS_ContraExitOsOBLevels:
         return ContraExitOsOBSignal();
      case IBS_EnterOsOBLevels:
         return EnterOsOBSignal();
      case IBS_ExitOsOBLevels:
         return ExitOsOBSignal();
      default:
         return ENTRY_SIGNAL_NONE;
     }
  }
//+------------------------------------------------------------------+
