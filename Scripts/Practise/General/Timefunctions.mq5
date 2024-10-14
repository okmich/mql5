//+------------------------------------------------------------------+
//|                                                Timefunctions.mq5 |
//|                                    Copyright 2023, Michael Enudi |
//|                                             okmich2002@yahoo.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2023, Michael Enudi"
#property link      "okmich2002@yahoo.com"
#property version   "1.00"
//+------------------------------------------------------------------+
//| Script program start function                                    |
//+------------------------------------------------------------------+
void OnStart()
  {
//---
   datetime serverTime = TimeTradeServer();
   Print("Server Time: ", TimeToString(serverTime, TIME_DATE | TIME_MINUTES));

   datetime terminalTime = TimeCurrent();
   Print("Terminal Time: ", TimeToString(terminalTime, TIME_DATE | TIME_MINUTES));

   datetime localTime = TimeLocal();
   Print("Local Time: ", TimeToString(localTime, TIME_DATE | TIME_MINUTES));

   datetime gmtTime = TimeGMT();
   Print("GMT Time: ", TimeToString(gmtTime, TIME_DATE | TIME_MINUTES));

   int timeDLS = TimeDaylightSavings();
   Print("TimeDaylightSavings: ", timeDLS);

   int timeGmtOffset = TimeGMTOffset();
   Print("TimeGMTOffset: ", timeGmtOffset);


// Get the trading session information
   datetime sessionQuoteStart=0, sessionQuoteEnd=0, sessionTradeStart=0, sessionTradeEnd=0;
   if(SymbolInfoSessionQuote(_Symbol, SUNDAY, 0, sessionQuoteStart, sessionQuoteEnd) &&
      SymbolInfoSessionTrade(_Symbol, SUNDAY, 0, sessionTradeStart, sessionTradeEnd))
     {
      // Get the current time
      datetime currentTime = TimeCurrent();
      Print("Session Quote Start: ", TimeToString(sessionQuoteStart, TIME_DATE | TIME_MINUTES));
      Print("Session Quote End: ", TimeToString(sessionQuoteEnd, TIME_DATE | TIME_MINUTES));
      Print("Session Trade Start: ", TimeToString(sessionTradeStart, TIME_DATE | TIME_MINUTES));
      Print("Session Trade End: ", TimeToString(sessionTradeEnd, TIME_DATE | TIME_MINUTES));
      Print("currentTime: ", TimeToString(currentTime, TIME_DATE | TIME_MINUTES));
      // Check if the current time is within the trading session
      if(currentTime >= sessionTradeStart && currentTime < sessionTradeEnd)
        {
         // Symbol is tradable
         Print("The symbol ", _Symbol, " is tradable at the current time.");
        }
      else
        {
         // Symbol is not tradable
         Print("The symbol ", _Symbol, " is not tradable at the current time.");
        }
     }
   else
     {
      Print("Failed to retrieve trading session information for ", _Symbol);
     }
  }
//+------------------------------------------------------------------+
