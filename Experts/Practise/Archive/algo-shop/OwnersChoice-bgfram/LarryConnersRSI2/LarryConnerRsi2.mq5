//+------------------------------------------------------------------+
//|                                             LarryConnorsRsi2.mq5 |
//|                                Copyright 2020, Algotrading.co.za |
//|                                     http://www.algotrading.co.za |
//+------------------------------------------------------------------+
#property copyright "Copyright 2020, Algotrading.co.za"
#property link      "http://www.algotrading.co.za"
#property version   "1.02"
#property description   "Larry Conners RSI 2"
//---
#include <Trade\PositionInfo.mqh>
#include <Trade\Trade.mqh>
#include <Trade\SymbolInfo.mqh>
#include <Trade\AccountInfo.mqh>
#include <Trade\DealInfo.mqh>
#include <Trade\OrderInfo.mqh>
#include <Expert\Money\MoneyFixedMargin.mqh>
CPositionInfo  m_position;                   // trade position object
CTrade         m_trade;                      // trading object
CSymbolInfo    m_symbol;                     // symbol info object
CAccountInfo   m_account;                    // account info wrapper
CDealInfo      m_deal;                       // deals object
COrderInfo     m_order;                      // pending orders object
CMoneyFixedMargin *m_money;

//--- input parameters
input group  "Main Settings"
input string   inpComment           = "Larry Conners RSI2"; //Trade Comment
input ulong    m_magic=11172019824;                 // magic number
input bool     InpPrintLog          = true;     // Print log
input uchar    InpMaxBuyPositions   = 2;         // Max Buy Positions
input uchar    InpMaxSellPositions  = 2;         // Max Sell Positions

input group  "Money Management"
input ushort   InpStopLoss       = 45;       // Stop Loss, in pips
input ushort   InpTakeProfit     = 45;       // Take Profit, in pips
input bool     InpUseTrailing    = true;     // Use Trailing stop
input ushort   InpTrailingStop   = 15;       // Trailing Stop, in pips
input ushort   InpTrailingStep   = 5;        // Trailing Step, in pips
input double   InpRisk= 10.0;       // Risk in percentage of free margin

input group  "Slow Moving Average settings"
input int                  Inp_MA_Slow_ma_period=55;// MA Slow: averaging period
input int                  Inp_MA_Slow_ma_shift=0;// MA horizontal shift
input ENUM_MA_METHOD       Inp_MA_Slow_ma_method=MODE_EMA;// MA smoothing type
input ENUM_APPLIED_PRICE   Inp_MA_Slow_applied_price=PRICE_CLOSE;// MA type of price
input ENUM_TIMEFRAMES      Inp_MA_Slow_TF =PERIOD_CURRENT;    // Moving Average Timeframe

input group  "RSI Settings"
input int               Inp_RSI_ma_period    = 2;          // RSI: averaging period
input ENUM_APPLIED_PRICE Inp_RSI_applied_price=PRICE_CLOSE; // RSI: type of price
input double            InpRSILevelUP        = 90;          // RSI Level UP
input double            InpRSILevelDOWN      = 10;          // RSI Level DOWN
input ENUM_TIMEFRAMES   Inp_RSI_TF = PERIOD_CURRENT;           // Stochastics time frame


input group  "Trading Times"
input bool   TradeOnMonday        = true;                       // Trade on Monday
input bool   TradeOnTuesday       = true;                       // Trade on Tuesday
input bool   TradeOnWednesday     = true;                       // Trade on Wednesday
input bool   TradeOnThursday      = true;                       // Trade on Thursday
input bool   TradeOnFriday        = true;                       // Trade on Friday
input bool   UsingTradingHour     = true;                       // Using Trade Hour
input int    StartHour            = 0;                          // Start Hour
input int    EndHour              = 24;                         // End Hour

//---
ulong  m_slippage=10;                        // slippage
double ExtStopLoss      = 0.0;
double ExtTakeProfit    = 0.0;
double ExtTrailingStop  = 0.0;
double ExtTrailingStep  = 0.0;
string ExtComment = "";


double m_adjusted_point;                     // point value adjusted for 3 or 5 points

bool           bln_delete_all=false;
datetime       dt_last_delete=0;

int    handle_iMA_Slow;                      // variable for storing the handle of the iMA indicator
int    handle_iMA_Fast;                      // variable for storing the handle of the iMA indicator
int    handle_iRSI;                     // variable for storing the handle of the IRSI indicator

