//+------------------------------------------------------------------+
//|                                               MarketScanning.mq5 |
//|                        Copyright 2020, MetaQuotes Software Corp. |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2020, MetaQuotes Software Corp."
#property link      "https://www.mql5.com"
#property version   "1.00"

//#include <Okmich\Scanner\CenterOfGravityScanBot.mqh>
//#include <Okmich\Scanner\ChannelBreakoutScanBot.mqh>
//#include <Okmich\Scanner\IchimokuScanBot.mqh>
#include <Okmich\Scanner\ADXOscillatorScanBot.mqh>

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
//---
   //CPrintReportSink mReportSink;
   C
   CMarketScanner mMarketScanner(GetPointer(mReportSink));
   CBaseBot  *bots[ArraySize(timeFrames)];
   for(int i =0; i < ArraySize(timeFrames); i++)
      //bots[i] = new CChannelBreakoutBot(_Symbol, timeFrames[i], 10);
      //bots[i] = new CIchimokuScanBot(_Symbol, timeFrames[i]);
      bots[i] = new CADXOscillatorScanBot(_Symbol, timeFrames[i], 14, 24);

   mMarketScanner.RunBots(345340534, bots);
  }
//+------------------------------------------------------------------+
