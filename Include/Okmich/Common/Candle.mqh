//+------------------------------------------------------------------+
//|                                                  Candlestick.mqh |
//|                                    Copyright 2020, Michael Enudi |
//|                                             okmich2002@yahoo.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2020, Michael Enudi"
#property link      "okmich2002@yahoo.com"
//+------------------------------------------------------------------+
//| defines                                                          |
//+------------------------------------------------------------------+

enum ENUM_CANDLE_CLASS
  {
   CANDLE_CLS_BULLISH,
   CANDLE_CLS_BEARISH,
   CANDLE_CLS_SIGNAL,
   CANDLE_CLS_UNKNOWN
  };

/**
 * https://en.wikipedia.org/wiki/Candlestick_pattern#Simple_patterns
 */
enum ENUM_CANDLE_PATTERN
  {
   CANDLE_PATTERN_NONE,
   CANDLE_PATTERN_HAMMER,
   CANDLE_PATTERN_INVERTED_HAMMER,
   CANDLE_PATTERN_DOJI,
   CANDLE_PATTERN_DRAGONFLY_DOJI,
   CANDLE_PATTERN_GRAVESTONE_DOJI,
   CANDLE_PATTERN_SHOOTING_STAR,
   CANDLE_PATTERN_HANGING_MAN,
   CANDLE_PATTERN_SPINNING_TOP,
   CANDLE_PATTERN_MARABUZO,
   CANDLE_PATTERN_SHAVEN_HEAD,
   CANDLE_PATTERN_SHAVEN_HEAD_LITE,
   CANDLE_PATTERN_SHAVEN_BOTTOM,
   CANDLE_PATTERN_SHAVEN_BOTTOM_LITE,
   CANDLE_PATTERN_LONG_UPPER_SHADOW,
   CANDLE_PATTERN_LONG_LOWER_SHADOW
  };
//+------------------------------------------------------------------+

enum ENUM_CANDLE_TYPE
  {
   CANDLE_TYPE_BEARISH = 0,
   CANDLE_TYPE_BULLISH = 1
  };
//+------------------------------------------------------------------+

enum ENUM_CANDLE_PATTERN_MULTIPATTERN
  {
   MULTIPATTERN_NONE,
   MULTIPATTERN_BEARISH_ENGULFING, //send bear bar fully engulfs first bull bar
   MULTIPATTERN_BEARISH_HARAMI,
   MULTIPATTERN_BULLISH_ENGULFING, //send bull bar fully engulfs first bear bar
   MULTIPATTERN_BULLISH_HARAMI,
   MULTIPATTERN_MORNING_STAR       //3 candle stick pattern
  };
//+------------------------------------------------------------------+

//+------------------------------------------------------------------+
//| CCandle                                                     |
//+------------------------------------------------------------------+
class CCandle
  {
private:
   datetime          m_dt;
   double            m_open, m_high, m_low, m_close;
   double            m_mid;
   long              m_vol;
   ENUM_CANDLE_TYPE  m_type;
   double            m_body;
   double            m_lower_shadow;
   double            m_upper_shadow;
   double            m_range;
   void              init(const datetime& dt, const double pOpen, const double pHigh,
                          const double pLow, const double pClose, const long ivol);

public:
                     CCandle(const datetime& dt, const double pOpen, const double pHigh,
           const double pLow, const double pClose, const long ivol=0)
     {
      init(dt, pOpen, pHigh, pLow, pClose, ivol);
     };
                     CCandle(const double pOpen, const double pHigh,const double pLow, const double pClose)
     {
      datetime now = TimeCurrent();
      init(now, pOpen, pHigh, pLow, pClose, 0);
     };
                     CCandle(MqlRates& rate)
     {
      init(rate.time, rate.open, rate.high, rate.low, rate.close, rate.tick_volume);
     };
   datetime          time() {return m_dt;}
   double            open() {return m_open;}
   double            high() {return m_high;}
   double            low() {return m_low;}
   double            close() {return m_close;}
   double            body() {return m_body;}
   long              volumn() {return m_vol;}
   double            middle() {return m_mid;}
   double            lowerShadow() {return m_lower_shadow;}
   double            upperShadow() {return m_upper_shadow;}
   double            range() {return m_range;}
   double            medianPrice() {return (m_high + m_low)/2;}
   double            typicalPrice() {return (m_high + m_low + m_close)/3;}
   ENUM_CANDLE_TYPE  type() {return m_type;}
   ENUM_CANDLE_PATTERN       pattern();
   ENUM_CANDLE_PATTERN_MULTIPATTERN findPattern(const double pOpen, const double pHigh,
         const double pLow, const double pClose);
   ENUM_CANDLE_PATTERN_MULTIPATTERN findPattern(MqlRates& mqlRate)
     {
      return findPattern(mqlRate.open, mqlRate.high, mqlRate.low, mqlRate.close);
     };
   string            toString();
  };
