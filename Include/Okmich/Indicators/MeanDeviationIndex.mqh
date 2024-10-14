//+------------------------------------------------------------------+
//|                                          CMeanDeviationIndex.mqh |
//|                                    Copyright 2021, Michael Enudi |
//|                                             okmich2002@yahoo.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2020, Michael Enudi"
#property link      "okmich2002@yahoo.com"
#property version   "1.00"

#include "BaseIndicator.mqh"

enum ENUM_MDI_Strategies
  {
   MDI_AboveBelowZero,
   MDI_AboveBelowSignal,
   MDI_MdiSlope,
   MDI_SignalSlope,
   MDI_Convergence
  };

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
class CMeanDeviationIndex : public CBaseIndicator
  {
private :
   int                mBarsToCopy;
   //--- indicator paramter
   int                m_MdiPeriod, m_MdiSmoothing, m_MdiDblSmoothing, m_MdiSignal;
   double             m_MdiTrendVal;
   //--- indicator
   int                m_MdiHandle;
   //--- indicator buffer
   double             m_MdiBuffer[], m_SignalBuffer[], m_TrendClassBuffer[];

   ENUM_ENTRY_SIGNAL  AboveBelowZeroLine();
   ENUM_ENTRY_SIGNAL  AboveBelowSignalLine();
   ENUM_ENTRY_SIGNAL  MdiSlope();
   ENUM_ENTRY_SIGNAL  SignalSlope();
   ENUM_ENTRY_SIGNAL  Convergence();

public:
                     CMeanDeviationIndex(string symbol, ENUM_TIMEFRAMES period, int InputMdiPeriod=26, int InputMdiSmooth=12,
                       int InputMdiDblSmooth=2, int InputMdiSignal=5,
                       double InputTrendValue=0.001, int historyBars=6): CBaseIndicator(symbol, period)
     {
      m_MdiPeriod = InputMdiPeriod;
      m_MdiSmoothing = InputMdiSmooth;
      m_MdiDblSmoothing = InputMdiDblSmooth;
      m_MdiSignal = InputMdiSignal;
      m_MdiTrendVal = InputTrendValue;

      mBarsToCopy = historyBars;
     }

   virtual bool       Init();
   virtual bool       Refresh(int ShiftToUse=1);
   virtual void       Release();

   double             GetData(int buffer=0, int shift=1);
   void               GetData(double &buffer[], int buffer=0, int shift=1);
   
   ENUM_ENTRY_SIGNAL  TradeSignal(ENUM_MDI_Strategies strategyOption);
  };
//+------------------------------------------------------------------+


//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
bool CMeanDeviationIndex::Init(void)
  {
   ArraySetAsSeries(m_MdiBuffer, true);
   ArraySetAsSeries(m_SignalBuffer, true);
   ArraySetAsSeries(m_TrendClassBuffer, true);

   m_MdiHandle = iCustom(m_Symbol, m_TF, "Okmich\\Mean Deviation Index",
                         m_MdiPeriod, m_MdiSmoothing, m_MdiDblSmoothing, m_MdiSignal, m_MdiTrendVal);

   return m_MdiHandle != INVALID_HANDLE;
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
bool CMeanDeviationIndex::Refresh(int ShiftToUse=1)
  {
   m_ShiftToUse = ShiftToUse;
   int mdiCopied = CopyBuffer(m_MdiHandle, 0, 0, mBarsToCopy, m_MdiBuffer);
   int mdiSigCopied = CopyBuffer(m_MdiHandle, 1, 0, mBarsToCopy, m_SignalBuffer);
   CopyBuffer(m_MdiHandle, 2, 0, mBarsToCopy, m_TrendClassBuffer);

   return mBarsToCopy == mdiCopied && mdiCopied == mdiSigCopied;
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void CMeanDeviationIndex::Release(void)
  {
   IndicatorRelease(m_MdiHandle);
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
double CMeanDeviationIndex::GetData(int bufferIndx=0, int shift=1)
  {
   if(shift >= mBarsToCopy || bufferIndx > 1)
      return EMPTY_VALUE;

   switch(bufferIndx)
     {
      case 0:
         return m_MdiBuffer[shift];
      case 1:
         return m_SignalBuffer[shift];
      case 2:
         return m_TrendClassBuffer[shift];
      default:
         return EMPTY_VALUE;
     }
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void CMeanDeviationIndex::GetData(double &buffer[], int bufferIndx=0, int shift=1)
  {
   if(shift >= mBarsToCopy || bufferIndx > 1)
      return;

   ArraySetAsSeries(buffer, true);
   ArrayResize(buffer, mBarsToCopy - shift);

   switch(bufferIndx)
     {
      case 0:
         ArrayCopy(buffer, m_MdiBuffer, 0, shift);
         break;
      case 1:
         ArrayCopy(buffer, m_SignalBuffer, 0, shift);
         break;
      case 2:
         ArrayCopy(buffer, m_TrendClassBuffer, 0, shift);
         break;
      default:
         break;
     }
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
ENUM_ENTRY_SIGNAL CMeanDeviationIndex::AboveBelowSignalLine()
  {
   if(m_MdiBuffer[1] > m_SignalBuffer[1])
      return ENTRY_SIGNAL_BUY;
   else
      if(m_MdiBuffer[1] < m_SignalBuffer[1])
         return ENTRY_SIGNAL_SELL;
      else
         return ENTRY_SIGNAL_NONE;
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
ENUM_ENTRY_SIGNAL CMeanDeviationIndex::AboveBelowZeroLine()
  {
   if(m_MdiBuffer[1] > 0)
      return ENTRY_SIGNAL_BUY;
   else
      if(m_MdiBuffer[1] < 0)
         return ENTRY_SIGNAL_SELL;
      else
         return ENTRY_SIGNAL_NONE;
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
ENUM_ENTRY_SIGNAL CMeanDeviationIndex::MdiSlope()
  {
   double slope = RegressionSlope(m_MdiBuffer, 3, 1);
   return (slope > 0) ? ENTRY_SIGNAL_BUY : (slope < 0) ? ENTRY_SIGNAL_SELL : ENTRY_SIGNAL_NONE;
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
ENUM_ENTRY_SIGNAL CMeanDeviationIndex::SignalSlope()
  {
   double slope = RegressionSlope(m_SignalBuffer, 3, 1);
   return (slope > 0) ? ENTRY_SIGNAL_BUY : (slope < 0) ? ENTRY_SIGNAL_SELL : ENTRY_SIGNAL_NONE;
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
ENUM_ENTRY_SIGNAL CMeanDeviationIndex::TradeSignal(ENUM_MDI_Strategies strategyOption)
  {
   switch(strategyOption)
     {
      case MDI_AboveBelowSignal:
         return AboveBelowSignalLine();
      case MDI_AboveBelowZero:
         return AboveBelowZeroLine();
      case MDI_Convergence:
         return (m_TrendClassBuffer[1] == m_MdiTrendVal) ? ENTRY_SIGNAL_BUY :
                (m_TrendClassBuffer[1] == -m_MdiTrendVal) ? ENTRY_SIGNAL_SELL : ENTRY_SIGNAL_NONE;
      case MDI_MdiSlope:
         return MdiSlope();
      case MDI_SignalSlope:
         return SignalSlope();
      default :
         return ENTRY_SIGNAL_NONE;
     }
  }
//+------------------------------------------------------------------+
