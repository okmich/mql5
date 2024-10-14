//+------------------------------------------------------------------+
//|                                           AccountInformation.mq5 |
//|                                    Copyright 2020, Michael Enudi |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2020, Michael Enudi"
#property link      "https://www.mql5.com"
#property version   "1.00"
//+------------------------------------------------------------------+
//| Script program start function                                    |
//+------------------------------------------------------------------+
void OnStart()
  {
      double acctBalance = AccountInfoDouble(ACCOUNT_BALANCE);
      double currentProfit = AccountInfoDouble(ACCOUNT_PROFIT);
      double equity = AccountInfoDouble(ACCOUNT_EQUITY);
      Print("acctBalance is ", acctBalance, ", currentProfit is ", currentProfit, " while equity is ", equity);
      
      double margin = AccountInfoDouble(ACCOUNT_MARGIN);
      double freeMargin = AccountInfoDouble(ACCOUNT_MARGIN_FREE);
      double marginLevel = AccountInfoDouble(ACCOUNT_MARGIN_LEVEL);
      Print("Margin is ", margin, ", free margin is ", freeMargin, " while margin level is ", marginLevel);
      
      double assets = AccountInfoDouble(ACCOUNT_ASSETS);
      double liability = AccountInfoDouble(ACCOUNT_LIABILITIES);
      double marginMaintenance = AccountInfoDouble(ACCOUNT_MARGIN_MAINTENANCE);
      double initialMargin = AccountInfoDouble(ACCOUNT_MARGIN_INITIAL);
      
      string str = "=";
      string stringFormat = "Account Information ";
      Comment(currentProfit); 
  }
//+------------------------------------------------------------------+
