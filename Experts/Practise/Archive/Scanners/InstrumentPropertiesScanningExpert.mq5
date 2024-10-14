//+------------------------------------------------------------------+
//|                           InstrumentPropertiesScanningExpert.mq5 |
//|                                    Copyright 2020, Michael Enudi |
//|                                             okmich2002@yahoo.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2020, Michael Enudi"
#property link      "okmich2002@yahoo.com"
#property version   "1.00"

#include <Okmich\Scanner\InstrumentPropertiesBot.mqh>

input string InpBrokerCode="Deriv";
input string InpServerAddress = "http://127.0.0.1/service/save/instrument-calc";

//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+
int OnInit()
  {
   if(StringLen(InpBrokerCode) < 2)
     {
      Alert("Please configurethe Broker Code for script");
      return INIT_PARAMETERS_INCORRECT;
     }
//--- create timer
   EventSetTimer(3600);
//---
   return(INIT_SUCCEEDED);
  }

//+------------------------------------------------------------------+
//| Expert deinitialization function                                 |
//+------------------------------------------------------------------+
void OnDeinit(const int reason)
  {
//--- destroy timer
   EventKillTimer();

  }
//+------------------------------------------------------------------+
//| Expert tick function                                             |
//+------------------------------------------------------------------+
void OnTick()
  {
  }
  
//+------------------------------------------------------------------+
//| Timer function                                                   |
//+------------------------------------------------------------------+
void OnTimer()
  {
   CRestApiScanReportSink mReportSink(InpServerAddress);
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
