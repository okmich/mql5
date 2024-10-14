//+------------------------------------------------------------------+
//|                                                   AggregateM.mqh |
//|                                    Copyright 2022, Michael Enudi |
//|                                             okmich2002@yahoo.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2022, Michael Enudi"
#property link      "okmich2002@yahoo.com"
#property version   "1.00"

#include "BaseIndicator.mqh"

enum ENUM_AGGM_Strategies
  {
   AGGM_EnterOsOBLevels,
   AGGM_ContraEnterOsOBLevels,
   AGGM_ExitOsOBLevels,
   AGGM_ContraExitOsOBLevels,
   AGGM_CrossMidLevel,
   AGGM_Directional,
   AGGM_SignalCrossover
  };

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
class CAggregateM : public CBaseIndicator
  {
private :
   int                mBarsToCopy;
   //--- indicator paramter
   int                mShortRankPeriod, mLongRankPeriod, mSignalPeriod;
   double             mObLevel, mOsLevel;
   //--- indicator
   int                m_Handle;
   //--- indicator buffer
   double             m_Buffer[], m_SignalBuffer[];

   ENUM_ENTRY_SIGNAL  EnterOsOBSignal();
   ENUM_ENTRY_SIGNAL  ContraEnterOsOBSignal();
   ENUM_ENTRY_SIGNAL  ExitOsOBSignal();
   ENUM_ENTRY_SIGNAL  ContraExitOsOBSignal();
   ENUM_ENTRY_SIGNAL  CrossMidSignal();
   ENUM_ENTRY_SIGNAL  DirectionalSignal();
   ENUM_ENTRY_SIGNAL  SignalCrossover();

public:
                     CAggregateM(string symbol, ENUM_TIMEFRAMES period,
               int InputShortRankPeriod=10, int InputLongRankPeriod=252, int InputSignalPeriod=3,
               double InptOBLevel = 80, double InptOSLevel = 20, int InpBarsToInspect=6): CBaseIndicator(symbol, period)
     {
      mShortRankPeriod = InputShortRankPeriod;
      mLongRankPeriod = InputLongRankPeriod;
      mSignalPeriod = InputSignalPeriod;

      mObLevel = InptOBLevel;
      mOsLevel = InptOSLevel;

      mBarsToCopy = InpBarsToInspect;
     }

   virtual bool       Init();
   virtual bool       Refresh(int ShiftToUse=1);
   virtual void       Release();

   double             GetData(int i);
   void               GetData(double &buffer[], int shift=0);

   ENUM_ENTRY_SIGNAL  TradeSignal(ENUM_AGGM_Strategies signalOption);
  };

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
bool CAggregateM::Init(void)
  {
   ArraySetAsSeries(m_Buffer, true);
   ArraySetAsSeries(m_SignalBuffer, true);

   m_Handle = iCustom(m_Symbol, m_TF, "Okmich\\Aggregate M", mLongRankPeriod, mShortRankPeriod, mSignalPeriod);
   return m_Handle != INVALID_HANDLE && mBarsToCopy > 2;
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
bool CAggregateM::Refresh(int ShiftToUse=1)
  {
   m_ShiftToUse = ShiftToUse;
   int dataCopied = CopyBuffer(m_Handle, 0, 0, mBarsToCopy, m_Buffer);
   int signalCopied = CopyBuffer(m_Handle, 1, 0, mBarsToCopy, m_SignalBuffer);
   return mBarsToCopy == dataCopied && dataCopied == signalCopied;
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void CAggregateM::Release(void)
  {
   IndicatorRelease(m_Handle);
  }


//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
double CAggregateM::GetData(int i)
  {
   if(i >= mBarsToCopy)
      return EMPTY_VALUE;
   return m_Buffer[i];
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void CAggregateM::GetData(double &buffer[], int shift=0)
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
ENUM_ENTRY_SIGNAL CAggregateM::EnterOsOBSignal(void)
  {
   return CBaseIndicator::_EnterOsOBSignal(m_Buffer,mObLevel,mOsLevel);
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
ENUM_ENTRY_SIGNAL CAggregateM::ContraEnterOsOBSignal(void)
  {
   ENUM_ENTRY_SIGNAL signal = EnterOsOBSignal();
   return signal == ENTRY_SIGNAL_BUY ? ENTRY_SIGNAL_SELL :
          (signal == ENTRY_SIGNAL_SELL) ? ENTRY_SIGNAL_BUY : ENTRY_SIGNAL_NONE;
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
ENUM_ENTRY_SIGNAL CAggregateM::ExitOsOBSignal(void)
  {
   return CBaseIndicator::_ExitOsOBSignal(m_Buffer,mObLevel,mOsLevel);
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
ENUM_ENTRY_SIGNAL CAggregateM::ContraExitOsOBSignal(void)
  {
   ENUM_ENTRY_SIGNAL signal = ExitOsOBSignal();
   return signal == ENTRY_SIGNAL_BUY ? ENTRY_SIGNAL_SELL :
          (signal == ENTRY_SIGNAL_SELL) ? ENTRY_SIGNAL_BUY : ENTRY_SIGNAL_NONE;
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
ENUM_ENTRY_SIGNAL CAggregateM::CrossMidSignal(void)
  {
   return CBaseIndicator::_CrossMidSignal(m_Buffer, (mObLevel+mOsLevel)/2);
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
ENUM_ENTRY_SIGNAL CAggregateM::DirectionalSignal(void)
  {
   return CBaseIndicator::_DirectionalSignal(m_Buffer);
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
ENUM_ENTRY_SIGNAL CAggregateM::SignalCrossover(void)
  {
   if(m_Buffer[2] > m_SignalBuffer[2] && m_Buffer[1] < m_SignalBuffer[1])
      return ENTRY_SIGNAL_SELL;
   else
      if(m_Buffer[2] < m_SignalBuffer[2] && m_Buffer[1] > m_SignalBuffer[1])
         return ENTRY_SIGNAL_BUY;
   return ENTRY_SIGNAL_NONE;
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
ENUM_ENTRY_SIGNAL CAggregateM::TradeSignal(ENUM_AGGM_Strategies signalOption)
  {
   switch(signalOption)
     {
      case AGGM_ContraEnterOsOBLevels:
         return ContraEnterOsOBSignal();
      case AGGM_ContraExitOsOBLevels:
         return ContraExitOsOBSignal();
      case AGGM_CrossMidLevel:
         return CrossMidSignal();
      case AGGM_Directional:
         return DirectionalSignal();
      case AGGM_EnterOsOBLevels:
         return EnterOsOBSignal();
      case AGGM_ExitOsOBLevels:
         return ExitOsOBSignal();
      case AGGM_SignalCrossover:
         return SignalCrossover();
      default:
         return ENTRY_SIGNAL_NONE;
     }
  }
//+------------------------------------------------------------------+
