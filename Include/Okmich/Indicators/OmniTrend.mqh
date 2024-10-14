//+------------------------------------------------------------------+
//|                                                    OmniTrend.mqh |
//|                                                    Michael Enudi |
//|                                             okmich2002@yahoo.com |
//+------------------------------------------------------------------+
#property copyright "Michael Enudi"
#property link      "okmich2002@yahoo.com"

#include "BaseIndicator.mqh"

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
class COmniTrend : public CBaseIndicator
  {
private :
   int                mBarsToCopy;
   //--- indicator paramter
   int                m_MaPeriod, m_AtrPeriod;
   double             m_AtrMultiplier, m_OffsetFactor;
   ENUM_MA_TYPE      m_Smoothing_method;
   //--- indicator
   int                m_Handle;
   //--- indicator buffer
   double             m_UpBuffer[], m_DownBuffer[];

   bool               IsEmpty(double arg);

public:
                     COmniTrend(string symbol, ENUM_TIMEFRAMES period, int InputMaPeriod=32, int InputAtrPeriod=20,
              ENUM_MA_TYPE InptSmoothingMethod=MA_TYPE_EMA,  double InputAtrMultiplier=1.5, double InputOffsetFactor=3,
              int historyBars=10): CBaseIndicator(symbol, period)
     {
      m_MaPeriod = InputMaPeriod;
      m_Smoothing_method = InptSmoothingMethod;
      m_AtrPeriod = InputAtrPeriod;
      m_AtrMultiplier = InputAtrMultiplier;
      m_OffsetFactor = InputOffsetFactor;

      mBarsToCopy = historyBars;
     }

   virtual bool        Init();
   virtual bool        Refresh(int ShiftToUse=1);
   virtual void        Release();

   double              GetData(int bufferIndex=0, int shift=0);
   void                GetData(double &buffer[], int bufferIndex=0, int shift=0);

   ENUM_ENTRY_SIGNAL   TradeFilter(int shift=1);
   ENUM_ENTRY_SIGNAL   TradeSignal();
  };

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
bool COmniTrend::Init(void)
  {
   ArraySetAsSeries(m_UpBuffer, true);
   ArraySetAsSeries(m_DownBuffer, true);
   m_Handle = iCustom(m_Symbol, m_TF, "Articles\\Omni Trend", m_MaPeriod, m_Smoothing_method, PRICE_CLOSE, m_AtrPeriod,
                      m_AtrMultiplier, m_OffsetFactor, 0);
   return m_Handle != INVALID_HANDLE;
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
bool COmniTrend::Refresh(int ShiftToUse=1)
  {
   m_ShiftToUse = ShiftToUse;
   int copied1 = CopyBuffer(m_Handle, 0, 0, mBarsToCopy, m_UpBuffer);
   int copied2 = CopyBuffer(m_Handle, 1, 0, mBarsToCopy, m_DownBuffer);
   return mBarsToCopy == copied1 && copied1 == copied2;
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void COmniTrend::Release(void)
  {
   IndicatorRelease(m_Handle);
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
double COmniTrend::GetData(int bufferIndex=0, int shift=0)
  {
   if(shift >= mBarsToCopy || bufferIndex > 1)
      return EMPTY_VALUE;

   if(bufferIndex == 0)
      return m_UpBuffer[shift];
   else
      if(bufferIndex == 1)
         return m_DownBuffer[shift];
      else
         return EMPTY_VALUE;
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void COmniTrend::GetData(double &buffer[], int bufferIndex=0, int shift=0)
  {
   if(shift >= mBarsToCopy || bufferIndex > 1)
      return;

   ArraySetAsSeries(buffer, true);
   ArrayResize(buffer, mBarsToCopy - shift);

   if(bufferIndex == 0)
      ArrayCopy(buffer, m_UpBuffer, 0, shift);
   else
      if(bufferIndex == 1)
         ArrayCopy(buffer, m_DownBuffer, 0, shift);
      else
         return;
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
ENUM_ENTRY_SIGNAL COmniTrend::TradeSignal()
  {
   ENUM_ENTRY_SIGNAL filterShift1 = TradeFilter(m_ShiftToUse);
   ENUM_ENTRY_SIGNAL filterShift2 = TradeFilter(m_ShiftToUse+1);
   if(filterShift2 != filterShift1 && filterShift1 != ENTRY_SIGNAL_NONE)
      return filterShift1;
   else
      return ENTRY_SIGNAL_NONE;
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
ENUM_ENTRY_SIGNAL COmniTrend::TradeFilter(int shift=1)
  {
   if(IsEmpty(m_UpBuffer[shift]) && !IsEmpty(m_DownBuffer[shift]))
      return ENTRY_SIGNAL_SELL;
   else
      if(!IsEmpty(m_UpBuffer[shift]) && IsEmpty(m_DownBuffer[shift]))
         return ENTRY_SIGNAL_BUY;
      else
         return ENTRY_SIGNAL_NONE;
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
bool COmniTrend::IsEmpty(double arg)
  {
   return arg == EMPTY_VALUE || arg == 0.0;
  }
//+------------------------------------------------------------------+
