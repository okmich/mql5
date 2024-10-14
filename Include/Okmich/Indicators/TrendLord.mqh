//+------------------------------------------------------------------+
//|                                                    TrendLord.mqh |
//|                                    Copyright 2021, Michael Enudi |
//|                                             okmich2002@yahoo.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2021, Michael Enudi"
#property link      "okmich2002@yahoo.com"

#include "BaseIndicator.mqh"

enum ENUM_TLD_Strategies
  {
   TLD_AboveBelowPrice,
   TLD_Direction
  };

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
class CTrendLord : public CBaseIndicator
  {
private :
   int                mBarsToCopy, mBarsToEstablishTrend;
   double             mTLShift1;
   //--- indicator paramter
   int                m_Period;
   //--- indicator
   int                m_Handle;
   //--- indicator buffer
   double             m_Buffer[];

   ENUM_ENTRY_SIGNAL  AboveBelowPriceSignal();
   ENUM_ENTRY_SIGNAL  DirectionalSignal();

public:
                     CTrendLord(string symbol, ENUM_TIMEFRAMES period, int InputPeriod=50,
              int InptBarCountForTrendInd = 3,
              int historyBars=240): CBaseIndicator(symbol, period)
     {
      m_Period = InputPeriod;
      mBarsToEstablishTrend = InptBarCountForTrendInd;
      mBarsToCopy = historyBars + 1;
     }

   virtual bool       Init();
   virtual bool       Refresh(int ShiftToUse=1);
   virtual void       Release();

   double             GetData(int shift=0);
   void               GetData(double &buffer[], int shift=0);

   double             PointInRange();

   ENUM_ENTRY_SIGNAL  TradeFilter(ENUM_TLD_Strategies signalOption);
  };

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
bool CTrendLord::Init(void)
  {
   ArraySetAsSeries(m_Buffer, true);

   m_Handle = iCustom(m_Symbol, m_TF, "Articles\\TrendLord", m_Period, PRICE_CLOSE);
   return m_Handle != INVALID_HANDLE;
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
bool CTrendLord::Refresh(int ShiftToUse=1)
  {
   m_ShiftToUse = ShiftToUse;
   int copied = CopyBuffer(m_Handle, 0, 0, mBarsToCopy, m_Buffer);
   mTLShift1 = m_Buffer[1];
   return mBarsToCopy == copied;
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void CTrendLord::Release(void)
  {
   IndicatorRelease(m_Handle);
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
double CTrendLord::GetData(int shift=0)
  {
   if(shift >= mBarsToCopy)
      return EMPTY_VALUE;

   return m_Buffer[shift];
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void CTrendLord::GetData(double &buffer[], int shift=0)
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
double CTrendLord::PointInRange(void)
  {
   double highestHigh = m_Buffer[ArrayMaximum(m_Buffer, 1, mBarsToCopy-1)];
   double lowestLow = m_Buffer[ArrayMinimum(m_Buffer, 1, mBarsToCopy-1)];
   double inputRange =  highestHigh - lowestLow;
   return (inputRange == 0) ? 0.0 : ((mTLShift1 - lowestLow)/inputRange);
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
ENUM_ENTRY_SIGNAL CTrendLord::AboveBelowPriceSignal(void)
  {
   double lastClose = iClose(m_Symbol, m_TF, 1);
   if(lastClose > m_Buffer[1])
      return ENTRY_SIGNAL_BUY;
   else
      if(lastClose < m_Buffer[1])
         return ENTRY_SIGNAL_SELL;
      else
         return ENTRY_SIGNAL_NONE;
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
ENUM_ENTRY_SIGNAL CTrendLord::DirectionalSignal(void)
  {
   if(m_Buffer[2] < m_Buffer[1])
      return ENTRY_SIGNAL_BUY;
   else
      if(m_Buffer[2] > m_Buffer[1])
         return ENTRY_SIGNAL_SELL;
      else
         return ENTRY_SIGNAL_NONE;
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
ENUM_ENTRY_SIGNAL CTrendLord::TradeFilter(ENUM_TLD_Strategies signalOption)
  {
   switch(signalOption)
     {
      case TLD_AboveBelowPrice:
         return AboveBelowPriceSignal();
      case TLD_Direction:
         return DirectionalSignal();
      default:
         return ENTRY_SIGNAL_NONE;
     }
  }
//+------------------------------------------------------------------+
