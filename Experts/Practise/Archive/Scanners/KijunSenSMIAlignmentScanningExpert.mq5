//+------------------------------------------------------------------+
//|                                       IchimokuScanningExpert.mq5 |
//|                                    Copyright 2020, Michael Enudi |
//|                                             okmich2002@yahoo.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2020, Michael Enudi"
#property link      "okmich2002@yahoo.com"
#property version   "1.00"

#include <Okmich\Common\TradeFunctions.mqh>
#include <Okmich\Scanner\DirectionalMomentumAlignmentScanBot.mqh>

input string         InpServerAddress = "http://127.0.0.1/service/save/scan-results";
input int            InpKijunsen = 26;
input int            InpKijunsenSmoothing = 5;
input int            InpSmi = 13;
input int            InpSmiSmoothig = 25;
input int            InpSmiDblSmoothig = 3;
input int            InpSmiSignal = 5;
input ENUM_MA_METHOD InpSmoothingMethod = MODE_EMA;


//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
CRestApiScanReportSink mReportSink(InpServerAddress);
CMarketScanner mMarketScanner(GetPointer(mReportSink));
ENUM_TIMEFRAMES timeFrames[];

static bool mRunCompleted;
//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+
int OnInit()
  {
   mRunCompleted = false;
   mMarketScanner.GetTimeframes(timeFrames);

//--- create timer
   EventSetTimer(900);

   return(INIT_SUCCEEDED);
  }
  
//+------------------------------------------------------------------+
//| Expert deinitialization function                                 |
//+------------------------------------------------------------------+
void OnDeinit(const int reason)
  {
//---

  }
//+------------------------------------------------------------------+
//| Expert tick function                                             |
//+------------------------------------------------------------------+
void OnTick()
  {
   //we only run 80% of time into the 15mins candle, ie. every 12th minute of a 15mins bar
   datetime barOpenTime = iTime(_Symbol, PERIOD_M15, 0);
   datetime currentTime = TimeCurrent();
   if(!mRunCompleted && isPastNPercentWithinTF(PERIOD_M15, 80,currentTime, barOpenTime))
     {
      int arrayLen = ArraySize(timeFrames);
      int selectedSymbols = SymbolsTotal(true);
      long timeCode = mMarketScanner.GetTimeCode();
      for(int s =0; s < selectedSymbols; s++)
        {
         CBaseBot  *bots[6];
         for(int i =0; i < arrayLen; i++)
            bots[i] = new CKijunsenSmiAlignmentScanBot(SymbolName(s, true), timeFrames[i],
                  InpKijunsen, InpKijunsenSmoothing, InpSmoothingMethod,
                  InpSmi, InpSmiSmoothig, InpSmiDblSmoothig, InpSmiSignal);

         mMarketScanner.RunBots(timeCode, bots);
        }
      mRunCompleted = true;
     }
  }

//+------------------------------------------------------------------+
//| Timer function                                                   |
//+------------------------------------------------------------------+
void OnTimer()
  {
   mRunCompleted = false;
  }
//+------------------------------------------------------------------+
