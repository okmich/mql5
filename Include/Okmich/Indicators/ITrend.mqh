//+------------------------------------------------------------------+
//|                                                       ITrend.mqh |
//|                                                    Michael Enudi |
//|                                             okmich2002@yahoo.com |
//+------------------------------------------------------------------+
#property copyright "Michael Enudi"
#property link      "okmich2002@yahoo.com"


#include "BaseIndicator.mqh"

enum ENUM_BBLine
  {
   Base=BASE_LINE,
   Upper=UPPER_BAND,
   Lower=LOWER_BAND
  };

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
class CiTrend : public CBaseIndicator
  {
private :
   int                mBarsToCopy;
   //--- indicator paramter
   int                m_MaPeriod, m_BullBearPeriod;
   double             m_Deviation;
   ENUM_BBLine        m_BBLineType;
   //--- indicator
   //--- indicator
   int                m_Handle;
   //--- indicator buffer
   double             m_NegBuffer[], m_PosBuffer[];

public:
                     CiTrend(string symbol, ENUM_TIMEFRAMES period,
           int InputBBMaPeriod,  double InputDeviation,
           int InputBearBullPeriod, ENUM_BBLine InputBBLineType, int historyBars=5): CBaseIndicator(symbol, period)
     {
      m_MaPeriod = InputBBMaPeriod;
      m_BullBearPeriod = InputBearBullPeriod;
      m_Deviation = InputDeviation;
      m_BBLineType = InputBBLineType;

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
bool CiTrend::Init(void)
  {
   ArraySetAsSeries(m_NegBuffer, true);
   ArraySetAsSeries(m_PosBuffer, true);

   m_Handle = iCustom(m_Symbol, m_TF, "Articles\\iTrend", PRICE_CLOSE, m_MaPeriod, 0, m_Deviation,
                      PRICE_CLOSE, m_BBLineType, m_BullBearPeriod);
   return m_Handle != INVALID_HANDLE;
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
bool CiTrend::Refresh(int ShiftToUse=1)
  {
   m_ShiftToUse = ShiftToUse;
   int bullsCopied = CopyBuffer(m_Handle, 0, 0, mBarsToCopy, m_PosBuffer);
   int bearsCopied = CopyBuffer(m_Handle, 1, 0, mBarsToCopy, m_NegBuffer);

   return mBarsToCopy == bearsCopied && bearsCopied == bullsCopied;
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void CiTrend::Release(void)
  {
   IndicatorRelease(m_Handle);
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
double CiTrend::GetData(int bufferIndx=0, int shift=0)
  {
   if(shift >= mBarsToCopy || bufferIndx > 1)
      return EMPTY_VALUE;

   switch(bufferIndx)
     {
      case 0:
         return m_PosBuffer[shift];
      case 1:
         return m_NegBuffer[shift];
      default:
         return EMPTY_VALUE;
     }
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void CiTrend::GetData(double &buffer[], int bufferIndx=0, int shift=0)
  {
   if(shift >= mBarsToCopy || bufferIndx > 1)
      return;

   ArraySetAsSeries(buffer, true);
   ArrayResize(buffer, mBarsToCopy - shift);

   switch(bufferIndx)
     {
      case 0:
         ArrayCopy(buffer, m_PosBuffer, 0, shift);
         break;
      case 1:
      default:
         ArrayCopy(buffer, m_NegBuffer, 0, shift);
         break;
     }
  }
  
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
ENUM_ENTRY_SIGNAL CiTrend::TradeSignal()
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
