//+------------------------------------------------------------------+
//|                                                        Aroon.mqh |
//|                                    Copyright 2021, Michael Enudi |
//|                                             okmich2002@yahoo.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2021, Michael Enudi"
#property link      "okmich2002@yahoo.com"

#include "BaseIndicator.mqh"

enum ENUM_CAroon_Stategies
  {
   AROON_Stategies_CrossesOver,
   AROON_Stategies_CrossesLevels
  };

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
class CAroon : public CBaseIndicator
  {
private :
   int                mBarsToCopy;

   double             mBullValue, mBullSlope;
   double             mBearValue, mBearSlope;
   //--- indicator paramter
   int                m_Period, m_ObLevel, m_OsLevel;
   //--- indicator
   int                m_Handle;
   //--- indicator buffer
   double             m_BullBuffer[], m_BearBuffer[];

   ENUM_ENTRY_SIGNAL  CrossesOverSignal();
   ENUM_ENTRY_SIGNAL  CrossesLevelsSignal();
public:
                     CAroon(string symbol, ENUM_TIMEFRAMES period,
          int InputPeriod=25, int InptOBLevel=75, int InptOSLevel=25,
          int historyBars=5): CBaseIndicator(symbol, period)
     {
      m_Period = InputPeriod;
      mBarsToCopy = historyBars;
      m_ObLevel = InptOBLevel;
      m_OsLevel = InptOSLevel;
     }

   virtual bool                   Init();
   virtual bool                   Refresh(int ShiftToUse=1);
   virtual void                   Release();

   double                         GetData(int buffer=0, int shift=0);
   void                           GetData(double &buffer[], int buffer=0, int shift=0);

   double                         BullSlope(int shift=1);
   double                         BearSlope(int shift=1);

   ENUM_ENTRY_SIGNAL              TradeSignal(ENUM_CAroon_Stategies);
  };

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
bool CAroon::Init(void)
  {
   ArraySetAsSeries(m_BullBuffer, true);
   ArraySetAsSeries(m_BearBuffer, true);

   m_Handle = iCustom(m_Symbol, m_TF, "Articles\\Aroon", m_Period);
   return m_Handle != INVALID_HANDLE;
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
bool CAroon::Refresh(int ShiftToUse=1)
  {
   m_ShiftToUse = ShiftToUse;
   int bullsCopied = CopyBuffer(m_Handle, 0, 0, mBarsToCopy, m_BullBuffer);
   int bearsCopied = CopyBuffer(m_Handle, 1, 0, mBarsToCopy, m_BearBuffer);

   mBearValue = m_BearBuffer[m_ShiftToUse];
   mBearSlope = m_BearBuffer[m_ShiftToUse] - m_BearBuffer[m_ShiftToUse+1];
   mBullValue = m_BullBuffer[m_ShiftToUse];
   mBullSlope = m_BullBuffer[m_ShiftToUse] - m_BullBuffer[m_ShiftToUse+1];

   return mBarsToCopy == bearsCopied && bearsCopied == bullsCopied;
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void CAroon::Release(void)
  {
   IndicatorRelease(m_Handle);
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
double CAroon::GetData(int bufferIndx=0, int shift=0)
  {
   if(shift >= mBarsToCopy || bufferIndx > 1)
      return EMPTY_VALUE;

   switch(bufferIndx)
     {
      case 0:
         return m_BearBuffer[shift];
      case 1:
         return m_BullBuffer[shift];
      default:
         return EMPTY_VALUE;
     }
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void CAroon::GetData(double &buffer[], int bufferIndx=0, int shift=0)
  {
   if(shift >= mBarsToCopy || bufferIndx > 1)
      return;

   ArraySetAsSeries(buffer, true);
   ArrayResize(buffer, mBarsToCopy - shift);

   switch(bufferIndx)
     {
      case 0:
         ArrayCopy(buffer, m_BearBuffer, 0, shift);
         break;
      case 1:
      default:
         ArrayCopy(buffer, m_BullBuffer, 0, shift);
         break;
     }
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
double CAroon::BearSlope(int shift=1)
  {
   if(shift >= mBarsToCopy)
      return EMPTY_VALUE;

   return m_BearBuffer[shift] - m_BearBuffer[shift+1];
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
double CAroon::BullSlope(int shift = 1)
  {
   if(shift >= mBarsToCopy)
      return EMPTY_VALUE;

   return m_BullBuffer[shift] - m_BullBuffer[shift+1];
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
ENUM_ENTRY_SIGNAL  CAroon::CrossesOverSignal(void)
  {
   if(m_BullBuffer[m_ShiftToUse+1] < m_BearBuffer[m_ShiftToUse+1] && m_BullBuffer[m_ShiftToUse] >= m_BearBuffer[m_ShiftToUse])
      return ENTRY_SIGNAL_BUY;

   if(m_BearBuffer[m_ShiftToUse+1] < m_BullBuffer[m_ShiftToUse+1] && m_BearBuffer[m_ShiftToUse] >= m_BullBuffer[m_ShiftToUse])
      return ENTRY_SIGNAL_SELL;

   return ENTRY_SIGNAL_NONE;
  }

//+------------------------------------------------------------------+
//| Aroon Down falls from top or Aroon Up rises from below           |
//+------------------------------------------------------------------+
ENUM_ENTRY_SIGNAL  CAroon::CrossesLevelsSignal(void)
  {
   bool buySignal = m_BullBuffer[m_ShiftToUse+1] < m_OsLevel && m_BullBuffer[m_ShiftToUse] > m_OsLevel;
   bool sellSignal = m_BearBuffer[m_ShiftToUse+1] > m_ObLevel && m_BearBuffer[m_ShiftToUse] < m_ObLevel;

   if(buySignal && !sellSignal)
      return ENTRY_SIGNAL_BUY;
   else
      if(!buySignal && sellSignal)
         return ENTRY_SIGNAL_SELL;

   return ENTRY_SIGNAL_NONE;
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
ENUM_ENTRY_SIGNAL CAroon::TradeSignal(ENUM_CAroon_Stategies logicOption)
  {
   switch(logicOption)
     {
      case AROON_Stategies_CrossesLevels:
         return CrossesLevelsSignal();
      case AROON_Stategies_CrossesOver:
         return CrossesOverSignal();
      default:
         return ENTRY_SIGNAL_NONE;
     }
  }
//+------------------------------------------------------------------+
