//+------------------------------------------------------------------+
//|                                               MarketScanning.mq5 |
//|                        Copyright 2020, MetaQuotes Software Corp. |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2020, MetaQuotes Software Corp."
#property link      "https://www.mql5.com"
#property version   "1.00"

#include <Okmich\Scanner\ADXOscillatorScanBot.mqh>
//#include <Okmich\Scanner\CenterOfGravityScanBot.mqh>

input string serverAddress = "http://127.0.0.1:8000/service/save/scan-results";  //Remote Server
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
   //CFileScanReportSink mReportSink;
   CRestApiScanReportSink mReportSink(serverAddress);
   CMarketScanner mMarketScanner(GetPointer(mReportSink));
   //FolderClean("*");
   for(int s =0; s < selectedSymbols; s++)
     {
      CBaseBot  *bots[6];
      for(int i =0; i < 6; i++)
         //bots[i] = new CCoGBot(SymbolName(s, true), timeFrames[i], 10, 3, 20, 3, 28, 3, 3);
         bots[i] = new CADXOscillatorScanBot(SymbolName(s, true), timeFrames[i], 14);

      mMarketScanner.RunBots(23939396, bots);
     }
   //concatenateAllResult(scanCode);
  }
//+------------------------------------------------------------------+


//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void concatenateAllResult(string scanCode)
  {
   string file_name;
   long search_handle=FileFindFirst("*", file_name);

   if(search_handle!=INVALID_HANDLE)
     {
      int fileHandle=FileOpen(scanCode+".txt",FILE_WRITE|FILE_CSV);
      int readHandle;
      //--- check if the passed strings are file or directory names in the loop
      do
        {
         ResetLastError();
         readHandle = FileOpen(file_name, FILE_READ|FILE_TXT);
         readAndWrite(readHandle, fileHandle);
         Print("Merged ", file_name);
         FileDelete(file_name);
        }
      while(FileFindNext(search_handle,file_name));
      //--- close search handle
      FileFindClose(search_handle);
     }
   else
      Print("Files not found!");

  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void readAndWrite(int readHandle, int writeHandle)
  {
   string eachLine;
//--- read data from the file
   while(!FileIsEnding(readHandle))
     {
      eachLine=FileReadString(readHandle);
      FileWriteString(writeHandle, eachLine + "\n");
     }
//--- close the file
   FileClose(readHandle);
  }
//+------------------------------------------------------------------+