//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+
int OnInit()
  {
//---
   if(InpTrailingStop!=0 && InpTrailingStep==0 && InpUseTrailing)
     {
      string err_text= "Trailing is not possible: parameter \"Trailing Step\" is zero!";
      //--- when testing, we will only output to the log about incorrect input parameters
      if(MQLInfoInteger(MQL_TESTER))
        {
         Print(__FUNCTION__,", ERROR: ",err_text);
         return(INIT_FAILED);
        }
      else // if the Expert Advisor is run on the chart, tell the user about the error
        {
         Alert(__FUNCTION__,", ERROR: ",err_text);
         return(INIT_PARAMETERS_INCORRECT);
        }
     }
//---
   if(!m_symbol.Name(Symbol())) // sets symbol name
      return(INIT_FAILED);

   RefreshRates();
//---
   m_trade.SetExpertMagicNumber(m_magic);
   m_trade.SetMarginMode();
   m_trade.SetTypeFillingBySymbol(m_symbol.Name());
   m_trade.SetDeviationInPoints(m_slippage);
//--- tuning for 3 or 5 digits
   int digits_adjust=1;
   if(m_symbol.Digits()==3 || m_symbol.Digits()==5)
      digits_adjust=10;
   m_adjusted_point=m_symbol.Point()*digits_adjust;

   ExtStopLoss       = InpStopLoss        * m_adjusted_point;
   ExtTakeProfit     = InpTakeProfit      * m_adjusted_point;
   ExtTrailingStop   = InpTrailingStop    * m_adjusted_point;
   ExtTrailingStep   = InpTrailingStep    * m_adjusted_point;
   ExtComment = inpComment;

//--- check the input parameter "Lots"
   string err_text="";

   if(m_money!=NULL)
      delete m_money;
   m_money=new CMoneyFixedMargin;
   if(m_money!=NULL)
     {
      if(!m_money.Init(GetPointer(m_symbol),Period(),m_symbol.Point()*digits_adjust))
         return(INIT_FAILED);
      m_money.Percent(InpRisk);
     }
   else
     {
      Print(__FUNCTION__,", ERROR: Object CMoneyFixedMargin is NULL");
      return(INIT_FAILED);
     }

//--- create handle of the indicator iRSI
   handle_iRSI=iRSI(m_symbol.Name(),Inp_RSI_TF,Inp_RSI_ma_period,handle_iRSI);
//--- if the handle is not created
   if(handle_iRSI==INVALID_HANDLE)
     {
      //--- tell about the failure and output the error code
      PrintFormat("Failed to create handle of the iRSI indicator for the symbol %s/%s, error code %d",
                  m_symbol.Name(),
                  EnumToString(Period()),
                  GetLastError());
      //--- the indicator is stopped early
      return(INIT_FAILED);
     }
//---

//--- create handle of the indicator iMA
   handle_iMA_Slow=iMA(m_symbol.Name(),Inp_MA_Slow_TF,Inp_MA_Slow_ma_period,Inp_MA_Slow_ma_shift,
                       Inp_MA_Slow_ma_method,handle_iMA_Slow);
//--- if the handle is not created
   if(handle_iMA_Slow==INVALID_HANDLE)
     {
      //--- tell about the failure and output the error code
      PrintFormat("Failed to create handle of the iMA (\"Slow\") indicator for the symbol %s/%s, error code %d",
                  m_symbol.Name(),
                  EnumToString(Period()),
                  GetLastError());
      //--- the indicator is stopped early
      return(INIT_FAILED);
     }

   return(INIT_SUCCEEDED);
  }
//+------------------------------------------------------------------+
//| Expert deinitialization function                                 |
//+------------------------------------------------------------------+
void OnDeinit(const int reason)
  {
//---
   if(m_money!=NULL)
      delete m_money;


   IndicatorRelease(handle_iMA_Slow);
   IndicatorRelease(handle_iRSI);

  }
//+------------------------------------------------------------------+
//| Expert tick function                                             |
//+------------------------------------------------------------------+
void OnTick()
  {
   double level;
   bool buy_signal=false;
   bool sell_signal=false;

   if(InpUseTrailing)
      NormalTrailing();

   if(TimeCheck() == false)
      return;

   if(isNewBar() == false)
      return;


   CheckSignal(buy_signal,sell_signal);

   if(buy_signal)
     {
      if(FreezeStopsLevels(level))
        {
         OpenPosition(POSITION_TYPE_BUY,level);
        }
     }

   if(sell_signal)
     {
      if(FreezeStopsLevels(level))
        {
         OpenPosition(POSITION_TYPE_SELL,level);
        }
     }

  }


//+------------------------------------------------------------------+
//| CheckSignal                                                      |
//+------------------------------------------------------------------+
void CheckSignal(bool &buy_signal,bool &sell_signal)
  {
   buy_signal=false;
   sell_signal=false;

   MqlRates rates[];
   double ma_slow[],rsi[];
   ArraySetAsSeries(ma_slow,true);
   ArraySetAsSeries(rates,true);
   ArraySetAsSeries(rsi,true);

   int start_pos=0,count=3;

   if(!iGetArray(handle_iMA_Slow,0,start_pos,count,ma_slow)||
      !iGetArray(handle_iRSI,0,start_pos,count,rsi) ||
      CopyRates(_Symbol,0,0,count,rates) < count)
     {
      return;
     }
   double price=0.0;
   double sl=0.0;
   double tp=0.0;
   int count_buys=0;
   double volume_buys=0.0;
   double volume_biggest_buys=0.0;
   int count_sells=0;
   double volume_sells=0.0;
   double volume_biggest_sells=0.0;

   CalculateAllPositions(count_buys,volume_buys,volume_biggest_buys,
                         count_sells,volume_sells,volume_biggest_sells);



   if(count_sells < InpMaxSellPositions && rsi[1] > InpRSILevelUP && rates[1].close < ma_slow[1])
     {
      sell_signal = true;
     }

   if(count_buys < InpMaxBuyPositions && rsi[1] < InpRSILevelDOWN && rates[1].close > ma_slow[1])
     {
      buy_signal = true;
     }

  }


//+------------------------------------------------------------------+
//| TradeTransaction function                                        |
//+------------------------------------------------------------------+
void OnTradeTransaction(const MqlTradeTransaction &trans,
                        const MqlTradeRequest &request,
                        const MqlTradeResult &result)
  {

  }
