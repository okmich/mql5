//+------------------------------------------------------------------+
//|                                       KaufmanEfficiencyRatio.mqh |
//|                                                    Michael Enudi |
//|                                             okmich2002@yahoo.com |
//+------------------------------------------------------------------+
#property copyright "Michael Enudi"
#property link      "okmich2002@yahoo.com"

#include "BaseIndicator.mqh"

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
class CKaufmanEfficiencyRatio : public CBaseIndicator
  {
private :
   int                mBarsToCopy;
   //--- indicator paramter
   int                m_Period;
   double             m_KThreshold;
   //--- indicator
   int                m_Handle;
   //--- indicator buffer
   double             m_Buffer[];

public:
                     CKaufmanEfficiencyRatio(string symbol, ENUM_TIMEFRAMES period,
                           int InputPeriod, double InputKThreshold, int historyBars=4): CBaseIndicator(symbol, period)
     {
      m_Period = InputPeriod;
      m_KThreshold = InputKThreshold;
      mBarsToCopy = historyBars;
     }

   virtual bool        Init();
   virtual bool        Refresh(int ShiftToUse=1);
   virtual void        Release();

   double              GetData(int shift=0);
   void                GetData(double &buffer[], int shift=0);

   bool                TradeFilter();
  };

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
bool CKaufmanEfficiencyRatio::Init(void)
  {
   ArraySetAsSeries(m_Buffer, true);

   m_Handle = iCustom(m_Symbol, m_TF, "Articles\\Kaufman Efficiency Ratio", m_Period);
   return m_Handle != INVALID_HANDLE;
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
bool CKaufmanEfficiencyRatio::Refresh(int ShiftToUse=1)
  {
   m_ShiftToUse = ShiftToUse;
   int copied = CopyBuffer(m_Handle, 0, 0, mBarsToCopy, m_Buffer);

   return mBarsToCopy == copied;
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void CKaufmanEfficiencyRatio::Release(void)
  {
   IndicatorRelease(m_Handle);
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
double CKaufmanEfficiencyRatio::GetData(int shift=0)
  {
   if(shift >= mBarsToCopy)
      return EMPTY_VALUE;

   return m_Buffer[shift];
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void CKaufmanEfficiencyRatio::GetData(double &buffer[], int shift=0)
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
bool CKaufmanEfficiencyRatio::TradeFilter()
  {
   return m_Buffer[m_ShiftToUse] > m_KThreshold;
  }
//+------------------------------------------------------------------+

//+------------------------------------------------------------------+
