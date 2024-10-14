//+------------------------------------------------------------------+
//|                                             SchaffTrendCycle.mqh |
//|                                    Copyright 2021, Michael Enudi |
//|                                             okmich2002@yahoo.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2021, Michael Enudi"
#property link      "okmich2002@yahoo.com"

#include "BaseIndicator.mqh"

enum ENUM_STC_Strategies
  {
   STC_CrossesMidLevels,
   STC_EntersObOsLevels,
   STC_ContraEntersObOsLevels,
   STC_ExitsObOsLevels,
   STC_ContraExitsObOsLevels,
   STC_GoingUpOrDown
  };

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
class CSchaffTrendCycle : public CBaseIndicator
  {
private :
   int                mScore;
   int                mBarsToCopy;

   double             mStcValue, mStcSlope;
   //--- indicator paramter
   int                m_Period, m_FastEmaPeriod, m_SlowEmaPeriod, m_SmoothingPeriod, m_OsLevel, m_ObLevel;
   ENUM_APPLIED_PRICE m_AppliedPrice;
   //--- indicator
   int                m_Handle;
   //--- indicator buffer
   double             m_Buffer[];

   ENUM_ENTRY_SIGNAL  CrossesMidLevelsSignal();
   ENUM_ENTRY_SIGNAL  DirectionalSignal();
   ENUM_ENTRY_SIGNAL  EntersObOsLevelsSignal();
   ENUM_ENTRY_SIGNAL  ContraEntersObOsLevelsSignal();
   ENUM_ENTRY_SIGNAL  ExitsObOsLevelsSignal();
   ENUM_ENTRY_SIGNAL  ContraExitsObOsLevelsSignal();

public:
                     CSchaffTrendCycle(string symbol, ENUM_TIMEFRAMES period, int InputPeriod=32,
                     int InputFastEma=23,int InputSlowEma=50,int InputSmoothing=3,
                     int InputOBlevel=80, int historyBars=10): CBaseIndicator(symbol, period)
     {
      m_Period = InputPeriod;
      m_FastEmaPeriod = InputFastEma;
      m_SlowEmaPeriod = InputSlowEma;
      m_SmoothingPeriod = InputSmoothing;
      m_ObLevel = InputOBlevel;
      m_OsLevel = 100 - InputOBlevel;

      mBarsToCopy = historyBars;
     }

   virtual bool       Init();
   virtual bool       Refresh(int ShiftToUse=1);
   virtual void       Release();

   double             GetData(int shift=0);
   void               GetData(double &buffer[], int shift=0);

   ENUM_ENTRY_SIGNAL  TradeSignal(ENUM_STC_Strategies strategyOption);
  };

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
bool CSchaffTrendCycle::Init(void)
  {
   ArraySetAsSeries(m_Buffer, true);

   m_Handle = iCustom(m_Symbol, m_TF, "Articles\\Schaff Trend Cycle", m_Period, m_FastEmaPeriod, m_SlowEmaPeriod,
                      m_SmoothingPeriod, m_AppliedPrice);
   return m_Handle != INVALID_HANDLE;
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
bool CSchaffTrendCycle::Refresh(int ShiftToUse=1)
  {
   m_ShiftToUse = ShiftToUse;
   int copied = CopyBuffer(m_Handle, 0, 0, mBarsToCopy, m_Buffer);

   mStcValue = m_Buffer[1];
   mStcSlope = m_Buffer[1] - m_Buffer[2];

   return mBarsToCopy == copied;
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void CSchaffTrendCycle::Release(void)
  {
   IndicatorRelease(m_Handle);
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
double CSchaffTrendCycle::GetData(int shift=0)
  {
   if(shift >= mBarsToCopy)
      return EMPTY_VALUE;

   return m_Buffer[shift];
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void CSchaffTrendCycle::GetData(double &buffer[], int shift=0)
  {
   if(shift >= mBarsToCopy)
      return;

   ArraySetAsSeries(buffer, true);
   ArrayResize(buffer, mBarsToCopy - shift);

   ArrayCopy(buffer, m_Buffer, 0, shift);
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
ENUM_ENTRY_SIGNAL CSchaffTrendCycle::CrossesMidLevelsSignal(void)
  {
   return m_Buffer[1] < 50 ? ENTRY_SIGNAL_SELL :
          m_Buffer[1] > 50 ? ENTRY_SIGNAL_BUY : ENTRY_SIGNAL_NONE;
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
ENUM_ENTRY_SIGNAL CSchaffTrendCycle::DirectionalSignal(void)
  {
   return m_Buffer[2] < m_Buffer[1] ? ENTRY_SIGNAL_BUY :
          m_Buffer[2] > m_Buffer[1] ? ENTRY_SIGNAL_SELL : ENTRY_SIGNAL_NONE;
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
ENUM_ENTRY_SIGNAL CSchaffTrendCycle::EntersObOsLevelsSignal(void)
  {
   if(m_Buffer[2] <= m_ObLevel && m_Buffer[1] > m_ObLevel)
      return ENTRY_SIGNAL_SELL;
   else
      if(m_Buffer[2] >= m_OsLevel && m_Buffer[1] < m_OsLevel)
         return ENTRY_SIGNAL_BUY;
      else
         return ENTRY_SIGNAL_NONE;
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
ENUM_ENTRY_SIGNAL CSchaffTrendCycle::ContraEntersObOsLevelsSignal(void)
  {
   ENUM_ENTRY_SIGNAL signal = EntersObOsLevelsSignal();

   return signal == ENTRY_SIGNAL_BUY ? ENTRY_SIGNAL_SELL :
          signal == ENTRY_SIGNAL_SELL  ? ENTRY_SIGNAL_BUY : ENTRY_SIGNAL_NONE;
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
ENUM_ENTRY_SIGNAL CSchaffTrendCycle::ExitsObOsLevelsSignal(void)
  {
   if(m_Buffer[2] >= m_ObLevel && m_Buffer[1] < m_ObLevel)
      return ENTRY_SIGNAL_SELL;
   else
      if(m_Buffer[2] <= m_OsLevel && m_Buffer[1] > m_OsLevel)
         return ENTRY_SIGNAL_BUY;
      else
         return ENTRY_SIGNAL_NONE;
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
ENUM_ENTRY_SIGNAL CSchaffTrendCycle::ContraExitsObOsLevelsSignal(void)
  {
   ENUM_ENTRY_SIGNAL signal = ExitsObOsLevelsSignal();

   return signal == ENTRY_SIGNAL_BUY ? ENTRY_SIGNAL_SELL :
          signal == ENTRY_SIGNAL_SELL  ? ENTRY_SIGNAL_BUY : ENTRY_SIGNAL_NONE;
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
ENUM_ENTRY_SIGNAL CSchaffTrendCycle::TradeSignal(ENUM_STC_Strategies strategyOption)
  {
   switch(strategyOption)
     {
      case STC_ContraEntersObOsLevels:
         return ContraEntersObOsLevelsSignal();
      case STC_ContraExitsObOsLevels:
         return ContraExitsObOsLevelsSignal();
      case STC_CrossesMidLevels:
         return CrossesMidLevelsSignal();
      case STC_EntersObOsLevels:
         return EntersObOsLevelsSignal();
      case STC_ExitsObOsLevels:
         return ExitsObOsLevelsSignal();
      case STC_GoingUpOrDown:
         return DirectionalSignal();
      default:
         return ENTRY_SIGNAL_NONE;
     }
  }
//+------------------------------------------------------------------+
