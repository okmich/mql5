//+------------------------------------------------------------------+
//|                                                  LaguerreRsi.mqh |
//|                                    Copyright 2021, Michael Enudi |
//|                                             okmich2002@yahoo.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2021, Michael Enudi"
#property link      "okmich2002@yahoo.com"

#include "BaseIndicator.mqh"

enum ENUM_CLaguerreRsi_Strategies
  {
   LGRSI_EnterOsOBLevels,
   LGRSI_ContraEnterOsOBLevels,
   LGRSI_ExitOsOBLevels,
   LGRSI_ContraExitOsOBLevels,
   LGRSI_CrossMidLevel,
   LGRSI_Directional
  };

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
class CLaguerreRsi : public CBaseIndicator
  {
private :
   //--- indicator paramter
   int                mBarsToCopy;
   double             m_Gamma, m_OverBoughtLevel, m_OverSoldLevel;
   //--- indicator handle
   int                mHandle;
   //--- indicator buffer
   double             m_Buffer[];

   ENUM_ENTRY_SIGNAL              EnterOsOBSignal();
   ENUM_ENTRY_SIGNAL              ContraEnterOsOBSignal();
   ENUM_ENTRY_SIGNAL              ExitOsOBSignal();
   ENUM_ENTRY_SIGNAL              ContraExitOsOBSignal();
   ENUM_ENTRY_SIGNAL              CrossMidSignal();
   ENUM_ENTRY_SIGNAL              DirectionalSignal();

public:
                     CLaguerreRsi(string symbol, ENUM_TIMEFRAMES period,
                double InputGamma=0.6, double InptOBLevel=0.8, double InptOSLevel=0.2,
                int InptBarsToCopy=6): CBaseIndicator(symbol, period)
     {
      m_Gamma = InputGamma;
      m_OverBoughtLevel = InptOBLevel;
      m_OverSoldLevel = InptOSLevel;

      mBarsToCopy = InptBarsToCopy;
     }

   virtual bool                   Init();
   virtual bool                   Refresh(int ShiftToUse=1);
   virtual void                   Release();

   double                         GetData(int shift=0);
   void                           GetData(double &buffer[], int shift=0);

   ENUM_ENTRY_SIGNAL              TradeSignal(ENUM_CLaguerreRsi_Strategies signalOption);
  };
  
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
bool CLaguerreRsi::Init(void)
  {
   ArraySetAsSeries(m_Buffer, true);
   mHandle =  iCustom(m_Symbol, m_TF, "Articles\\Laguerre RSI", m_Gamma);

   return mHandle != INVALID_HANDLE;
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
bool CLaguerreRsi::Refresh(int ShiftToUse=1)
  {
   m_ShiftToUse = ShiftToUse;
   int copied = CopyBuffer(mHandle, 0, 0, mBarsToCopy, m_Buffer);
   return copied == mBarsToCopy;
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void CLaguerreRsi::Release(void)
  {
   IndicatorRelease(mHandle);
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
double CLaguerreRsi::GetData(int shift=0)
  {
   if(shift >= mBarsToCopy)
      return EMPTY_VALUE;

   return m_Buffer[shift];
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void CLaguerreRsi::GetData(double &buffer[], int shift=0)
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
ENUM_ENTRY_SIGNAL CLaguerreRsi::EnterOsOBSignal(void)
  {
   if(m_Buffer[2] > m_OverSoldLevel &&  m_Buffer[1] < m_OverSoldLevel)
      return ENTRY_SIGNAL_BUY;
   else
      if(m_Buffer[2] < m_OverBoughtLevel &&  m_Buffer[1] > m_OverBoughtLevel)
         return ENTRY_SIGNAL_SELL;
   return ENTRY_SIGNAL_NONE;
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
ENUM_ENTRY_SIGNAL CLaguerreRsi::ContraEnterOsOBSignal(void)
  {
   ENUM_ENTRY_SIGNAL signal = EnterOsOBSignal();
   return signal == ENTRY_SIGNAL_BUY ? ENTRY_SIGNAL_SELL :
          (signal == ENTRY_SIGNAL_SELL) ? ENTRY_SIGNAL_BUY : ENTRY_SIGNAL_NONE;
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
ENUM_ENTRY_SIGNAL CLaguerreRsi::ExitOsOBSignal(void)
  {
   if(m_Buffer[2] > m_OverBoughtLevel &&  m_Buffer[1] < m_OverBoughtLevel)
      return ENTRY_SIGNAL_SELL;
   else
      if(m_Buffer[2] < m_OverSoldLevel &&  m_Buffer[1] > m_OverSoldLevel)
         return ENTRY_SIGNAL_BUY;
   return ENTRY_SIGNAL_NONE;
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
ENUM_ENTRY_SIGNAL CLaguerreRsi::ContraExitOsOBSignal(void)
  {
   ENUM_ENTRY_SIGNAL signal = ExitOsOBSignal();
   return signal == ENTRY_SIGNAL_BUY ? ENTRY_SIGNAL_SELL :
          (signal == ENTRY_SIGNAL_SELL) ? ENTRY_SIGNAL_BUY : ENTRY_SIGNAL_NONE;
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
ENUM_ENTRY_SIGNAL CLaguerreRsi::CrossMidSignal(void)
  {
   double mid = (m_OverBoughtLevel+m_OverSoldLevel)/2;
   if(m_Buffer[2] > mid &&  m_Buffer[1] < mid)
      return ENTRY_SIGNAL_SELL;
   else
      if(m_Buffer[2] < mid && m_Buffer[1] > mid)
         return ENTRY_SIGNAL_BUY;
      else
         return ENTRY_SIGNAL_NONE;
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
ENUM_ENTRY_SIGNAL CLaguerreRsi::DirectionalSignal(void)
  {
   double prevAvg = (m_Buffer[3]+m_Buffer[2])/2;
   return (prevAvg > m_Buffer[1]) ? ENTRY_SIGNAL_BUY :
          (prevAvg < m_Buffer[1]) ? ENTRY_SIGNAL_SELL : ENTRY_SIGNAL_NONE;
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
ENUM_ENTRY_SIGNAL CLaguerreRsi::TradeSignal(ENUM_CLaguerreRsi_Strategies signalOption)
  {
   switch(signalOption)
     {
      case LGRSI_ContraEnterOsOBLevels:
         return ContraEnterOsOBSignal();
      case LGRSI_ContraExitOsOBLevels:
         return ContraExitOsOBSignal();
      case LGRSI_CrossMidLevel:
         return CrossMidSignal();
      case LGRSI_Directional:
         return DirectionalSignal();
      case LGRSI_EnterOsOBLevels:
         return EnterOsOBSignal();
      case LGRSI_ExitOsOBLevels:
         return ExitOsOBSignal();
      default:
         return ENTRY_SIGNAL_NONE;
     }
  }