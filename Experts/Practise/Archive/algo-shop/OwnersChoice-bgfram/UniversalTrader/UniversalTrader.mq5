//+------------------------------------------------------------------+
//|                                              UniversalTrader.mq5 |
//|                                Copyright 2020, Algotrading.co.za |
//|                                     http://www.algotrading.co.za |
//+------------------------------------------------------------------+

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
//+------------------------------------------------------------------+
//| Enum Lor or Risk                                                 |
//+------------------------------------------------------------------+
enum ENUM_MA_TRADE_TYPE
  {
   cross=0,   // MA crossover
   trend=1,  //  MA Trend
  };

enum ENUM_STOCH_TRADE_TYPE
  {
   stochretracelevels=0,   // Retrace back from levels
   stochexceedlevels=1,  //  Exceed Levels
  };

enum ENUM_RSI_TRADE_TYPE
  {
   rsiretracelevels=0,   // Retrace back from levels
   rsiexceedlevels=1,  //  Exceed Levels
  };


enum ENUM_MFI_TRADE_TYPE
  {
   mfiretracelevels=0,   // Retrace back from levels
   mfiexceedlevels=1,  //  Exceed Levels
  };

enum ENUM_BOL_TRADE_TYPE
  {
   retraceBands=0,   // Cross back from upper/lower band
   exceedBands=1,  //  Above/Below bands
  };

enum ENUM_MACD_TRADE_TYPE
  {
   macdcross=0,   // signal line crosses main line
   macdtrend=1,  //  macd trend
  };


//--- input parameters
input group  "Main Settings"
input string   inpComment           = "Universal EA"; //Trade Comment
input ulong    m_magic=1152020141;                 // magic number
input bool     InpPrintLog          = false;     // Print log
input uchar    InpMaxBuyPositions   = 2;         // Max Buy Positions
input uchar    InpMaxSellPositions  = 2;         // Max Sell Positions


input group  "Money Management"
input ushort   InpStopLoss       = 100;       // Stop Loss, in pips
input ushort   InpTakeProfit     = 500;       // Take Profit, in pips
input bool     InpUseTrailing    = true;     // Use Trailing stop
input ushort   InpTrailingStop   = 10;       // Trailing Stop, in pips
input ushort   InpTrailingStep   = 5;        // Trailing Step, in pips
input double   InpRisk= 5.0;       // Risk in percentage of free margin

input group  "Moving Average settings"
input bool                 InpTradeMovingAverages    = false;     // Trade moving averages
input ENUM_MA_TRADE_TYPE InpEnumMATradeType=cross;    // MA Trade Type (MA Trend must be used with another indicator)
input int                  Inp_MA_Slow_ma_period=200;// MA Slow averaging period
input int                  Inp_MA_Slow_ma_shift=0;// MA Slow horizontal shift
input ENUM_MA_METHOD       Inp_MA_Slow_ma_method=MODE_EMA;// MA Slow smoothing type
input ENUM_APPLIED_PRICE   Inp_MA_Slow_applied_price=PRICE_CLOSE;// MA Slow type of price
input int                  Inp_MA_Fast_ma_period=50;// MA Fast averaging period
input int                  Inp_MA_Fast_ma_shift=0;// MA Fast horizontal shift
input ENUM_MA_METHOD       Inp_MA_Fast_ma_method=MODE_EMA;// MA Fast smoothing type
input ENUM_APPLIED_PRICE   Inp_MA_Fast_applied_price=PRICE_CLOSE;// MA fast type of price
input ENUM_TIMEFRAMES      Inp_MA_TF =PERIOD_CURRENT;    // MA Timeframe

input group  "Stochastic Settings"
input bool                 InpTradeStochastics    = false;     // Trade stochastics
input bool                 InpReversStoch          = false;     // Reverse Signal
input ENUM_STOCH_TRADE_TYPE InpEnumStochTradeType = stochexceedlevels;    // Stochastic Trade Type
input int               InpKperiod        = 5;              // Stochastic: K-period (number of bars for calculations)
input int               InpDperiod        = 3;              // Stochastic: D-period (period of first smoothing)
input int               InpSlowing        = 3;              // Stochastic: final smoothing
input ENUM_MA_METHOD    InpMa_method      = MODE_SMA;       // Stochastic: type of smoothing
input ENUM_STO_PRICE    InpPrice_field    = STO_LOWHIGH;    // Stochastic: stochastic calculation method
input double            InpStochLevelUP        = 80;             // Stochastic signal (level UP)
input double            InpStochLevelDOWN      = 20;             // Stochastic signal (level DOWN)
input ENUM_TIMEFRAMES   Inp_Stoch_TF = PERIOD_CURRENT;           // Stochastics time frame

