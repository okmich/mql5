//+------------------------------------------------------------------+
//|                                    CorrelationTrendIndicator.mq5 |
//|                                    Copyright 2020, Michael Enudi |
//|                                             okmich2002@yahoo.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2020, Michael Enudi"
#property link      "okmich2002@yahoo.com"
#property version   "1.00"

#include "BaseIndicator.mqh"
#include <Indicators\Trend.mqh>

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
class CCorrelationTrendIndicator : public CBaseIndicator
  {
private :
   double               mShortShift1, mShortShift2, mLongShift1, mLongShift2;
   //--- indicator settings
   int                   mBarsToCopy;
   int                   m_ShortPeriod, m_LongPeriod;
   ENUM_APPLIED_PRICE    m_AppliedPrice;
   //--- indicator
   int                   m_Handle;
   //--- indicator buffer
   double             m_ShortBuffer[], m_LongBuffer[];

public:
                     CCorrelationTrendIndicator(string symbol, ENUM_TIMEFRAMES period,
                              int shortPeriod, int longPeriod,
                              ENUM_APPLIED_PRICE appliedPrice=PRICE_CLOSE): CBaseIndicator(symbol, period)
     {
      m_ShortPeriod = shortPeriod;
      m_LongPeriod = longPeriod;
      m_AppliedPrice = appliedPrice;
      mBarsToCopy = 10;
     }

   virtual bool                   Init();
   virtual bool                   Refresh(int ShiftToUse=1);
   virtual void                   Release();

   ENUM_ENTRY_SIGNAL             GetTradeSignal(int shift=1);
   double                        GetData(int bufferIndx=0, int shift=0);
   void                          GetData(double &buffer[], int bufferIndx=0, int shift=0);
  };
//+------------------------------------------------------------------+


//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
bool CCorrelationTrendIndicator::Init(void)
  {
   ArraySetAsSeries(m_ShortBuffer, true);
   ArraySetAsSeries(m_LongBuffer, true);

   m_Handle = iCustom(m_Symbol, m_TF, "Articles\\Correlation Trend Indicator",
                         m_ShortPeriod, m_LongPeriod, m_AppliedPrice);
   return m_Handle != INVALID_HANDLE;
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
ENUM_ENTRY_SIGNAL CCorrelationTrendIndicator::GetTradeSignal(int shift=1)
  {
////--- LONG
//   if(mShortSmaShift1 > mLongSmaShift1 && //crossed over
//      mShortSmaShift1 > mShortSmaShift2 && //short ma is upward
//      mLongSmaShift1 > mLongSmaShift2) //long ma is upward
//      return ENTRY_SIGNAL_BUY;
//   else
//      if(mShortSmaShift1 < mLongSmaShift1 && //crossed over
//         mShortSmaShift1 < mShortSmaShift2 && //short ma is downward
//         mLongSmaShift1 < mLongSmaShift2) //long ma is upward
//         return ENTRY_SIGNAL_SELL;

   return ENTRY_SIGNAL_NONE;
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
bool CCorrelationTrendIndicator::Refresh(int ShiftToUse=1)
  {
   m_ShiftToUse = ShiftToUse;
   int shortCopied = CopyBuffer(m_Handle, 0, 0, mBarsToCopy, m_ShortBuffer);
   int LongCopied = CopyBuffer(m_Handle, 1, 0, mBarsToCopy, m_LongBuffer);

   return mBarsToCopy == shortCopied && shortCopied == LongCopied;
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void CCorrelationTrendIndicator::Release(void)
  {
   IndicatorRelease(m_Handle);
  }


//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
double CCorrelationTrendIndicator::GetData(int bufferIndx=0, int shift=0)
  {
   switch(bufferIndx)
     {
      case 0:
         return m_ShortBuffer[shift];
      case 1:
         return m_LongBuffer[shift];
      default:
         return EMPTY_VALUE;
     }

  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void CCorrelationTrendIndicator::GetData(double &buffer[], int bufferIndx=0, int shift=0)
  {
   ArraySetAsSeries(buffer, true);
   ArrayResize(buffer, mBarsToCopy - shift);

   switch(bufferIndx)
     {
      case 0:
         ArrayCopy(buffer, m_ShortBuffer, 0, shift);
         break;
      case 1:
         ArrayCopy(buffer, m_LongBuffer, 0, shift);
         break;
      default:
         break;
     }
  }
