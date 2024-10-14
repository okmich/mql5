//+------------------------------------------------------------------+
//|                                  KijunSenSMIAlignmentScanBot.mqh |
//|                                    Copyright 2020, Michael Enudi |
//|                                             okmich2002@yahoo.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2020, Michael Enudi"
#property link      "okmich2002@yahoo.com"

#include "MarketScanner.mqh"

#define SMI_IND "Okmich\\Ergodic SMI"
#define SKS_IND "Okmich\\Smoothed Kijun-Sen"

const string BOT_CODE_SUFFIX = "KJSSMIALGN";
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
class CKijunsenSmiAlignmentScanBot : public CBaseBot
  {
private:
   //--- indicator settings
   int               m_KijunsenPeriod, m_KijunSmoothing;
   ENUM_MA_METHOD    m_KijunSmoothMethod;
   int               m_SmiPeriod, mSmiSmooth1, mSmiSmooth2, mSmiSignalPeriod;
   //--- indicator handles
   int               mKijunsenHandle, mSmiHandle;
   //--- indicator buffers
   int               handleFastCG, handleMiddleCG, handleSlowCG;
   double            mKijunSenBuffer[];
   double            mSmiBuffer[], mSmiSignalBuffer[];
   double            closePrice;

   bool              Setup();

public:
                     CKijunsenSmiAlignmentScanBot(string symbol, ENUM_TIMEFRAMES tf,
                                int kijunSenPeriod = 26, int smoothing = 5, ENUM_MA_METHOD smoothMethod=MODE_EMA,
                                int smiLength=13, int smoothPeriod1 = 25, int smoothPeriod2 = 3,
                                int signalPeriod = 5) : CBaseBot(BOT_CODE_SUFFIX, tf, symbol)
     {
      m_KijunsenPeriod = kijunSenPeriod;
      m_KijunSmoothing = smoothing;
      m_KijunSmoothMethod = smoothMethod;
      m_SmiPeriod = smiLength;
      mSmiSmooth1 = smoothPeriod1;
      mSmiSmooth2 = smoothPeriod2;
      mSmiSignalPeriod = signalPeriod;
     };

                    ~CKijunsenSmiAlignmentScanBot()
     {
      IndicatorRelease(mKijunsenHandle);
      IndicatorRelease(mSmiHandle);
     };

   //this is the main implementation for this bot.
   virtual void      Begin();
  };

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
bool CKijunsenSmiAlignmentScanBot::Setup(void)
  {
   ArraySetAsSeries(mKijunSenBuffer, true);
   ArraySetAsSeries(mSmiBuffer, true);
   ArraySetAsSeries(mSmiSignalBuffer, true);

   mKijunsenHandle  = iCustom(mSymbol, mTimeFrame, SKS_IND, m_KijunsenPeriod, m_KijunSmoothing, m_KijunSmoothMethod);
   mSmiHandle       = iCustom(mSymbol, mTimeFrame, SMI_IND, m_SmiPeriod, mSmiSmooth1, mSmiSmooth2, mSmiSignalPeriod, PRICE_WEIGHTED);

   if(mKijunsenHandle == INVALID_HANDLE || mSmiHandle == INVALID_HANDLE)
      return false;

   return true;
  }


//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void CKijunsenSmiAlignmentScanBot::Begin(void)
  {
   if(!Setup())
     {
      mWorthReporting = false;
      return ;
     }
   int barsToCopy = 3;

   int sksCopied = CopyBuffer(mKijunsenHandle, 0, mShiftIndex, barsToCopy, mKijunSenBuffer);

   int smiCopied = CopyBuffer(mSmiHandle, 0, mShiftIndex, barsToCopy, mSmiBuffer);
   int smiSignalCopied = CopyBuffer(mSmiHandle, 1, mShiftIndex, barsToCopy, mSmiSignalBuffer);

   if(sksCopied != smiCopied || smiCopied != smiSignalCopied)
      return;

   int sksOutlook = mKijunSenBuffer[0] > mKijunSenBuffer[1] ? 1 : mKijunSenBuffer[0] < mKijunSenBuffer[1] ? -1 : 0;
   int smiFirstOutlook = mSmiBuffer[0] > mSmiBuffer[1] ? 1 : mSmiBuffer[0] < mSmiBuffer[1] ? -1 : 0;
   int smiSecondOutlook = mSmiBuffer[0] > mSmiSignalBuffer[1] ? 1 : mSmiBuffer[0] < mSmiSignalBuffer[1] ? -1 : 0;


   if(sksOutlook == smiFirstOutlook && smiFirstOutlook == smiSecondOutlook && sksOutlook != 0)
     {
      mWorthReporting = true;
      mSignal = sksOutlook > 0 ? ENTRY_SIGNAL_BUY : ENTRY_SIGNAL_SELL;
      //--- prepare the result if worthreporting
      mScanValues = StringFormat("kijunsen#kjs=%f,outlook=%d|smi#main=%f,signal=%f,outlook1=%d,outlook2=%d|",
                                 mKijunSenBuffer[0],sksOutlook,mSmiBuffer[0],mSmiSignalBuffer[0],
                                 smiFirstOutlook,smiSecondOutlook) +
                    CurrentCandleProperties(mShiftIndex);
     }

  }


//+------------------------------------------------------------------+
