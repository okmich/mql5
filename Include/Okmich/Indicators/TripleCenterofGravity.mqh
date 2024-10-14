//+------------------------------------------------------------------+
//|                                        TripleCenterofGravity.mqh |
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
class CTripleCog : public CBaseIndicator
  {
private :
   int                m_BarsToInspect;
   //--- indicator paramter
   int                m_CogPeriod1, m_CogPeriod2, m_CogPeriod3, m_Mul1, m_Mul2, m_Mul3, m_Signal;
   bool               m_UseDsl;
   double             m_RangeThreshold;
   //--- indicator
   int                m_Handle;
   //--- indicator buffer
   double             m_CogBuffer[], m_ObBuffer[], m_OsBuffer[];

public:
                     CTripleCog(string symbol, ENUM_TIMEFRAMES period,
              int InpCogPeriod1, int InpCogPeriod2, int InpCogPeriod3,
              int InpMul1, int InpMul2, int InpMul3,
              bool InpUseDsl=false, int InptSignal=7, double InputRangeThreshold = 0.002,
              int InpBarsToInspect=5): CBaseIndicator(symbol, period)
     {
      m_CogPeriod1 = InpCogPeriod1;
      m_CogPeriod2 = InpCogPeriod2;
      m_CogPeriod3 = InpCogPeriod3;
      m_Mul1 = InpMul1;
      m_Mul2 = InpMul2;
      m_Mul3 = InpMul3;

      m_UseDsl = InpUseDsl;
      m_Signal = InptSignal;
      m_RangeThreshold = InputRangeThreshold;

      m_BarsToInspect = InpBarsToInspect;
     }

   virtual bool                   Init();
   virtual bool                   Refresh(int ShiftToUse=1);
   virtual void                   Release();

   double                         GetData(int shift=0, int bufferIndx=0);
   void                           GetData(double &buffer[], int shift=0, int bufferIndx=0);
   ENUM_ENTRY_SIGNAL              TradeSignal();

   ENUM_ENTRY_SIGNAL              Phase();
   ENUM_ENTRY_SIGNAL              Bias(void);
   ENUM_TRENDSTATE                VolatilityState(void);
  };
//+------------------------------------------------------------------+


//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
bool CTripleCog::Init(void)
  {
   ArraySetAsSeries(m_CogBuffer, true);
   ArraySetAsSeries(m_ObBuffer, true);
   ArraySetAsSeries(m_OsBuffer, true);

   if(m_UseDsl)
      m_Handle = iCustom(m_Symbol, m_TF, "Okmich\\CenterOfGravity", m_CogPeriod1, m_CogPeriod2, m_CogPeriod3,
                         m_Mul1, m_Mul2, m_Mul3, m_Signal);
   else
      m_Handle = iCustom(m_Symbol, m_TF, "Okmich\\CenterOfGravity", m_CogPeriod1, m_CogPeriod2, m_CogPeriod3,
                         m_Mul1, m_Mul2, m_Mul3);

   return m_Handle != INVALID_HANDLE && m_BarsToInspect > 2;
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
ENUM_ENTRY_SIGNAL CTripleCog::TradeSignal()
  {
   double main = m_CogBuffer[1];
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
bool CTripleCog::Refresh(int ShiftToUse=1)
  {
   m_ShiftToUse = ShiftToUse;
   int dataCopied = CopyBuffer(m_Handle, 0, 0, m_BarsToInspect, m_CogBuffer);
   if(m_UseDsl)
     {
      CopyBuffer(m_Handle, 1, 0, m_BarsToInspect, m_ObBuffer);
      CopyBuffer(m_Handle, 2, 0, m_BarsToInspect, m_OsBuffer);
     }

   return m_BarsToInspect == dataCopied;
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void CTripleCog::Release(void)
  {
   IndicatorRelease(m_Handle);
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
double CTripleCog::GetData(int shift=0, int bufferIndx=0)
  {
   if(shift >= m_BarsToInspect || bufferIndx > 2)
      return EMPTY_VALUE;

   switch(bufferIndx)
     {
      case 0:
         return m_CogBuffer[shift];
      case 1:
         return m_UseDsl ? m_ObBuffer[shift] : EMPTY_VALUE;
      case 2:
         return m_UseDsl ? m_OsBuffer[shift] : EMPTY_VALUE;
      default:
         return EMPTY_VALUE;
     }
  }
  
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void CTripleCog::GetData(double &buffer[], int shift=0, int bufferIndx=0)
  {
   if(shift >= m_BarsToInspect || bufferIndx > 2)
      return;

   ArraySetAsSeries(buffer, true);
   ArrayResize(buffer, m_BarsToInspect - shift);

   switch(bufferIndx)
     {
      case 0:
         ArrayCopy(buffer, m_CogBuffer, 0, shift);
         break;
      case 1:
         if(!m_UseDsl)
            return;
         ArrayCopy(buffer, m_ObBuffer, 0, shift);
         break;
      case 2:
         if(!m_UseDsl)
            return;
         ArrayCopy(buffer, m_OsBuffer, 0, shift);
         break;
      default:
         break;
     }
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
ENUM_ENTRY_SIGNAL CTripleCog::Bias(void)
  {
   return CBaseIndicator::Bias(m_ObBuffer, m_OsBuffer);
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
ENUM_ENTRY_SIGNAL CTripleCog::Phase()
  {
   return CBaseIndicator::Phase(m_CogBuffer, m_ObBuffer, m_OsBuffer, 50.0);
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
ENUM_TRENDSTATE CTripleCog::VolatilityState(void)
  {
   double levelDiff = m_ObBuffer[1] - m_OsBuffer[1];
   return (levelDiff > m_RangeThreshold)? TS_TREND : TS_FLAT;
  }
//+------------------------------------------------------------------+
