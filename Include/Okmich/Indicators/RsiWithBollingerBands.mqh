//+------------------------------------------------------------------+
//|                                        RsiWithBollingerBands.mqh |
//|                                    Copyright 2023, Michael Enudi |
//|                                             okmich2002@yahoo.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2023, Michael Enudi"
#property link      "okmich2002@yahoo.com"


#include "BaseIndicator.mqh"

enum ENUM_RsiBB_Strategies
  {
   RsiBB_RsiBBMid_Crossover,
   RsiBB_RsiBBObOsEntry,
   RsiBB_RsiBBObOsExit,
   RsiBB_RsiSignal_Crossover
  };

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
class CRsiBBands : public CBaseIndicator
  {
private :
   int               mBarsToCopy;
   //--- indicator paramter
   int               mRsiPeriod, mRsiMaPeriod, mBBMaPeriod;
   double            mBBDeviatn;
   //--- indicator handle
   int                m_Handle;
   //--- indicator buffer
   double             m_RsiBuffer[], m_BBMidBuffer[], m_BBTlBuffer[], m_BBBlBuffer[], m_RsiMaBuffer[];

   ENUM_ENTRY_SIGNAL  RsiBBMidCrossover();
   ENUM_ENTRY_SIGNAL  RsiBBObOsEntry();
   ENUM_ENTRY_SIGNAL  RsiBBObOsExit();
   ENUM_ENTRY_SIGNAL  RsiSignalCrossover();

public:
                     CRsiBBands(string symbol, ENUM_TIMEFRAMES period, int InptRsiPeriod,
              int InptBBMaPeriod, double InptBBDeviation, int IntRsiMaPeriod,
              int historyBars=6): CBaseIndicator(symbol, period)
     {
      mRsiPeriod = InptRsiPeriod;
      mRsiMaPeriod = IntRsiMaPeriod;
      mBBMaPeriod = InptBBMaPeriod;
      mBBDeviatn = InptBBDeviation;

      mBarsToCopy = historyBars;
     }

   virtual bool       Init();
   virtual bool       Refresh(int ShiftToUse=1);
   virtual void       Release();

   double             GetData(int bufferIndx=0, int shift=0);
   void               GetData(double &buffer[], int bufferIndx=0, int shift=0);

   double             Rsi(int ShiftToUse=1);
   double             RsiMa(int ShiftToUse=1);
   double             BBMid(int ShiftToUse=1);
   double             BBTop(int ShiftToUse=1);
   double             BBBottom(int ShiftToUse=1);

   ENUM_ENTRY_SIGNAL  TradeSignal(ENUM_RsiBB_Strategies signalOption);
  };

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
bool CRsiBBands::Init(void)
  {
   ArraySetAsSeries(m_RsiBuffer, true);
   ArraySetAsSeries(m_BBMidBuffer, true);
   ArraySetAsSeries(m_BBTlBuffer, true);
   ArraySetAsSeries(m_BBBlBuffer, true);
   ArraySetAsSeries(m_RsiMaBuffer, true);

   m_Handle = iCustom(m_Symbol, m_TF, "Okmich\\RSI_With_BollingerBands",
                      mRsiPeriod, mBBMaPeriod, mBBDeviatn, mRsiMaPeriod);

   return m_Handle != INVALID_HANDLE;
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
bool CRsiBBands::Refresh(int ShiftToUse=1)
  {
   m_ShiftToUse = ShiftToUse;
   CopyBuffer(m_Handle, 0, 0, mBarsToCopy, m_RsiBuffer);
   CopyBuffer(m_Handle, 1, 0, mBarsToCopy, m_BBTlBuffer);
   CopyBuffer(m_Handle, 2, 0, mBarsToCopy, m_BBMidBuffer);
   CopyBuffer(m_Handle, 3, 0, mBarsToCopy, m_BBBlBuffer);
   CopyBuffer(m_Handle, 4, 0, mBarsToCopy, m_RsiMaBuffer);

   return true;
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void CRsiBBands::Release(void)
  {
   IndicatorRelease(m_Handle);
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
double CRsiBBands::GetData(int bufferIndx=0, int shift=0)
  {
   if(shift >= mBarsToCopy || bufferIndx > 4)
      return EMPTY_VALUE;

   switch(bufferIndx)
     {
      case 0:
         return m_RsiBuffer[shift];
      case 1:
         return m_BBMidBuffer[shift];
      case 2:
         return m_BBTlBuffer[shift];
      case 3:
         return m_BBBlBuffer[shift];
      case 4:
         return m_RsiMaBuffer[shift];
      default:
         return EMPTY_VALUE;
     }
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void CRsiBBands::GetData(double &buffer[], int bufferIndx=0, int shift=0)
  {
   if(shift >= mBarsToCopy || bufferIndx > 3)
      return;

   ArraySetAsSeries(buffer, true);
   ArrayResize(buffer, mBarsToCopy - shift);

   switch(bufferIndx)
     {
      case 0:
         ArrayCopy(buffer, m_RsiBuffer, 0, shift);
         break;
      case 1:
         ArrayCopy(buffer, m_BBMidBuffer, 0, shift);
         break;
      case 2:
         ArrayCopy(buffer, m_BBTlBuffer, 0, shift);
         break;
      case 3:
         ArrayCopy(buffer, m_BBBlBuffer, 0, shift);
         break;
      case 4:
         ArrayCopy(buffer, m_RsiMaBuffer, 0, shift);
         break;
      default:
         break;
     }
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
ENUM_ENTRY_SIGNAL CRsiBBands::RsiBBMidCrossover(void)
  {
//m_ShiftToUse
   if(m_RsiBuffer[m_ShiftToUse+1] < m_BBMidBuffer[m_ShiftToUse+1] &&
      m_RsiBuffer[m_ShiftToUse] > m_BBMidBuffer[m_ShiftToUse])
      return ENTRY_SIGNAL_BUY;
   else
      if(m_RsiBuffer[m_ShiftToUse+1] > m_BBMidBuffer[m_ShiftToUse+1] &&
         m_RsiBuffer[m_ShiftToUse] < m_BBMidBuffer[m_ShiftToUse])
         return ENTRY_SIGNAL_SELL;
      else
         return ENTRY_SIGNAL_NONE;
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
ENUM_ENTRY_SIGNAL CRsiBBands::RsiBBObOsEntry(void)
  {
   if(m_RsiBuffer[m_ShiftToUse+1] > m_BBBlBuffer[m_ShiftToUse+1] &&
      m_RsiBuffer[m_ShiftToUse] < m_BBBlBuffer[m_ShiftToUse])  //crossing the lower bband downward
      return ENTRY_SIGNAL_BUY;
   else
      if(m_RsiBuffer[m_ShiftToUse+1] < m_BBTlBuffer[m_ShiftToUse+1] &&
         m_RsiBuffer[m_ShiftToUse] > m_BBTlBuffer[m_ShiftToUse])   //crossing the upper bband upward
         return ENTRY_SIGNAL_SELL;
      else
         return ENTRY_SIGNAL_NONE;
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
ENUM_ENTRY_SIGNAL CRsiBBands::RsiBBObOsExit(void)
  {
   if(m_RsiBuffer[m_ShiftToUse+1] < m_BBBlBuffer[m_ShiftToUse+1] &&
      m_RsiBuffer[m_ShiftToUse] > m_BBBlBuffer[m_ShiftToUse]) //crossing the lower bband upward
      return ENTRY_SIGNAL_BUY;
   else
      if(m_RsiBuffer[m_ShiftToUse+1] > m_BBTlBuffer[m_ShiftToUse+1]&&
         m_RsiBuffer[m_ShiftToUse] < m_BBTlBuffer[m_ShiftToUse])  //crossing the upper bband downward
         return ENTRY_SIGNAL_SELL;
      else
         return ENTRY_SIGNAL_NONE;
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
ENUM_ENTRY_SIGNAL CRsiBBands::RsiSignalCrossover(void)
  {
//m_ShiftToUse
   if(m_RsiBuffer[m_ShiftToUse+1] < m_RsiMaBuffer[m_ShiftToUse+1] &&
      m_RsiBuffer[m_ShiftToUse] > m_RsiMaBuffer[m_ShiftToUse])
      return ENTRY_SIGNAL_BUY;
   else
      if(m_RsiBuffer[m_ShiftToUse+1] > m_RsiMaBuffer[m_ShiftToUse+1] &&
         m_RsiBuffer[m_ShiftToUse] < m_RsiMaBuffer[m_ShiftToUse])
         return ENTRY_SIGNAL_SELL;
      else
         return ENTRY_SIGNAL_NONE;
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
ENUM_ENTRY_SIGNAL CRsiBBands::TradeSignal(ENUM_RsiBB_Strategies signalOption)
  {
   switch(signalOption)
     {
      case RsiBB_RsiBBMid_Crossover:
         return RsiBBMidCrossover();
      case RsiBB_RsiBBObOsEntry:
         return RsiBBObOsEntry();
      case RsiBB_RsiBBObOsExit:
         return RsiBBObOsExit();
      case RsiBB_RsiSignal_Crossover:
         return RsiSignalCrossover();
      default:
         return ENTRY_SIGNAL_NONE;
     }
  }
//+------------------------------------------------------------------+