input group  "RSI Settings"
input bool                 InpTradeRSI   = false;     // Trade RSI
input bool                 InpReversRSI          = false;     // Reverse Signal
input ENUM_RSI_TRADE_TYPE InpEnumRSITradeType = rsiexceedlevels;    // RSI Trade Type
input int               Inp_RSI_ma_period    = 14;          // RSI: averaging period
input ENUM_APPLIED_PRICE Inp_RSI_applied_price=PRICE_CLOSE; // RSI: type of price
input double            InpRSILevelUP        = 70;          // RSI Level UP
input double            InpRSILevelDOWN      = 30;          // RSI Level DOWN
input ENUM_TIMEFRAMES   Inp_RSI_TF = PERIOD_CURRENT;           // RSI time frame

input group  "Williams Percent Range Settings"
input bool                 InpTradeWPR  = false;              // Trade WPR
input int                  Inp_WPR_ma_period    = 20;          // WPR: averaging period
input int                  Inp_WMR_Buy_Level             = -80;             // WPR: Buy Level
input int                  Inp_WMR_Sell_Level            = -20;             // WPR: Sell level
input ENUM_TIMEFRAMES      Inp_WPR_TF = PERIOD_CURRENT;           // WPR: time frame

input group  "Bollinger Settings"
input bool                 InpTradeBollinger    = false;     // Trade Bollinger Bands
input bool                 InpReversBol         = false;     // Reverse Signal
input ENUM_BOL_TRADE_TYPE InpEnumBolTradeType = exceedBands;    // Bollinger Trade Type
input int               Inp_Bollinger_Ma_Period        = 20;    // Bollinger: Averaging period
input int               Inp_Bollinger_ma_shift=0;             // Bollinger Shift
input double            Inp_Bollinger_Deviation=2;               // Bollinger Deviation
input ENUM_APPLIED_PRICE   Inp_Bollinger_applied_price=PRICE_CLOSE;// Bollinger type of price
input ENUM_TIMEFRAMES   Inp_Bollinger_TimeFrame = PERIOD_CURRENT;           // Bollinger time frame

input group  "Fractal Settings"
input bool   InpTradeFractals    = false;     // Trade Fractals
input int               Inp_Fractals_shift=2;             // Fractals Shift
input ENUM_TIMEFRAMES   Inp_Fractals_TimeFrame = PERIOD_CURRENT;           // Fractals time frame

input group  "CCI Settings"
input bool   InpTradeCCI    = false;     // Trade CCI
input bool                 InpReversCCI          = false;     // Reverse Signal
input int                  Inp_CCI_ma_period             = 12;             // CCI: averaging period
input ENUM_APPLIED_PRICE   Inp_CCI_applied_price         = PRICE_TYPICAL;  // CCI: type of price
input int                  Inp_CCI_Up_Level              = 100;             // CCI Up level
input int                  Inp_CCI_Down_Level            = -100;            // CCI Down level
input int                  Inp_CCI_Current_Bar           = 1;              // CCI Current Bar
input ENUM_TIMEFRAMES      Inp_CCI_TimeFrame             = PERIOD_CURRENT;     // CCI: timeframe

input group  "Aligator Settings - Must be used with another Indicator"
input bool     InpTradeAlligator    = false;     // Trade Alligator
input int      Inp_Alligator_jaw_period   = 13;    // Alligator: period for the calculation of jaws
input int      Inp_Alligator_jaw_shift    = 8;     // Alligator: horizontal shift of jaws
input int      Inp_Alligator_teeth_period = 8;     // Alligator: period for the calculation of teeth
input int      Inp_Alligator_teeth_shift  = 5;     // Alligator: horizontal shift of teeth
input int      Inp_Alligator_lips_period  = 5;     // Alligator: period for the calculation of lips
input int      Inp_Alligator_lips_shift   = 3;     // Alligator: horizontal shift of lips
input ENUM_MA_METHOD    Inp_Alligator_Ma_method      = MODE_SMA;       // Alligator: type of smoothing
input ENUM_APPLIED_PRICE   Inp_Alligator_applied_price         = PRICE_TYPICAL;  // Alligator: type of price
input ENUM_TIMEFRAMES   Inp_Alligator_TimeFrame = PERIOD_CURRENT;           // Alligator time frame
input ushort   InpMouthSize   = 2;        // Mouth size, Difference between jaw and lips (In Pips)

