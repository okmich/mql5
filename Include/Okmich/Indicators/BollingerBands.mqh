//+------------------------------------------------------------------+
//|                                              CBollingerBands.mqh |
//|                                    Copyright 2021, Michael Enudi |
//|                                             okmich2002@yahoo.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2020, Michael Enudi"
#property link      "okmich2002@yahoo.com"
#property version   "1.00"

#include "BaseIndicator.mqh"
#include <Okmich\Common\Common.mqh>

enum ENUM_BB_Strategies
  {
   BB_AboveBelow_Bands,
   BB_AboveBelow_MidLine
  };

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
class CBollingerBands : public CBaseIndicator
  {
private :
   int                mBarsToCopy;
   //--- indicator paramter
   int                m_MaPeriod;
   double             m_Deviation;
   //--- indicator
   int                m_BbsHandle;
   //--- indicator buffer
   double             m_UpperBandBuffer[], m_MiddleBandBuffer[], m_LowerBandBuffer[];
   double             m_PercentBandBuffer[], m_BBWidthBuffer[], m_ClosePrices[];
   //--- other variables

   ENUM_ENTRY_SIGNAL  AboveBelowMidLine();
   ENUM_ENTRY_SIGNAL  AboveBelowBands();

public:
                     CBollingerBands(string symbol, ENUM_TIMEFRAMES period,
                   int InputMaPeriod=20, double InputDeviation=2.0,
                   int InputRankSqueezePeriod=126): CBaseIndicator(symbol, period)
     {
      m_MaPeriod = InputMaPeriod;
      m_Deviation = InputDeviation;
      mBarsToCopy = InputRankSqueezePeriod;
     }

   virtual bool        Init();
   virtual bool        Refresh(int ShiftToUse=1);
   virtual void        Release();

   double              GetData(int buffer=0, int shift=0);
   void                GetData(double &buffer[], int buffer=0, int shift=0);

   double              MovingAverage(int shift=1);
   double              PercentB(int shift=1);
   double              Squeeze(int shift=1);
   double              RankedSqueeze(int shift=1);
   double              LowerBand(int shift=1);
   double              UpperBand(int shift=1);

   ENUM_ENTRY_SIGNAL   TradeSignal(ENUM_BB_Strategies strategyOption);
  };

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
bool CBollingerBands::Init(void)
  {
   ArraySetAsSeries(m_UpperBandBuffer, true);
   ArraySetAsSeries(m_MiddleBandBuffer, true);
   ArraySetAsSeries(m_LowerBandBuffer, true);
   ArraySetAsSeries(m_BBWidthBuffer, true);
   ArraySetAsSeries(m_PercentBandBuffer, true);

   ArraySetAsSeries(m_ClosePrices, true);

   m_BbsHandle = iBands(m_Symbol, m_TF, m_MaPeriod, 0, m_Deviation, PRICE_CLOSE);

   return m_BbsHandle != INVALID_HANDLE;
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void CBollingerBands::Release(void)
  {
   IndicatorRelease(m_BbsHandle);
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
bool CBollingerBands::Refresh(int ShiftToUse=1)
  {
   m_ShiftToUse = ShiftToUse;
   int copiedBars = mBarsToCopy+5;
   int middleCopied = CopyBuffer(m_BbsHandle, 0, 0, copiedBars, m_MiddleBandBuffer);
   int upperCopied = CopyBuffer(m_BbsHandle, 1, 0, copiedBars, m_UpperBandBuffer);
   int lowerCopied = CopyBuffer(m_BbsHandle, 2, 0, copiedBars, m_LowerBandBuffer);

   int closeCopied = CopyClose(m_Symbol, m_TF, 0, copiedBars, m_ClosePrices);

   ArrayResize(m_BBWidthBuffer, copiedBars);
   ArrayResize(m_PercentBandBuffer, copiedBars);

   double iBandRange = 0;
   for(int i=0; i<copiedBars; i++)
     {
      iBandRange = m_UpperBandBuffer[i] - m_LowerBandBuffer[i];
      m_BBWidthBuffer[i] = (iBandRange/m_MiddleBandBuffer[i]);
      m_PercentBandBuffer[i] = (iBandRange == 0) ? 0 : (m_ClosePrices[i] - m_LowerBandBuffer[i])/iBandRange;
     }

   return copiedBars == upperCopied && upperCopied == middleCopied && middleCopied == lowerCopied;
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
double CBollingerBands::GetData(int bufferIndx=0, int shift=0)
  {
   if(shift >= mBarsToCopy || bufferIndx > 4)
      return EMPTY_VALUE;

   switch(bufferIndx)
     {
      case 0:
         return m_UpperBandBuffer[shift];
      case 1:
         return m_MiddleBandBuffer[shift];
      case 2:
         return m_LowerBandBuffer[shift];
      case 3:
         return m_BBWidthBuffer[shift];
      case 4:
         return m_PercentBandBuffer[shift];
      default:
         return EMPTY_VALUE;
     }

  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void CBollingerBands::GetData(double &buffer[], int bufferIndx=0, int shift=0)
  {
   if(shift >= mBarsToCopy || bufferIndx > 4)
      return;

   ArraySetAsSeries(buffer, true);
   ArrayResize(buffer, mBarsToCopy - shift);

   switch(bufferIndx)
     {
      case 0:
         ArrayCopy(buffer, m_UpperBandBuffer, 0, shift);
         break;
      case 1:
         ArrayCopy(buffer, m_MiddleBandBuffer, 0, shift);
         break;
      case 2:
         ArrayCopy(buffer, m_LowerBandBuffer, 0, shift);
         break;
      case 3:
         ArrayCopy(buffer, m_BBWidthBuffer, 0, shift);
         break;
      case 4:
         ArrayCopy(buffer, m_PercentBandBuffer, 0, shift);
         break;
      default:
         break;
     }
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
double CBollingerBands::MovingAverage(int shift=1)
  {
   if(shift >= mBarsToCopy)
      return 0;

   return m_MiddleBandBuffer[shift];
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
double CBollingerBands::UpperBand(int shift=1)
  {
   if(shift >= mBarsToCopy)
      return 0;

   return m_UpperBandBuffer[shift];
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
double CBollingerBands::LowerBand(int shift=1)
  {
   if(shift >= mBarsToCopy)
      return 0;

   return m_LowerBandBuffer[shift];
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
double CBollingerBands::PercentB(int shift=1)
  {
   if(shift >= mBarsToCopy)
      return EMPTY_VALUE;

   return m_PercentBandBuffer[shift];
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
double CBollingerBands::Squeeze(int shift=1)
  {
   if(shift >= mBarsToCopy)
      return EMPTY_VALUE;

   return m_BBWidthBuffer[shift];
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
double CBollingerBands::RankedSqueeze(int shift=1)
  {
   if(mBarsToCopy < shift+5)
      return EMPTY_VALUE;

   return PercentRank(m_BBWidthBuffer, shift, mBarsToCopy);
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
ENUM_ENTRY_SIGNAL CBollingerBands::AboveBelowBands(void)
  {
   if(m_ClosePrices[m_ShiftToUse+1] < m_UpperBandBuffer[m_ShiftToUse+1] &&
      m_ClosePrices[m_ShiftToUse] > m_UpperBandBuffer[m_ShiftToUse])
      return ENTRY_SIGNAL_BUY;
   else
      if(m_ClosePrices[m_ShiftToUse+1] > m_LowerBandBuffer[m_ShiftToUse+1] &&
         m_ClosePrices[m_ShiftToUse] < m_LowerBandBuffer[m_ShiftToUse])
         return ENTRY_SIGNAL_SELL;
      else
         return ENTRY_SIGNAL_NONE;
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
ENUM_ENTRY_SIGNAL CBollingerBands::AboveBelowMidLine(void)
  {
   if(m_ClosePrices[m_ShiftToUse] > m_MiddleBandBuffer[m_ShiftToUse])
      return ENTRY_SIGNAL_BUY;
   else
      if(m_ClosePrices[m_ShiftToUse] < m_MiddleBandBuffer[m_ShiftToUse])
         return ENTRY_SIGNAL_SELL;
      else
         return ENTRY_SIGNAL_NONE;
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
ENUM_ENTRY_SIGNAL CBollingerBands::TradeSignal(ENUM_BB_Strategies strategyOption)
  {
   switch(strategyOption)
     {
      case BB_AboveBelow_MidLine:
         return AboveBelowMidLine();
      case BB_AboveBelow_Bands:
         return AboveBelowBands();
      default:
         return ENTRY_SIGNAL_NONE;
     }
  }
//+------------------------------------------------------------------+
