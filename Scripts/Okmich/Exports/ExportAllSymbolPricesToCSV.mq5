//+------------------------------------------------------------------+
//|                                   ExportAllSymbolPricesToCSV.mq5 |
//|                                                    Michael Enudi |
//|                                             okmich2002@yahoo.com |
//+------------------------------------------------------------------+
#property copyright "Michael Enudi"
#property link      "okmich2002@yahoo.com"
#property version   "1.00"
#property script_show_inputs

static int _digits = 4;
//+------------------------------------------------------------------+
//| Script program start function                                    |
//+------------------------------------------------------------------+
void OnStart()
  {
   int totalSymbolsCnt = SymbolsTotal(true);
   for(int x = 0; x < totalSymbolsCnt; x++)
      getPricesAndExport(SymbolName(x, true));
  }
//+------------------------------------------------------------------+

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void getPricesAndExport(string iSymbol)
  {
   MqlRates mqlRates[];
   datetime startDates = D'01.01.2019 00:00:00', endDates = D'31.12.2022 23:59:59';
//digits
   _digits = (int)SymbolInfoInteger(iSymbol, SYMBOL_DIGITS);

   int copied = CopyRates(iSymbol, PERIOD_M1, startDates, endDates, mqlRates);

// write prices to file
   string fileName = StringFormat("%s_export.csv", iSymbol);
   int fileHandle=FileOpen(fileName,FILE_WRITE|FILE_CSV);
   FileWriteString(fileHandle,
                   "Time;Open;high;low;close;tick_volume;spread\n");
   for(int i = 0; i < ArraySize(mqlRates); i++)
     {
      FileWriteString(fileHandle, mqlRateToString(mqlRates[i]));
     }

   FileClose(fileHandle);

//log
   Print(copied, " 1 minute bars of ", iSymbol, " copied");
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
string mqlRateToString(MqlRates &rate)
  {
   return StringFormat("%s;%s;%s;%s;%s;%s;%s\n",
                       myTimeToString(rate.time),
                       DoubleToString(rate.open, _digits),
                       DoubleToString(rate.high, _digits),
                       DoubleToString(rate.low, _digits),
                       DoubleToString(rate.close, _digits),
                       IntegerToString(rate.tick_volume),
                       IntegerToString(rate.spread));
  }
  
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
string myTimeToString(datetime time)
  {
   string result = TimeToString(time, TIME_DATE|TIME_MINUTES);
   StringReplace(result, ".", "-");
   return result + ".00";
  }
//+------------------------------------------------------------------+
