//+------------------------------------------------------------------+
//|                                               MoneyFlowTrend.mqh |
//|                                    Copyright 2020, Michael Enudi |
//|                                             okmich2002@yahoo.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2020, Michael Enudi"
#property link      "okmich2002@yahoo.com"
#property version   "1.00"

#include "BaseIndicator.mqh"

const string AD_IND = "Okmich\\AccumulationDistribution";
const string MFT_IND = "Okmich\\Money Flow Trend";

enum ENUM_MF_CALC_TYPE
  {
   MF_CALC_TYPE_AD,
   MF_CALC_TYPE_OBV,
   MF_CALC_TYPE_PRESSURE
  };

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
class CMoneyFlowTrend : public CBaseIndicator
  {
private :
   int                mBarsToCopy;
   //--- indicator paramter
   ENUM_MF_CALC_TYPE    mCalculationType;
   ENUM_APPLIED_VOLUME  mAppliedVolume;
   int                  mSmoothing;
   ENUM_MA_METHOD       mSmoothingMethod;

   //--- indicator
   int                m_IndHandle;
   //--- indicator buffer
   double             mIndBuffer[], mSlopeBuffer[];

   bool               allPositiveSlope(int idx, int bars);
   bool               allNegativeSlope(int idx, int bars);

public:
                     CMoneyFlowTrend(string symbol, ENUM_TIMEFRAMES period,
                   ENUM_MF_CALC_TYPE calculationType = MF_CALC_TYPE_PRESSURE,
                   ENUM_APPLIED_VOLUME appliedVolType = VOLUME_TICK,
                   int InpSmoothing=12,
                   ENUM_MA_METHOD smoothingMethod = MODE_SMA,
                   int historyBars=6): CBaseIndicator(symbol, period)
     {
      mCalculationType = calculationType;
      mAppliedVolume = appliedVolType;
      mSmoothing = InpSmoothing;
      mSmoothingMethod = smoothingMethod;
      mBarsToCopy = historyBars;
     }

   virtual bool                   Init();
   virtual bool                   Refresh(int ShiftToUse=1);
   virtual void                   Release();

   double                         GetData(int buffer=0, int shift=0);
   void                           GetData(double &buffer[], int buffer=0, int shift=0);

   int                            Trend(int shift=1, int consecutiveBars=4); //1 => BULL, -1=BEAR
   int                            MoneyFlow(int shift=1); //1 => BULL, -1=BEAR
   int                            MoneyFlowSlope(int shift=1); //1 => BULL, -1=BEAR
   
   ENUM_ENTRY_SIGNAL              TradeSignal();
  };

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
bool CMoneyFlowTrend::Init(void)
  {
   ArraySetAsSeries(mIndBuffer, true);
   ArraySetAsSeries(mSlopeBuffer, true);

   switch(mCalculationType)
     {
      case MF_CALC_TYPE_AD:
         m_IndHandle = iCustom(m_Symbol, m_TF, AD_IND, mAppliedVolume, mSmoothing, mSmoothingMethod);
         break;
      case MF_CALC_TYPE_PRESSURE:
      default:
         m_IndHandle = iCustom(m_Symbol, m_TF, MFT_IND, mAppliedVolume, mSmoothing, mSmoothingMethod);
     }

   return m_IndHandle != INVALID_HANDLE;
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
ENUM_ENTRY_SIGNAL CMoneyFlowTrend::TradeSignal()
  {
   int flag = Trend(1, 4) + MoneyFlowSlope(1) + MoneyFlow(1);

   if(flag == 3)
      return ENTRY_SIGNAL_BUY;
   else
      if(flag == -3)
         return ENTRY_SIGNAL_SELL;
      else
         return ENTRY_SIGNAL_NONE;
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
bool CMoneyFlowTrend::Refresh(int ShiftToUse=1)
  {
   m_ShiftToUse = ShiftToUse;
   int dataCopied = CopyBuffer(m_IndHandle, 0, 0, mBarsToCopy, mIndBuffer);
   int slopeDataCopied = CopyBuffer(m_IndHandle, 1, 0, mBarsToCopy, mSlopeBuffer);

   return mBarsToCopy == dataCopied && dataCopied == slopeDataCopied;
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void CMoneyFlowTrend::Release(void)
  {
   IndicatorRelease(m_IndHandle);
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
double CMoneyFlowTrend::GetData(int buffer=0, int shift=0)
  {
   if(shift >= mBarsToCopy || buffer > 1)
      return EMPTY_VALUE;

   return buffer == 0 ? mIndBuffer[shift] : mSlopeBuffer[shift];
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void CMoneyFlowTrend::GetData(double &buffer[], int bufferIndx=0, int shift=0)
  {
   if(shift >= mBarsToCopy || bufferIndx > 1)
      return;

   ArraySetAsSeries(buffer, true);
   ArrayResize(buffer, ArraySize(mIndBuffer) - shift);

   if(bufferIndx ==0)
      ArrayCopy(buffer, mIndBuffer, 0, shift);
   else
      ArrayCopy(buffer, mSlopeBuffer, 0, shift);
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
int CMoneyFlowTrend::Trend(int shift=1,int consecutiveBars=4)
  {
   if(consecutiveBars >= mBarsToCopy)
      return 0;

   if(shift >= mBarsToCopy)
      return 0;

   int moneyFlow = 0;
   if(allPositiveSlope(shift, consecutiveBars))
      return 1;

   if(allNegativeSlope(shift, consecutiveBars))
      return -1;

   return moneyFlow;

  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
int CMoneyFlowTrend::MoneyFlow(int shift=1)
  {
   if(shift >= mBarsToCopy)
      return 0;

   return (mIndBuffer[shift] > mSlopeBuffer[shift]) ? 1 : (mIndBuffer[shift] < mSlopeBuffer[shift]) ? -1 : 0;
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
int CMoneyFlowTrend::MoneyFlowSlope(int shift=1)
  {
   if(shift >= mBarsToCopy - 1)
      return 0;

   return (mIndBuffer[shift] > mIndBuffer[shift+1]) ? 1 : (mIndBuffer[shift] < mIndBuffer[shift+1]) ? -1 : 0;
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
bool CMoneyFlowTrend::allPositiveSlope(int idx, int bars)
  {
   for(int i = idx; i < bars; i++)
      if(mSlopeBuffer[i] <= mSlopeBuffer[i-1])
         return false;

   return true;
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
bool CMoneyFlowTrend::allNegativeSlope(int idx,int bars)
  {
   for(int i = idx; i < bars; i++)
      if(mSlopeBuffer[i] >= mSlopeBuffer[i-1])
         return false;

   return true;
  }
//+------------------------------------------------------------------+
