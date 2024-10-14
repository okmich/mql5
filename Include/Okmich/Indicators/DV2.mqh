//+------------------------------------------------------------------+
//|                                                          DV2.mqh |
//|                                    Copyright 2020, Michael Enudi |
//|                                             okmich2002@yahoo.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2020, Michael Enudi"
#property link      "okmich2002@yahoo.com"
#property version   "1.00"

#include "BaseIndicator.mqh"

enum ENUM_DVO_Strategies
  {
   DVO_EnterOsOBLevels,
   DVO_ContraEnterOsOBLevels,
   DVO_ExitOsOBLevels,
   DVO_ContraExitOsOBLevels,
   DVO_CrossMidLevel,
   DVO_Directional
  };

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
class CDvo : public CBaseIndicator
  {
private :
   int                mBarsToCopy;
   //--- indicator paramter
   int                mMaPeriod, mPRankPeriod;
   double             mObLevel, mOsLevel;
   //--- indicator
   int                m_DvoHandle;
   //--- indicator buffer
   double             mDvoBuffer[];
   
   ENUM_ENTRY_SIGNAL  EnterOsOBSignal();
   ENUM_ENTRY_SIGNAL  ContraEnterOsOBSignal();
   ENUM_ENTRY_SIGNAL  ExitOsOBSignal();
   ENUM_ENTRY_SIGNAL  ContraExitOsOBSignal();
   ENUM_ENTRY_SIGNAL  CrossMidSignal();
   ENUM_ENTRY_SIGNAL  DirectionalSignal();

public:
                     CDvo(string symbol, ENUM_TIMEFRAMES period, int InputMaPeriod=2,
        int InptPRankPeriod=2, double InptOBLevel = 80, double InptOSLevel = 20,
        int InpBarsToInspect=6): CBaseIndicator(symbol, period)
     {
      mMaPeriod = InputMaPeriod;
      mPRankPeriod = InptPRankPeriod;
      mObLevel = InptOBLevel;
      mOsLevel = InptOSLevel;
      mBarsToCopy = InpBarsToInspect;
     }

   virtual bool       Init();
   virtual bool       Refresh(int ShiftToUse=1);
   virtual void       Release();

   double             GetData(int i);
   void               GetData(double &buffer[], int shift=0);
   
   ENUM_ENTRY_SIGNAL  TradeSignal(ENUM_DVO_Strategies signalOption);
  };

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
bool CDvo::Init(void)
  {
   ArraySetAsSeries(mDvoBuffer, true);

   m_DvoHandle = iCustom(m_Symbol, m_TF, "Okmich\\DV2", mMaPeriod, mPRankPeriod);
   return m_DvoHandle != INVALID_HANDLE && mBarsToCopy > 2;
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
bool CDvo::Refresh(int ShiftToUse=1)
  {
   m_ShiftToUse = ShiftToUse;
   int dataCopied = CopyBuffer(m_DvoHandle, 0, 0, mBarsToCopy, mDvoBuffer);
   return mBarsToCopy == dataCopied;
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void CDvo::Release(void)
  {
   IndicatorRelease(m_DvoHandle);
  }


//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
double CDvo::GetData(int i)
  {
   if(i >= mBarsToCopy)
      return EMPTY_VALUE;
   return mDvoBuffer[i];
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void CDvo::GetData(double &buffer[], int shift=0)
  {
   if(shift >= mBarsToCopy)
      return;

   ArraySetAsSeries(buffer, true);
   ArrayResize(buffer, mBarsToCopy - shift);

   ArrayCopy(buffer, mDvoBuffer, 0, shift);
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
ENUM_ENTRY_SIGNAL CDvo::EnterOsOBSignal(void)
  {
   return CBaseIndicator::_EnterOsOBSignal(mDvoBuffer,mObLevel,mOsLevel);
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
ENUM_ENTRY_SIGNAL CDvo::ContraEnterOsOBSignal(void)
  {
   ENUM_ENTRY_SIGNAL signal = EnterOsOBSignal();
   return signal == ENTRY_SIGNAL_BUY ? ENTRY_SIGNAL_SELL :
          (signal == ENTRY_SIGNAL_SELL) ? ENTRY_SIGNAL_BUY : ENTRY_SIGNAL_NONE;
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
ENUM_ENTRY_SIGNAL CDvo::ExitOsOBSignal(void)
  {
   return CBaseIndicator::_ExitOsOBSignal(mDvoBuffer,mObLevel,mOsLevel);
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
ENUM_ENTRY_SIGNAL CDvo::ContraExitOsOBSignal(void)
  {
   ENUM_ENTRY_SIGNAL signal = ExitOsOBSignal();
   return signal == ENTRY_SIGNAL_BUY ? ENTRY_SIGNAL_SELL :
          (signal == ENTRY_SIGNAL_SELL) ? ENTRY_SIGNAL_BUY : ENTRY_SIGNAL_NONE;
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
ENUM_ENTRY_SIGNAL CDvo::CrossMidSignal(void)
  {
   return CBaseIndicator::_CrossMidSignal(mDvoBuffer, (mObLevel+mOsLevel)/2);
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
ENUM_ENTRY_SIGNAL CDvo::DirectionalSignal(void)
  {
   return CBaseIndicator::_DirectionalSignal(mDvoBuffer);
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
ENUM_ENTRY_SIGNAL CDvo::TradeSignal(ENUM_DVO_Strategies signalOption)
  {
   switch(signalOption)
     {
      case DVO_ContraEnterOsOBLevels:
         return ContraEnterOsOBSignal();
      case DVO_ContraExitOsOBLevels:
         return ContraExitOsOBSignal();
      case DVO_CrossMidLevel:
         return CrossMidSignal();
      case DVO_Directional:
         return DirectionalSignal();
      case DVO_EnterOsOBLevels:
         return EnterOsOBSignal();
      case DVO_ExitOsOBLevels:
         return ExitOsOBSignal();
      default:
         return ENTRY_SIGNAL_NONE;
     }
  }
//+------------------------------------------------------------------+
