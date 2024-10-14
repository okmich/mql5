//+------------------------------------------------------------------+
//|                                       ChannelBreakoutScanBot.mqh |
//|                                    Copyright 2020, Michael Enudi |
//|                                             okmich2002@yahoo.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2020, Michael Enudi"
#property link      "okmich2002@yahoo.com"

#include "MarketScanner.mqh"
const string BOT_CODE_SUFFIX = "CHNBRK";
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
class CChannelBreakoutBot : public CBaseBot
  {
private:
   //--- indicator settings
   int               m_NumberOfBars;
   //--- indicator handles
   double            highs[], lows[], closes[];

   bool              Setup();
   int               getLastHighestClose(int i, int MAX=10);
   int               getLastLowestClose(int i, int MAX=10);

public:
                     CChannelBreakoutBot(string symbol, ENUM_TIMEFRAMES tf,
                       int numberOfBars) : CBaseBot(IntegerToString(numberOfBars)+BOT_CODE_SUFFIX, tf, symbol)
     {
      m_NumberOfBars = numberOfBars;
     };

                    ~CChannelBreakoutBot() {};

   //this is the main implementation for this bot.
   virtual void      Begin();
  };

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
bool CChannelBreakoutBot::Setup(void)
  {
   ArraySetAsSeries(highs, true);
   ArraySetAsSeries(lows, true);
   ArraySetAsSeries(closes, true);

   return true;
  }


//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void CChannelBreakoutBot::Begin(void)
  {
   if(!Setup())
     {
      mWorthReporting = false;
      return ;
     }
   int highsCopied = CopyHigh(mSymbol, mTimeFrame, mShiftIndex, m_NumberOfBars+6, highs);
   int lowsCopied = CopyLow(mSymbol, mTimeFrame, mShiftIndex, m_NumberOfBars+6, lows);
   int closeCopied = CopyClose(mSymbol, mTimeFrame, mShiftIndex, m_NumberOfBars+6, closes);

   double currentClose = closes[mShiftIndex];
   int maxHighArg = ArrayMaximum(highs, 1);
   int minLowArg = ArrayMinimum(lows, 1);
   if(currentClose > highs[maxHighArg])
     {
      mSignal = ENTRY_SIGNAL_BUY;
      int t = getLastHighestClose(mShiftIndex+1, 20);
      mScore = (20 - t)/2;
      mWorthReporting = mScore >= 0;
     }
   else
      if(currentClose < lows[minLowArg])
        {
         mSignal = ENTRY_SIGNAL_SELL;
         int t = getLastLowestClose(mShiftIndex+1, 20);
         mScore = (20 - t)/2;
         mWorthReporting = mScore >= 0;
        }
//--- prepare the result if worthreporting
   if(mWorthReporting)
      mScanValues = CurrentCandleProperties(mShiftIndex);
  }


//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
int CChannelBreakoutBot::getLastHighestClose(int i,int MAX=10)
  {
   if(i >= MAX)
      return i-1;

   int maxHighArg = ArrayMaximum(highs, i+1);
   if(maxHighArg > -1 && closes[i] > highs[maxHighArg])
     {
      return getLastHighestClose(i+1, MAX);
     }
   else
      return i-1;
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
int CChannelBreakoutBot::getLastLowestClose(int i, int MAX=10)
  {
   if(i >= MAX)
      return i-1;

   int maxLowArg = ArrayMinimum(lows, i+1);
   if(maxLowArg > -1 && closes[i] > lows[maxLowArg])
     {
      return getLastLowestClose(i+1, MAX);
     }
   else
      return i-1;
  }
//+------------------------------------------------------------------+
