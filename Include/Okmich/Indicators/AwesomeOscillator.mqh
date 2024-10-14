//+------------------------------------------------------------------+
//|                                            AwesomeOscillator.mqh |
//|                                    Copyright 2022, Michael Enudi |
//|                                             okmich2002@yahoo.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2022, Michael Enudi"
#property link      "okmich2002@yahoo.com"
#property version   "1.00"

#include "BaseIndicator.mqh"

enum ENUM_AO_Strategies
  {
   AO_ZeroLine_Crossover,
   AO_Saucer
  };

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
class CAwesomeOscillator : public CBaseIndicator
  {
private :
   int               mBarsToCopy;
   //--- indicator paramter
   //--- indicator handle
   int                m_Handle;
   //--- indicator buffer
   double             m_Buffer[];

   ENUM_ENTRY_SIGNAL  ZeroLineCrossover();
   ENUM_ENTRY_SIGNAL  Saucer();

public:
                     CAwesomeOscillator(string symbol, ENUM_TIMEFRAMES period, int historyBars=6): CBaseIndicator(symbol, period)
     {
      mBarsToCopy = historyBars;
     }

   virtual bool       Init();
   virtual bool       Refresh(int ShiftToUse=1);
   virtual void       Release();

   double             GetData(int shift=0);
   void               GetData(double &buffer[], int shift=0);

   ENUM_ENTRY_SIGNAL  ZerolineFilter();
   ENUM_ENTRY_SIGNAL  TradeSignal(ENUM_AO_Strategies signalOption);
  };

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
bool CAwesomeOscillator::Init(void)
  {
   ArraySetAsSeries(m_Buffer, true);
   m_Handle = iAO(m_Symbol, m_TF);

   return m_Handle != INVALID_HANDLE;
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
bool CAwesomeOscillator::Refresh(int ShiftToUse=1)
  {
   m_ShiftToUse = ShiftToUse;
   int valuesCopied = CopyBuffer(m_Handle, 0, 0, mBarsToCopy, m_Buffer);
   return valuesCopied == mBarsToCopy;
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void CAwesomeOscillator::Release(void)
  {
   IndicatorRelease(m_Handle);
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
double CAwesomeOscillator::GetData(int shift=0)
  {
   if(shift >= mBarsToCopy)
      return EMPTY_VALUE;

   return m_Buffer[shift];
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void CAwesomeOscillator::GetData(double &buffer[], int shift=0)
  {
   if(shift >= mBarsToCopy)
      return;

   ArraySetAsSeries(buffer, true);
   ArrayResize(buffer, ArraySize(m_Buffer) - shift);

   ArrayCopy(buffer, m_Buffer, 0, shift);
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
ENUM_ENTRY_SIGNAL CAwesomeOscillator::Saucer(void)
  {
   if(m_Buffer[m_ShiftToUse+2] > 0 && m_Buffer[m_ShiftToUse+2] < m_Buffer[m_ShiftToUse+3] &&
      m_Buffer[m_ShiftToUse+1] > 0 && m_Buffer[m_ShiftToUse+1] < m_Buffer[m_ShiftToUse+2] &&
      m_Buffer[m_ShiftToUse] > 0 && m_Buffer[m_ShiftToUse] > m_Buffer[m_ShiftToUse+1])
      return ENTRY_SIGNAL_BUY;

   if(m_Buffer[m_ShiftToUse+2] < 0 && m_Buffer[m_ShiftToUse+2] > m_Buffer[m_ShiftToUse+3] &&
      m_Buffer[m_ShiftToUse+1] < 0 && m_Buffer[m_ShiftToUse+1] > m_Buffer[m_ShiftToUse+2] &&
      m_Buffer[m_ShiftToUse] < 0 && m_Buffer[m_ShiftToUse] < m_Buffer[m_ShiftToUse+1])
      return ENTRY_SIGNAL_SELL;
   else
      return ENTRY_SIGNAL_NONE;
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
ENUM_ENTRY_SIGNAL CAwesomeOscillator::ZeroLineCrossover(void)
  {
   return CBaseIndicator::_CrossMidSignal(m_Buffer, 0.0);
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
ENUM_ENTRY_SIGNAL CAwesomeOscillator::ZerolineFilter(void)
  {
   return m_Buffer[m_ShiftToUse] > 0 ? ENTRY_SIGNAL_BUY :
          m_Buffer[m_ShiftToUse] < 0 ? ENTRY_SIGNAL_SELL : ENTRY_SIGNAL_NONE;
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
ENUM_ENTRY_SIGNAL CAwesomeOscillator::TradeSignal(ENUM_AO_Strategies signalOption)
  {
   switch(signalOption)
     {
      case AO_Saucer:
         return Saucer();
      case AO_ZeroLine_Crossover:
         return ZeroLineCrossover();
      default:
         return ENTRY_SIGNAL_NONE;
     }
  }
//+------------------------------------------------------------------+
