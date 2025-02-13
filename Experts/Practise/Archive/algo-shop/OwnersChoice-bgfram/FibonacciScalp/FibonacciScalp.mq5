//+------------------------------------------------------------------+
//|                                               FibonacciScalp.mq5 |
//|                                      Copyright 2019, Algotrading |
//|                                         http://algotrading.co.za |
//+------------------------------------------------------------------+

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

enum ENUM_LOT_OR_RISK
  {
   lot=0,   // Constant lot
   risk=1,  // Risk in percent of free margin
  };

enum ENUM_TRADING_RANGE
  {
   big=0,    //  23.6 - 61.8
   small=1,  //  38.2 - 50
   none=2,   // No Open range (Reversals Only)
  };

input group  "Main Settings"
input string   inpComment           = "Fibo Trader"; //Trade Comment
input ulong    m_magic=11172019824;                  // magic number
input bool     InpPrintLog          = true;         // Print log
input uchar    InpMaxBuyPositions   = 2;             // Max Buy Positions
input uchar    InpMaxSellPositions  = 2;             // Max Sell Positions

input group  "Money Management"
input ushort   InpStopLoss       = 50;      // Stop Loss, in pips
input ushort   InpTakeProfit     = 90;      // Take Profit, in pips
input bool     InpUseTrailing    = true;    // Use Trailing stop
input ushort   InpTrailingStop   = 45;      // Trailing Stop, in pips
input ushort   InpTrailingStep   = 15;      // Trailing Step, in pips
input ENUM_LOT_OR_RISK IntLotOrRisk=risk;    // Money management: Lot OR Risk
input double   InpVolumeLotOrRisk=3.0;       // Amount for Lot or Risk

input group  "Fibonacci Settings"
input ENUM_TIMEFRAMES      Inp_Fibo_TimeFrame         = PERIOD_H4;         // Fibo time frame
input uchar                Inp_Fibo_NumBars           = 4;                 // Number of bars for finding support and resistance levels
input ENUM_TRADING_RANGE   Inp_Fibo_TradingRange = small;    // Set the open trading range


input group  "MACD Settings"
input int      Inp_MACD_fast_ema_period   = 12;    // MACD: period for Fast average calculation
input int      Inp_MACD_slow_ema_period   = 26;    // MACD: period for Slow average calculation
input int      Inp_MACD_signal_period     = 9;    // MACD: period for their difference averaging
input ENUM_APPLIED_PRICE   Inp_MACD_applied_price     = PRICE_HIGH; // MACD: type of price
input ENUM_TIMEFRAMES   Inp_MACD_TimeFrame = PERIOD_H4;  // MACD time frame


input group  "Trading Times"
input bool   TradeOnMonday        = true;                       // Trade on Monday
input bool   TradeOnTuesday       = true;                       // Trade on Tuesday
input bool   TradeOnWednesday     = true;                       // Trade on Wednesday
input bool   TradeOnThursday      = true;                       // Trade on Thursday
input bool   TradeOnFriday        = true;                       // Trade on Friday
input bool   UsingTradingHour     = true;                       // Using Trade Hour
input int    StartHour            = 0;                          // Start Hour
input int    EndHour              = 24;                         // End Hour

input   group  "News settings";
input bool     LowNews             = false; //Pause trading on low news
input int      LowIndentBefore     = 15; //Pause before low news (In Minutes)
input int      LowIndentAfter      = 15; //Pause after low news (In Minutes)
input bool     MidleNews           = false; //Pause trading on medium news
input int      MidleIndentBefore   = 30; //Pause before medium news (In Minutes)
input int      MidleIndentAfter    = 30; //Pause after medium news (In Minutes)
input bool     HighNews            = true; //Pause trading on high news
input int      HighIndentBefore    = 60; //Pause before high news (In Minutes)
input int      HighIndentAfter     = 60; //Pause after high news (In Minutes)
input bool     NFPNews             = true; //Pause trading on NFP news
input int      NFPIndentBefore     = 180; //Pause before NFP news (In Minutes)
input int      NFPIndentAfter      = 180; //Pause after NFP news (In Minutes)

input bool    DrawNewsLines        = true; //Draw news lines
input color   LowColor             = clrGreen; //Low news line color
input color   MidleColor           = clrBlue;//Medium news line color
input color   HighColor            = clrRed; //High news line color
input bool    OnlySymbolNews       = true; //Show news for current symbol
input int     GMTplus=0;     // Your Time Zone, GMT (for news)

