//+------------------------------------------------------------------+
//|                                         InstrumentProperties.mq5 |
//|                        Copyright 2020, MetaQuotes Software Corp. |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2020, MetaQuotes Software Corp."
#property link      "https://www.mql5.com"
#property version   "1.00"

#include <Okmich\Scanner\InstrumentPropertiesBot.mqh>
input string InpBrokerCode="Deriv";

CAccountInfo accountInfo;

//+------------------------------------------------------------------+
//| Script program start function                                    |
//+------------------------------------------------------------------+
void OnStart()
  {
   if(StringLen(InpBrokerCode) < 2)
   Alert("Please confirm that the Broker Code for script is " + InpBrokerCode);
   CRestApiScanReportSink mReportSink("http://127.0.0.1:8000/service/save/instrument-calc");
   CMarketScanner mMarketScanner(GetPointer(mReportSink));
   long timeCode = mMarketScanner.GetTimeCode();
//--all symbols
   int selectedSymbols = SymbolsTotal(true);
   for(int s =0; s < selectedSymbols; s++)
     {
      CBaseBot  *bots[1];
      for(int i =0; i < 1; i++)
         bots[i] = new CInstrumentPropertiesBot(InpBrokerCode, SymbolName(s, true));

      mMarketScanner.RunBots(timeCode, bots);
     }
  }

//+------------------------------------------------------------------+