input group  "MACD Settings"
input bool     InpTradeMACD    = false;     // Trade MACD
input ENUM_MACD_TRADE_TYPE InpEnumMACDTradeType = macdcross;    // MACD Trade Type (MACD Trend must be used with another indicator)
input int      Inp_MACD_fast_ema_period   = 12;    // MACD: period for Fast average calculation
input int      Inp_MACD_slow_ema_period   = 26;    // MACD: period for Slow average calculation
input int      Inp_MACD_signal_period     = 9;    // MACD: period for their difference averaging
input ENUM_APPLIED_PRICE   Inp_MACD_applied_price     = PRICE_CLOSE; // MACD: type of price
input ENUM_TIMEFRAMES   Inp_MACD_TimeFrame = PERIOD_CURRENT;  // MACD time frame

input group  "ADX Settings - Must be used with another Indicator"
input bool     InpTradeADX    = false;     // Trade ADX
input int      Inp_ADX_adx_period= 14;        // ADX: averaging period
input int      InpADXMinimum     = 25;       // ADX: minimum
input ENUM_TIMEFRAMES   Inp_ADX_TimeFrame = PERIOD_CURRENT;  // ADX time frame

input group  "MFI Settings"
input bool             InpTradeMFI   = false;     // Trade MFI
input bool               InpReversMFI          = false;     // Reverse Signal
input ENUM_MFI_TRADE_TYPE InpEnumMFITradeType = mfiexceedlevels;    // MFI Trade Type
input int               Inp_MFI_ma_period    = 14;          // MFI: averaging period
input double            InpMFILevelUP        = 80;          // MFI Level UP
input double            InpMFILevelDOWN      = 20;          // MFI Level DOWN
input ENUM_APPLIED_VOLUME  Inp_MFI_applied_volume=VOLUME_TICK;   // MFI type of volume
input ENUM_TIMEFRAMES   Inp_MFI_TF = PERIOD_CURRENT;           // MFI time frame


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
input bool     LowNews             = true; //Pause trading on low news
input int      LowIndentBefore     = 15; //Pause before low news (In Minutes)
input int      LowIndentAfter      = 15; //Pause after low news (In Minutes)
input bool     MidleNews           = true; //Pause trading on medium news
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
input int  GMTplus=3;     // Your Time Zone, GMT (for news)

//---
ulong  m_slippage=10;                        // slippage
double ExtStopLoss      = 0.0;
double ExtTakeProfit    = 0.0;
double ExtTrailingStop  = 0.0;
double ExtTrailingStep  = 0.0;
double ExtMouthSize  = 0.0;
string ExtComment = "";

double m_adjusted_point;                     // point value adjusted for 3 or 5 points

bool           bln_delete_all=false;
datetime       dt_last_delete=0;

int    handle_iMA_Slow;
int    handle_iMA_Fast;
int    handle_iRSI;
int    handle_iWPR;
int    handle_iStoch;
int    handle_iFractals;
int    handle_iAlligator;
int    handle_iBollinger;
int    handle_iMacd;
int    handle_iCCI;
int    handle_iADX;
int    handle_iMFI;

