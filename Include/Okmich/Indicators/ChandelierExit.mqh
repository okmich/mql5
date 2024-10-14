//+------------------------------------------------------------------+
//|                                               ChandelierExit.mqh |
//|                                    Copyright 2020, Michael Enudi |
//|                                             okmich2002@yahoo.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2020, Michael Enudi"
#property link      "okmich2002@yahoo.com"
#property version   "1.00"

#include "BaseIndicator.mqh"

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
class CChandelierExit : public CBaseIndicator
  {
private :
   int               mBarsToCopy;
   //--- indicator settings
   int               m_AtrPeriod, m_Lookback;
   double            m_AtrMulti1, m_AtrMulti2;
   //--- indicator handle
   int               m_Handle;
   //--- indicator buffers
   double            mBull1Buffer[], mBear1Buffer[], mBull2Buffer[], mBear2Buffer[];

public:
                     CChandelierExit(string symbol, ENUM_TIMEFRAMES period,
                   int atrPeriod,
                   double atrMultiplier1,
                   double atrMultiplier2,
                   int lookbackPeriod,
                   int historyBars = 6): CBaseIndicator(symbol, period)
     {
      m_AtrPeriod = atrPeriod;
      m_AtrMulti1 = atrMultiplier1;
      m_AtrMulti2 = atrMultiplier2;
      m_Lookback = lookbackPeriod;

      mBarsToCopy = historyBars;
     };

   virtual bool                   Init();
   virtual bool                   Refresh(int ShiftToUse=1);
   virtual void                   Release();

   ENUM_ENTRY_SIGNAL              TradeSignal();

   double                         GetData(int buffer=0, int shift=0);
   void                           GetData(double &buffer[], int buffer=0, int shift=0);

   virtual double                 FirstExitMark(int shift=1);
   virtual double                 LastExitMark(int shift=1);

   int                            AlignmentStatement(int shift1);
   ENUM_EXIT_SIGNAL               ExitCondition(ENUM_POSITION_TYPE positionType, double closingPriceShift2, double closingPriceShift1);
  };

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
bool CChandelierExit::Init(void)
  {
   ArraySetAsSeries(mBull1Buffer, true);
   ArraySetAsSeries(mBear1Buffer, true);
   ArraySetAsSeries(mBull2Buffer, true);
   ArraySetAsSeries(mBear2Buffer, true);

   m_Handle = iCustom(m_Symbol, m_TF, "Articles\\Chandelier Exit", m_AtrPeriod, m_AtrMulti1, m_AtrMulti2, m_Lookback);
   return m_Handle != INVALID_HANDLE;
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
bool CChandelierExit::Refresh(int ShiftToUse=1)
  {
   m_ShiftToUse = ShiftToUse;
   int bulls1Copied = CopyBuffer(m_Handle, 0, 0, mBarsToCopy, mBull1Buffer);
   int bears1Copied = CopyBuffer(m_Handle, 1, 0, mBarsToCopy, mBear1Buffer);
   int bulls2Copied = CopyBuffer(m_Handle, 2, 0, mBarsToCopy, mBull2Buffer);
   int bears2Copied = CopyBuffer(m_Handle, 3, 0, mBarsToCopy, mBear2Buffer);

   return mBarsToCopy == bulls1Copied && bulls1Copied == bears1Copied
          && bears1Copied == bulls2Copied && bulls2Copied == bears2Copied;
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void CChandelierExit::Release(void)
  {
   IndicatorRelease(m_Handle);
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
ENUM_ENTRY_SIGNAL CChandelierExit::TradeSignal(void)
  {
   bool previousBarAligned = AlignmentStatement(1);
   bool previous2BarsAligned = AlignmentStatement(2);

   if(previous2BarsAligned != previousBarAligned && previousBarAligned != 0)
      return previousBarAligned == 1 ? ENTRY_SIGNAL_BUY : ENTRY_SIGNAL_SELL;

   return ENTRY_SIGNAL_NONE;
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
double CChandelierExit::GetData(int bufferIndx=0, int shift=0)
  {
   if(shift >= mBarsToCopy || bufferIndx > 3)
      return EMPTY_VALUE;

   switch(bufferIndx)
     {
      case 0:
         return mBull1Buffer[shift];
      case 1:
         return mBear1Buffer[shift];
      case 2:
         return mBull2Buffer[shift];
      case 3:
         return mBear2Buffer[shift];
      default:
         return EMPTY_VALUE;
     }
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void CChandelierExit::GetData(double &buffer[], int bufferIndx=0, int shift=0)
  {
   if(shift >= mBarsToCopy || bufferIndx > 1)
      return;

   ArraySetAsSeries(buffer, true);
   ArrayResize(buffer, mBarsToCopy - shift);

   switch(bufferIndx)
     {
      case 0:
         ArrayCopy(buffer, mBull1Buffer, 0, shift);
         break;
      case 1:
         ArrayCopy(buffer, mBear1Buffer, 0, shift);
         break;
      case 2:
         ArrayCopy(buffer, mBull2Buffer, 0, shift);
         break;
      case 3:
         ArrayCopy(buffer, mBear2Buffer, 0, shift);
         break;
     }
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
double CChandelierExit::FirstExitMark(int shift=1)
  {
   if(shift >= mBarsToCopy)
      return EMPTY_VALUE;

   if(mBull1Buffer[shift] == EMPTY_VALUE)
      return mBear1Buffer[shift];
   else
      return mBull1Buffer[shift];
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
double CChandelierExit::LastExitMark(int shift=1)
  {
   if(shift >= mBarsToCopy)
      return EMPTY_VALUE;

   if(mBull2Buffer[shift] == EMPTY_VALUE)
      return mBear2Buffer[shift];
   else
      return mBull2Buffer[shift];
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
int CChandelierExit::AlignmentStatement(int shift=1)
  {
   if(mBull1Buffer[shift] != EMPTY_VALUE && mBull2Buffer[shift] != EMPTY_VALUE)
      return 1;
   else
      if(mBear1Buffer[shift] != EMPTY_VALUE && mBear2Buffer[shift] != EMPTY_VALUE)
         return -1;
   return 0;
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
ENUM_EXIT_SIGNAL CChandelierExit::ExitCondition(ENUM_POSITION_TYPE positionType, double closingPriceShift2, double closingPriceShift1)
  {
   double level2Shift1 = LastExitMark(1);
   double level2Shift2 = LastExitMark(2);

   switch(positionType)
     {
      case POSITION_TYPE_BUY :
         return (closingPriceShift2 > level2Shift2 && closingPriceShift1 < level2Shift1) ? EXIT_SIGNAL_EXIT : EXIT_SIGNAL_HOLD;
         break;
      case POSITION_TYPE_SELL :
         return (closingPriceShift2 < level2Shift2 && closingPriceShift1 > level2Shift1) ? EXIT_SIGNAL_EXIT : EXIT_SIGNAL_HOLD;
         break;
      default:
         return EXIT_SIGNAL_HOLD;

     }
   return EXIT_SIGNAL_HOLD;
  }
//+------------------------------------------------------------------+