//+------------------------------------------------------------------+

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void CCandle::init(const datetime& dt, const double open, const double high,
                   const double low, const double close, const long vol=0)
  {
   this.m_dt = dt;
   this.m_open = open;
   this.m_high = high;
   this.m_low = low;
   this.m_close = close;
   this.m_range = high - low;
   this.m_vol = vol;
   this.m_body = MathAbs(open - close);
   this.m_mid = (m_range/2) + m_low ;
   if(m_open > m_close)
     {
      m_type = CANDLE_TYPE_BEARISH;
      this.m_upper_shadow = high - open;
      this.m_lower_shadow = close - low;
     }
   else
     {
      this.m_type = CANDLE_TYPE_BULLISH;
      this.m_upper_shadow = high - close;
      this.m_lower_shadow = open - low;
     }
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
ENUM_CANDLE_PATTERN CCandle::pattern(void)
  {
//marabuzo
   if(m_lower_shadow == 0 && m_upper_shadow == 0)
      return CANDLE_PATTERN_MARABUZO;

   double itenth_of_range = 0.1 * this.m_range;
//double ftenth_of_range = 0.1 * itenth_of_range; //fractional ten
//dojis
   if(m_body < (itenth_of_range/2)) //very very small body
     {
      double tinybody = itenth_of_range/2;
      //dragonfly doji
      if(m_upper_shadow < tinybody && m_lower_shadow >= (8 * itenth_of_range))
         return CANDLE_PATTERN_DRAGONFLY_DOJI;

      //gravestone doji
      if(m_lower_shadow < tinybody && m_upper_shadow >= (8 * itenth_of_range))
         return CANDLE_PATTERN_GRAVESTONE_DOJI;

      //doji - should it be 2*itenth_of_range
      if(MathAbs(m_lower_shadow - m_upper_shadow) <= itenth_of_range)
         return CANDLE_PATTERN_DOJI;
     }

   if(m_lower_shadow < itenth_of_range)
     {
      //Shaven Bottom
      if(m_body >= (4 * itenth_of_range) && m_lower_shadow == 0)
         return CANDLE_PATTERN_SHAVEN_BOTTOM;

      //Shaven Bottom Lite
      if(m_body >= (4 * itenth_of_range) && m_lower_shadow < (0.5 * itenth_of_range))
         return CANDLE_PATTERN_SHAVEN_BOTTOM_LITE;

      //inverted hammer
      if(m_upper_shadow >= (6 * itenth_of_range) && m_upper_shadow >= (2 * m_body))
         return CANDLE_PATTERN_INVERTED_HAMMER;

      //Shooting Star
      if(m_upper_shadow >= (6 * itenth_of_range) && m_body <= (3 * itenth_of_range))
         return CANDLE_PATTERN_SHOOTING_STAR;
     }

   if(m_upper_shadow < itenth_of_range)
     {
      //Shaven Head
      if(m_body >= (4 * itenth_of_range) && m_upper_shadow == 0)
         return CANDLE_PATTERN_SHAVEN_HEAD;

      //Shaven Head Lite - almost shaven head but there is a tiny upper shadowd
      if(m_body >= (4 * itenth_of_range) && m_upper_shadow < (0.5 * itenth_of_range))
         return CANDLE_PATTERN_SHAVEN_HEAD_LITE;


      //Hammer - the lower shadow is at least twice the size of the real body
      if(m_lower_shadow >= (6 * itenth_of_range) && m_lower_shadow >= (2 * m_body))
         return CANDLE_PATTERN_HAMMER;

      //inverted Hanging_man - https://en.wikipedia.org/wiki/Hanging_man_(candlestick_pattern)
      if(m_lower_shadow >= (2 * m_body))
         return CANDLE_PATTERN_HANGING_MAN;
     }

//long upper shadow
   if(m_upper_shadow >= (0.6667 * m_range) && m_lower_shadow <= (2 * itenth_of_range))
      return CANDLE_PATTERN_LONG_UPPER_SHADOW;

//long lower shadow
   if(m_lower_shadow >= (0.6667 * m_range) && m_upper_shadow <= (2 * itenth_of_range))
      return CANDLE_PATTERN_LONG_LOWER_SHADOW;

//spinning top - https://en.wikipedia.org/wiki/Spinning_top_(candlestick_pattern)
   if(MathAbs(m_upper_shadow - m_lower_shadow) <= itenth_of_range && m_body <= (3 * itenth_of_range))
      return CANDLE_PATTERN_SPINNING_TOP;

   return CANDLE_PATTERN_NONE;
  }


//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
ENUM_CANDLE_PATTERN_MULTIPATTERN CCandle::findPattern(const double pOpen, const double pHigh,
      const double pLow, const double pClose)
  {
   bool isBullish = pOpen < pClose;
//bearish engulfing
   if(m_type == CANDLE_TYPE_BEARISH && isBullish && m_open >= pHigh &&  m_low < pLow)
      return MULTIPATTERN_BEARISH_ENGULFING;
//bullish engulfing
   if(m_type == CANDLE_TYPE_BULLISH && !isBullish && m_close >= pHigh &&  m_low < pLow)
      return MULTIPATTERN_BULLISH_ENGULFING;
//bearish harami
   double other_range = pHigh - pLow;
   bool haramiPredicate = m_range < (other_range / 2);
   if(m_type == CANDLE_TYPE_BEARISH && isBullish && m_high <= pClose &&  m_low > pOpen && haramiPredicate)
      return MULTIPATTERN_BEARISH_HARAMI;
//bullish harami
   if(CANDLE_TYPE_BULLISH && !isBullish && m_high <= pOpen &&  m_low > pClose && haramiPredicate)
      return MULTIPATTERN_BULLISH_HARAMI;

   return MULTIPATTERN_NONE;
  }

//+------------------------------------------------------------------+
//| CCandle::toString(void)                                     |
//+------------------------------------------------------------------+
string CCandle::toString(void)
  {
   return StringFormat("Candle[time=%s, open=%f, high=%f, close=%f, low=%f, lsh=%f, ush=%f, range=%f, body=%f, type=%s, vol=%f]",
                       TimeToString(m_dt), this.m_open, this.m_high, this.m_close, this.m_low,
                       this.m_lower_shadow, this.m_upper_shadow,
                       this.m_range, this.m_body, EnumToString(m_type), this.m_vol);
  }
//+------------------------------------------------------------------+


//+------------------------------------------------------------------+
//| HELPER FUNCTIONS                                                 |
//+------------------------------------------------------------------+

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
bool isPinBar(ENUM_CANDLE_TYPE type, const double pOpen, const double pHigh,
              const double pLow, const double pClose)
  {
   return false;
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
bool isPinBar(ENUM_CANDLE_TYPE type, const MqlRates &mqlRate)
  {
   return false;
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
bool isReversalCandle(ENUM_CANDLE_TYPE type, const double pOpen, const double pHigh,
                      const double pLow, const double pClose)
  {
   return false;
  }

//+------------------------------------------------------------------+
bool isReversalCandles(ENUM_CANDLE_TYPE type, MqlRates& mqlRate[], int startIdx, int count)
  {
   return false;
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
bool isContinuationCandle(ENUM_CANDLE_TYPE type, const double open, const double high,
                          const double low, const double close)
  {
   return false;
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
bool isContinuationCandles(ENUM_CANDLE_TYPE type, MqlRates& mqlRate[], int startIdx, int count)
  {
   return false;
  }
//+------------------------------------------------------------------+

//CCandle toCandle(){
//   CCandle* candle = new CCandle(0,0,0,0,0);
//   return candle;
//};
