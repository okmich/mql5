//+------------------------------------------------------------------+
//|                                               Lot Calculator.mq5 |
//|                                         Copyleft 2018, zebedeig |
//|                           https://www.mql5.com/en/users/zebedeig |
//+------------------------------------------------------------------+

#property copyright    "Copyleft 2018, by zebedeig"
#property link         "https://www.mql5.com/en/users/zebedeig"
#property version      "1.00"
#property description  "Tool used to calculate the correct lot size to trade, given a fixed risk and a number of pips."
#property description  "Simply enter the number of pips of your desired stop loss order, and the indicator will show you "
#property description  "the number of lots to trade based on your total account amount, your account currency and present chart currency pair."

#property strict
#property indicator_chart_window
#property indicator_plots 0

#include <Okmich\Common\AtrReader.mqh>
#include <Okmich\Common\AdrReader.mqh>

#define MODE_TICKVALUE
#define MODE_TICKSIZE
#define MODE_DIGITS

enum ENUM_PointType
  {
   adr, //Average Daily Range
   atr, //Average True Range
   pip  //Pip
  };

input ENUM_PointType PointType = pip; //How to calculate distance
input double Risk = 0.02; // Free margin fraction you want to risk for the trade
input bool useAccountBalance = false; // Check to read the actual free margin of your balance, uncheck to specify it
input int AccountBalance = 2000; // Specify here a simulated balance value
input int Points = 1650; // Stop loss distance from open order in points
input int AtrPeriod = 50; //ATR/ADR Period.
input double AtrMultiple = 1.0; //Multiple of ATR.

//+------------------------------------------------------------------+
//| Custom indicator initialization function                         |
//+------------------------------------------------------------------+

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
CAtrReader mAtrReader(_Symbol, _Period, AtrPeriod);
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
int OnInit()
  {
// Broker digits
   double Digits = _Digits;
   return(INIT_SUCCEEDED);
  }

//+------------------------------------------------------------------+
//| Custom indicator de-init function                         |
//+------------------------------------------------------------------+

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void OnDeinit(const int reason)
  {
   Comment("");  // Cleanup
//Print(__FUNCTION__,"_UninitReason = ",getUninitReasonText(_UninitReason));
   return;
  }

//+------------------------------------------------------------------+
//| Custom indicator iteration function                              |
//+------------------------------------------------------------------+

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
int OnCalculate(const int rates_total,
                const int prev_calculated,
                const datetime &time[],
                const double &open[],
                const double &high[],
                const double &low[],
                const double &close[],
                const long &tick_volume[],
                const long &volume[],
                const int &spread[]
               )
  {
   string CommentString = "";

   string DepositCurrency = AccountInfoString(ACCOUNT_CURRENCY);
   double freeMargin = 0;
   if(useAccountBalance)
     {
      freeMargin = AccountInfoDouble(ACCOUNT_FREEMARGIN);
     }
   else
     {
      freeMargin = AccountBalance;
     }

   double pointDist = 0.0, onePeriod = 0.0, lots=0.0;
   string atrMessage = "";
   if(PointType == adr)
     {
      onePeriod = calculateAverageDailyRangeInPoints(_Symbol, AtrPeriod);
      pointDist = onePeriod * AtrMultiple;

      atrMessage ="-----------------------------------------------------------------\n";
      atrMessage += StringFormat("%d-period ADR Period is %s points. \nWith %s multiple, the risk level in point will be %s away",
                                    AtrPeriod, 
                                    DoubleToString(onePeriod, _Digits),
                                    DoubleToString(AtrMultiple, 2), 
                                    DoubleToString(pointDist, _Digits));
     }
   else
      if(PointType == atr)
        {
         onePeriod = mAtrReader.atrPoints();
         pointDist = onePeriod * AtrMultiple;

         atrMessage ="-----------------------------------------------------------------\n";
         atrMessage += StringFormat("%d-period ATR Period is %s points. \nWith %s multiple, the risk level in point will be %s away",
                                    AtrPeriod, DoubleToString(onePeriod, _Digits),
                                    DoubleToString(AtrMultiple, 2), 
                                    DoubleToString(pointDist, _Digits));
        }
      else
        {
         pointDist = Points;
        }
   ENUM_SYMBOL_CALC_MODE calcMode = (ENUM_SYMBOL_CALC_MODE)SymbolInfoInteger(_Symbol, SYMBOL_TRADE_CALC_MODE);
   double contractSize = SymbolInfoDouble(_Symbol, SYMBOL_TRADE_CONTRACT_SIZE);
   double tickValue = SymbolInfoDouble(_Symbol, SYMBOL_TRADE_TICK_VALUE);

   if(calcMode == SYMBOL_CALC_MODE_CFDLEVERAGE)
      lots = (Risk * freeMargin) / (_Point * pointDist * contractSize);
   else
      lots = Risk * freeMargin / (tickValue * pointDist);

// Truncate lot quantity to 2 decimal digits without rounding it
   lots = floor(lots * 10000) / 10000;

   double minLotSize = SymbolInfoDouble(_Symbol, SYMBOL_VOLUME_MIN);

   CommentString+="\n\n-----------------------------------------------------------------\n";
   CommentString+="Your free margin: "+ DepositCurrency + " " + DoubleToString(freeMargin, 2) + "\n";
   CommentString+="Risk selected: " + DoubleToString(Risk * 100, 2) + "%\n";
   CommentString+="Risk selected: " + DepositCurrency + " " + DoubleToString(Risk * freeMargin, 2) + "\n";
   CommentString+= atrMessage + "\n";
   CommentString+="-----------------------------------------------------------------\n";
   CommentString+="Value of one point trading 1 lot of " + Symbol() + ": " + DepositCurrency + " " + DoubleToString(tickValue * contractSize, 5) + "\n";
   CommentString+="Max lots of " + Symbol() + " to trade while risking " + DoubleToString(pointDist, _Digits) + " points: " + DoubleToString(lots, 4) + "\n";
   CommentString+="Min lot size for " + Symbol() + " is " + DoubleToString(minLotSize, 4) + "\n";
   CommentString+="-----------------------------------------------------------------\n";

   Comment(CommentString);

//--- return value of prev_calculated for next call
   return(rates_total);
  }

//+------------------------------------------------------------------+
//| Custom functions                                                 |
//+------------------------------------------------------------------+

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
string getUninitReasonText(int reasonCode) // Return reason for De-init function
  {
   string text="";

   switch(reasonCode)
     {
      case REASON_ACCOUNT:
         text="Account was changed";
         break;
      case REASON_CHARTCHANGE:
         text="Symbol or timeframe was changed";
         break;
      case REASON_CHARTCLOSE:
         text="Chart was closed";
         break;
      case REASON_PARAMETERS:
         text="Input-parameter was changed";
         break;
      case REASON_RECOMPILE:
         text="Program "+__FILE__+" was recompiled";
         break;
      case REASON_REMOVE:
         text="Program "+__FILE__+" was removed from chart";
         break;
      case REASON_TEMPLATE:
         text="New template was applied to chart";
         break;
      default:
         text="Another reason";
     }

   return text;
  }

//+------------------------------------------------------------------+
