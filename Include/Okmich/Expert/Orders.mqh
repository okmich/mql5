//+------------------------------------------------------------------+
//|                                                 MarketOrders.mqh |
//|                                    Copyright 2022, Michael Enudi |
//|                                             okmich2002@yahoo.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2022, Michael Enudi"
#property link      "okmich2002@yahoo.com"

#include <Okmich\Common\Common.mqh>
#include <Trade\Trade.mqh>

#define  ORDER_SEND_RETRIES_COUNT 3
#define  ORDER_SEND_RETRIES_INTERVAL_MAX 3000

//+------------------------------------------------------------------+
//| /////////////////// methods implementation ///////////////////// |
//+------------------------------------------------------------------+
bool ExecuteEntryOrder(CTrade &mTradeHandle, Entry &entry, ENUM_TIMEFRAMES timeframe)
  {
   switch(entry.signal)
     {
      case ENTRY_SIGNAL_BUY:
         MarketBuy(mTradeHandle, entry);
         break;
      case ENTRY_SIGNAL_SELL:
         MarketSell(mTradeHandle, entry);
         break;
      case ENTRY_SIGNAL_BUY_LIMIT:
         MarketBuyLimit(mTradeHandle, timeframe, entry);
         break;
      case ENTRY_SIGNAL_BUY_STOP:
         MarketBuyStop(mTradeHandle, timeframe, entry);
         break;
      case ENTRY_SIGNAL_SELL_LIMIT:
         MarketSellLimit(mTradeHandle, timeframe, entry);
         break;
      case ENTRY_SIGNAL_SELL_STOP:
         MarketSellStop(mTradeHandle, timeframe, entry);
         break;
      case ENTRY_SIGNAL_NONE:
      default:
         return true;
     }

   return false;
  }

//+------------------------------------------------------------------+
//| MarketBuy(CTrade &mTradeHandle, Entry &entry)                    |
//+------------------------------------------------------------------+
void MarketBuy(CTrade &mTradeHandle, Entry &entry)
  {
   string message = StringFormat("Market order:[p:%f | sl: %f | tp: %f | vol: %f]",
                                 NormalizeDouble(entry.price, 5), NormalizeDouble(entry.sl, 5),
                                 NormalizeDouble(entry.tp, 5), NormalizeDouble(entry.vol, 2));
   int returnCode = 0;
   if(CallPositionOpen(mTradeHandle, 0, entry, ORDER_TYPE_BUY, message, returnCode))
      Print(StringFormat("Bought %.5f lots @ %s (%d)", entry.vol, entry.sym, entry.magic));
   else
      Print(__FUNCTION__ +  StringFormat(" All attempts to place order failed. Reason: %s", GetRetcodeID(returnCode)));
  }

//+------------------------------------------------------------------+
//| MarketBuyLimit(CTrade &mTradeHandle, Entry &entry)               |
//+------------------------------------------------------------------+
void MarketBuyLimit(CTrade &mTradeHandle, ENUM_TIMEFRAMES tf, Entry &entry)
  {
   string message = StringFormat("Buy limit order:[p:%f | sl: %f | tp: %f | vol: %f]",
                                 NormalizeDouble(entry.price, 5), NormalizeDouble(entry.sl, 5),
                                 NormalizeDouble(entry.tp, 5), NormalizeDouble(entry.vol, 2));
   int returnCode = 0;
   ulong ticket = GetPendingOrder(entry.sym, ORDER_TYPE_BUY_LIMIT, entry.magic);
   if(ticket == -1) //no existing ticket
     {
      if(CallPositionOpen(mTradeHandle, tf, entry, ORDER_TYPE_BUY_LIMIT, message, returnCode))
         Print(StringFormat("Placed buy limit order of %.5f lots @ %s (%d)",
                            entry.vol, entry.sym, entry.magic));
      else
         Print(__FUNCTION__ + StringFormat(" All attempts to place buy limit order failed. Reason: %s", GetRetcodeID(returnCode)));
     }
   else
     {
      //modify existing order using the ticket
      if(CallModifyOrder(mTradeHandle, tf, ticket, entry, returnCode))
         Print(StringFormat("Modified existing buy limit order of %.5f lots @ %s (%d)",
                            entry.vol, entry.sym, entry.magic));
      else
         Print(__FUNCTION__ + StringFormat(" All attempts to modify buy limit order failed. Reason: %s", GetRetcodeID(returnCode)));

     }
  }

