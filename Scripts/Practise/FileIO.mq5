//+------------------------------------------------------------------+
//|                                                       FileIO.mq5 |
//|                        Copyright 2020, MetaQuotes Software Corp. |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2020, MetaQuotes Software Corp."
#property link      "https://www.mql5.com"
#property version   "1.00"
//+------------------------------------------------------------------+
//| Script program start function                                    |
//+------------------------------------------------------------------+
void OnStart()
  {
   string file_name;
   long search_handle=FileFindFirst("*", file_name);

   int    i=1;
   if(search_handle!=INVALID_HANDLE)
     {
      int fileHandle=FileOpen("all.txt",FILE_WRITE|FILE_CSV);
      int readHandle;
      //--- check if the passed strings are file or directory names in the loop
      do
        {
         ResetLastError();
         readHandle = FileOpen(file_name, FILE_READ|FILE_TXT);
         readAndWrite(readHandle, fileHandle);
         Print("Done with ", file_name);
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
