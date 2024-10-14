//+------------------------------------------------------------------+
//|                                       CenterOfGravityScanBot.mqh |
//|                                    Copyright 2020, Michael Enudi |
//|                                             okmich2002@yahoo.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2020, Michael Enudi"
#property link      "okmich2002@yahoo.com"
#property version   "2.0"

#include "MarketScanner.mqh"

#define CENTER_OF_GRAVITY_IND "Okmich\\CenterOfGravity"
#define SCANNER_CODE "3COG"

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
class CCoGBot : public CBaseBot
  {

private:
   //--- indicator settings
   int               m_FastCGPeriod;
   int               m_MediumCGPeriod;
   int               m_SlowCGPeriod;
   //--- indicator value properties
   ENUM_OUTLOOK      fastCGOutLk, middleCGOutLk, slowCGOutLk;
   //--- indicator handles
   int               handleFastCG, handleMiddleCG, handleSlowCG;
   double            bufferFastCG[], bufferMiddleCG[], bufferSlowCG[];

   bool              Setup();

public:
                     CCoGBot(string symbol, ENUM_TIMEFRAMES tf,
           int fastCOG,
           int mediumCOG,
           int slowCOG) : CBaseBot(SCANNER_CODE, tf, symbol)
     {
      m_FastCGPeriod = fastCOG;
      m_MediumCGPeriod = mediumCOG;
      m_SlowCGPeriod = slowCOG;
     };

                    ~CCoGBot()
     {
      IndicatorRelease(handleFastCG);
      IndicatorRelease(handleMiddleCG);
      IndicatorRelease(handleSlowCG);
     };

   //this is the main implementation for this bot.
   virtual void      Begin();
  };

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
bool CCoGBot::Setup(void)
  {
   ArraySetAsSeries(bufferFastCG, true);
   ArraySetAsSeries(bufferMiddleCG, true);
   ArraySetAsSeries(bufferSlowCG, true);

//create all the indicators
   handleFastCG       = iCustom(mSymbol, mTimeFrame, CENTER_OF_GRAVITY_IND, m_FastCGPeriod);
   handleMiddleCG     = iCustom(mSymbol, mTimeFrame, CENTER_OF_GRAVITY_IND, m_MediumCGPeriod);
   handleSlowCG       = iCustom(mSymbol, mTimeFrame, CENTER_OF_GRAVITY_IND, m_SlowCGPeriod);

   if(handleFastCG == INVALID_HANDLE || handleMiddleCG == INVALID_HANDLE ||
      handleSlowCG == INVALID_HANDLE)

      return false;
   else
      return true;
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void CCoGBot::Begin(void)
  {
   int barsToCopy = 2;
   if(!Setup())
     {
      mWorthReporting = false;
      return ;
     }
   // according to john ehler, the signal line for CG is the CG value of the previous bar.
   CopyBuffer(handleFastCG, 0, mShiftIndex, barsToCopy, bufferFastCG);
   double fastPipDiff = (bufferFastCG[0] - bufferFastCG[1]);
   fastCGOutLk = fastPipDiff > 0 ? OUTLOOK_BULLISH : (fastPipDiff < 0) ? OUTLOOK_BEARISH: OUTLOOK_NONE;

   CopyBuffer(handleMiddleCG, 0, mShiftIndex, barsToCopy, bufferMiddleCG);
   double middlePipDiff = (bufferMiddleCG[0] - bufferMiddleCG[1]);
   middleCGOutLk = middlePipDiff > 0 ? OUTLOOK_BULLISH : (middlePipDiff < 0) ? OUTLOOK_BEARISH: OUTLOOK_NONE;

   CopyBuffer(handleSlowCG, 0, mShiftIndex, barsToCopy, bufferSlowCG);
   double slowPipDiff = (bufferSlowCG[0] - bufferSlowCG[1]);
   slowCGOutLk = slowPipDiff > 0 ? OUTLOOK_BULLISH : (slowPipDiff < 0) ? OUTLOOK_BEARISH: OUTLOOK_NONE;

//--- apply selection rule
   if(slowCGOutLk == middleCGOutLk && middleCGOutLk == fastCGOutLk)
     {
      mSignal = (slowCGOutLk == OUTLOOK_BEARISH) ? ENTRY_SIGNAL_SELL : ENTRY_SIGNAL_BUY;
      mWorthReporting = true;
      mScore = 10;

      //--- prepare the result if worthreporting
      mScanValues = StringFormat("fast#CG=%f,SIG=%f,Diff=%f|middle#CG=%f,SIG=%f,Diff=%f|Slow#CG=%f,SIG=%f,Diff=%f|",
                                 bufferFastCG[0],bufferFastCG[1],fastPipDiff,
                                 bufferMiddleCG[0],bufferMiddleCG[1],middlePipDiff,
                                 bufferSlowCG[0],bufferMiddleCG[1],slowPipDiff) +
                    CurrentCandleProperties(mShiftIndex);
     }

  }
//+------------------------------------------------------------------+
