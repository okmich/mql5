//+------------------------------------------------------------------+
//|                                                       Vortex.mqh |
//|                                    Copyright 2022, Michael Enudi |
//|                                             okmich2002@yahoo.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2022, Michael Enudi"
#property link      "okmich2002@yahoo.com"

#include "BaseIndicator.mqh"

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
class CVortex : public CBaseIndicator
  {
private :
   int                mBarsToCopy;

   double             mBearSlope, mBullSlope;
   //--- indicator paramter
   int                m_Period, m_Smoothing;
   //--- indicator
   int                m_Handle;
   //--- indicator buffer
   double             m_NegBuffer[], m_PosBuffer[];

public:
                     CVortex(string symbol, ENUM_TIMEFRAMES period,
           int InputPeriod=25, int InputSmoothingPeriod=75, int historyBars=5): CBaseIndicator(symbol, period)
     {
      m_Period = InputPeriod;
      m_Smoothing = InputSmoothingPeriod;
      mBarsToCopy = historyBars;
     }

   virtual bool       Init();
   virtual bool       Refresh(int ShiftToUse=1);
   virtual void       Release();

   double             GetData(int bufferIndx=0, int shift=0);
   void               GetData(double &buffer[], int bufferIndx=0, int shift=0);

   double             BullSlope(int shift=1);
   double             BearSlope(int shift=1);

   ENUM_ENTRY_SIGNAL  TradeSignal();
  };

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
bool CVortex::Init(void)
  {
   ArraySetAsSeries(m_NegBuffer, true);
   ArraySetAsSeries(m_PosBuffer, true);

   m_Handle = iCustom(m_Symbol, m_TF, "Articles\\Vortex", m_Period, m_Smoothing);
   return m_Handle != INVALID_HANDLE;
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
bool CVortex::Refresh(int ShiftToUse=1)
  {
   m_ShiftToUse = ShiftToUse;
   int bullsCopied = CopyBuffer(m_Handle, 2, 0, mBarsToCopy, m_PosBuffer);
   int bearsCopied = CopyBuffer(m_Handle, 4, 0, mBarsToCopy, m_NegBuffer);

   return mBarsToCopy == bearsCopied && bearsCopied == bullsCopied;
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void CVortex::Release(void)
  {
   IndicatorRelease(m_Handle);
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
double CVortex::GetData(int bufferIndx=0, int shift=0)
  {
   if(shift >= mBarsToCopy || bufferIndx > 1)
      return EMPTY_VALUE;

   switch(bufferIndx)
     {
      case 0:
         return m_NegBuffer[shift];
      case 1:
         return m_PosBuffer[shift];
      default:
         return EMPTY_VALUE;
     }
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void CVortex::GetData(double &buffer[], int bufferIndx=0, int shift=0)
  {
   if(shift >= mBarsToCopy || bufferIndx > 1)
      return;

   ArraySetAsSeries(buffer, true);
   ArrayResize(buffer, mBarsToCopy - shift);

   switch(bufferIndx)
     {
      case 0:
         ArrayCopy(buffer, m_NegBuffer, 0, shift);
         break;
      case 1:
      default:
         ArrayCopy(buffer, m_PosBuffer, 0, shift);
         break;
     }
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
double CVortex::BearSlope(int shift=1)
  {
   if(shift >= mBarsToCopy)
      return EMPTY_VALUE;

   return RegressionSlope(m_NegBuffer, 3, 1);
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
double CVortex::BullSlope(int shift = 1)
  {
   if(shift >= mBarsToCopy)
      return EMPTY_VALUE;

   return RegressionSlope(m_PosBuffer, 3, 1);
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
ENUM_ENTRY_SIGNAL CVortex::TradeSignal()
  {
   if(m_NegBuffer[m_ShiftToUse+1] > m_PosBuffer[m_ShiftToUse+1] && m_NegBuffer[m_ShiftToUse] < m_PosBuffer[m_ShiftToUse])
      return ENTRY_SIGNAL_BUY;
   else
      if(m_NegBuffer[m_ShiftToUse+1] < m_PosBuffer[m_ShiftToUse+1] && m_NegBuffer[m_ShiftToUse] > m_PosBuffer[m_ShiftToUse])
         return ENTRY_SIGNAL_SELL;
      else
         return ENTRY_SIGNAL_NONE;
  }
//+------------------------------------------------------------------+