//+-----------------------------------------------------------------------------------------------+
//| MarketBuyStop(CTrade &mTradeHandle, ENUM_TIMEFRAMES tf, Entry &entry)
//+-----------------------------------------------------------------------------------------------+
void MarketBuyStop(CTrade &mTradeHandle, ENUM_TIMEFRAMES tf, Entry &entry)
  {
   string message = StringFormat("Buy stop order:[p:%f | sl: %f | tp: %f | vol: %f]",
                                 NormalizeDouble(entry.price, 5), NormalizeDouble(entry.sl, 5),
                                 NormalizeDouble(entry.tp, 5), NormalizeDouble(entry.vol, 2));
   int returnCode = 0;
   ulong ticket = GetPendingOrder(entry.sym, ORDER_TYPE_BUY_STOP, entry.magic);
   if(ticket == -1) //no existing ticket
     {
      if(CallPositionOpen(mTradeHandle, tf, entry, ORDER_TYPE_BUY_STOP, message, returnCode))
         Print(StringFormat("Placed buy stop order of %.5f lots @ %s (%d)",
                            entry.vol, entry.sym, entry.magic));
      else
         Print(__FUNCTION__ + StringFormat(" All attempts to place buy stop order failed. Reason: %s", GetRetcodeID(returnCode)));
     }
   else
     {
      //modify existing order using the ticket
      if(CallModifyOrder(mTradeHandle, tf, ticket, entry, returnCode))
         Print(StringFormat("Modified existing buy stop order of %.5f lots @ %s (%d)",
                            entry.vol, entry.sym, entry.magic));
      else
         Print(__FUNCTION__ + StringFormat(" All attempts to modify buy stop order failed. Reason: %s", GetRetcodeID(returnCode)));

     }
  }

//+------------------------------------------------------------------+
//| MarketSell(CTrade &mTradeHandle, Entry &entry)                   |
//+------------------------------------------------------------------+
void MarketSell(CTrade &mTradeHandle, Entry &entry)
  {
   string message = StringFormat("Market order:[p:%f | sl: %f | tp: %f | vol: %f]",
                                 NormalizeDouble(entry.price, 5), NormalizeDouble(entry.sl, 5),
                                 NormalizeDouble(entry.tp, 5), NormalizeDouble(entry.vol, 2));
   int returnCode = 0;
   if(CallPositionOpen(mTradeHandle, 0, entry, ORDER_TYPE_SELL, message, returnCode))
      Print(StringFormat("Sold %.5f lots @ %s (%d)", entry.vol, entry.sym, entry.magic));
   else
      Print(__FUNCTION__ + StringFormat(" All attempts to place order failed. Reason: %s", GetRetcodeID(returnCode)));
  }

//+------------------------------------------------------------------+
//| MarketSellLimit(CTrade &mTradeHandle, Entry &entry)              |
//+------------------------------------------------------------------+
void MarketSellLimit(CTrade &mTradeHandle, ENUM_TIMEFRAMES tf, Entry &entry)
  {
   string message = StringFormat("Sell limit order:[p:%f | sl: %f | tp: %f | vol: %f]",
                                 NormalizeDouble(entry.price, 5), NormalizeDouble(entry.sl, 5),
                                 NormalizeDouble(entry.tp, 5), NormalizeDouble(entry.vol, 2));
   int returnCode = 0;
   ulong ticket = GetPendingOrder(entry.sym, ORDER_TYPE_SELL_LIMIT, entry.magic);
   if(ticket == -1) //no existing ticket
     {
      if(CallPositionOpen(mTradeHandle, tf, entry, ORDER_TYPE_SELL_LIMIT, message, returnCode))
         Print(StringFormat("Placed sell limit %.5f lots @ %s (%d)", entry.vol, entry.sym, entry.magic));
      else
         Print(__FUNCTION__ + StringFormat(" All attempts to place sell limit order failed. Reason: %s", GetRetcodeID(returnCode)));
     }

   else
     {
      if(CallModifyOrder(mTradeHandle, tf, ticket, entry, returnCode))
         Print(StringFormat("Modified existing sell limit order of %.5f lots @ %s (%d)",
                            entry.vol, entry.sym, entry.magic));
      else
         Print(__FUNCTION__ + StringFormat(" All attempts to modify sell limit order failed. Reason: %s", GetRetcodeID(returnCode)));
     }
  }

