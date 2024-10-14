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

   string fileName = StringFormat("%s_%s_ATR.csv", _Symbol, EnumToString(_Period));

   double atr[];
   MqlRates mqlRates[];

   ArraySetAsSeries(atr, true);
   ArraySetAsSeries(mqlRates, true);

   int period = 14;
   int atrHandle = iATR(_Symbol, _Period, period);
   int indCopied = CopyBuffer(atrHandle, 0, 0, toCopy, atr);
   int barsCopied = CopyRates(_Symbol, _Period,0, toCopy,mqlRates);

   int fileHandle=FileOpen(fileName,FILE_WRITE|FILE_CSV);
   string eachLine = "";

   Print("Export begins");

   FileWriteString(fileHandle,
                   "Time,Open,high,low,close,tick_volume,indvalue\n");
   for(int i = 0; i < MathMin(barsCopied, indCopied); i++)
     {
      eachLine = StringFormat("%s,%f,%f,%f,%f,%d,%f,%f\n",
                              TimeToString(mqlRates[i].time),
                              NormalizeDouble(mqlRates[i].open,  _Digits),
                              NormalizeDouble(mqlRates[i].high,  _Digits),
                              NormalizeDouble(mqlRates[i].low,  _Digits),
                              NormalizeDouble(mqlRates[i].close,  _Digits),
                              mqlRates[i].tick_volume,
                              NormalizeDouble((atr[i] == EMPTY_VALUE ? 0 : atr[i]),  _Digits),
                              NormalizeDouble((atr[i] == EMPTY_VALUE ? 0 : atr[i]/_Point),  _Digits)
                             );
      FileWriteString(fileHandle, eachLine);
     }

   FileClose(fileHandle);
   Print("Export complete");
  }
//+------------------------------------------------------------------+

//+------------------------------------------------------------------+
