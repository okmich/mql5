//+------------------------------------------------------------------+
//|                                                  QQEofRsiOma.mqh |
//|                                    Copyright 2021, Michael Enudi |
//|                                             okmich2002@yahoo.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2021, Michael Enudi"
#property link      "okmich2002@yahoo.com"

#include "BaseIndicator.mqh"

enum ENUM_QQEofRsiOma_Strategies
  {
   QQERsiOma_MidLevelCrossover,
   QQERsiOma_FastSlowCrossover,
   QQERsiOma_MidLevelFastSlowCrossover,
  };

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
class CQQERsiOma : public CBaseIndicator
  {
private :
   int                mBarsToCopy;
   //--- indicator paramter
   int                m_RsiPeriod, m_AvgPeriod, m_SmoothFactor;
   double             m_FastPeriod, m_SlowPeriod;
   ENUM_MA_METHOD     m_AvgMethod;
   //--- indicator
   int                m_Handle;
   //--- indicator buffer
   double             m_QQEBuffer[], m_FastBuffer[], m_SlowBuffer[];

   ENUM_ENTRY_SIGNAL  MidLevelCrossoverSignal();
   ENUM_ENTRY_SIGNAL  FastSlowCrossoverSignal();
   ENUM_ENTRY_SIGNAL  MidBasedFastSlowCrossoverSignal();

public:
                     CQQERsiOma(string symbol, ENUM_TIMEFRAMES period,
        int InputRSIPeriod=14, int InputAvgPeriod=32, ENUM_MA_METHOD InputAgvMethod=MODE_EMA,
        int InputSmoothFactor=5, double InputFastPeriod=2.618, double InputSlowPeriod=4.236): CBaseIndicator(symbol, period)
     {
      m_RsiPeriod = InputRSIPeriod;
      m_AvgPeriod = InputAvgPeriod;
      m_AvgMethod = InputAgvMethod;
      m_SmoothFactor = InputSmoothFactor;
      m_FastPeriod = InputFastPeriod;
      m_SlowPeriod = InputSlowPeriod;

      mBarsToCopy = 4;
     }

   virtual bool       Init();
   virtual bool       Refresh(int ShiftToUse=1);
   virtual void       Release();

   double             GetData(int bufferIndx=0, int shift=0);

   ENUM_ENTRY_SIGNAL  TradeSignal(ENUM_QQEofRsiOma_Strategies logicOption);
  };

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
bool CQQERsiOma::Init(void)
  {
   ArraySetAsSeries(m_QQEBuffer, true);
   ArraySetAsSeries(m_FastBuffer, true);
   ArraySetAsSeries(m_SlowBuffer, true);

   m_Handle = iCustom(m_Symbol, m_TF, "Articles\\QQE of rsi(oma)", m_RsiPeriod,
                      m_AvgPeriod, m_AvgMethod, m_SmoothFactor, 
                      m_FastPeriod, m_SlowPeriod, PRICE_CLOSE);
   return m_Handle != INVALID_HANDLE;
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void CQQERsiOma::Release(void)
  {
   IndicatorRelease(m_Handle);
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
bool CQQERsiOma::Refresh(int ShiftToUse=1)
  {
   m_ShiftToUse = ShiftToUse;
   int mainCopied = CopyBuffer(m_Handle, 2, 0, mBarsToCopy, m_QQEBuffer);
   int fastCopied = CopyBuffer(m_Handle, 0, 0, mBarsToCopy, m_FastBuffer);
   int slowcopied = CopyBuffer(m_Handle, 1, 0, mBarsToCopy, m_SlowBuffer);

   return mainCopied == fastCopied && fastCopied == slowcopied && mainCopied ==mBarsToCopy;
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
double CQQERsiOma::GetData(int bufferIndx=0, int shift=0)
  {
   if(shift >= mBarsToCopy || bufferIndx > 2)
      return EMPTY_VALUE;

   switch(bufferIndx)
     {
      case 1:
         return m_FastBuffer[shift];
      case 2:
         return m_SlowBuffer[shift];
      case 0:
      default:
         return m_QQEBuffer[shift];
     }
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
ENUM_ENTRY_SIGNAL CQQERsiOma::MidBasedFastSlowCrossoverSignal(void)
  {
   ENUM_ENTRY_SIGNAL signal = FastSlowCrossoverSignal();
   if(m_QQEBuffer[2] > 50 && signal == ENTRY_SIGNAL_BUY)
      return signal;

   if(m_QQEBuffer[2] < 50 && signal == ENTRY_SIGNAL_SELL)
      return signal;

   return ENTRY_SIGNAL_NONE;
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
ENUM_ENTRY_SIGNAL CQQERsiOma::FastSlowCrossoverSignal(void)
  {
   if(m_QQEBuffer[2] > m_SlowBuffer[2] && m_QQEBuffer[1] < m_SlowBuffer[1])
      return ENTRY_SIGNAL_SELL;
   else
      if(m_QQEBuffer[2] < m_SlowBuffer[2] && m_QQEBuffer[1] > m_SlowBuffer[1])
         return ENTRY_SIGNAL_BUY;
      else
         return ENTRY_SIGNAL_NONE;
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
ENUM_ENTRY_SIGNAL CQQERsiOma::MidLevelCrossoverSignal(void)
  {
   if(m_QQEBuffer[2] > 50 && m_QQEBuffer[1] <= 50)
      return ENTRY_SIGNAL_SELL;
   else
      if(m_QQEBuffer[2] < 50 && m_QQEBuffer[1] >= 50)
         return ENTRY_SIGNAL_BUY;
      else
         return ENTRY_SIGNAL_NONE;
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
ENUM_ENTRY_SIGNAL CQQERsiOma::TradeSignal(ENUM_QQEofRsiOma_Strategies logicOption)
  {
   switch(logicOption)
     {
      case QQERsiOma_FastSlowCrossover:
         return FastSlowCrossoverSignal();
      case QQERsiOma_MidLevelCrossover:
         return MidLevelCrossoverSignal();
      case QQERsiOma_MidLevelFastSlowCrossover:
         return MidBasedFastSlowCrossoverSignal();
      default:
         return ENTRY_SIGNAL_NONE;
     }
  }
//+------------------------------------------------------------------+
