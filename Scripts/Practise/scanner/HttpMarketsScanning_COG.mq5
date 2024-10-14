//+------------------------------------------------------------------+
//|                                               MarketScanning.mq5 |
//|                        Copyright 2020, MetaQuotes Software Corp. |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2020, MetaQuotes Software Corp."
#property link      "https://www.mql5.com"
#property version   "1.00"

#include <Okmich\Scanner\CenterOfGravityScanBot.mqh>
//+------------------------------------------------------------------+
//| Script program start function                                    |
//+------------------------------------------------------------------+
void OnStart()
  {
//--- declare the timeframes
   ENUM_TIMEFRAMES timeFrames[6];
   timeFrames[0] = PERIOD_M15;
   timeFrames[1] = PERIOD_M30;
   timeFrames[2] = PERIOD_H1;
   timeFrames[3] = PERIOD_H4;
   timeFrames[4] = PERIOD_H12;
   timeFrames[5] = PERIOD_D1;

//--all symbols
   int selectedSymbols = SymbolsTotal(true);
//---
   CRestApiScanReportSink mReportSink("http://127.0.0.1:8000/service/save/scan-results");
   //CPrintReportSink mReportSink;
   CMarketScanner mMarketScanner(GetPointer(mReportSink));
   long timeCode = mMarketScanner.GetTimeCode();
   for(int s =0; s < selectedSymbols; s++)
     {
      CBaseBot  *bots[6];
      for(int i =0; i < 6; i++)
         bots[i] = new CCoGBot(SymbolName(s, true), timeFrames[i], 10, 3, 16, 3, 26, 3);

      mMarketScanner.RunBots(timeCode, bots);
     }
  }
  
  
//+------------------------------------------------------------------+