//+------------------------------------------------------------------+
//| MarketSellStop(CTrade &mTradeHandle, ENUM_TIMEFRAMES tf, Entry &entry)
//+------------------------------------------------------------------+
void MarketSellStop(CTrade &mTradeHandle, ENUM_TIMEFRAMES tf, Entry &entry)
  {
   string message = StringFormat("Sell stop order:[p:%f | sl: %f | tp: %f | vol: %f]",
                                 NormalizeDouble(entry.price, 5), NormalizeDouble(entry.sl, 5),
                                 NormalizeDouble(entry.tp, 5), NormalizeDouble(entry.vol, 2));
   int returnCode = 0;
   ulong ticket = GetPendingOrder(entry.sym, ORDER_TYPE_SELL_STOP, entry.magic);
   if(ticket == -1) //no existing ticket
     {
      if(CallPositionOpen(mTradeHandle, tf, entry, ORDER_TYPE_SELL_STOP, message, returnCode))
         Print(StringFormat("Placed sell stop order of %.5f lots @ %s (%d)", entry.vol, entry.sym, entry.magic));
      else
         Print(__FUNCTION__ + StringFormat(" All attempts to place stop order failed. Reason: %s", GetRetcodeID(returnCode)));
     }
   else
     {
      if(CallModifyOrder(mTradeHandle, tf, ticket, entry, returnCode))
         Print(StringFormat("Modified existing sell stop order of %.5f lots @ %s (%d)",
                            entry.vol, entry.sym, entry.magic));
      else
         Print(__FUNCTION__ + StringFormat(" All attempts to modify sell stop order failed. Reason: %s", GetRetcodeID(returnCode)));

     }
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
bool CallPositionOpen(CTrade &mTradeHandle, ENUM_TIMEFRAMES tf, Entry &entry, ENUM_ORDER_TYPE orderType, string message, uint &returnCode)
  {
   int attempts = 1;
   bool _isSuccessful = false;
   returnCode = 0;

   do
     {
      if(orderType == ORDER_TYPE_BUY || orderType == ORDER_TYPE_SELL)
         _isSuccessful = mTradeHandle.PositionOpen(entry.sym,
                         orderType,
                         entry.vol,
                         entry.price,
                         entry.sl,
                         entry.tp,
                         message);
      else
        {
         ENUM_ORDER_TYPE_TIME orderTimeType = (entry.order_expiry < 1) ? ORDER_TIME_GTC : ORDER_TIME_SPECIFIED;
         datetime expirationTime = (orderTimeType == ORDER_TIME_GTC) ? 0 : TimeCurrent() + (entry.order_expiry * PeriodSeconds(tf));
         _isSuccessful = mTradeHandle.OrderOpen(entry.sym,
                                                orderType,
                                                entry.vol,
                                                0,
                                                entry.price,
                                                entry.sl,
                                                entry.tp,
                                                orderTimeType,
                                                expirationTime,
                                                message);
        }
      returnCode = mTradeHandle.ResultRetcode();
      if(returnCode == TRADE_RETCODE_PLACED || returnCode == TRADE_RETCODE_DONE)
        {
         return true;
        }

      if(!_isSuccessful && returnCode == TRADE_RETCODE_TOO_MANY_REQUESTS)
        {
         attempts++;
         int waitTime = rand() % ORDER_SEND_RETRIES_INTERVAL_MAX;
         if(waitTime < 1000)
            waitTime = 1000;
         Print(StringFormat("Failed to place order successfully. Reason: %s. Waiting to retry order [%s] in %d ms",
                            GetRetcodeID(returnCode), message, waitTime));
         Sleep(waitTime);
        }
      else
        {
         //a valid technical error
         Print(StringFormat("Failed to place order successfully. Reason: %s.",
                            GetRetcodeID(returnCode)));
         return false;
        }
     }
   while(attempts <= ORDER_SEND_RETRIES_COUNT && !_isSuccessful);

   return false;
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
bool CallModifyOrder(CTrade &mTradeHandle, ENUM_TIMEFRAMES timeframe, ulong ticket, Entry &entry, uint &returnCode)
  {
   int attempts = 1;
   bool _isSuccessful = false;
   returnCode = 0;
   ENUM_ORDER_TYPE_TIME orderTimeType = (entry.order_expiry < 1) ? ORDER_TIME_GTC : ORDER_TIME_SPECIFIED;
   datetime expirationTime = (orderTimeType == ORDER_TIME_GTC) ? 0 : TimeCurrent() + (entry.order_expiry * PeriodSeconds(timeframe));
   do
     {
      _isSuccessful = mTradeHandle.OrderModify(ticket, entry.price, entry.sl, entry.tp,  orderTimeType, expirationTime, 0);
      returnCode = mTradeHandle.ResultRetcode();
      if(returnCode == TRADE_RETCODE_PLACED || returnCode == TRADE_RETCODE_DONE)
         return true;
      else
         if(!_isSuccessful && returnCode == TRADE_RETCODE_TOO_MANY_REQUESTS)
           {
            attempts++;
            int waitTime = rand() % ORDER_SEND_RETRIES_INTERVAL_MAX;
            if(waitTime < 1000)
               waitTime = 1000;
            Print(StringFormat("Failed to modify order successfully. Reason: %s. Waiting to retry in %d ms",
                               GetRetcodeID(returnCode), waitTime));
            Sleep(waitTime);
           }
         else
            return false; //a valid technical error
     }
   while(attempts <= ORDER_SEND_RETRIES_COUNT && !_isSuccessful);

   return false;
  }

////+------------------------------------------------------------------+
////|                                                                  |
////+------------------------------------------------------------------+
//void ClearOrdersBeyondNBars(CTrade &mTradeHandle, string symbol, int nBars)
//  {
//   string _sym="";
//   ulong order_magic, ticket, magic = mTradeHandle.RequestMagic();
//
//   int total = OrdersTotal();
//
//   for(int i = total-1; i>= 0; i--)
//     {
//      ticket = OrderGetTicket(i);
//      if(ticket > 0)
//        {
//         _sym = OrderGetString(ORDER_SYMBOL);
//         order_magic = OrderGetInteger(ORDER_MAGIC);
//
//         if(_sym == symbol && order_magic == magic)
//           {
//            mTradeHandle.OrderDelete(ticket);
//           }
//        }
//     }
//  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
ulong GetPendingOrder(string symbol, ENUM_ORDER_TYPE orderType, ulong magic)
  {
   string _sym="";
   ulong order_magic, ticket=-1;
   ENUM_ORDER_TYPE type;

   int total = OrdersTotal();

   for(int i = total-1; i>=0; i--)
     {
      ticket = OrderGetTicket(i);
      if(ticket > 0)
        {
         _sym = OrderGetString(ORDER_SYMBOL);
         type = ENUM_ORDER_TYPE(OrderGetInteger(ORDER_TYPE));
         order_magic = OrderGetInteger(ORDER_MAGIC);

         if(_sym == symbol && type == orderType && order_magic == magic)
            return ticket;
        }
     }
   return -1;
  }
//+------------------------------------------------------------------+
