//+------------------------------------------------------------------+
//|                                                          ATR.mq5 |
//|                                    Copyright 2020, Michael Enudi |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2020, Michael Enudi"
#property link      "https://www.mql5.com"
#property version   "1.00"
//+------------------------------------------------------------------+
//| Script program start function                                    |
//+------------------------------------------------------------------+

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void OnStart()
  {
   int toCopy = Bars(_Symbol, _Period);

   string fileName = StringFormat("%s_%s_TsiWithDsl.csv", _Symbol, EnumToString(_Period));

   double tsi[], oblevel[], oslevel[];
   MqlRates mqlRates[];

   ArraySetAsSeries(tsi, true);
   ArraySetAsSeries(oblevel, true);
   ArraySetAsSeries(oslevel, true);
   ArraySetAsSeries(mqlRates, true);

   int handle = iCustom(_Symbol, _Period, "Okmich\\True Strength Index (DSL)", 13, 25, 2, 5);
   int tsiCopied = CopyBuffer(handle, 0, 0, toCopy, tsi);
   int obCopied = CopyBuffer(handle, 1, 0, toCopy, oblevel);
   int osCopied = CopyBuffer(handle, 2, 0, toCopy, oslevel);
   int barsCopied = CopyRates(_Symbol, _Period,0, toCopy,mqlRates);

   int fileHandle=FileOpen(fileName,FILE_WRITE|FILE_CSV);
   string eachLine = "";

   Print("Export begins");

   FileWriteString(fileHandle,
                   "Time,Open,high,low,close,tick_volume,tsi,os,ob\n");
   for(int i = 0; i < MathMin(barsCopied, toCopy); i++)
     {
      eachLine = StringFormat("%s,%f,%f,%f,%f,%d,%f,%f,%f\n",
                              TimeToString(mqlRates[i].time),
                              NormalizeDouble(mqlRates[i].open,  _Digits),
                              NormalizeDouble(mqlRates[i].high,  _Digits),
                              NormalizeDouble(mqlRates[i].low,  _Digits),
                              NormalizeDouble(mqlRates[i].close,  _Digits),
                              mqlRates[i].tick_volume,
                              NormalizeDouble((tsi[i] == EMPTY_VALUE ? 0 : tsi[i]),  2),
                              NormalizeDouble((oblevel[i] == EMPTY_VALUE ? 0 : oblevel[i]),  2),
                              NormalizeDouble((oslevel[i] == EMPTY_VALUE ? 0 : oslevel[i]),  2)
                             );
      FileWriteString(fileHandle, eachLine);
     }

   FileClose(fileHandle);
   Print("Export complete");
  }
//+------------------------------------------------------------------+

//+------------------------------------------------------------------+
