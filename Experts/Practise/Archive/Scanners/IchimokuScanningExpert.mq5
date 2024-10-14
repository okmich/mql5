//+------------------------------------------------------------------+
//|                                       IchimokuScanningExpert.mq5 |
//|                                    Copyright 2020, Michael Enudi |
//|                                             okmich2002@yahoo.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2020, Michael Enudi"
#property link      "okmich2002@yahoo.com"
#property version   "1.00"

#include <Okmich\Common\TradeFunctions.mqh>
#include <Okmich\Scanner\IchimokuScanBot.mqh>

input string serverAddress             = "http://127.0.0.1/service/save/scan-results";
input int    InpTenkensen = 9;
input int    InpKijunsen = 26;
input int    InpSenkouSpanB = 52;

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
CRestApiScanReportSink mReportSink(serverAddress);
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
      int selectedSymbols = SymbolsTotal(true);
      long timeCode = mMarketScanner.GetTimeCode();
      for(int s =0; s < selectedSymbols; s++)
        {
         CBaseBot  *bots[6];
         for(int i =0; i < 6; i++)
            bots[i] = new CIchimokuScanBot(SymbolName(s, true), timeFrames[i],
                                           InpTenkensen, InpKijunsen, InpSenkouSpanB);

         mMarketScanner.RunBots(timeCode, bots);
        }
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
