//+------------------------------------------------------------------+
//|                                                   AllSymbols.mq5 |
//|                                    Copyright 2020, Michael Enudi |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2020, Michael Enudi"
#property link      "https://www.mql5.com"
#property version   "1.00"
//+------------------------------------------------------------------+
//| Script program start function                                    |
//+------------------------------------------------------------------+
void OnStart()
  {
   int allSymbols = SymbolsTotal(true);
   Print("The number of tradable symbols ", allSymbols);

   int selectedSysmbols = SymbolsTotal(true);
   string msg = "Symbols \n ===========  \n";
   for(int i = 0; i < selectedSysmbols; i++)
      msg += " " + SymbolName(i, true) + "\n";
   Comment(msg);
   Print(msg);
  }
//+------------------------------------------------------------------+
