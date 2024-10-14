//+------------------------------------------------------------------+
//|                                      InstrumentPropertiesBot.mqh |
//|                                    Copyright 2020, Michael Enudi |
//|                                             okmich2002@yahoo.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2020, Michael Enudi"
#property link      "okmich2002@yahoo.com"

#include "MarketScanner.mqh"
#include <Okmich\Common\AdrReader.mqh>
#include <Trade\AccountInfo.mqh>
#include <Trade\SymbolInfo.mqh>
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
class CInstrumentPropertiesBot : public CBaseBot
  {
private:
   string            mBrokerCode;
   CAccountInfo      accountInfo;
   CSymbolInfo       *symbolInfo;
   bool              Setup()
     {
      symbolInfo.Refresh();
      return true;
     };
     
   double            CalculateMargin(string symbol, ENUM_SYMBOL_CALC_MODE tradeCalcMode, double contractSize,
                                     long leverage, double marginRate);
   string            SymbolProperties(CSymbolInfo &sym);

public:
                     CInstrumentPropertiesBot(string brokerCode, string symbol) : CBaseBot("INSTR", _Period, symbol)
     {
      mBrokerCode = brokerCode;
      symbolInfo = new CSymbolInfo();
      symbolInfo.Name(symbol);
     };

                    ~CInstrumentPropertiesBot()
     {
      delete symbolInfo;
     };

   //this is the main implementation for this bot.
   virtual void      Begin();

   virtual string            Result(long timeCode)
     {
      return ScanValues();
     };
  };

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void CInstrumentPropertiesBot::Begin(void)
  {
   if(!Setup())
     {
      mWorthReporting = false;
      return ;
     }
   mScanValues = SymbolProperties(symbolInfo);
//--- prepare the result if worthreporting
   if(StringLen(mScanValues) > 0)
     {
      mWorthReporting = true;
     }
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
string CInstrumentPropertiesBot::SymbolProperties(CSymbolInfo &sym)
  {
   string symbol = sym.Name();
   string format = "%s|%s|%s|%f|%s|%s|%f|%.2f|%f|%f|%s|%s|%.2f|%.2f|%d|%s|%.2f|%.4f|%d|%.3f|%.6f|%.2f";
   ENUM_SYMBOL_CALC_MODE tradeCalcMode = sym.TradeCalcMode();
   string iClass = EnumToString(tradeCalcMode);
   double point = sym.Point();
   StringReplace(iClass, "SYMBOL_CALC_MODE_", "");
   double contractSize = sym.ContractSize();
   double initialMargin = sym.MarginInitial();
   double maintenanceMargin = sym.MarginMaintenance();
   double buyMarginRate = SymbolInfoMarginRate(symbol, ORDER_TYPE_BUY, initialMargin, maintenanceMargin);
   double minLot = sym.LotsMin();
   long leverage = accountInfo.Leverage();
   double marginRate = initialMargin/leverage;
   double adr = calculateAverageDailyRangeInPoints(symbol);
   double margin = CalculateMargin(symbol, tradeCalcMode, contractSize, leverage, marginRate);
   return StringFormat(format, mBrokerCode, symbol, iClass, contractSize, 
                       EnumToString(tradeCalcMode), sym.TradeCalcModeDescription(),
                       sym.TickSize(), sym.TickValue(), sym.StopsLevel(), margin,
                       EnumToString(sym.TradeMode()), EnumToString(sym.SwapMode()),
                       sym.SwapLong(), sym.SwapShort(),
                       sym.Spread(), (sym.SpreadFloat() ? "true" : "false"),
                       initialMargin, marginRate, leverage, minLot, point, adr
                      );
  }
  
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
double CInstrumentPropertiesBot::CalculateMargin(string symbol, ENUM_SYMBOL_CALC_MODE tradeCalcMode,
      double contractSize, long leverage, double marginRate)
  {
   double marketPrice = SymbolInfoDouble(symbol, SYMBOL_LAST);
   switch(tradeCalcMode)
     {
      case SYMBOL_CALC_MODE_FOREX :
         return contractSize / leverage;
      case SYMBOL_CALC_MODE_FOREX_NO_LEVERAGE:
         return contractSize;
      case SYMBOL_CALC_MODE_CFD:
        {
         return contractSize * marketPrice;
        }
      default:
         return contractSize / leverage;
     }

  }
//+------------------------------------------------------------------+
