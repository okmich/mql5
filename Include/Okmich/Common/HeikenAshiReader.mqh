//+------------------------------------------------------------------+
//|                                             HeikenAshiReader.mqh |
//|                                    Copyright 2020, Michael Enudi |
//|                                             okmich2002@yahoo.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2020, Michael Enudi"
#property description "A utility class for calculating Heiken Ashi Candle sticks and returning descriptions about them."
#property link      "okmich2002@yahoo.com"

#include <Okmich\Common\Candle.mqh>
//+------------------------------------------------------------------+
//| HeikenAshiReader                                                 |
//+------------------------------------------------------------------+
class CHeikenAshiReader
  {
private:
   string            mSymbol;
   ENUM_TIMEFRAMES   mTimeFrame;
   int               mHistoryBars;
   CCandle           *mCandles[];

   void              Refresh();

public:
                     CHeikenAshiReader(string symbol,ENUM_TIMEFRAMES timeFrame, int numberOfBars)
     {
      mSymbol = symbol;
      mTimeFrame = timeFrame;
      mHistoryBars = numberOfBars;

      ArrayResize(mCandles, mHistoryBars);
     };

   double            GetPrice(int i=0, ENUM_APPLIED_PRICE priceType = PRICE_CLOSE);

   ENUM_CANDLE_CLASS EvaluateCandleClass(int i, bool refreshFlag=false);
   ENUM_CANDLE_TYPE  CandleType(int i, bool refreshFlag=false);
  };

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
ENUM_CANDLE_TYPE CHeikenAshiReader::CandleType(int i, bool refreshFlag=false)
  {
   if(i >= mHistoryBars)
      return NULL;
//if required reload price data and candle array
   if(refreshFlag)
      Refresh();

   return mCandles[i].type();
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
ENUM_CANDLE_CLASS CHeikenAshiReader::EvaluateCandleClass(int i, bool refreshFlag=false)
  {
   if(i >= mHistoryBars)
      return NULL;
//if required reload price data and candle array
   if(refreshFlag)
      Refresh();

   switch(mCandles[i].pattern())
     {
      case CANDLE_PATTERN_INVERTED_HAMMER:
      case CANDLE_PATTERN_LONG_UPPER_SHADOW:
      case CANDLE_PATTERN_SHAVEN_BOTTOM:
      case CANDLE_PATTERN_SHAVEN_BOTTOM_LITE:
      case CANDLE_PATTERN_SHOOTING_STAR:
         return CANDLE_CLS_BULLISH;

      case CANDLE_PATTERN_HAMMER:
      case CANDLE_PATTERN_HANGING_MAN:
      case CANDLE_PATTERN_LONG_LOWER_SHADOW:
      case CANDLE_PATTERN_SHAVEN_HEAD:
      case CANDLE_PATTERN_SHAVEN_HEAD_LITE:
         return CANDLE_CLS_BEARISH;

      case CANDLE_PATTERN_SPINNING_TOP:
      case CANDLE_PATTERN_DOJI:
      case CANDLE_PATTERN_DRAGONFLY_DOJI:
      case CANDLE_PATTERN_GRAVESTONE_DOJI:
         return CANDLE_CLS_SIGNAL;

      default:
         return CANDLE_CLS_UNKNOWN;
     }
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void CHeikenAshiReader::Refresh(void)
  {
   MqlRates mqlRates[];
   ArraySetAsSeries(mqlRates, true);

   int ratesCopied = CopyRates(mSymbol, mTimeFrame, 0, mHistoryBars + 1, mqlRates);

   for(int i = 1; i < mHistoryBars; i++)
     {
      delete  mCandles[i-1]; //remove any existing pointer

      double ha_open =(mqlRates[i-1].open +mqlRates[i-1].close)/2;
      double ha_close=(mqlRates[i].open + mqlRates[i].high + mqlRates[i].low + mqlRates[i].close)/4;
      double ha_high =MathMax(mqlRates[i].high, MathMax(ha_open,ha_close));
      double ha_low  =MathMin(mqlRates[i].low, MathMin(ha_open,ha_close));

      mCandles[i-1] = new CCandle(ha_open, ha_high, ha_low, ha_close);
     }


  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
double CHeikenAshiReader::GetPrice(int i=0, ENUM_APPLIED_PRICE priceType = PRICE_CLOSE)
  {
   if(i >= mHistoryBars)
      return NULL;

   switch(priceType)
     {
      case PRICE_CLOSE:
         return mCandles[i].close();
      case PRICE_HIGH:
         return mCandles[i].high();
      case PRICE_LOW:
         return mCandles[i].low();
      case PRICE_OPEN:
         return mCandles[i].open();
      case PRICE_MEDIAN:
         return mCandles[i].medianPrice();
      case PRICE_TYPICAL:
         return mCandles[i].typicalPrice();
      default:
         return EMPTY_VALUE;
     }
  }
//+------------------------------------------------------------------+
