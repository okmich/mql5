//+------------------------------------------------------------------+
//|                                         ADXOscillatorScanBot.mqh |
//|                                    Copyright 2020, Michael Enudi |
//|                                             okmich2002@yahoo.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2020, Michael Enudi"
#property link      "okmich2002@yahoo.com"

#include "MarketScanner.mqh"
#define ADX_OSC_IND "Okmich\\ADX Oscillator"

const string BOT_CODE_SUFFIX = "ADX_OSC";
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
class CADXOscillatorScanBot : public CBaseBot
  {
private:
   //--- indicator settings
   int               mADXPeriod;
   double            mTrendIndication;
   //--- indicator handles
   int               mAdxOscHandle;
   //--- indicator buffers
   double            mADXBuffer[], mOscBuffer[];
   double            mDIPlusBuffer[], mDIMinusBuffer[];

   bool              Setup();

public:
                     CADXOscillatorScanBot(string symbol, ENUM_TIMEFRAMES tf,
                         int adxPeriod = 14,int trendIndThreshold = 24) : CBaseBot(BOT_CODE_SUFFIX, tf, symbol)
     {
      mADXPeriod = adxPeriod;
      mTrendIndication = trendIndThreshold;
     };

                    ~CADXOscillatorScanBot()
     {
      IndicatorRelease(mAdxOscHandle);
     };

   //this is the main implementation for this bot.
   virtual void      Begin();
  };

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
bool CADXOscillatorScanBot::Setup(void)
  {
   ArraySetAsSeries(mADXBuffer, true);
   ArraySetAsSeries(mOscBuffer, true);
   ArraySetAsSeries(mDIPlusBuffer, true);
   ArraySetAsSeries(mDIMinusBuffer, true);

   mAdxOscHandle  = iCustom(mSymbol, mTimeFrame, ADX_OSC_IND, mADXPeriod);

   if(mAdxOscHandle == INVALID_HANDLE)
      return false;

   return true;
  }


//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void CADXOscillatorScanBot::Begin(void)
  {
   if(!Setup())
     {
      mWorthReporting = false;
      return ;
     }
   int barsToCopy = 4;

   int adxCopied = CopyBuffer(mAdxOscHandle, 0, mShiftIndex, barsToCopy, mADXBuffer);
   int oscCopied = CopyBuffer(mAdxOscHandle, 1, mShiftIndex, barsToCopy, mOscBuffer);
   int dpCopied = CopyBuffer(mAdxOscHandle, 2, mShiftIndex, barsToCopy, mDIPlusBuffer);
   int dmCopied = CopyBuffer(mAdxOscHandle, 3, mShiftIndex, barsToCopy, mDIMinusBuffer);

   if(adxCopied != oscCopied || oscCopied != dpCopied || dpCopied != dmCopied)
      return;

//we are not looking for non-trending regime
   if(mADXBuffer[0] < mTrendIndication)
      return;

   mSignal = ENTRY_SIGNAL_NONE;

// strong upward trend
   if(mOscBuffer[0] > 0 && mOscBuffer[0] > mOscBuffer[1])
     {
      mSignal = ENTRY_SIGNAL_BUY;
      mScore = 10;
     }
// osc is below 0 but increasing and ADX is increasing
// so we want to cautiously see if we can catch an early trend
   if(mOscBuffer[0] < 0 && mOscBuffer[0] > mOscBuffer[1]
      && mADXBuffer[0] > mADXBuffer[1])
     {
      mSignal = ENTRY_SIGNAL_BUY;
      mScore = 6;
     }

//strong bear trend
   if(mOscBuffer[0] < 0 && mOscBuffer[0] < mOscBuffer[1])
     {
      mSignal = ENTRY_SIGNAL_SELL;
      mScore = 10;
     }
// osc is above 0 but decreasing and ADX is increasing
// so we want to cautiously see if we can catch an early bear trend
   if(mOscBuffer[0] > 0 && mOscBuffer[0] < mOscBuffer[1]
      && mADXBuffer[0] > mADXBuffer[1])
     {
      mSignal = ENTRY_SIGNAL_SELL;
      mScore = 6;
     }


   if(mSignal != ENTRY_SIGNAL_NONE)
     {
      mWorthReporting = true;
      //--- prepare the result if worthreporting
      mScanValues = StringFormat("adx_osc#adx=%f,osc=%f,diplus=%f,diminus=%f|",
                                 mADXBuffer[0],mOscBuffer[0],mDIPlusBuffer[0],mDIMinusBuffer[0]) +
                    CurrentCandleProperties(mShiftIndex);
     }

  }


//+------------------------------------------------------------------+