string               Inp_Fibo_Object_Name       = "FiboLevels";      // Object name
color                Inp_Fibo_Color             = clrRed;            // Object color
ENUM_LINE_STYLE      Inp_Fibo_Line_Style        = STYLE_DASHDOTDOT;  // Line style
int                  Inp_Fibo_Line_Width        = 2;                 // Line width
bool                 Inp_Fibo_Move_Back         = false;             // Background object
bool                 Inp_Fibo_Selection         = false;             // Highlight to move
bool                 Inp_Fibo_RayLeft           = true;              // Object's continuation to the left
bool                 Inp_Fibo_RayRight          = true;              // Object's continuation to the right
bool                 Inp_Fibo_Hidden            = true;              // Hidden in the object list
long                 Inp_Fibo_ZOrder            = 0;                 // Priority for mouse click

//---
ulong  m_slippage=10;                        // slippage
double ExtStopLoss      = 0.0;
double ExtTakeProfit    = 0.0;
double ExtTrailingStop  = 0.0;
double ExtTrailingStep  = 0.0;
string ExtComment = "";

double m_resist=0.0;
double m_support=0.0;
string m_trend_type="";
string m_signal="";
bool   m_high_first=false;
double fibo_1_000=0.0;
double fibo_0_618=0.0;
double fibo_0_500=0.0;
double fibo_0_382=0.0;
double fibo_0_236=0.0;
double fibo_0_000=0.0;


double m_adjusted_point;                     // point value adjusted for 3 or 5 points

bool           bln_delete_all=false;
datetime       dt_last_delete=0;

int    handle_iMacd;

int NomNews=0,Now=0,MinBefore=0,MinAfter=0;
string NewsArr[4][1000];
datetime LastUpd;
string ValStr;
int   Upd            = 86400;      // Period news updates in seconds
bool  Next           = false;      // Draw only the future of news line
bool  Signal         = false;      // Signals on the upcoming news
datetime TimeNews[300];
string Valuta[300],News[300],Vazn[300];
int     LineWidth            = 1;
ENUM_LINE_STYLE LineStyle    = STYLE_DOT;

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

