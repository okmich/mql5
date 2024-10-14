//+------------------------------------------------------------------+
//|                                                          QQE.mqh |
//|                                    Copyright 2021, Michael Enudi |
//|                                             okmich2002@yahoo.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2021, Michael Enudi"
#property link      "okmich2002@yahoo.com"

#include "BaseIndicator.mqh"

enum ENUM_QQE_Strategies
  {
   QQE_MidLevelCrossover,
   QQE_BandCrossover,
   QQE_BandCrossover_2,
   QQE_MidLevelBandCrossover,
   QQE_MidLevelBandCrossover_2
  };

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
class CQqe : public CBaseIndicator
  {
private :
   int                mBarsToCopy;
   //--- indicator paramter
   int                m_RsiPeriod, m_SmoothFactor;
   double             m_FastPeriod, m_SlowPeriod;
   //--- indicator
   int                m_Handle;
   //--- indicator buffer
   double             m_QQEBuffer[], m_FastBuffer[], m_SlowBuffer[];

   ENUM_ENTRY_SIGNAL  MidLevelCrossoverSignal();
   ENUM_ENTRY_SIGNAL  BandCrossoverSignal();
   ENUM_ENTRY_SIGNAL  BandCrossoverSignal2();
   ENUM_ENTRY_SIGNAL  MidBasedBandCrossoverSignal();
   ENUM_ENTRY_SIGNAL  MidBasedBandCrossoverSignal2();

public:
                     CQqe(string symbol, ENUM_TIMEFRAMES period,
        int InputRSIPeriod=14, int InputSmoothFactor=14,
        double InputFastPeriod=2.618, double InputSlowPeriod=4.236): CBaseIndicator(symbol, period)
     {
      m_RsiPeriod = InputRSIPeriod;
      m_SmoothFactor = InputSmoothFactor;
      m_FastPeriod = InputFastPeriod;
      m_SlowPeriod = InputSlowPeriod;

      mBarsToCopy = 4;
     }

   virtual bool       Init();
   virtual bool       Refresh(int ShiftToUse=1);
   virtual void       Release();

   double             GetData(int bufferIndx=0, int shift=0);

   ENUM_ENTRY_SIGNAL  TradeSignal(ENUM_QQE_Strategies logicOption);
  };

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
bool CQqe::Init(void)
  {
   ArraySetAsSeries(m_QQEBuffer, true);
   ArraySetAsSeries(m_FastBuffer, true);
   ArraySetAsSeries(m_SlowBuffer, true);

   m_Handle = iCustom(m_Symbol, m_TF, "Articles\\QQE", m_RsiPeriod,
                      m_SmoothFactor, m_FastPeriod, m_SlowPeriod, PRICE_CLOSE);
   return m_Handle != INVALID_HANDLE;
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void CQqe::Release(void)
  {
   IndicatorRelease(m_Handle);
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
bool CQqe::Refresh(int ShiftToUse=1)
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
double CQqe::GetData(int bufferIndx=0, int shift=0)
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
ENUM_ENTRY_SIGNAL CQqe::MidBasedBandCrossoverSignal(void)
  {
   ENUM_ENTRY_SIGNAL signal = BandCrossoverSignal();
   if(m_QQEBuffer[2] > 50 && signal == ENTRY_SIGNAL_BUY)
      return signal;

   if(m_QQEBuffer[2] < 50 && signal == ENTRY_SIGNAL_SELL)
      return signal;

   return ENTRY_SIGNAL_NONE;
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
ENUM_ENTRY_SIGNAL CQqe::MidBasedBandCrossoverSignal2(void)
  {
   ENUM_ENTRY_SIGNAL signal = BandCrossoverSignal2();
   if(m_QQEBuffer[2] > 50 && signal == ENTRY_SIGNAL_BUY)
      return signal;

   if(m_QQEBuffer[2] < 50 && signal == ENTRY_SIGNAL_SELL)
      return signal;

   return ENTRY_SIGNAL_NONE;
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
ENUM_ENTRY_SIGNAL CQqe::BandCrossoverSignal(void)
  {
   if(m_QQEBuffer[2] > m_FastBuffer[2] && m_QQEBuffer[1] < m_FastBuffer[1])
      return ENTRY_SIGNAL_SELL;
   else
      if(m_QQEBuffer[2] < m_FastBuffer[2] && m_QQEBuffer[1] > m_FastBuffer[1])
         return ENTRY_SIGNAL_BUY;
      else
         return ENTRY_SIGNAL_NONE;
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
ENUM_ENTRY_SIGNAL CQqe::BandCrossoverSignal2(void)
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
ENUM_ENTRY_SIGNAL CQqe::MidLevelCrossoverSignal(void)
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
ENUM_ENTRY_SIGNAL CQqe::TradeSignal(ENUM_QQE_Strategies logicOption)
  {
   switch(logicOption)
     {
      case QQE_BandCrossover:
         return BandCrossoverSignal();
      case QQE_BandCrossover_2:
         return BandCrossoverSignal2();
      case QQE_MidLevelCrossover:
         return MidLevelCrossoverSignal();
      case QQE_MidLevelBandCrossover:
         return MidBasedBandCrossoverSignal();
      case QQE_MidLevelBandCrossover_2:
         return MidBasedBandCrossoverSignal2();
      default:
         return ENTRY_SIGNAL_NONE;
     }
  }
//+------------------------------------------------------------------+