double fractals_up         = EMPTY_VALUE;
double fractals_down       = EMPTY_VALUE;
int    fractals_up_number  = -1;
int    fractals_down_number= -1;

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
   ExtMouthSize   = InpMouthSize    * m_adjusted_point;
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


   string v1=StringSubstr(_Symbol,0,3);
   string v2=StringSubstr(_Symbol,3,3);
   ValStr=v1+","+v2;

   if(InpTradeMovingAverages)
     {
      handle_iMA_Slow=iMA(m_symbol.Name(),Inp_MA_TF,Inp_MA_Slow_ma_period,Inp_MA_Slow_ma_shift,
                          Inp_MA_Slow_ma_method,handle_iMA_Slow);

      if(handle_iMA_Slow==INVALID_HANDLE)
        {
         PrintFormat("Failed to create handle of the iMA (\"Slow\") indicator for the symbol %s/%s, error code %d",
                     m_symbol.Name(),
                     EnumToString(Inp_MA_TF),
                     GetLastError());
         return(INIT_FAILED);
        }


      handle_iMA_Fast=iMA(m_symbol.Name(),Inp_MA_TF,Inp_MA_Fast_ma_period,Inp_MA_Fast_ma_shift,
                          Inp_MA_Fast_ma_method,handle_iMA_Fast);
      if(handle_iMA_Fast==INVALID_HANDLE)
        {
         PrintFormat("Failed to create handle of the iMA (\"Fast\") indicator for the symbol %s/%s, error code %d",
                     m_symbol.Name(),
                     EnumToString(Inp_MA_TF),
                     GetLastError());
         return(INIT_FAILED);
        }
     }

   if(InpTradeStochastics)
     {
      handle_iStoch=iStochastic(m_symbol.Name(),Inp_Stoch_TF,
                                InpKperiod,InpDperiod,InpSlowing,
                                InpMa_method,InpPrice_field);

      if(handle_iStoch==INVALID_HANDLE)
        {
         PrintFormat("Failed to create handle of the iStochastic indicator for the symbol %s/%s, error code %d",
                     m_symbol.Name(),
                     EnumToString(Inp_Stoch_TF),
                     GetLastError());
         return(INIT_FAILED);
        }
     }

   if(InpTradeBollinger)
     {
      handle_iBollinger=iBands(m_symbol.Name(),Inp_Bollinger_TimeFrame,Inp_Bollinger_Ma_Period,Inp_Bollinger_ma_shift,Inp_Bollinger_Deviation,Inp_Bollinger_applied_price);
      if(handle_iBollinger==INVALID_HANDLE)
        {
         PrintFormat("Failed to create handle of the iBands indicator for the symbol %s/%s, error code %d",
                     m_symbol.Name(),
                     EnumToString(Inp_Bollinger_TimeFrame),
                     GetLastError());
         return(INIT_FAILED);
        }
     }

   if(InpTradeRSI)
     {
      handle_iRSI=iRSI(m_symbol.Name(),Inp_RSI_TF,Inp_RSI_ma_period,Inp_RSI_applied_price);

      if(handle_iRSI==INVALID_HANDLE)
        {
         PrintFormat("Failed to create handle of the iRSI indicator for the symbol %s/%s, error code %d",
                     m_symbol.Name(),
                     EnumToString(Inp_RSI_TF),
                     GetLastError());
         return(INIT_FAILED);
        }
     }

   if(InpTradeWPR)
     {
      handle_iWPR=iWPR(m_symbol.Name(),Inp_WPR_TF,Inp_WPR_ma_period);

      if(handle_iWPR==INVALID_HANDLE)
        {
         PrintFormat("Failed to create handle of the iWPR indicator for the symbol %s/%s, error code %d",
                     m_symbol.Name(),
                     EnumToString(Inp_WPR_TF),
                     GetLastError());
         return(INIT_FAILED);
        }
     }

   if(InpTradeFractals)
     {
      handle_iFractals=iFractals(m_symbol.Name(),Inp_Fractals_TimeFrame);
      if(handle_iFractals==INVALID_HANDLE)
        {
         PrintFormat("Failed to create handle of the iFractals indicator for the symbol %s/%s, error code %d",
                     m_symbol.Name(),
                     EnumToString(Inp_Fractals_TimeFrame),
                     GetLastError());
         return(INIT_FAILED);
        }
     }

   if(InpTradeAlligator)
     {
      handle_iAlligator=iAlligator(m_symbol.Name(),Inp_Alligator_TimeFrame,Inp_Alligator_jaw_period,Inp_Alligator_jaw_shift,
                                   Inp_Alligator_teeth_period,Inp_Alligator_teeth_shift,
                                   Inp_Alligator_lips_period,Inp_Alligator_lips_shift,Inp_Alligator_Ma_method,Inp_Alligator_applied_price);
      if(handle_iAlligator==INVALID_HANDLE)
        {
         PrintFormat("Failed to create handle of the iAlligator indicator for the symbol %s/%s, error code %d",
                     m_symbol.Name(),
                     EnumToString(Inp_Alligator_TimeFrame),
                     GetLastError());
         return(INIT_FAILED);
        }
     }

   if(InpTradeMACD)
     {
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
     }

   if(InpTradeCCI)
     {
      handle_iCCI=iCCI(m_symbol.Name(),Inp_CCI_TimeFrame,Inp_CCI_ma_period,Inp_CCI_applied_price);
      if(handle_iCCI==INVALID_HANDLE)
        {
         PrintFormat("Failed to create handle of the iCCI indicator for the symbol %s/%s, error code %d",
                     m_symbol.Name(),
                     EnumToString(Inp_CCI_TimeFrame),
                     GetLastError());
         return(INIT_FAILED);
        }

     }

   if(InpTradeADX)
     {
      handle_iADX=iADX(m_symbol.Name(),Inp_ADX_TimeFrame,Inp_ADX_adx_period);
      if(handle_iADX==INVALID_HANDLE)
        {
         PrintFormat("Failed to create handle of the iADX indicator for the symbol %s/%s, error code %d",
                     m_symbol.Name(),
                     EnumToString(Inp_ADX_TimeFrame),
                     GetLastError());
         return(INIT_FAILED);
        }

     }

   if(InpTradeMFI)
     {
      handle_iMFI=iMFI(m_symbol.Name(),Inp_MFI_TF,Inp_MFI_ma_period,Inp_MFI_applied_volume);
      if(handle_iMFI==INVALID_HANDLE)
        {
         PrintFormat("Failed to create handle of the iMFI indicator for the symbol %s/%s, error code %d",
                     m_symbol.Name(),
                     EnumToString(Inp_MFI_TF),
                     GetLastError());
         return(INIT_FAILED);
        }

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

   Comment("");
   del("NS_");

   IndicatorRelease(handle_iMA_Slow);
   IndicatorRelease(handle_iMA_Fast);
   IndicatorRelease(handle_iRSI);
   IndicatorRelease(handle_iWPR);
   IndicatorRelease(handle_iAlligator);
   IndicatorRelease(handle_iBollinger);
   IndicatorRelease(handle_iCCI);
   IndicatorRelease(handle_iFractals);
   IndicatorRelease(handle_iStoch);
   IndicatorRelease(handle_iMacd);
   IndicatorRelease(handle_iADX);
   IndicatorRelease(handle_iMFI);

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

   bool ma_buy = true;
   bool ma_sell = true;
   bool stoch_buy = true;
   bool stoch_sell = true;
   bool rsi_buy = true;
   bool rsi_sell = true;
   bool wpr_buy = true;
   bool wpr_sell = true;
   bool macd_buy = true;
   bool macd_sell = true;
   bool cci_buy = true;
   bool cci_sell = true;
   bool fractals_buy = true;
   bool fractals_sell = true;
   bool bollinger_buy = true;
   bool bollinger_sell = true;
   bool alligator_buy = true;
   bool alligator_sell = true;
   bool mfi_buy = true;
   bool mfi_sell = true;
   bool adx_buy = true;
   bool adx_sell = true;
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

   MqlRates rates[];
   ArraySetAsSeries(rates,true);

   int start_pos=0,count=3;

   CalculateAllPositions(count_buys,volume_buys,volume_biggest_buys,
                         count_sells,volume_sells,volume_biggest_sells);

   if(CopyRates(_Symbol,0,0,count,rates) < count)
     {
      return;
     }

   if(InpTradeAlligator)
     {
      CheckAlligatorSignal(alligator_buy,alligator_sell);
     }

   if(InpTradeBollinger)
     {
      CheckBollingerSignal(bollinger_buy,bollinger_sell);

     }

   if(InpTradeCCI)
     {
      CheckCCISignal(cci_buy,cci_sell);
     }

   if(InpTradeFractals)
     {
      CheckFractalsSignal(fractals_buy,fractals_sell);
     }

   if(InpTradeMACD)
     {
      CheckMacdSignal(macd_buy,macd_sell);
     }

   if(InpTradeMovingAverages)
     {
      CheckMASignal(ma_buy,ma_sell);
     }

   if(InpTradeRSI)
     {
      CheckRSISignal(rsi_buy,rsi_sell);
     }

   if(InpTradeWPR)
     {
      CheckWPRSignal(wpr_buy,wpr_sell);
     }

   if(InpTradeStochastics)
     {
      CheckStochSignal(stoch_buy,stoch_sell);
     }

   if(InpTradeADX)
     {
      CheckADXSignal(adx_buy,adx_sell);
     }

   if(InpTradeMFI)
     {
      CheckMFISignal(mfi_buy,mfi_sell);
     }



   good_buy = ma_buy && rsi_buy && wpr_buy && stoch_buy && alligator_buy && fractals_buy && bollinger_buy && macd_buy && cci_buy && adx_buy && mfi_buy;
   good_sell = ma_sell && rsi_sell && wpr_sell && stoch_sell && alligator_sell && fractals_sell && bollinger_sell && macd_sell && cci_sell && adx_sell && mfi_sell;

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
void CheckADXSignal(bool &adx_buy,bool &adx_sell)
  {

   adx_buy = false;
   adx_sell = false;

   double adx_main[];
   ArraySetAsSeries(adx_main,true);
   int start_pos=0,count=3;

   if(!iGetArray(handle_iADX,MAIN_LINE,start_pos,count,adx_main))
     {
      return;
     }

   if((int)adx_main[1]>InpADXMinimum)
     {
      adx_buy = true;
      adx_sell = true;
     }
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void CheckMFISignal(bool &mfi_buy,bool &mfi_sell)
  {
   mfi_buy = false;
   mfi_sell = false;

   double mfi[];
   ArraySetAsSeries(mfi,true);

   int start_pos=0,count=3;

   if(!iGetArray(handle_iMFI,0,start_pos,count,mfi))
     {
      return;
     }

   if(InpEnumMFITradeType == mfiexceedlevels)
     {
      if(mfi[1] > InpMFILevelUP)
        {
         if(!InpReversMFI)
           {
            mfi_buy = false;
            mfi_sell = true;
           }
         else
           {
            mfi_buy = true;
            mfi_sell = false;
           }
        }
      if(mfi[1] < InpMFILevelDOWN)
        {

         if(!InpReversMFI)
           {
            mfi_buy = true;
            mfi_sell = false;
           }
         else
           {
            mfi_buy = false;
            mfi_sell = true;
           }
        }
     }
   else
     {
      if(mfi[2] > InpMFILevelUP && mfi[1] < InpMFILevelUP)
        {
         if(!InpReversMFI)
           {
            mfi_buy = false;
            mfi_sell = true;
           }
         else
           {
            mfi_buy = true;
            mfi_sell = false;
           }
        }
      if(mfi[2]< InpMFILevelDOWN && mfi[1] > InpMFILevelDOWN)
        {
         if(!InpReversMFI)
           {
            mfi_buy = true;
            mfi_sell = false;
           }
         else
           {
            mfi_buy = false;
            mfi_sell = true;
           }
        }

     }
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void CheckMASignal(bool &ma_buy,bool &ma_sell)
  {
   ma_buy = false;
   ma_sell = false;

   double ma_slow[], ma_fast[];
   ArraySetAsSeries(ma_slow,true);
   ArraySetAsSeries(ma_fast,true);

   int start_pos=0,count=3;

   if(!iGetArray(handle_iMA_Slow,0,start_pos,count,ma_slow)||
      !iGetArray(handle_iMA_Fast,0,start_pos,count,ma_fast))
     {
      return;
     }

   if(InpEnumMATradeType == trend)
     {
      if(ma_fast[1] < ma_slow[1])
        {
         ma_buy = false;
         ma_sell = true;
        }
      if(ma_fast[1] > ma_slow[1])
        {
         ma_buy = true;
         ma_sell = false;
        }
     }
   else
     {
      if(ma_fast[2] > ma_slow[2] && ma_fast[1] < ma_slow[1])
        {
         ma_buy = false;
         ma_sell = true;
        }
      if(ma_fast[2] < ma_slow[2] && ma_fast[1] > ma_slow[1])
        {
         ma_buy = true;
         ma_sell = false;
        }

     }
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void CheckRSISignal(bool &rsi_buy,bool &rsi_sell)
  {
   rsi_buy = false;
   rsi_sell = false;

   double rsi[];
   ArraySetAsSeries(rsi,true);

   int start_pos=0,count=3;

   if(!iGetArray(handle_iRSI,0,start_pos,count,rsi))
     {
      return;
     }

   if(InpEnumRSITradeType == rsiexceedlevels)
     {
      if(rsi[1] > InpRSILevelUP)
        {
         if(!InpReversRSI)
           {
            rsi_buy = false;
            rsi_sell = true;
           }
         else
           {
            rsi_buy = true;
            rsi_sell = false;
           }
        }
      if(rsi[1] < InpRSILevelDOWN)
        {
         if(!InpReversRSI)
           {
            rsi_buy = true;
            rsi_sell = false;
           }
         else
           {
            rsi_buy = false;
            rsi_sell = true;
           }
        }
     }
   else
     {
      if(rsi[2] > InpRSILevelUP && rsi[1] < InpRSILevelUP)
        {
         if(!InpReversRSI)
           {
            rsi_buy = false;
            rsi_sell = true;
           }
         else
           {
            rsi_buy = true;
            rsi_sell = false;
           }
        }
      if(rsi[2]< InpRSILevelDOWN && rsi[1] > InpRSILevelDOWN)
        {
         if(!InpReversRSI)
           {
            rsi_buy = true;
            rsi_sell = false;
           }
         else
           {
            rsi_buy = false;
            rsi_sell = true;
           }
        }

     }

  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void CheckWPRSignal(bool &wpr_buy,bool &wpr_sell)
  {
   wpr_buy = false;
   wpr_sell = false;

   double wpr[];
   ArraySetAsSeries(wpr,true);

   int start_pos=0,count=3;

   if(!iGetArray(handle_iWPR,0,start_pos,count,wpr))
     {
      return;
     }


   if(wpr[1] > Inp_WMR_Sell_Level)
     {
      wpr_buy = false;
      wpr_sell = true;
     }

   if(wpr[1] < Inp_WMR_Buy_Level)
     {
      wpr_buy = true;
      wpr_sell = false;
     }

  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void CheckStochSignal(bool &stoch_buy,bool &stoch_sell)
  {
   stoch_buy = false;
   stoch_sell = false;

   double stoch[];
   ArraySetAsSeries(stoch,true);

   int start_pos=0,count=3;

   if(!iGetArray(handle_iStoch,0,start_pos,count,stoch))
     {
      return;
     }

   if(InpEnumStochTradeType == stochexceedlevels)
     {
      if(stoch[1] > InpStochLevelUP)
        {
         if(!InpReversStoch)
           {
            stoch_buy = false;
            stoch_sell = true;
           }
         else
           {
            stoch_buy = true;
            stoch_sell = false;
           }
        }
      if(stoch[1] < InpStochLevelDOWN)
        {
         if(!InpReversStoch)
           {
            stoch_buy = true;
            stoch_sell = false;
           }
         else
           {
            stoch_buy = false;
            stoch_sell = true;
           }
        }
     }
   else
     {
      if(stoch[2] > InpStochLevelUP && stoch[1] < InpStochLevelUP)
        {
         if(!InpReversStoch)
           {
            stoch_buy = false;
            stoch_sell = true;
           }
         else
           {
            stoch_buy = true;
            stoch_sell = false;
           }
        }
      if(stoch[2]< InpStochLevelDOWN && stoch[1] > InpStochLevelDOWN)
        {
         if(!InpReversStoch)
           {
            stoch_buy = true;
            stoch_sell = false;
           }
         else
           {
            stoch_buy = false;
            stoch_sell = true;
           }
        }

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
   if(InpEnumMACDTradeType == macdcross)
     {
      if(macd_main[1]<macd_signal[1] && macd_main[2]>macd_signal[2])
        {
         macd_buy = true;
         macd_sell = false;
        }
      if(macd_main[1]>macd_signal[1] && macd_main[2]<macd_signal[2])
        {
         macd_buy = false;
         macd_sell = true;
        }
     }
   else
     {
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
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void CheckAlligatorSignal(bool &alligator_buy,bool &alligator_sell)
  {

   alligator_buy = false;
   alligator_sell = false;
   double jaw[],teeth[],lips[];
   ArraySetAsSeries(jaw,true);
   ArraySetAsSeries(teeth,true);
   ArraySetAsSeries(lips,true);

   int start_pos=0,count=3;

   if(!iGetArray(handle_iAlligator,GATORJAW_LINE,start_pos,count,jaw) ||
      !iGetArray(handle_iAlligator,GATORTEETH_LINE,start_pos,count,teeth) ||
      !iGetArray(handle_iAlligator,GATORLIPS_LINE,start_pos,count,lips))
     {
      return;
     }

   bool mouthOpen = MathAbs(lips[1] - jaw[1]) > ExtMouthSize;

   if(lips[1]<teeth[1] && teeth[1]<jaw[1] && mouthOpen)
     {
      alligator_buy = false;
      alligator_sell = true;
     }

   if(lips[1]>teeth[1] && teeth[1]>jaw[1] && mouthOpen)
     {
      alligator_buy = true;
      alligator_sell = false;
     }

  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void CheckCCISignal(bool &cci_buy,bool &cci_sell)
  {
   cci_buy = false;
   cci_sell = false;
   double cci_array[];
   ArraySetAsSeries(cci_array,true);

   int buffer=0,start_pos=0;
   int count=3;

   if(!iGetArray(handle_iCCI,buffer,start_pos,count,cci_array))
     {
      return;
     }

   if((int)cci_array[1]>Inp_CCI_Up_Level)
     {
      if(!InpReversCCI)
        {
         cci_buy = false;
         cci_sell = true;
        }
      else
        {
         cci_buy = true;
         cci_sell = false;
        }
     }

   if((int)cci_array[1]<Inp_CCI_Down_Level)
     {
      if(!InpReversCCI)
        {
         cci_buy = true;
         cci_sell = false;
        }
      else
        {
         cci_buy = false;
         cci_sell = true;
        }
     }


  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void CheckFractalsSignal(bool &fractals_buy,bool &fractals_sell)
  {
   fractals_buy = false;
   fractals_sell = false;
   double fractals_upper[],fractals_lower[];
   ArraySetAsSeries(fractals_upper,true);
   ArraySetAsSeries(fractals_lower,true);

   int start_pos=0,count=100;

   if(!iGetArray(handle_iFractals,UPPER_LINE,start_pos,count,fractals_upper) ||
      !iGetArray(handle_iFractals,LOWER_LINE,start_pos,count,fractals_lower))
     {
      return;
     }

   fractals_up          = EMPTY_VALUE;
   fractals_down        = EMPTY_VALUE;
   fractals_up_number   = -1;
   fractals_down_number = -1;

   for(int i=Inp_Fractals_shift; i<count; i++)
     {
      if(fractals_upper[i]!=0.0 && fractals_upper[i]!=EMPTY_VALUE)
         if(fractals_up==EMPTY_VALUE)
           {
            fractals_up=fractals_upper[i];
            fractals_up_number=i;
           }
      if(fractals_lower[i]!=0.0 && fractals_lower[i]!=EMPTY_VALUE)
         if(fractals_down==EMPTY_VALUE)
           {
            fractals_down=fractals_lower[i];
            fractals_down_number=i;
           }
      if(fractals_up!=EMPTY_VALUE && fractals_down!=EMPTY_VALUE)
         break;
     }

   if(fractals_up==EMPTY_VALUE || fractals_down==EMPTY_VALUE)
      return;

   if(m_symbol.Bid()<fractals_down)
     {
      fractals_buy = false;
      fractals_sell = true;
     }

   if(m_symbol.Ask()>fractals_up)
     {
      fractals_buy = true;
      fractals_sell = false;
     }

  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void CheckBollingerSignal(bool &bollinger_buy,bool &bollinger_sell)
  {
   bollinger_buy=false;
   bollinger_sell=false;

   MqlRates rates[];
   double bands_upper_array[],bands_lower_array[];
   ArraySetAsSeries(rates,true);
   ArraySetAsSeries(bands_upper_array,true);
   ArraySetAsSeries(bands_lower_array,true);

   int start_pos=0,count=3;

   if(!iGetArray(handle_iBollinger,UPPER_BAND,start_pos,count,bands_upper_array) ||
      !iGetArray(handle_iBollinger,LOWER_BAND,start_pos,count,bands_lower_array) ||
      CopyRates(_Symbol,0,0,count,rates) < count)
     {
      return;
     }

   if(InpEnumBolTradeType == retraceBands)
     {
      if(rates[2].high > bands_upper_array[2]&& rates[1].low < bands_upper_array[1])
        {
         if(!InpReversBol)
           {
            bollinger_buy=false;
            bollinger_sell=true;
           }
         else
           {
            bollinger_buy=true;
            bollinger_sell=false;
           }
        }
      if(rates[2].low < bands_lower_array[2] && rates[1].high > bands_lower_array[1])
        {
         if(!InpReversBol)
           {
            bollinger_buy=true;
            bollinger_sell=false;
           }
         else
           {
            bollinger_buy=false;
            bollinger_sell=true;
           }
        }
     }
   else
     {
      if(rates[1].close > bands_upper_array[1])
        {
         if(!InpReversBol)
           {
            bollinger_buy=false;
            bollinger_sell=true;
           }
         else
           {
            bollinger_buy=true;
            bollinger_sell=false;
           }
        }
      if(rates[1].close < bands_lower_array[1])
        {
         if(!InpReversBol)
           {
            bollinger_buy=true;
            bollinger_sell=false;
           }
         else
           {
            bollinger_buy=false;
            bollinger_sell=true;
           }
        }

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
