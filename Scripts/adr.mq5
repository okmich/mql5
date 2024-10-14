//+------------------------------------------------------------------+
//|                                                          adr.mq5 |
//|                                                    Michael Enudi |
//|                                             okmich2002@yahoo.com |
//+------------------------------------------------------------------+
#property copyright "Michael Enudi"
#property link      "okmich2002@yahoo.com"
#property version   "1.00"

#include <Okmich\Common\AdrReader.mqh>
//+------------------------------------------------------------------+
//| Script program start function                                    |
//+------------------------------------------------------------------+
void OnStart()
  {
   int totalSymbols = SymbolsTotal(true);
   double adr=0, adrValueForMinVolume=0, minLotSize=0;
   string sym, results="Instruments       ADR         ADR Value      Min Vol\n";
   results+="====================================================== \n";
   for(int i = 0; i< totalSymbols; i++)
     {
      sym = SymbolName(i, true);
      adr = calculateAverageDailyRangeInPoints(sym);
      minLotSize = SymbolInfoDouble(sym, SYMBOL_VOLUME_MIN);
      adrValueForMinVolume = adr * SymbolInfoDouble(sym, SYMBOL_TRADE_CONTRACT_SIZE) *  SymbolInfoDouble(sym, SYMBOL_POINT)
                             *  SymbolInfoDouble(sym, SYMBOL_VOLUME_MIN);
      results += StringFormat("%30s         %12.2f        %10s    %10s \n", sym, adr,
                              DoubleToString(adrValueForMinVolume, 2), DoubleToString(minLotSize, 3));
     }
   Comment(results);
   Print(results);
  }
//+------------------------------------------------------------------+
