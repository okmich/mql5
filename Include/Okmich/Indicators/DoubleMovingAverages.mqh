//+------------------------------------------------------------------+
//|                                         DoubleMovingAverages.mq5 |
//|                                    Copyright 2020, Michael Enudi |
//|                                             okmich2002@yahoo.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2020, Michael Enudi"
#property link      "okmich2002@yahoo.com"
#property version   "1.00"

#include "MovingAverage.mqh"

enum ENUM_DBLMA_Strategies
  {
   DBLMA_CrossOver,
   DBLMA_PriceLocation,
   DBLMA_SlopeLocation
  };

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
class CDoubleMovingAverages : public CBaseIndicator
  {
private :
   //--- indicator settings
   int                  mBarsToCopy;
   int                  m_ShortMA, m_LongMA, m_MaShift;
   ENUM_MA_TYPE    m_MaMethod;
   ENUM_APPLIED_PRICE   m_AppliedPrice;
   //--- indicator
   int                  m_ShortHandle, m_LongHandle;
   //buffer
   double               m_ShortBuffer[], m_LongBuffer[];

   ENUM_ENTRY_SIGNAL    CrossoverFilter(int shift=1);
   ENUM_ENTRY_SIGNAL    SlopeAndLocationFilter(int shift=1);
   ENUM_ENTRY_SIGNAL    PriceLocationFilter(int shift=1);

public:
                     CDoubleMovingAverages(string symbol, ENUM_TIMEFRAMES period, int shortMA, int longMA,
                         ENUM_MA_TYPE smoothingMethod=MA_EMA, ENUM_APPLIED_PRICE appliedPrice=PRICE_CLOSE,
                         int maShift=0, int historyBars = 10): CBaseIndicator(symbol, period)
     {
      m_ShortMA = shortMA;
      m_LongMA = longMA;
      m_MaShift = maShift;
      m_MaMethod = smoothingMethod;
      m_AppliedPrice = appliedPrice;
      mBarsToCopy = historyBars;
     }

   virtual bool       Init();
   virtual bool       Refresh(int ShiftToUse=1);
   virtual void       Release();

   double                        GetData(int bufferIndx=0, int shift=0);
   void                          GetData(double &buffer[], int bufferIndx=0, int shift=0);

   ENUM_ENTRY_SIGNAL   TradeFilter(ENUM_DBLMA_Strategies strategyOption);
   ENUM_ENTRY_SIGNAL   TradeSignal(ENUM_DBLMA_Strategies strategyOption);
   //double                      MaDiff(int shift=1);
   //double                      MacdSlope(int shift=1) {return Macd(shift) - Macd(shift - 1);};
   double              Slope(int bufferIdx= 0, int bars = 3);
  };

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
bool CDoubleMovingAverages::Init(void)
  {
   ArraySetAsSeries(m_LongBuffer, true);
   ArraySetAsSeries(m_ShortBuffer, true);

   m_LongHandle = getIndicatorHandle(m_Symbol, m_TF, m_LongMA, m_MaMethod, m_MaShift, m_AppliedPrice);
   m_ShortHandle = getIndicatorHandle(m_Symbol, m_TF, m_ShortMA, m_MaMethod, m_MaShift, m_AppliedPrice);

   return m_LongHandle != INVALID_HANDLE && m_ShortHandle != INVALID_HANDLE;
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void CDoubleMovingAverages::Release(void)
  {
   IndicatorRelease(m_LongHandle);
   IndicatorRelease(m_ShortHandle);
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
bool CDoubleMovingAverages::Refresh(int ShiftToUse=1)
  {
   m_ShiftToUse = ShiftToUse;
   int longCopied = CopyBuffer(m_LongHandle, 0, 0, mBarsToCopy, m_LongBuffer);
   int shortCopied = CopyBuffer(m_ShortHandle, 0, 0, mBarsToCopy, m_ShortBuffer);


   return longCopied == shortCopied && shortCopied == mBarsToCopy;
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
double CDoubleMovingAverages::GetData(int bufferIndx=0, int shift=0)
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
void CDoubleMovingAverages::GetData(double &buffer[], int bufferIndx=0, int shift=0)
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

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
double CDoubleMovingAverages::Slope(int bufferIdx=0, int bars=3)
  {
   switch(bufferIdx)
     {
      case 0:
         return RegressionSlope(m_ShortBuffer, bars, m_ShiftToUse);
         break;
      case 1:
         return RegressionSlope(m_LongBuffer, bars, m_ShiftToUse);
      default:
         return EMPTY_VALUE;
     }
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
ENUM_ENTRY_SIGNAL CDoubleMovingAverages::CrossoverFilter(int shift=1)
  {
//--- LONG
   if(m_ShortBuffer[shift] > m_LongBuffer[shift])
      return ENTRY_SIGNAL_BUY;
   else
      if(m_ShortBuffer[shift] < m_LongBuffer[shift])
         return ENTRY_SIGNAL_SELL;

   return ENTRY_SIGNAL_NONE;
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
ENUM_ENTRY_SIGNAL CDoubleMovingAverages::SlopeAndLocationFilter(int shift=1)
  {
   double shortSlope = RegressionSlope(m_ShortBuffer, 3, shift);
   double longSlope = RegressionSlope(m_LongBuffer, 3, shift);
//--- LONG
   if(m_ShortBuffer[shift] > m_LongBuffer[shift] && //crossed over
      shortSlope > 0 && //short ma is upward
      longSlope > 0) //long ma is upward
      return ENTRY_SIGNAL_BUY;
   else
      if(m_ShortBuffer[shift] < m_LongBuffer[shift] && //crossed over
         shortSlope < 0 && //short ma is downward
         longSlope < 0) //long ma is upward
         return ENTRY_SIGNAL_SELL;

   return ENTRY_SIGNAL_NONE;
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
ENUM_ENTRY_SIGNAL CDoubleMovingAverages::PriceLocationFilter(int shift=1)
  {
   double mCloseShift1 = iClose(m_Symbol, m_TF, shift);
//--- LONG
   if(mCloseShift1 > m_ShortBuffer[shift] && //price above shorter ma
      m_ShortBuffer[shift] > m_LongBuffer[shift]) //price above longer ma
      return ENTRY_SIGNAL_BUY;
   else
      if(mCloseShift1 < m_ShortBuffer[shift] && //price below shorter ma
         m_ShortBuffer[shift] < m_LongBuffer[shift]) //price below longer ma
         return ENTRY_SIGNAL_SELL;

   return ENTRY_SIGNAL_NONE;
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
ENUM_ENTRY_SIGNAL CDoubleMovingAverages::TradeFilter(ENUM_DBLMA_Strategies strategyOption)
  {
   switch(strategyOption)
     {
      case DBLMA_CrossOver:
         return CrossoverFilter(m_ShiftToUse);
      case DBLMA_PriceLocation:
         return PriceLocationFilter(m_ShiftToUse);
      case DBLMA_SlopeLocation:
         return SlopeAndLocationFilter(m_ShiftToUse);
      default:
         return ENTRY_SIGNAL_NONE;
     }
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
ENUM_ENTRY_SIGNAL CDoubleMovingAverages::TradeSignal(ENUM_DBLMA_Strategies strategyOption)
  {
   ENUM_ENTRY_SIGNAL filterShift2 = ENTRY_SIGNAL_NONE, filterShift1 = ENTRY_SIGNAL_NONE;
   switch(strategyOption)
     {
      case DBLMA_CrossOver:
         filterShift1 = CrossoverFilter(m_ShiftToUse);
         filterShift2 = CrossoverFilter(m_ShiftToUse+1);
         break;
      case DBLMA_PriceLocation:
         filterShift1 = PriceLocationFilter(m_ShiftToUse);
         filterShift2 = PriceLocationFilter(m_ShiftToUse+1);
         break;
      case DBLMA_SlopeLocation:
         filterShift1 = SlopeAndLocationFilter(m_ShiftToUse);
         filterShift2 = SlopeAndLocationFilter(m_ShiftToUse+1);
         break;
      default:
         return ENTRY_SIGNAL_NONE;
     }

   return (filterShift2 != filterShift1) ? filterShift1 : ENTRY_SIGNAL_NONE;
  }
//+------------------------------------------------------------------+
