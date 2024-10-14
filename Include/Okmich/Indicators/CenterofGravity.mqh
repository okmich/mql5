//+------------------------------------------------------------------+
//|                                             CCenterofGravity.mqh |
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
class CCog : public CBaseIndicator
  {
private :
   int                m_BarsToInspect;
   //--- indicator paramter
   int                m_CogPeriod, m_Signal;
   bool               m_UseDsl;
   double             m_RangeThreshold;
   //--- indicator
   int                m_CogHandle;
   //--- indicator buffer
   double             m_CogBuffer[], m_ObBuffer[], m_OsBuffer[];

public:
                     CCog(string symbol, ENUM_TIMEFRAMES period, int InpCogPeriod,
        bool InpUseDsl=false, int InptSignal=7, double InputRangeThreshold = 0.002,
        int InpBarsToInspect=5): CBaseIndicator(symbol, period)
     {
      m_CogPeriod = InpCogPeriod;
      
      m_Signal = InptSignal;
      m_UseDsl = InpUseDsl;
      m_RangeThreshold = InputRangeThreshold;
      
      m_BarsToInspect = InpBarsToInspect;
     }

   virtual bool                   Init();
   virtual bool                   Refresh(int ShiftToUse=1);
   virtual void                   Release();

   double                         GetData(int i);
   double                         GetPeriod() { return m_CogPeriod;};
   ENUM_ENTRY_SIGNAL              TradeSignal();
   
   ENUM_ENTRY_SIGNAL              Phase();
   ENUM_ENTRY_SIGNAL              Bias(void);
   ENUM_TRENDSTATE                VolatilityState(void);
  };
//+------------------------------------------------------------------+


//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
bool CCog::Init(void)
  {
   ArraySetAsSeries(m_CogBuffer, true);
   ArraySetAsSeries(m_ObBuffer, true);
   ArraySetAsSeries(m_OsBuffer, true);

   if(m_UseDsl)
      m_CogHandle = iCustom(m_Symbol, m_TF, "Okmich\\Center of Gravity (DSL)", m_CogPeriod, m_Signal);
   else
      m_CogHandle = iCustom(m_Symbol, m_TF, "Okmich\\Center of Gravity", m_CogPeriod);

   return m_CogHandle != INVALID_HANDLE && m_BarsToInspect > 2;
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
ENUM_ENTRY_SIGNAL CCog::TradeSignal()
  {
   double main = m_CogBuffer[m_ShiftToUse];
   double signal = m_CogBuffer[2];
   if(main > signal)
      return ENTRY_SIGNAL_BUY;
   else
      if(main < signal)
         return ENTRY_SIGNAL_SELL;
      else
         return ENTRY_SIGNAL_NONE;

  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
bool CCog::Refresh(int ShiftToUse=1)
  {
   m_ShiftToUse = ShiftToUse;
   int dataCopied = CopyBuffer(m_CogHandle, 0, 0, m_BarsToInspect, m_CogBuffer);
   if(m_UseDsl)
     {
      CopyBuffer(m_CogHandle, 1, 0, m_BarsToInspect, m_ObBuffer);
      CopyBuffer(m_CogHandle, 2, 0, m_BarsToInspect, m_OsBuffer);
     }

   return m_BarsToInspect == dataCopied;
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void CCog::Release(void)
  {
   IndicatorRelease(m_CogHandle);
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
double CCog::GetData(int i)
  {
   if(i >= m_BarsToInspect)
      return EMPTY_VALUE;
   return m_CogBuffer[i];
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
ENUM_ENTRY_SIGNAL CCog::Bias(void)
  {
   return CBaseIndicator::Bias(m_ObBuffer, m_OsBuffer);
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
ENUM_ENTRY_SIGNAL CCog::Phase()
  {
   return CBaseIndicator::Phase(m_CogBuffer, m_ObBuffer, m_OsBuffer, 50.0);
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
ENUM_TRENDSTATE CCog::VolatilityState(void)
  {
   double levelDiff = m_ObBuffer[m_ShiftToUse] - m_OsBuffer[m_ShiftToUse];
   return (levelDiff > m_RangeThreshold)? TS_TREND : TS_FLAT;
  }
//+------------------------------------------------------------------+
