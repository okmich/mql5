//+------------------------------------------------------------------+
//|                                                   BoundedDpo.mqh |
//|                                    Copyright 2020, Michael Enudi |
//|                                             okmich2002@yahoo.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2020, Michael Enudi"
#property link      "okmich2002@yahoo.com"
#property version   "1.00"

#include "BaseIndicator.mqh"

enum ENUM_BDPO_Strategies
  {
   BDPO_EnterOsOBLevels,
   BDPO_ContraEnterOsOBLevels,
   BDPO_ExitOsOBLevels,
   BDPO_ContraExitOsOBLevels,
   BDPO_CrossMidLevel,
   BDPO_Directional
  };

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
class CBoundedDpo : public CBaseIndicator
  {
private :
   int                mBarsToCopy;
   //--- indicator paramter
   int                mPeriod, mPercentRankPeriod, mObLevel, mOsLevel;
   //--- indicator
   int                m_DpoHandle;
   //--- indicator buffer
   double             m_DpoBuffer[];

   ENUM_ENTRY_SIGNAL  EnterOsOBSignal();
   ENUM_ENTRY_SIGNAL  ContraEnterOsOBSignal();
   ENUM_ENTRY_SIGNAL  ExitOsOBSignal();
   ENUM_ENTRY_SIGNAL  ContraExitOsOBSignal();
   ENUM_ENTRY_SIGNAL  CrossMidSignal();
   ENUM_ENTRY_SIGNAL  DirectionalSignal();
public:
                     CBoundedDpo(string symbol, ENUM_TIMEFRAMES period, int InpDpoPeriod=10,
               int InptPRankPeriod = 252, int InptObLevel=90, int InptOsLevel=10,
               int InpBarsToInspect=10): CBaseIndicator(symbol, period)
     {
      mPeriod = InpDpoPeriod;
      mPercentRankPeriod = InptPRankPeriod;
      mObLevel = InptObLevel;
      mOsLevel = InptOsLevel;

      mBarsToCopy = InpBarsToInspect;
     }

   virtual bool                   Init();
   virtual bool                   Refresh(int ShiftToUse=1);
   virtual void                   Release();

   double                         GetData(int i);
   void                           GetData(double &buffer[], int shift=0);

   ENUM_ENTRY_SIGNAL              TradeSignal(ENUM_BDPO_Strategies signalOption);
  };

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
bool CBoundedDpo::Init(void)
  {
   ArraySetAsSeries(m_DpoBuffer, true);
   m_DpoHandle = iCustom(m_Symbol, m_TF, "Okmich\\Bounded DPO", mPeriod, mPercentRankPeriod);

   return m_DpoHandle != INVALID_HANDLE && mBarsToCopy > 2;
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
bool CBoundedDpo::Refresh(int ShiftToUse=1)
  {
   m_ShiftToUse = ShiftToUse;
   int dataCopied = CopyBuffer(m_DpoHandle, 0, 0, mBarsToCopy, m_DpoBuffer);
   return mBarsToCopy == dataCopied;
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void CBoundedDpo::Release(void)
  {
   IndicatorRelease(m_DpoHandle);
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
double CBoundedDpo::GetData(int i)
  {
   if(i >= mBarsToCopy)
      return EMPTY_VALUE;
   return m_DpoBuffer[i];
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void CBoundedDpo::GetData(double &buffer[], int shift=0)
  {
   if(shift >= mBarsToCopy)
      return;

   ArraySetAsSeries(buffer, true);
   ArrayResize(buffer, mBarsToCopy - shift);

   ArrayCopy(buffer, m_DpoBuffer, 0, shift);
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
ENUM_ENTRY_SIGNAL CBoundedDpo::EnterOsOBSignal(void)
  {
   return CBaseIndicator::_EnterOsOBSignal(m_DpoBuffer,mObLevel,mOsLevel);
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
ENUM_ENTRY_SIGNAL CBoundedDpo::ContraEnterOsOBSignal(void)
  {
   ENUM_ENTRY_SIGNAL signal = EnterOsOBSignal();
   return signal == ENTRY_SIGNAL_BUY ? ENTRY_SIGNAL_SELL :
          (signal == ENTRY_SIGNAL_SELL) ? ENTRY_SIGNAL_BUY : ENTRY_SIGNAL_NONE;
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
ENUM_ENTRY_SIGNAL CBoundedDpo::ExitOsOBSignal(void)
  {
   return CBaseIndicator::_ExitOsOBSignal(m_DpoBuffer,mObLevel,mOsLevel);
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
ENUM_ENTRY_SIGNAL CBoundedDpo::ContraExitOsOBSignal(void)
  {
   ENUM_ENTRY_SIGNAL signal = ExitOsOBSignal();
   return signal == ENTRY_SIGNAL_BUY ? ENTRY_SIGNAL_SELL :
          (signal == ENTRY_SIGNAL_SELL) ? ENTRY_SIGNAL_BUY : ENTRY_SIGNAL_NONE;
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
ENUM_ENTRY_SIGNAL CBoundedDpo::CrossMidSignal(void)
  {
   return CBaseIndicator::_CrossMidSignal(m_DpoBuffer, (mObLevel+mOsLevel)/2);
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
ENUM_ENTRY_SIGNAL CBoundedDpo::DirectionalSignal(void)
  {
   return CBaseIndicator::_DirectionalSignal(m_DpoBuffer);
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
ENUM_ENTRY_SIGNAL CBoundedDpo::TradeSignal(ENUM_BDPO_Strategies signalOption)
  {
   switch(signalOption)
     {
      case BDPO_ContraEnterOsOBLevels:
         return ContraEnterOsOBSignal();
      case BDPO_ContraExitOsOBLevels:
         return ContraExitOsOBSignal();
      case BDPO_CrossMidLevel:
         return CrossMidSignal();
      case BDPO_Directional:
         return DirectionalSignal();
      case BDPO_EnterOsOBLevels:
         return EnterOsOBSignal();
      case BDPO_ExitOsOBLevels:
         return ExitOsOBSignal();
      default:
         return ENTRY_SIGNAL_NONE;
     }
  }
//+------------------------------------------------------------------+