//+------------------------------------------------------------------+
//| Refreshes the symbol quotes data                                 |
//+------------------------------------------------------------------+
bool RefreshRates(void)
  {
//--- refresh rates
   if(!m_symbol.RefreshRates())
     {
      Print("RefreshRates error");
      return(false);
     }
//--- protection against the return value of "zero"
   if(m_symbol.Ask()==0 || m_symbol.Bid()==0)
      return(false);
//---
   return(true);
  }
//+------------------------------------------------------------------+
//| Check the correctness of the position volume                     |
//+------------------------------------------------------------------+
bool CheckVolumeValue(double volume,string &error_description)
  {
//--- minimal allowed volume for trade operations
   double min_volume=m_symbol.LotsMin();
   if(volume<min_volume)
     {
      error_description=StringFormat("Volume is less than the minimal allowed SYMBOL_VOLUME_MIN=%.2f",min_volume);
     }
//--- maximal allowed volume of trade operations
   double max_volume=m_symbol.LotsMax();
   if(volume>max_volume)
     {
      error_description=StringFormat("Volume is greater than the maximal allowed SYMBOL_VOLUME_MAX=%.2f",max_volume);

     }
//--- get minimal step of volume changing
   double volume_step=m_symbol.LotsStep();
   int ratio=(int)MathRound(volume/volume_step);
   if(MathAbs(ratio*volume_step-volume)>0.0000001)
     {
      error_description=StringFormat("Volume is not a multiple of the minimal step SYMBOL_VOLUME_STEP=%.2f, the closest correct volume is %.2f",
                                     volume_step,ratio*volume_step);
      return(false);
     }
   error_description="Correct volume value";
   return(true);
  }
//+------------------------------------------------------------------+
//| Check Freeze and Stops levels                                    |
//+------------------------------------------------------------------+
bool FreezeStopsLevels(double &level)
  {
//--- check Freeze and Stops levels
   /*
      Type of order/position  |  Activation price  |  Check
      ------------------------|--------------------|--------------------------------------------
      Buy Limit order         |  Ask               |  Ask-OpenPrice  >= SYMBOL_TRADE_FREEZE_LEVEL
      Buy Stop order          |  Ask             |  OpenPrice-Ask  >= SYMBOL_TRADE_FREEZE_LEVEL
      Sell Limit order        |  Bid             |  OpenPrice-Bid  >= SYMBOL_TRADE_FREEZE_LEVEL
      Sell Stop order       |  Bid             |  Bid-OpenPrice  >= SYMBOL_TRADE_FREEZE_LEVEL
      Buy position            |  Bid             |  TakeProfit-Bid >= SYMBOL_TRADE_FREEZE_LEVEL
                              |                    |  Bid-StopLoss   >= SYMBOL_TRADE_FREEZE_LEVEL
      Sell position           |  Ask             |  Ask-TakeProfit >= SYMBOL_TRADE_FREEZE_LEVEL
                              |                    |  StopLoss-Ask   >= SYMBOL_TRADE_FREEZE_LEVEL

      Buying is done at the Ask price                 |  Selling is done at the Bid price
      ------------------------------------------------|----------------------------------
      TakeProfit        >= Bid                        |  TakeProfit        <= Ask
      StopLoss          <= Bid                      |  StopLoss          >= Ask
      TakeProfit - Bid  >= SYMBOL_TRADE_STOPS_LEVEL   |  Ask - TakeProfit  >= SYMBOL_TRADE_STOPS_LEVEL
      Bid - StopLoss    >= SYMBOL_TRADE_STOPS_LEVEL   |  StopLoss - Ask    >= SYMBOL_TRADE_STOPS_LEVEL
   */
   if(!RefreshRates() || !m_symbol.Refresh())
      return(false);
//--- FreezeLevel -> for pending order and modification
   double freeze_level=m_symbol.FreezeLevel()*m_symbol.Point();
   if(freeze_level==0.0)
      freeze_level=(m_symbol.Ask()-m_symbol.Bid())*3.0;
   freeze_level*=1.1;
//--- StopsLevel -> for TakeProfit and StopLoss
   double stop_level=m_symbol.StopsLevel()*m_symbol.Point();
   if(stop_level==0.0)
      stop_level=(m_symbol.Ask()-m_symbol.Bid())*3.0;
   stop_level*=1.1;

   if(freeze_level<=0.0 || stop_level<=0.0)
      return(false);

   level=(freeze_level>stop_level)?freeze_level:stop_level;
//---
   return(true);
  }
