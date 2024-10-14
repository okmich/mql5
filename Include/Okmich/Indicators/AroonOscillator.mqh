//+------------------------------------------------------------------+
//|                                              AroonOscillator.mqh |
//|                                    Copyright 2023, Michael Enudi |
//|                                             okmich2002@yahoo.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2023, Michael Enudi"
#property link      "okmich2002@yahoo.com"
#property version   "1.00"

#include "BaseIndicator.mqh"
#include <Okmich\Common\Common.mqh>

enum ENUM_ARNOSC_Filter_Type
  {
   ARNOSC_CROSS_MID_LEVEL,  //Crosses mid level
  };

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
class CAroonOscillator : public CBaseIndicator
  {
private :
   int                mBarsToCopy;
   //--- indicator paramter
   int                m_Period;
   //--- indicator
   int                m_Handle;
   //--- indicator buffer
   double             m_Buffer[];

public:
                     CAroonOscillator(string symbol, ENUM_TIMEFRAMES period,
                    int InputPeriod=21, int historyBars=6): CBaseIndicator(symbol, period)
     {
      m_Period = InputPeriod;
      mBarsToCopy = historyBars;
     }

   virtual bool        Init();
   virtual bool        Refresh(int ShiftToUse=1);
   virtual void        Release();

   double              GetData(int shift=0);
   void                GetData(double &buffer[], int shift=0);

   ENUM_ENTRY_SIGNAL  MidLevelFilter(int shift=1);

   ENUM_ENTRY_SIGNAL  Filter(ENUM_ARNOSC_Filter_Type filterType);
  };

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
bool CAroonOscillator::Init(void)
  {
   ArraySetAsSeries(m_Buffer, true);
   m_Handle = iCustom(m_Symbol, m_TF, "Articles\\Aroon Oscillator", m_Period, 0);
   return m_Handle != INVALID_HANDLE;
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void CAroonOscillator::Release(void)
  {
   IndicatorRelease(m_Handle);
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
bool CAroonOscillator::Refresh(int ShiftToUse=1)
  {
   m_ShiftToUse = ShiftToUse;
   int copied = CopyBuffer(m_Handle, 0, 0, mBarsToCopy, m_Buffer);

   return copied == mBarsToCopy;
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
double CAroonOscillator::GetData(int shift=0)
  {
   if(shift >= mBarsToCopy)
      return EMPTY_VALUE;
   return m_Buffer[shift];
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void CAroonOscillator::GetData(double &buffer[], int shift=0)
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
ENUM_ENTRY_SIGNAL  CAroonOscillator::MidLevelFilter(int shift=1)
  {
   return m_Buffer[shift] > 0 ? ENTRY_SIGNAL_BUY :
          m_Buffer[shift] < 0 ? ENTRY_SIGNAL_SELL : ENTRY_SIGNAL_NONE;
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
ENUM_ENTRY_SIGNAL CAroonOscillator::Filter(ENUM_ARNOSC_Filter_Type filterType)
  {
   switch(filterType)
     {
      case ARNOSC_CROSS_MID_LEVEL:
         return MidLevelFilter(m_ShiftToUse);
      default:
         return ENTRY_SIGNAL_NONE;
     }
  }
//+------------------------------------------------------------------+
