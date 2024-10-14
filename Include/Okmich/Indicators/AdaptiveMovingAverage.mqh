//+------------------------------------------------------------------+
//|                                    AdaptiveMovingAverage.mqh.mqh |
//|                                    Copyright 2022, Michael Enudi |
//|                                             okmich2002@yahoo.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2022, Michael Enudi"
#property link      "okmich2002@yahoo.com"
#property version   "1.00"

#include "BaseIndicator.mqh"

enum ENUM_AMA_Strategies
  {
   AMA_PriceAboveBelowLine,
   AMA_BarsRisingFalling,
   AMA_Slope
  };

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
class CAma : public CBaseIndicator
  {
private :
   int                mBarsToCopy;
   //--- indicator paramter
   int                m_Period, m_FastMaPeriod, m_SlowMaPeriod, m_SlopCalcPeriod;
   //--- indicator handle
   int                m_Handle;
   //--- indicator buffer
   double             m_Buffer[];

   ENUM_ENTRY_SIGNAL  PriceAboveOrBelowLineFilter();
   ENUM_ENTRY_SIGNAL  SlopeFilter();
   ENUM_ENTRY_SIGNAL  RisingOrFalling();

public:
                     CAma(string symbol, ENUM_TIMEFRAMES period,
        int InputPeriod=9, int InputFastMaPeriod=2, int InputSlowMaPeriod=30,
        int InputHistoryPeriod = 3): CBaseIndicator(symbol, period)
     {
      m_Period = InputPeriod;
      m_FastMaPeriod = InputFastMaPeriod;
      m_SlowMaPeriod = InputSlowMaPeriod;
      m_SlopCalcPeriod = InputHistoryPeriod;

      mBarsToCopy = InputHistoryPeriod + 2;
     }

   virtual bool       Init();
   virtual bool       Refresh(int ShiftToUse=1);
   virtual void       Release();

   double             GetData(int shift=0);
   void               GetData(double &buffer[], int shift=0);

   ENUM_ENTRY_SIGNAL  TradeFilter(ENUM_AMA_Strategies strategy);
  };

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
bool CAma::Init(void)
  {
   ArraySetAsSeries(m_Buffer, true);
   m_Handle = iAMA(m_Symbol, m_TF, m_Period, m_FastMaPeriod, m_SlowMaPeriod, 0, PRICE_CLOSE);
   return m_Handle != INVALID_HANDLE;
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
bool CAma::Refresh(int ShiftToUse=1)
  {
   m_ShiftToUse = ShiftToUse;
   int maCopied = CopyBuffer(m_Handle, 0, 0, mBarsToCopy, m_Buffer);
   return maCopied == mBarsToCopy;
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void CAma::Release(void)
  {
   IndicatorRelease(m_Handle);
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
double CAma::GetData(int shift=0)
  {
   if(shift >= m_Period)
      return EMPTY_VALUE;

   return m_Buffer[shift];
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void CAma::GetData(double &buffer[], int shift=0)
  {
   if(shift >= m_Period)
      return;

   ArraySetAsSeries(buffer, true);
   ArrayResize(buffer, ArraySize(m_Buffer) - shift);

   ArrayCopy(buffer, m_Buffer, 0, shift);
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
ENUM_ENTRY_SIGNAL CAma::TradeFilter(ENUM_AMA_Strategies strategy)
  {
   switch(strategy)
     {
      case AMA_BarsRisingFalling:
         return RisingOrFalling();
      case AMA_PriceAboveBelowLine:
         return PriceAboveOrBelowLineFilter();
      case AMA_Slope:
         return SlopeFilter();
      default:
         return ENTRY_SIGNAL_NONE;
     }
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
ENUM_ENTRY_SIGNAL CAma::PriceAboveOrBelowLineFilter(void)
  {
   double lastClose = iClose(m_Symbol, m_TF, m_ShiftToUse);
   return (lastClose > m_Buffer[m_ShiftToUse]) ? ENTRY_SIGNAL_BUY :
          (lastClose < m_Buffer[m_ShiftToUse]) ? ENTRY_SIGNAL_SELL : ENTRY_SIGNAL_NONE;
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
ENUM_ENTRY_SIGNAL CAma::RisingOrFalling(void)
  {
   bool isRising=true, isFalling=true;
   for(int i=m_ShiftToUse; i<m_ShiftToUse+m_SlopCalcPeriod; i++)
     {
      isRising = isRising && (m_Buffer[i] > m_Buffer[i+1]);
      isFalling = isFalling && (m_Buffer[i] < m_Buffer[i+1]);
     }

   if(isRising)
      return ENTRY_SIGNAL_BUY;
   else
      if(isFalling)
         return ENTRY_SIGNAL_SELL;
      else
         return ENTRY_SIGNAL_NONE;
  }
//+------------------------------------------------------------------+


//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
ENUM_ENTRY_SIGNAL CAma::SlopeFilter(void)
  {
   double slope = RegressionSlope(m_Buffer, m_SlopCalcPeriod, m_ShiftToUse);
   return slope > 0 ?
          ENTRY_SIGNAL_BUY : (slope < 0) ?
          ENTRY_SIGNAL_SELL: ENTRY_SIGNAL_NONE;
  }
//+------------------------------------------------------------------+