//+------------------------------------------------------------------+
//| Open position                                                    |
//+------------------------------------------------------------------+
void OpenPosition(const ENUM_POSITION_TYPE pos_type,const double level)
  {
//--- buy
   if(pos_type==POSITION_TYPE_BUY)
     {
      double price=m_symbol.Ask();

      double sl=(InpStopLoss==0)?0.0:price-ExtStopLoss;
      if(sl!=0.0 && ExtStopLoss<level) // check sl
         sl=price-level;

      double tp=(InpTakeProfit==0)?0.0:price+ExtTakeProfit;
      if(tp!=0.0 && ExtTakeProfit<level) // check price
         tp=price+level;

      OpenBuy(sl,tp);
     }
//--- sell
   if(pos_type==POSITION_TYPE_SELL)
     {
      double price=m_symbol.Bid();

      double sl=(InpStopLoss==0)?0.0:price+ExtStopLoss;
      if(sl!=0.0 && ExtStopLoss<level) // check sl
         sl=price+level;

      double tp=(InpTakeProfit==0)?0.0:price-ExtTakeProfit;
      if(tp!=0.0 && ExtTakeProfit<level) // check tp
         tp=price-level;

      OpenSell(sl,tp);
     }
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
//+------------------------------------------------------------------+
//| Pending order                                                    |
//+------------------------------------------------------------------+
void PendingOrder(ENUM_ORDER_TYPE order_type,double price,double sl,double tp,string comment)
  {
   sl=m_symbol.NormalizePrice(sl);
   tp=m_symbol.NormalizePrice(tp);
   double volume=0.0;

   if(order_type == ORDER_TYPE_SELL_LIMIT || order_type == ORDER_TYPE_SELL_STOP)
     {

      double check_open_short_lot=0.0;

      check_open_short_lot=m_money.CheckOpenShort(m_symbol.Bid(),sl);
      if(InpPrintLog)
         Print("sl=",DoubleToString(sl,m_symbol.Digits()),
               ", CheckOpenLong: ",DoubleToString(check_open_short_lot,2),
               ", Balance: ",    DoubleToString(m_account.Balance(),2),
               ", Equity: ",     DoubleToString(m_account.Equity(),2),
               ", FreeMargin: ", DoubleToString(m_account.FreeMargin(),2));
      if(check_open_short_lot==0.0)
        {
         if(InpPrintLog)
            Print(__FUNCTION__,", ERROR: method CheckOpenShort returned the value of \"0.0\"");
         return;
        }

      //--- check volume before OrderSend to avoid "not enough money" error (CTrade)
      double check_volume_lot=m_trade.CheckVolume(m_symbol.Name(),check_open_short_lot,m_symbol.Bid(),ORDER_TYPE_SELL);

      if(check_volume_lot!=0.0)
        {
         if(check_volume_lot>=check_open_short_lot)
           {
            volume = check_open_short_lot;
           }
         else
           {
            return;
           }
        }
      else
        {
         return;
        }
     }

   if(order_type == ORDER_TYPE_BUY_LIMIT || order_type == ORDER_TYPE_BUY_STOP)
     {

      double check_open_long_lot=0.0;

      check_open_long_lot=m_money.CheckOpenLong(m_symbol.Bid(),sl);
      if(InpPrintLog)
         Print("sl=",DoubleToString(sl,m_symbol.Digits()),
               ", CheckOpenLong: ",DoubleToString(check_open_long_lot,2),
               ", Balance: ",    DoubleToString(m_account.Balance(),2),
               ", Equity: ",     DoubleToString(m_account.Equity(),2),
               ", FreeMargin: ", DoubleToString(m_account.FreeMargin(),2));
      if(check_open_long_lot==0.0)
        {
         if(InpPrintLog)
            Print(__FUNCTION__,", ERROR: method check_open_long_lot returned the value of \"0.0\"");
         return;
        }

      //--- check volume before OrderSend to avoid "not enough money" error (CTrade)
      double check_volume_lot=m_trade.CheckVolume(m_symbol.Name(),check_open_long_lot,m_symbol.Ask(),ORDER_TYPE_BUY);

      if(check_volume_lot!=0.0)
        {
         if(check_volume_lot>=check_open_long_lot)
           {
            volume = check_open_long_lot;
           }
         else
           {
            return;
           }
        }
      else
        {
         return;
        }
     }

   bool result=false;

   result=m_trade.OrderOpen(m_symbol.Name(),order_type,volume,0.0,
                            m_symbol.NormalizePrice(price),m_symbol.NormalizePrice(sl),m_symbol.NormalizePrice(tp),
                            ORDER_TIME_GTC,0,comment);
   if(result)
     {
      if(m_trade.ResultOrder()==0)
        {
         if(InpPrintLog)
           {
            Print("#1 ",EnumToString(order_type)," -> false. Result Retcode: ",m_trade.ResultRetcode(),
                  ", description of result: ",m_trade.ResultRetcodeDescription());
            PrintResultTrade(m_trade,m_symbol);
           }
        }
      else
        {
         if(InpPrintLog)
           {
            Print("#2 ",EnumToString(order_type)," -> true. Result Retcode: ",m_trade.ResultRetcode(),
                  ", description of result: ",m_trade.ResultRetcodeDescription());
            PrintResultTrade(m_trade,m_symbol);
           }
        }
     }
   else
     {
      if(InpPrintLog)
        {
         Print("#3 ",EnumToString(order_type)," -> false. Result Retcode: ",m_trade.ResultRetcode(),
               ", description of result: ",m_trade.ResultRetcodeDescription());
         PrintResultTrade(m_trade,m_symbol);
        }
     }
//---
  }
//+------------------------------------------------------------------+
//| Open Buy position                                                |
//+------------------------------------------------------------------+
void OpenBuy(double sl,double tp)
  {
   sl=m_symbol.NormalizePrice(sl);
   tp=m_symbol.NormalizePrice(tp);

   double long_lot=0.0;

   long_lot=m_money.CheckOpenLong(m_symbol.Ask(),sl);
   if(InpPrintLog)
      Print("sl=",DoubleToString(sl,m_symbol.Digits()),
            ", CheckOpenLong: ",DoubleToString(long_lot,2),
            ", Balance: ",    DoubleToString(m_account.Balance(),2),
            ", Equity: ",     DoubleToString(m_account.Equity(),2),
            ", FreeMargin: ", DoubleToString(m_account.FreeMargin(),2));
   if(long_lot==0.0)
     {
      if(InpPrintLog)
         Print(__FUNCTION__,", ERROR: method CheckOpenLong returned the value of \"0.0\"");
      return;
     }

   if(m_symbol.LotsLimit()>0.0)
     {
      int count_buys=0;
      double volume_buys=0.0;
      double volume_biggest_buys=0.0;
      int count_sells=0;
      double volume_sells=0.0;
      double volume_biggest_sells=0.0;
      CalculateAllPositions(count_buys,volume_buys,volume_biggest_buys,
                            count_sells,volume_sells,volume_biggest_sells);
      if(volume_buys+volume_sells+long_lot>m_symbol.LotsLimit())
        {
         Print("#0 Buy, Volume Buy (",DoubleToString(volume_buys,2),
               ") + Volume Sell (",DoubleToString(volume_sells,2),
               ") + Volume long (",DoubleToString(long_lot,2),
               ") > Lots Limit (",DoubleToString(m_symbol.LotsLimit(),2),")");
         return;
        }
     }
//--- check volume before OrderSend to avoid "not enough money" error (CTrade)
   double free_margin_check= m_account.FreeMarginCheck(m_symbol.Name(),ORDER_TYPE_BUY,long_lot,m_symbol.Ask());
   double margin_check     = m_account.MarginCheck(m_symbol.Name(),ORDER_TYPE_SELL,long_lot,m_symbol.Bid());
   if(free_margin_check>margin_check)
     {
      if(m_trade.Buy(long_lot,m_symbol.Name(),m_symbol.Ask(),sl,tp,ExtComment)) // CTrade::Buy -> "true"
        {
         if(m_trade.ResultDeal()==0)
           {
            if(InpPrintLog)
               Print("#1 Buy -> false. Result Retcode: ",m_trade.ResultRetcode(),
                     ", description of result: ",m_trade.ResultRetcodeDescription());
            if(InpPrintLog)
               PrintResultTrade(m_trade,m_symbol);
           }
         else
           {
            if(InpPrintLog)
               Print("#2 Buy -> true. Result Retcode: ",m_trade.ResultRetcode(),
                     ", description of result: ",m_trade.ResultRetcodeDescription());
            if(InpPrintLog)
               PrintResultTrade(m_trade,m_symbol);
           }
        }
      else
        {
         if(InpPrintLog)
            Print("#3 Buy -> false. Result Retcode: ",m_trade.ResultRetcode(),
                  ", description of result: ",m_trade.ResultRetcodeDescription());
         if(InpPrintLog)
            PrintResultTrade(m_trade,m_symbol);
        }
     }
   else
     {
      if(InpPrintLog)
         Print(__FUNCTION__,", ERROR: method CAccountInfo::FreeMarginCheck returned the value ",DoubleToString(free_margin_check,2));
      return;
     }
//---
  }
//+------------------------------------------------------------------+
//| Open Sell position                                               |
//+------------------------------------------------------------------+
void OpenSell(double sl,double tp)
  {
   sl=m_symbol.NormalizePrice(sl);
   tp=m_symbol.NormalizePrice(tp);

   double short_lot=0.0;

   short_lot=m_money.CheckOpenShort(m_symbol.Bid(),sl);
   if(InpPrintLog)
      Print("sl=",DoubleToString(sl,m_symbol.Digits()),
            ", CheckOpenLong: ",DoubleToString(short_lot,2),
            ", Balance: ",    DoubleToString(m_account.Balance(),2),
            ", Equity: ",     DoubleToString(m_account.Equity(),2),
            ", FreeMargin: ", DoubleToString(m_account.FreeMargin(),2));
   if(short_lot==0.0)
     {
      if(InpPrintLog)
         Print(__FUNCTION__,", ERROR: method CheckOpenShort returned the value of \"0.0\"");
      return;
     }

   if(m_symbol.LotsLimit()>0.0)
     {
      int count_buys=0;
      double volume_buys=0.0;
      double volume_biggest_buys=0.0;
      int count_sells=0;
      double volume_sells=0.0;
      double volume_biggest_sells=0.0;
      CalculateAllPositions(count_buys,volume_buys,volume_biggest_buys,
                            count_sells,volume_sells,volume_biggest_sells);
      if(volume_buys+volume_sells+short_lot>m_symbol.LotsLimit())
        {
         Print("#0 Buy, Volume Buy (",DoubleToString(volume_buys,2),
               ") + Volume Sell (",DoubleToString(volume_sells,2),
               ") + Volume short (",DoubleToString(short_lot,2),
               ") > Lots Limit (",DoubleToString(m_symbol.LotsLimit(),2),")");
         return;
        }
     }
//--- check volume before OrderSend to avoid "not enough money" error (CTrade)
   double free_margin_check= m_account.FreeMarginCheck(m_symbol.Name(),ORDER_TYPE_SELL,short_lot,m_symbol.Bid());
   double margin_check     = m_account.MarginCheck(m_symbol.Name(),ORDER_TYPE_SELL,short_lot,m_symbol.Bid());
   if(free_margin_check>margin_check)
     {
      if(m_trade.Sell(short_lot,m_symbol.Name(),m_symbol.Bid(),sl,tp,ExtComment)) // CTrade::Sell -> "true"
        {
         if(m_trade.ResultDeal()==0)
           {
            if(InpPrintLog)
               Print("#1 Sell -> false. Result Retcode: ",m_trade.ResultRetcode(),
                     ", description of result: ",m_trade.ResultRetcodeDescription());
            if(InpPrintLog)
               PrintResultTrade(m_trade,m_symbol);
           }
         else
           {
            if(InpPrintLog)
               Print("#2 Sell -> true. Result Retcode: ",m_trade.ResultRetcode(),
                     ", description of result: ",m_trade.ResultRetcodeDescription());
            if(InpPrintLog)
               PrintResultTrade(m_trade,m_symbol);
           }
        }
      else
        {
         if(InpPrintLog)
            Print("#3 Sell -> false. Result Retcode: ",m_trade.ResultRetcode(),
                  ", description of result: ",m_trade.ResultRetcodeDescription());
         if(InpPrintLog)
            PrintResultTrade(m_trade,m_symbol);
        }
     }
   else
     {
      if(InpPrintLog)
         Print(__FUNCTION__,", ERROR: method CAccountInfo::FreeMarginCheck returned the value ",DoubleToString(free_margin_check,2));
      return;
     }
//---
  }
//+------------------------------------------------------------------+
//| Print CTrade result                                              |
//+------------------------------------------------------------------+
void PrintResultTrade(CTrade &trade,CSymbolInfo &symbol)
  {
   Print("File: ",__FILE__,", symbol: ",symbol.Name());
   Print("Code of request result: "+IntegerToString(trade.ResultRetcode()));
   Print("code of request result as a string: "+trade.ResultRetcodeDescription());
   Print("Deal ticket: "+IntegerToString(trade.ResultDeal()));
   Print("Order ticket: "+IntegerToString(trade.ResultOrder()));
   Print("Volume of deal or order: "+DoubleToString(trade.ResultVolume(),2));
   Print("Price, confirmed by broker: "+DoubleToString(trade.ResultPrice(),symbol.Digits()));
   Print("Current bid price: "+DoubleToString(symbol.Bid(),symbol.Digits())+" (the requote): "+DoubleToString(trade.ResultBid(),symbol.Digits()));
   Print("Current ask price: "+DoubleToString(symbol.Ask(),symbol.Digits())+" (the requote): "+DoubleToString(trade.ResultAsk(),symbol.Digits()));
   Print("Broker comment: "+trade.ResultComment());
   int d=0;
  }
//+------------------------------------------------------------------+
//| Get value of buffers                                             |
//+------------------------------------------------------------------+
double iGetArray(const int handle,const int buffer,const int start_pos,const int count,double &arr_buffer[])
  {
   bool result=true;
   if(!ArrayIsDynamic(arr_buffer))
     {
      Print("This a no dynamic array!");
      return(false);
     }
   ArrayFree(arr_buffer);
//--- reset error code
   ResetLastError();
//--- fill a part of the iBands array with values from the indicator buffer
   int copied=CopyBuffer(handle,buffer,start_pos,count,arr_buffer);
   if(copied!=count)
     {
      //--- if the copying fails, tell the error code
      PrintFormat("Failed to copy data from the indicator, error code %d",GetLastError());
      //--- quit with zero result - it means that the indicator is considered as not calculated
      return(false);
     }
   return(result);
  }
//+------------------------------------------------------------------+
//| Trailing                                                         |
//|   InpTrailingStop: min distance from price to Stop Loss          |
//+------------------------------------------------------------------+
void NormalTrailing()
  {
   if(InpTrailingStop==0)
      return;
   for(int i=PositionsTotal()-1; i>=0; i--) // returns the number of open positions
      if(m_position.SelectByIndex(i))
         if(m_position.Symbol()==m_symbol.Name() && m_position.Magic()==m_magic)
           {
            if(m_position.PositionType()==POSITION_TYPE_BUY)
              {
               if(m_position.PriceCurrent()-m_position.PriceOpen()>ExtTrailingStop+ExtTrailingStep)
                  if(m_position.StopLoss()<m_position.PriceCurrent()-(ExtTrailingStop+ExtTrailingStep))
                    {
                     if(!m_trade.PositionModify(m_position.Ticket(),
                                                m_symbol.NormalizePrice(m_position.PriceCurrent()-ExtTrailingStop),
                                                m_position.TakeProfit()))
                        Print("Modify BUY ",m_position.Ticket(),
                              " Position -> false. Result Retcode: ",m_trade.ResultRetcode(),
                              ", description of result: ",m_trade.ResultRetcodeDescription());
                    }
              }
            else
              {
               if(m_position.PriceOpen()-m_position.PriceCurrent()>ExtTrailingStop+ExtTrailingStep)
                  if((m_position.StopLoss()>(m_position.PriceCurrent()+(ExtTrailingStop+ExtTrailingStep))) ||
                     (m_position.StopLoss()==0))
                    {
                     if(!m_trade.PositionModify(m_position.Ticket(),
                                                m_symbol.NormalizePrice(m_position.PriceCurrent()+ExtTrailingStop),
                                                m_position.TakeProfit()))
                        Print("Modify SELL ",m_position.Ticket(),
                              " Position -> false. Result Retcode: ",m_trade.ResultRetcode(),
                              ", description of result: ",m_trade.ResultRetcodeDescription());
                    }
              }

           }
  }
//+------------------------------------------------------------------+
//| Trailing                                                         |
//|   InpTrailingStop: min distance from price to Stop Loss          |
//+------------------------------------------------------------------+
void Trailing(const double stop_level)
  {
   /*
        Buying is done at the Ask price                 |  Selling is done at the Bid price
      ------------------------------------------------|----------------------------------
      TakeProfit        >= Bid                        |  TakeProfit        <= Ask
      StopLoss          <= Bid                      |  StopLoss          >= Ask
      TakeProfit - Bid  >= SYMBOL_TRADE_STOPS_LEVEL   |  Ask - TakeProfit  >= SYMBOL_TRADE_STOPS_LEVEL
      Bid - StopLoss    >= SYMBOL_TRADE_STOPS_LEVEL   |  StopLoss - Ask    >= SYMBOL_TRADE_STOPS_LEVEL
   */
   if(InpTrailingStop==0)
      return;
   for(int i=PositionsTotal()-1; i>=0; i--) // returns the number of open positions
      if(m_position.SelectByIndex(i))
         if(m_position.Symbol()==m_symbol.Name() && m_position.Magic()==m_magic)
           {
            if(m_position.PositionType()==POSITION_TYPE_BUY)
              {
               if(m_position.PriceCurrent()-m_position.PriceOpen()>ExtTrailingStop+ExtTrailingStep)
                  if(m_position.StopLoss()<m_position.PriceCurrent()-(ExtTrailingStop+ExtTrailingStep))
                     if(ExtTrailingStop>=stop_level)
                       {
                        if(!m_trade.PositionModify(m_position.Ticket(),
                                                   m_symbol.NormalizePrice(m_position.PriceCurrent()-ExtTrailingStop),
                                                   m_position.TakeProfit()))
                           Print("Modify ",m_position.Ticket(),
                                 " Position -> false. Result Retcode: ",m_trade.ResultRetcode(),
                                 ", description of result: ",m_trade.ResultRetcodeDescription());
                        RefreshRates();
                        m_position.SelectByIndex(i);
                        PrintResultModify(m_trade,m_symbol,m_position);
                        continue;
                       }
              }
            else
              {
               if(m_position.PriceOpen()-m_position.PriceCurrent()>ExtTrailingStop+ExtTrailingStep)
                  if((m_position.StopLoss()>(m_position.PriceCurrent()+(ExtTrailingStop+ExtTrailingStep))) ||
                     (m_position.StopLoss()==0))
                     if(ExtTrailingStop>=stop_level)
                       {
                        if(!m_trade.PositionModify(m_position.Ticket(),
                                                   m_symbol.NormalizePrice(m_position.PriceCurrent()+ExtTrailingStop),
                                                   m_position.TakeProfit()))
                           Print("Modify ",m_position.Ticket(),
                                 " Position -> false. Result Retcode: ",m_trade.ResultRetcode(),
                                 ", description of result: ",m_trade.ResultRetcodeDescription());
                        RefreshRates();
                        m_position.SelectByIndex(i);
                        PrintResultModify(m_trade,m_symbol,m_position);
                       }
              }

           }
  }
//+------------------------------------------------------------------+
//| Print CTrade result                                              |
//+------------------------------------------------------------------+
void PrintResultModify(CTrade &trade,CSymbolInfo &symbol,CPositionInfo &position)
  {
   Print("File: ",__FILE__,", symbol: ",m_symbol.Name());
   Print("Code of request result: "+IntegerToString(trade.ResultRetcode()));
   Print("code of request result as a string: "+trade.ResultRetcodeDescription());
   Print("Deal ticket: "+IntegerToString(trade.ResultDeal()));
   Print("Order ticket: "+IntegerToString(trade.ResultOrder()));
   Print("Volume of deal or order: "+DoubleToString(trade.ResultVolume(),2));
   Print("Price, confirmed by broker: "+DoubleToString(trade.ResultPrice(),symbol.Digits()));
   Print("Current bid price: "+DoubleToString(symbol.Bid(),symbol.Digits())+" (the requote): "+DoubleToString(trade.ResultBid(),symbol.Digits()));
   Print("Current ask price: "+DoubleToString(symbol.Ask(),symbol.Digits())+" (the requote): "+DoubleToString(trade.ResultAsk(),symbol.Digits()));
   Print("Broker comment: "+trade.ResultComment());
   Print("Freeze Level: "+DoubleToString(m_symbol.FreezeLevel(),0),", Stops Level: "+DoubleToString(m_symbol.StopsLevel(),0));
   Print("Price of position opening: "+DoubleToString(position.PriceOpen(),symbol.Digits()));
   Print("Price of position's Stop Loss: "+DoubleToString(position.StopLoss(),symbol.Digits()));
   Print("Price of position's Take Profit: "+DoubleToString(position.TakeProfit(),symbol.Digits()));
   Print("Current price by position: "+DoubleToString(position.PriceCurrent(),symbol.Digits()));
   int d=0;
  }
//+------------------------------------------------------------------+
//| Close positions                                                  |
//+------------------------------------------------------------------+
void ClosePositions(const ENUM_POSITION_TYPE pos_type)
  {
   for(int i=PositionsTotal()-1; i>=0; i--) // returns the number of current positions
      if(m_position.SelectByIndex(i))     // selects the position by index for further access to its properties
         if(m_position.Symbol()==m_symbol.Name() && m_position.Magic()==m_magic)
            if(m_position.PositionType()==pos_type) // gets the position type
               m_trade.PositionClose(m_position.Ticket()); // close a position by the specified symbol
  }
//+------------------------------------------------------------------+
//| Calculate all positions                                          |
//+------------------------------------------------------------------+
void CalculateAllPositions(int &count_buys,double &volume_buys,double &volume_biggest_buys,
                           int &count_sells,double &volume_sells,double &volume_biggest_sells)
  {
   count_buys  =0;
   volume_buys   = 0.0;
   volume_biggest_buys  = 0.0;
   count_sells =0;
   volume_sells  = 0.0;
   volume_biggest_sells = 0.0;
   for(int i=PositionsTotal()-1; i>=0; i--)
      if(m_position.SelectByIndex(i)) // selects the position by index for further access to its properties
         if(m_position.Symbol()==m_symbol.Name() && m_position.Magic()==m_magic)
           {
            if(m_position.PositionType()==POSITION_TYPE_BUY)
              {
               count_buys++;
               volume_buys+=m_position.Volume();
               if(m_position.Volume()>volume_biggest_buys)
                  volume_biggest_buys=m_position.Volume();
               continue;
              }
            else
               if(m_position.PositionType()==POSITION_TYPE_SELL)
                 {
                  count_sells++;
                  volume_sells+=m_position.Volume();
                  if(m_position.Volume()>volume_biggest_sells)
                     volume_biggest_sells=m_position.Volume();
                 }
           }
  }
//+------------------------------------------------------------------+

//+------------------------------------------------------------------+
//| Time Check Function                                              |
//+------------------------------------------------------------------+
bool TimeCheck()
  {
   bool Result = false;
   bool CheckDay = false;
   bool CheckHour = false;
   MqlDateTime TimeNow;
   TimeToStruct(TimeCurrent(),TimeNow);
// Check day
   if((TimeNow.day_of_week == 1 && TradeOnMonday) ||
      (TimeNow.day_of_week == 2 && TradeOnTuesday) ||
      (TimeNow.day_of_week == 3 && TradeOnWednesday) ||
      (TimeNow.day_of_week == 4 && TradeOnThursday) ||
      (TimeNow.day_of_week == 5 && TradeOnFriday))
      CheckDay = true;
// Check hour
   if(StartHour < EndHour)
      if(TimeNow.hour >= StartHour &&
         TimeNow.hour <= EndHour)
         CheckHour = true;
   if(StartHour > EndHour)
      if(TimeNow.hour >= StartHour ||
         TimeNow.hour <= EndHour)
         CheckHour = true;
   if(StartHour == EndHour)
      if(TimeNow.hour == StartHour)
         CheckHour = true;
// Check All
   if(UsingTradingHour && CheckDay && CheckHour)
      Result = true;
   if(!UsingTradingHour && CheckDay)
      Result = true;
   return(Result);
  }
//+------------------------------------------------------------------+

//+------------------------------------------------------------------+
//| Returns true if a new bar has appeared for a symbol/period pair  |
//+------------------------------------------------------------------+
bool isNewBar()
  {
//--- memorize the time of opening of the last bar in the static variable
   static datetime last_time=0;
//--- current time
   datetime lastbar_time=(datetime)SeriesInfoInteger(Symbol(),Period(),SERIES_LASTBAR_DATE);

//--- if it is the first call of the function
   if(last_time==0)
     {
      //--- set the time and exit
      last_time=lastbar_time;
      return(false);
     }

//--- if the time differs
   if(last_time!=lastbar_time)
     {
      //--- memorize the time and return true
      last_time=lastbar_time;
      return(true);
     }
//--- if we passed to this line, then the bar is not new; return false
   return(false);
  }
//+------------------------------------------------------------------+


//+------------------------------------------------------------------+
//| Profit all positions                                             |
//+------------------------------------------------------------------+
double  ProfitAllPositions()
  {
   double profit=0.0;

   for(int i=PositionsTotal()-1; i>=0; i--)
      if(m_position.SelectByIndex(i)) // selects the position by index for further access to its properties
         if(m_position.Symbol()==m_symbol.Name() && m_position.Magic()==m_magic)
            profit+=m_position.Commission()+m_position.Swap()+m_position.Profit();
//---
   return(profit);
  }
//+------------------------------------------------------------------+
//| Is position exists                                               |
//+------------------------------------------------------------------+
bool IsPositionExists(void)
  {
   for(int i=PositionsTotal()-1; i>=0; i--)
      if(m_position.SelectByIndex(i)) // selects the position by index for further access to its properties
         if(m_position.Symbol()==m_symbol.Name() && m_position.Magic()==m_magic)
            return(true);
//---
   return(false);
  }
//+------------------------------------------------------------------+
//| Is pendinf orders exists                                         |
//+------------------------------------------------------------------+
bool IsPendingOrdersExists(void)
  {
   for(int i=OrdersTotal()-1; i>=0; i--) // returns the number of current orders
      if(m_order.SelectByIndex(i))     // selects the pending order by index for further access to its properties
         if(m_order.Symbol()==m_symbol.Name() && m_order.Magic()==m_magic)
            return(true);
//---
   return(false);
  }
//+------------------------------------------------------------------+
//| Close all positions                                              |
//+------------------------------------------------------------------+
void CloseAllPositions()
  {
   for(int i=PositionsTotal()-1; i>=0; i--) // returns the number of current positions
      if(m_position.SelectByIndex(i))     // selects the position by index for further access to its properties
         if(m_position.Symbol()==m_symbol.Name() && m_position.Magic()==m_magic)
            m_trade.PositionClose(m_position.Ticket()); // close a position by the specified symbol
  }
//+------------------------------------------------------------------+
//| Delete all pending orders                                        |
//+------------------------------------------------------------------+
void DeleteAllPendingOrders()
  {
   for(int i=OrdersTotal()-1; i>=0; i--) // returns the number of current orders
      if(m_order.SelectByIndex(i))     // selects the pending order by index for further access to its properties
         if(m_order.Symbol()==m_symbol.Name() && m_order.Magic()==m_magic)
            m_trade.OrderDelete(m_order.Ticket());
  }

//+------------------------------------------------------------------+
//+------------------------------------------------------------------+
