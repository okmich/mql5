//+------------------------------------------------------------------+
//|                                      OpenManyPositionsAtOnce.mq5 |
//|                                                    Michael Enudi |
//|                                             okmich2002@yahoo.com |
//+------------------------------------------------------------------+
#property copyright "Michael Enudi"
#property link      "okmich2002@yahoo.com"
#property version   "1.00"

#include <Okmich\Common\Common.mqh>
#include <Trade\Trade.mqh>

#define  ORDER_SEND_RETRIES_COUNT 3
#define  ORDER_SEND_RETRIES_INTERVAL_MAX 3000

CTrade            mCTrade;

//+------------------------------------------------------------------+
//| Script program start function                                    |
//+------------------------------------------------------------------+
void OnStart()
  {
//---
   ulong magic = 3459384;
   mCTrade.SetExpertMagicNumber(magic);
   Entry entries[5];

   double ask = SymbolInfoDouble(_Symbol, SYMBOL_ASK);
   double bid = SymbolInfoDouble(_Symbol, SYMBOL_BID);
   double lot = SymbolInfoDouble(_Symbol, SYMBOL_VOLUME_MIN);

   entries[0] = anEntry(_Symbol, ENTRY_SIGNAL_BUY, ask, 0.0, 0.0, lot, magic);
   entries[1] = anEntry(_Symbol, ENTRY_SIGNAL_SELL, bid, 0.0, 0.0, lot, magic);
   entries[2] = anEntry(_Symbol, ENTRY_SIGNAL_BUY, ask, 0.0, 0.0, lot, magic);
   entries[3] = anEntry(_Symbol, ENTRY_SIGNAL_BUY, ask, 0.0, 0.0, lot, magic);
   entries[4] = anEntry(_Symbol, ENTRY_SIGNAL_SELL, bid, 0.0, 0.0, lot, magic);

   for(int i = 0; i < 5; i++)
     {
      CallPositionOpen(entries[i], "I am testing multiple calls");
      Print("Calling ", i, " Done");
     }
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
bool CallPositionOpen(Entry &entry, string message)
  {
   int attempts = 1;
   bool _isSuccessful = false;
   uint resultCode = 0;
   ENUM_ORDER_TYPE orderType = entry.signal == ENTRY_SIGNAL_BUY ? ORDER_TYPE_BUY :
                               entry.signal == ENTRY_SIGNAL_SELL ? ORDER_TYPE_SELL :
                               ORDER_TYPE_CLOSE_BY; // what does ORDER_TYPE_CLOSE_BY do
   do
     {
      if(mCTrade.PositionOpen(entry.sym, orderType, entry.vol, entry.price, entry.sl, entry.tp, message))
        {
         resultCode = mCTrade.ResultRetcode();
         if(resultCode == TRADE_RETCODE_PLACED || resultCode == TRADE_RETCODE_DONE)
           {
            _isSuccessful = true;
           }
        }

      if(!_isSuccessful)
        {
         attempts++;
         int waitTime = rand() % ORDER_SEND_RETRIES_INTERVAL_MAX;
         if(waitTime < 1000)
            waitTime = 1000;
         Print(StringFormat("Failed to place order successfully. Reason: %d. Waiting to retry order [%s] in %d ms",
                            resultCode, message, waitTime));
         Sleep(waitTime);
        }
     }
   while(attempts <= ORDER_SEND_RETRIES_COUNT && !_isSuccessful);

   return false;
  }
//+------------------------------------------------------------------+