//--- check the input parameter "Lots"
   if(IntLotOrRisk==lot)
     {
      if(!CheckVolumeValue(InpVolumeLotOrRisk,err_text))
        {
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
     }
   else
     {
      if(m_money!=NULL)
         delete m_money;
      m_money=new CMoneyFixedMargin;
      if(m_money!=NULL)
        {
         if(!m_money.Init(GetPointer(m_symbol),Period(),m_symbol.Point()*digits_adjust))
            return(INIT_FAILED);
         m_money.Percent(InpVolumeLotOrRisk);
        }
      else
        {
         Print(__FUNCTION__,", ERROR: Object CMoneyFixedMargin is NULL");
         return(INIT_FAILED);
        }
     }

   handle_iMacd=iMACD(m_symbol.Name(),Inp_MACD_TimeFrame,Inp_MACD_fast_ema_period,
                      Inp_MACD_slow_ema_period,Inp_MACD_signal_period,Inp_MACD_applied_price);
   if(handle_iMacd==INVALID_HANDLE)
     {
      PrintFormat("Failed to create handle of the iMACD indicator for the symbol %s/%s, error code %d",
                  m_symbol.Name(),
                  EnumToString(Inp_MACD_TimeFrame),
                  GetLastError());
      return(INIT_FAILED);
     }

   string v1=StringSubstr(_Symbol,0,3);
   string v2=StringSubstr(_Symbol,3,3);
   ValStr=v1+","+v2;

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

   Comment("");
   del("NS_");

   IndicatorRelease(handle_iMacd);

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

   if(!MQLInfoInteger(MQL_TESTER))
     {
      if(!CheckNews())
        {
         // News event occuring return;
         return;
        }
     }

   if(isNewBar() == false)
      return;

   if(!FiboMove())
     {
      return;
     }


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

   bool fibo_buy = true;
   bool fibo_sell = true;
   bool macd_buy = true;
   bool macd_sell = true;

   double price=0.0;
   double sl=0.0;
   double tp=0.0;
   int count_buys=0;
   double volume_buys=0.0;
   double volume_biggest_buys=0.0;
   int count_sells=0;
   double volume_sells=0.0;
   double volume_biggest_sells=0.0;
   bool good_buy = false;
   bool good_sell = false;
   string trend = "NONE";


   CalculateAllPositions(count_buys,volume_buys,volume_biggest_buys,
                         count_sells,volume_sells,volume_biggest_sells);

   CheckFiboSignal(fibo_buy,fibo_sell);

   CheckMacdSignal(macd_buy,macd_sell);

   good_buy =  fibo_buy && macd_buy;
   good_sell = fibo_sell && macd_sell;

   if(macd_buy)
     {
      trend = "BUY";
     }

   if(macd_sell)
     {
      trend = "SELL";
     }

   Comment("MACD Trend : " + trend);

   if(count_sells < InpMaxSellPositions && good_sell)
     {
      sell_signal = true;
     }

   if(count_buys < InpMaxBuyPositions && good_buy)
     {
      buy_signal = true;
     }

  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void CheckMacdSignal(bool &macd_buy,bool &macd_sell)
  {
   macd_buy = false;
   macd_sell = false;
   double macd_main[],macd_signal[];
   ArraySetAsSeries(macd_main,true);
   ArraySetAsSeries(macd_signal,true);

   int start_pos=0,count=5;
   if(!iGetArray(handle_iMacd,MAIN_LINE,start_pos,count,macd_main) ||
      !iGetArray(handle_iMacd,SIGNAL_LINE,start_pos,count,macd_signal))
     {
      return;
     }

   if(macd_main[3]>=macd_main[2] && macd_main[2]>=macd_main[1])
     {
      macd_buy = false;
      macd_sell = true;
     }

   if(macd_main[3]<=macd_main[2] && macd_main[2]<=macd_main[1])
     {
      macd_buy = true;
      macd_sell = false;
     }
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void CheckFiboSignal(bool &fibo_buy,bool &fibo_sell)
  {
   fibo_buy = false;
   fibo_sell = false;

   MqlRates rates[];
   ArraySetAsSeries(rates,true);

   int start_pos=0,count=3;

   if(CopyRates(_Symbol,0,0,count,rates) < count)
     {
      return;
     }

   double price_1=ObjectGetDouble(0,Inp_Fibo_Object_Name,OBJPROP_PRICE,0);
   double price_2=ObjectGetDouble(0,Inp_Fibo_Object_Name,OBJPROP_PRICE,1);

   if(price_1==0.0 || price_2==0.0)
     {
      return;
     }

   double fibo_range=price_1-price_2;
   fibo_1_000=price_1;
   fibo_0_618=price_2+fibo_range*0.618;
   fibo_0_500=price_2+fibo_range*0.500;
   fibo_0_382=price_2+fibo_range*0.382;
   fibo_0_236=price_2+fibo_range*0.236;
   fibo_0_000=price_2;


   if(rates[1].close  < fibo_0_236)
     {
      fibo_buy = true;
      fibo_sell = false;
     }

   if(rates[1].close > fibo_0_382 && rates[1].close  < fibo_0_500 && Inp_Fibo_TradingRange == small)
     {
      fibo_buy = true;
      fibo_sell = true;
     }

   if(rates[1].close > fibo_0_236 && rates[1].close  < fibo_0_618 && Inp_Fibo_TradingRange == big)
     {
      fibo_buy = true;
      fibo_sell = true;
     }

   if(rates[1].close > fibo_0_618)
     {
      fibo_sell = true;
      fibo_buy = false;
     }

  }



//+------------------------------------------------------------------+
//| Fibo move                                                        |
//+------------------------------------------------------------------+
bool FiboMove()
  {
   MqlRates ArrRatesDay[];
   ArraySetAsSeries(ArrRatesDay,true);
   int copy_rates=CopyRates(m_symbol.Name(),Inp_Fibo_TimeFrame,0,Inp_Fibo_NumBars,ArrRatesDay);
   if(copy_rates==-1 || copy_rates!=Inp_Fibo_NumBars)
      return(false);
//---
   datetime time_1   = D'1970.01.01 00:00:00';     // first point time
   double   price_1  = DBL_MIN;                    // first point price
   datetime time_2   = D'1970.01.01 00:00:00';     // second point time
   double   price_2  = DBL_MAX;                    // second point price
   for(int i=0; i<copy_rates; i++)
     {
      if(ArrRatesDay[i].high>price_1)
        {
         time_1=ArrRatesDay[i].time;
         price_1=ArrRatesDay[i].high;
        }
      if(ArrRatesDay[i].low<price_2)
        {
         time_2=ArrRatesDay[i].time;
         price_2=ArrRatesDay[i].low;
        }
     }
   if(time_1==D'1970.01.01 00:00:00' || time_2==D'1970.01.01 00:00:00')
      return(false);
   if(time_1>time_2)
      m_high_first=false;
//--- create an object
   if(!FiboLevelsCreate(0,Inp_Fibo_Object_Name,0,time_1,price_1,time_2,price_2,Inp_Fibo_Color,
                        Inp_Fibo_Line_Style,Inp_Fibo_Line_Width,Inp_Fibo_Move_Back,Inp_Fibo_Selection,Inp_Fibo_RayLeft,Inp_Fibo_RayRight,Inp_Fibo_Hidden,Inp_Fibo_ZOrder))
     {
      return(false);
     }
//---
   return(true);
  }
//+------------------------------------------------------------------+
//| Create Fibonacci Retracement by the given coordinates            |
//+------------------------------------------------------------------+
bool FiboLevelsCreate(const long            chart_ID=0,        // chart's ID
                      const string          name="FiboLevels", // object name
                      const int             sub_window=0,      // subwindow index
                      datetime              time1=0,           // first point time
                      double                price1=0,          // first point price
                      datetime              time2=0,           // second point time
                      double                price2=0,          // second point price
                      const color           clr=clrRed,        // object color
                      const ENUM_LINE_STYLE style=STYLE_SOLID, // object line style
                      const int             width=1,           // object line width
                      const bool            back=false,        // in the background
                      const bool            selection=true,    // highlight to move
                      const bool            ray_left=false,    // object's continuation to the left
                      const bool            ray_right=false,   // object's continuation to the right
                      const bool            hidden=true,       // hidden in the object list
                      const long            z_order=0)         // priority for mouse click
  {
//--- set anchor points' coordinates if they are not set
   ChangeFiboLevelsEmptyPoints(time1,price1,time2,price2);
   if(ObjectFind(chart_ID,name)<0)
     {
      //--- reset the error value
      ResetLastError();
      //--- Create Fibonacci Retracement by the given coordinates
      if(!ObjectCreate(chart_ID,name,OBJ_FIBO,sub_window,time1,price1,time2,price2))
        {
         Print(__FUNCTION__,
               ": failed to create \"Fibonacci Retracement\"! Error code = ",GetLastError());
         return(false);
        }
      //--- set color
      ObjectSetInteger(chart_ID,name,OBJPROP_COLOR,clr);
      //--- set line style
      ObjectSetInteger(chart_ID,name,OBJPROP_STYLE,style);
      //--- set line width
      ObjectSetInteger(chart_ID,name,OBJPROP_WIDTH,width);
      //--- display in the foreground (false) or background (true)
      ObjectSetInteger(chart_ID,name,OBJPROP_BACK,back);
      //--- enable (true) or disable (false) the mode of highlighting the channel for moving
      //--- when creating a graphical object using ObjectCreate function, the object cannot be
      //--- highlighted and moved by default. Inside this method, selection parameter
      //--- is true by default making it possible to highlight and move the object
      ObjectSetInteger(chart_ID,name,OBJPROP_SELECTABLE,selection);
      ObjectSetInteger(chart_ID,name,OBJPROP_SELECTED,selection);
      //--- enable (true) or disable (false) the mode of continuation of the object's display to the left
      ObjectSetInteger(chart_ID,name,OBJPROP_RAY_LEFT,ray_left);
      //--- enable (true) or disable (false) the mode of continuation of the object's display to the right
      ObjectSetInteger(chart_ID,name,OBJPROP_RAY_RIGHT,ray_right);
      //--- hide (true) or display (false) graphical object name in the object list
      ObjectSetInteger(chart_ID,name,OBJPROP_HIDDEN,hidden);
      //--- set the priority for receiving the event of a mouse click in the chart
      ObjectSetInteger(chart_ID,name,OBJPROP_ZORDER,z_order);
     }
   else
     {
      if(!FiboLevelsPointChange(chart_ID,name,0,time1,price1) || !FiboLevelsPointChange(chart_ID,name,1,time2,price2))
         return(false);
     }
//--- successful execution
   return(true);
  }
//+------------------------------------------------------------------+
//| Set number of levels and their parameters                        |
//+------------------------------------------------------------------+
bool FiboLevelsSet(int             levels,            // number of level lines
                   double          &values[],         // values of level lines
                   color           &colors[],         // color of level lines
                   ENUM_LINE_STYLE &styles[],         // style of level lines
                   int             &widths[],         // width of level lines
                   const long      chart_ID=0,        // chart's ID
                   const string    name="FiboLevels") // object name
  {
//--- check array sizes
   if(levels!=ArraySize(colors) || levels!=ArraySize(styles) ||
      levels!=ArraySize(widths) || levels!=ArraySize(widths))
     {
      Print(__FUNCTION__,": array length does not correspond to the number of levels, error!");
      return(false);
     }
//--- set the number of levels
   ObjectSetInteger(chart_ID,name,OBJPROP_LEVELS,levels);
//--- set the properties of levels in the loop
   for(int i=0; i<levels; i++)
     {
      //--- level value
      ObjectSetDouble(chart_ID,name,OBJPROP_LEVELVALUE,i,values[i]);
      //--- level color
      ObjectSetInteger(chart_ID,name,OBJPROP_LEVELCOLOR,i,colors[i]);
      //--- level style
      ObjectSetInteger(chart_ID,name,OBJPROP_LEVELSTYLE,i,styles[i]);
      //--- level width
      ObjectSetInteger(chart_ID,name,OBJPROP_LEVELWIDTH,i,widths[i]);
      //--- level description
      ObjectSetString(chart_ID,name,OBJPROP_LEVELTEXT,i,DoubleToString(100*values[i],1));
     }
//--- successful execution
   return(true);
  }
//+------------------------------------------------------------------+
//| Move Fibonacci Retracement anchor point                          |
//+------------------------------------------------------------------+
bool FiboLevelsPointChange(const long   chart_ID=0,        // chart's ID
                           const string name="FiboLevels", // object name
                           const int    point_index=0,     // anchor point index
                           datetime     time=0,            // anchor point time coordinate
                           double       price=0)           // anchor point price coordinate
  {
//--- if point position is not set, move it to the current bar having Bid price
   if(!time)
      time=TimeCurrent();
   if(!price)
      price=SymbolInfoDouble(Symbol(),SYMBOL_BID);
//--- reset the error value
   ResetLastError();
//--- move the anchor point
   if(!ObjectMove(chart_ID,name,point_index,time,price))
     {
      Print(__FUNCTION__,
            ": failed to move the anchor point! Error code = ",GetLastError());
      return(false);
     }
//--- successful execution
   return(true);
  }
//+------------------------------------------------------------------+
//| Delete Fibonacci Retracement                                     |
//+------------------------------------------------------------------+
bool FiboLevelsDelete(const long   chart_ID=0,        // chart's ID
                      const string name="FiboLevels") // object name
  {
//--- reset the error value
   ResetLastError();
//--- delete the object
   if(!ObjectDelete(chart_ID,name))
     {
      Print(__FUNCTION__,
            ": failed to delete \"Fibonacci Retracement\"! Error code = ",GetLastError());
      return(false);
     }
//--- successful execution
   return(true);
  }
//+------------------------------------------------------------------+
//| Check the values of Fibonacci Retracement anchor points and set  |
//| default values for empty ones                                    |
//+------------------------------------------------------------------+
void ChangeFiboLevelsEmptyPoints(datetime &time1,double &price1,
                                 datetime &time2,double &price2)
  {
//--- if the second point's time is not set, it will be on the current bar
   if(!time2)
      time2=TimeCurrent();
//--- if the second point's price is not set, it will have Bid value
   if(!price2)
      price2=SymbolInfoDouble(Symbol(),SYMBOL_BID);
//--- if the first point's time is not set, it is located 9 bars left from the second one
   if(!time1)
     {
      //--- array for receiving the open time of the last 10 bars
      datetime temp[10];
      CopyTime(Symbol(),Period(),time2,10,temp);
      //--- set the first point 9 bars left from the second one
      time1=temp[0];
     }
//--- if the first point's price is not set, move it 200 points below the second one
   if(!price1)
      price1=price2-200*SymbolInfoDouble(Symbol(),SYMBOL_POINT);
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
//| Open Buy position                                                |
//+------------------------------------------------------------------+
void OpenBuy(double sl,double tp)
  {
   sl=m_symbol.NormalizePrice(sl);
   tp=m_symbol.NormalizePrice(tp);

   double long_lot=0.0;
   if(IntLotOrRisk==risk)
     {
      long_lot=m_money.CheckOpenLong(m_symbol.Ask(),sl);
      if(InpPrintLog)
        {
         Print("sl=",DoubleToString(sl,m_symbol.Digits()),
               ", CheckOpenLong: ",DoubleToString(long_lot,2),
               ", Balance: ",    DoubleToString(m_account.Balance(),2),
               ", Equity: ",     DoubleToString(m_account.Equity(),2),
               ", FreeMargin: ", DoubleToString(m_account.FreeMargin(),2));
        }
      if(long_lot==0.0)
        {
         if(InpPrintLog)
            Print(__FUNCTION__,", ERROR: method CheckOpenLong returned the value of \"0.0\"");
         return;
        }
     }
   else
     {
      long_lot=InpVolumeLotOrRisk;
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
      if(m_trade.Buy(long_lot,m_symbol.Name(),m_symbol.Ask(),sl,tp,inpComment)) // CTrade::Buy -> "true"
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
   if(IntLotOrRisk==risk)
     {
      short_lot=m_money.CheckOpenShort(m_symbol.Bid(),sl);
      if(InpPrintLog)
        {
         Print("sl=",DoubleToString(sl,m_symbol.Digits()),
               ", CheckOpenLong: ",DoubleToString(short_lot,2),
               ", Balance: ",    DoubleToString(m_account.Balance(),2),
               ", Equity: ",     DoubleToString(m_account.Equity(),2),
               ", FreeMargin: ", DoubleToString(m_account.FreeMargin(),2));
        }
      if(short_lot==0.0)
        {
         if(InpPrintLog)
            Print(__FUNCTION__,", ERROR: method CheckOpenShort returned the value of \"0.0\"");
         return;
        }
     }
   else
     {
      short_lot=InpVolumeLotOrRisk;
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
   Print(free_margin_check);
   Print(margin_check);
   if(free_margin_check>margin_check)
     {
      if(m_trade.Sell(short_lot,m_symbol.Name(),m_symbol.Bid(),sl,tp,inpComment)) // CTrade::Sell -> "true"
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
//|                                                                  |
//+------------------------------------------------------------------+
bool CheckNews()
  {

   string TextDisplay="";

   /*  Check News   */
   bool trade=true;
   string nstxt="";
   int NewsPWR=0;
   datetime nextSigTime=0;
   if(LowNews || MidleNews || HighNews || NFPNews)
     {
      // Investing
      if(CheckInvestingNews(NewsPWR,nextSigTime))
        {
         trade=false;   // news time
        }
     }
   if(trade)
     {
      // No News, Trade enabled
      nstxt="No News";
      if(ObjectFind(0,"NS_Label")!=-1)
        {
         ObjectDelete(0,"NS_Label");
        }

     }
   else  // waiting news , check news power
     {
      color clrT=LowColor;
      if(NewsPWR>3)
        {
         nstxt= "Trading paused NFP news";
         clrT = HighColor;
        }
      else
        {
         if(NewsPWR>2)
           {
            nstxt= "Trading paused high news";
            clrT = HighColor;
           }
         else
           {
            if(NewsPWR>1)
              {
               nstxt= "Trading paused medium news";
               clrT = MidleColor;
              }
            else
              {
               nstxt= "Trading paused low news";
               clrT = LowColor;
              }
           }
        }
      // Make Text Label
      if(nextSigTime>0)
        {
         nstxt=nstxt;
        }
      if(ObjectFind(0,"NS_Label")==-1)
        {
         LabelCreate(nstxt,clrT);
        }
      if(ObjectGetInteger(0,"NS_Label",OBJPROP_COLOR)!=clrT)
        {
         ObjectDelete(0,"NS_Label");
         LabelCreate(nstxt,clrT);
        }
     }
   nstxt="\n"+nstxt;
   /*  End Check News   */

   TextDisplay=TextDisplay+nstxt;

   return trade;

  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
string ReadCBOE()
  {

   string cookie=NULL,headers;
   char post[],result[];
   string TXT="";
   int res;
//--- to work with the server, you must add the URL "https://www.google.com/finance"
//--- the list of allowed URL (Main menu-> Tools-> Settings tab "Advisors"):
   string google_url="http://ec.forexprostools.com/?columns=exc_currency,exc_importance&importance=1,2,3&calType=week&timeZone=15&lang=1";
//---
   ResetLastError();
//--- download html-pages
   int timeout=5000; //--- timeout less than 1,000 (1 sec.) is insufficient at a low speed of the Internet
   res=WebRequest("GET",google_url,cookie,NULL,timeout,post,0,result,headers);
//--- error checking
   if(res==-1)
     {
      Print("WebRequest error, err.code  =",GetLastError());
      MessageBox("You must add the address 'http://ec.forexprostools.com/' in the list of allowed URL tab 'Advisors' "," Error ",MB_ICONINFORMATION);
      //--- You must add the address ' "+ google url"' in the list of allowed URL tab 'Advisors' "," Error "
     }
   else
     {
      TXT=CharArrayToString(result,0,WHOLE_ARRAY,CP_ACP);
     }

   return(TXT);
  }
//+------------------------------------------------------------------+
datetime TimeNewsFunck(int nomf)
  {
   string s=NewsArr[0][nomf];
   string time=StringSubstr(s,0,4)+"."+StringSubstr(s,5,2)+"."+StringSubstr(s,8,2)+" "+StringSubstr(s,11,2)+":"+StringSubstr(s,14,4);
   return((datetime)(StringToTime(time) + GMTplus*3600));
  }
//////////////////////////////////////////////////////////////////////////////////
void UpdateNews()
  {
   string TEXT=ReadCBOE();
   int sh = StringFind(TEXT,"pageStartAt>")+12;
   int sh2= StringFind(TEXT,"</tbody>");
   TEXT=StringSubstr(TEXT,sh,sh2-sh);

   sh=0;
   while(!IsStopped())
     {
      sh = StringFind(TEXT,"event_timestamp",sh)+17;
      sh2= StringFind(TEXT,"onclick",sh)-2;
      if(sh<17 || sh2<0)
         break;
      NewsArr[0][NomNews]=StringSubstr(TEXT,sh,sh2-sh);

      sh = StringFind(TEXT,"flagCur",sh)+10;
      sh2= sh+3;
      if(sh<10 || sh2<3)
         break;
      NewsArr[1][NomNews]=StringSubstr(TEXT,sh,sh2-sh);
      if(OnlySymbolNews && StringFind(ValStr,NewsArr[1][NomNews])<0)
         continue;

      sh = StringFind(TEXT,"title",sh)+7;
      sh2= StringFind(TEXT,"Volatility",sh)-1;
      if(sh<7 || sh2<0)
         break;
      NewsArr[2][NomNews]=StringSubstr(TEXT,sh,sh2-sh);
      if(StringFind(NewsArr[2][NomNews],"High")>=0 && !HighNews)
         continue;
      if(StringFind(NewsArr[2][NomNews],"Moderate")>=0 && !MidleNews)
         continue;
      if(StringFind(NewsArr[2][NomNews],"Low")>=0 && !LowNews)
         continue;

      sh=StringFind(TEXT,"left event",sh)+12;
      int sh1=StringFind(TEXT,"Speaks",sh);
      sh2=StringFind(TEXT,"<",sh);
      if(sh<12 || sh2<0)
         break;
      if(sh1<0 || sh1>sh2)
         NewsArr[3][NomNews]=StringSubstr(TEXT,sh,sh2-sh);
      else
         NewsArr[3][NomNews]=StringSubstr(TEXT,sh,sh1-sh);

      NomNews++;
      if(NomNews==300)
         break;
     }
  }
//+------------------------------------------------------------------+
int del(string name) // Спец. ф-ия deinit()
  {
   for(int n=ObjectsTotal(0)-1; n>=0; n--)
     {
      string Obj_Name=ObjectName(0,n);
      if(StringFind(Obj_Name,name,0)!=-1)
        {
         ObjectDelete(0,Obj_Name);
        }
     }
   return 0;                                      // Выход из deinit()
  }
//+------------------------------------------------------------------+
bool CheckInvestingNews(int &pwr,datetime &mintime)
  {

   bool CheckNews=false;
   pwr=0;
   int maxPower=0;
   if(LowNews || MidleNews || HighNews || NFPNews)
     {
      if(TimeCurrent()-LastUpd>=Upd)
        {
         Print("Investing.com News Loading...");
         UpdateNews();
         LastUpd=TimeCurrent();
         Comment("");
        }
      ChartRedraw(0);
      //---Draw a line on the chart news--------------------------------------------
      if(DrawNewsLines)
        {
         for(int i=0; i<NomNews; i++)
           {
            string Name=StringSubstr("NS_"+TimeToString(TimeNewsFunck(i),TIME_MINUTES)+"_"+NewsArr[1][i]+"_"+NewsArr[3][i],0,63);
            if(NewsArr[3][i]!="")
               if(ObjectFind(0,Name)==0)
                  continue;
            if(OnlySymbolNews && StringFind(ValStr,NewsArr[1][i])<0)
               continue;
            if(TimeNewsFunck(i)<TimeCurrent() && Next)
               continue;

            color clrf=clrNONE;
            if(HighNews && StringFind(NewsArr[2][i],"High")>=0)
               clrf=HighColor;
            if(MidleNews && StringFind(NewsArr[2][i],"Moderate")>=0)
               clrf=MidleColor;
            if(LowNews && StringFind(NewsArr[2][i],"Low")>=0)
               clrf=LowColor;

            if(clrf==clrNONE)
               continue;

            if(NewsArr[3][i]!="")
              {
               ObjectCreate(0,Name,OBJ_VLINE,0,TimeNewsFunck(i),0);
               ObjectSetInteger(0,Name,OBJPROP_COLOR,clrf);
               ObjectSetInteger(0,Name,OBJPROP_STYLE,LineStyle);
               ObjectSetInteger(0,Name,OBJPROP_WIDTH,LineWidth);
               // ObjectSetInteger(0,Name,OBJPROP_BACK,fa);
              }
           }
        }
      //---------------event Processing------------------------------------
      int ii;
      CheckNews=false;
      for(ii=0; ii<NomNews; ii++)
        {
         int power=0;
         if(HighNews && StringFind(NewsArr[2][ii],"High")>=0)
           {
            power=3;
            MinBefore=HighIndentBefore;
            MinAfter=HighIndentAfter;
           }
         if(MidleNews && StringFind(NewsArr[2][ii],"Moderate")>=0)
           {
            power=2;
            MinBefore=MidleIndentBefore;
            MinAfter=MidleIndentAfter;
           }
         if(LowNews && StringFind(NewsArr[2][ii],"Low")>=0)
           {
            power=1;
            MinBefore=LowIndentBefore;
            MinAfter=LowIndentAfter;
           }
         if(NFPNews && StringFind(NewsArr[3][ii],"Nonfarm Payrolls")>=0)
           {
            power=4;
            MinBefore=NFPIndentBefore;
            MinAfter=NFPIndentAfter;
           }
         if(power==0)
            continue;

         if(TimeCurrent()+MinBefore*60>TimeNewsFunck(ii) && TimeCurrent()-MinAfter*60<TimeNewsFunck(ii) && (!OnlySymbolNews || (OnlySymbolNews && StringFind(ValStr,NewsArr[1][ii])>=0)))
           {
            if(power>maxPower)
              {
               maxPower=power;
               mintime=TimeNewsFunck(ii);
              }
           }
         else
           {
            CheckNews=false;
           }
        }
      if(maxPower>0)
        {
         CheckNews=true;
        }
     }
   pwr=maxPower;
   return(CheckNews);
  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
bool LabelCreate(const string text="Label",const color clr=clrRed)
  {
   long x_distance;
   long y_distance;
   long chart_ID=0;
   string name="NS_Label";
   int sub_window=0;
   ENUM_BASE_CORNER  corner=CORNER_LEFT_UPPER;
   string font="Arial";
   int font_size=28;
   double angle=0.0;
   ENUM_ANCHOR_POINT anchor=ANCHOR_LEFT_UPPER;
   bool back=false;
   bool selection=false;
   bool hidden=true;
   long z_order=0;
//--- определим размеры окна
   ChartGetInteger(0,CHART_WIDTH_IN_PIXELS,0,x_distance);
   ChartGetInteger(0,CHART_HEIGHT_IN_PIXELS,0,y_distance);
   ResetLastError();
   if(!ObjectCreate(chart_ID,name,OBJ_LABEL,sub_window,0,0))
     {
      Print(__FUNCTION__,
            ": failed to create text label! Error code = ",GetLastError());
      return(false);
     }
   ObjectSetInteger(chart_ID,name,OBJPROP_XDISTANCE,(int)(x_distance/2.7));
   ObjectSetInteger(chart_ID,name,OBJPROP_YDISTANCE,(int)(y_distance/1.5));
   ObjectSetInteger(chart_ID,name,OBJPROP_CORNER,corner);
   ObjectSetString(chart_ID,name,OBJPROP_TEXT,text);
   ObjectSetString(chart_ID,name,OBJPROP_FONT,font);
   ObjectSetInteger(chart_ID,name,OBJPROP_FONTSIZE,font_size);
   ObjectSetDouble(chart_ID,name,OBJPROP_ANGLE,angle);
   ObjectSetInteger(chart_ID,name,OBJPROP_ANCHOR,anchor);
   ObjectSetInteger(chart_ID,name,OBJPROP_COLOR,clr);
   ObjectSetInteger(chart_ID,name,OBJPROP_BACK,back);
   ObjectSetInteger(chart_ID,name,OBJPROP_SELECTABLE,selection);
   ObjectSetInteger(chart_ID,name,OBJPROP_SELECTED,selection);
   ObjectSetInteger(chart_ID,name,OBJPROP_HIDDEN,hidden);
   ObjectSetInteger(chart_ID,name,OBJPROP_ZORDER,z_order);
   return(true);
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
int TimeYear(datetime date)
  {
   MqlDateTime tm;
   TimeToStruct(date,tm);
   return(tm.year);
  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
int TimeDay(datetime date)
  {
   MqlDateTime tm;
   TimeToStruct(date,tm);
   return(tm.day);
  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
int TimeMonth(datetime date)
  {
   MqlDateTime tm;
   TimeToStruct(date,tm);
   return(tm.mon);
  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
int TimeDayOfWeek(datetime date)
  {
   MqlDateTime tm;
   TimeToStruct(date,tm);
   return(tm.day_of_week);
  }
//+------------------------------------------------------------------+
//+------------------------------------------------------------------+

//+------------------------------------------------------------------+
