//+------------------------------------------------------------------+
//|                                                          DPO.mqh |
//|                                    Copyright 2020, Michael Enudi |
//|                                             okmich2002@yahoo.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2020, Michael Enudi"
#property link      "okmich2002@yahoo.com"
#property version   "1.00"

#include "BaseIndicator.mqh"

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
class CDpo : public CBaseIndicator
  {
private :
   int                mBarsToCopy;
   //--- indicator paramter
   int                mPeriod;
   //--- indicator
   int                m_DpoHandle;
   //--- indicator buffer
   double             m_DpoBuffer[];

public:
                     CDpo(string symbol, ENUM_TIMEFRAMES period, int InpDpoPeriod=12,
        int InpBarsToInspect=10): CBaseIndicator(symbol, period)
     {
      mPeriod = InpDpoPeriod;

      mBarsToCopy = InpBarsToInspect;
     }

   virtual bool         Init();
   virtual bool         Refresh(int ShiftToUse=1);
   virtual void         Release();
   
   double               GetData(int i);
   void                 GetData(double &buffer[], int shift=0);
   
   double               GetPeriod() { return mPeriod;};
   
   ENUM_ENTRY_SIGNAL    TradeSignal();
  };
//+------------------------------------------------------------------+


//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
bool CDpo::Init(void)
  {
   ArraySetAsSeries(m_DpoBuffer, true);
   m_DpoHandle = iCustom(m_Symbol, m_TF, "Examples\\DPO", mPeriod);
   return m_DpoHandle != INVALID_HANDLE && mBarsToCopy > 2;
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
ENUM_ENTRY_SIGNAL CDpo::TradeSignal()
  {
   double main = m_DpoBuffer[1];
   double signal = m_DpoBuffer[2];
   if(main > 0 && main > signal)
      return ENTRY_SIGNAL_BUY;
   else
      if(main < 0 && main < signal)
         return ENTRY_SIGNAL_SELL;
      else
         return ENTRY_SIGNAL_NONE;
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
bool CDpo::Refresh(int ShiftToUse=1)
  {
   m_ShiftToUse = ShiftToUse;
   int dataCopied = CopyBuffer(m_DpoHandle, 0, 0, mBarsToCopy, m_DpoBuffer);

   return mBarsToCopy == dataCopied;
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void CDpo::Release(void)
  {
   IndicatorRelease(m_DpoHandle);
  }


//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
double CDpo::GetData(int i)
  {
   if(i >= mBarsToCopy)
      return EMPTY_VALUE;
   return m_DpoBuffer[i];
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void CDpo::GetData(double &buffer[], int shift=0)
  {
   if(shift >= mBarsToCopy)
      return;

   ArraySetAsSeries(buffer, true);
   ArrayResize(buffer, mBarsToCopy - shift);

   ArrayCopy(buffer, m_DpoBuffer, 0, shift);
  }
//+------------------------------------------------------------------+
