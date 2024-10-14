//+------------------------------------------------------------------+
//|                                                 UnionExample.mq5 |
//|                                    Copyright 2024, Michael Enudi |
//|                                             okmich2002@yahoo.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2024, Michael Enudi"
#property link      "okmich2002@yahoo.com"
#property version   "1.00"

union MqlRatesToBytes
  {
   uchar byteArray[sizeof(MqlRates)];
   MqlRates mqlRates;
  };

MqlRatesToBytes converter;


//+------------------------------------------------------------------+
//| Script program start function                                    |
//+------------------------------------------------------------------+
void OnStart()
  {
   MqlRates array[];
   if(CopyRates(Symbol(),PERIOD_CURRENT,0,1,array)!=1)
     {
      Print("CopyRates failed, error: ",(string)GetLastError());
      return;
     }
   Print("Current bar ",Symbol()," ",StringSubstr(EnumToString(Period()),7)," (ArrayPrint):");
   ArrayPrint(array);
   converter.mqlRates = array[0];
   
   ArrayPrint(converter.byteArray);

  }
//+------------------------------------------------------------------+
