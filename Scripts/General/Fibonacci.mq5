//+------------------------------------------------------------------+
//|                                                    Fibonacci.mq5 |
//|                                                    Michael Enudi |
//|                                             okmich2002@yahoo.com |
//+------------------------------------------------------------------+
#property copyright "Michael Enudi"
#property link      "okmich2002@yahoo.com"
#property version   "1.00"
//+------------------------------------------------------------------+
//| Script program start function                                    |
//+------------------------------------------------------------------+
void OnStart()
  {
   string message = "";
   for(int i = 1; i <= 15; i++)
      message += IntegerToString(i) + " => " + IntegerToString(fibonacci(i)) + "\n";

   Comment(message);
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
long fibonacci(long n)
  {
   if(n <= 1)
      return 1;
   else
      return fibonacci(n-1) + fibonacci(n-2);
  }
//+------------------------------------------------------------------+
