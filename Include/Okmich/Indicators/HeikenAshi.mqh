//+------------------------------------------------------------------+
//|                                                  CHeikenAshi.mqh |
//|                                    Copyright 2020, Michael Enudi |
//|                                             okmich2002@yahoo.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2020, Michael Enudi"
#property link      "okmich2002@yahoo.com"
#property version   "1.00"

#include <Okmich\Common\Candle.mqh>
#include "BaseIndicator.mqh"

//#define HEIKEN_ASHI_IND "Examples\\Heiken_Ashi"

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
class CHeikenAshi : public CBaseIndicator
  {
private :
   int               mBarsToCopy;
   //--- indicator handles
   //--- indicator buffer
   CCandle           *mCandles[];
   MqlRates          m_MqlRates[];
   //--- general
   datetime          m_LastOpenTime;

public:
                     CHeikenAshi(string symbol, ENUM_TIMEFRAMES period, int historyBars=6): CBaseIndicator(symbol, period)
     {
      mBarsToCopy = historyBars + 1;
     };

   virtual bool                   Init();
   virtual bool                   Refresh(int ShiftToUse=1);
   virtual void                   Release();

   ENUM_CANDLE_PATTERN GetPattern(int shift  = 1);
   ENUM_CANDLE_TYPE  GetType(int shift  = 1);
   ENUM_CANDLE_STATE BullBearNeutral(int shift  = 1);
  };

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
bool CHeikenAshi::Init(void)
  {
   ArrayResize(mCandles, mBarsToCopy);
//
   ArraySetAsSeries(m_MqlRates, true);
   ArraySetAsSeries(mCandles, true);

   return true;
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
bool CHeikenAshi::Refresh(int ShiftToUse=1)
  {
   m_ShiftToUse = ShiftToUse;
   int ratesCopied = CopyRates(m_Symbol, m_TF, 0, mBarsToCopy, m_MqlRates);
//file the candle array
   double open, close, high, low;
   for(int i = 0; i < mBarsToCopy - 1; i++)
     {
      open =(m_MqlRates[i+1].open + m_MqlRates[i+1].close)/2;
      close=(m_MqlRates[i].open + m_MqlRates[i].high + m_MqlRates[i].low + m_MqlRates[i].close)/4;
      high =MathMax(m_MqlRates[i].high,MathMax(open,close));
      low  =MathMin(m_MqlRates[i].low,MathMin(open,close));

      mCandles[i] = new CCandle(open, high, low,close);
     }

   return mBarsToCopy == ratesCopied;
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void CHeikenAshi::Release(void)
  {
   for(int i = 0; i < ArraySize(mCandles); i++)
      delete mCandles[i];
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
ENUM_CANDLE_PATTERN CHeikenAshi::GetPattern(int shift  = 1)
  {
   return mCandles[shift].pattern();
  };

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
ENUM_CANDLE_TYPE CHeikenAshi::GetType(int shift  = 1)
  {
   return mCandles[shift].type();
  };

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
ENUM_CANDLE_STATE CHeikenAshi::BullBearNeutral(int shift  = 1)
  {
   switch(mCandles[shift].pattern())
     {
      case CANDLE_PATTERN_INVERTED_HAMMER:
      case CANDLE_PATTERN_LONG_UPPER_SHADOW:
      case CANDLE_PATTERN_SHAVEN_BOTTOM:
      case CANDLE_PATTERN_SHAVEN_BOTTOM_LITE:
      case CANDLE_PATTERN_SHOOTING_STAR:
         return CANDLE_STATE_BULL;

      case CANDLE_PATTERN_HAMMER:
      case CANDLE_PATTERN_HANGING_MAN:
      case CANDLE_PATTERN_LONG_LOWER_SHADOW:
      case CANDLE_PATTERN_SHAVEN_HEAD:
      case CANDLE_PATTERN_SHAVEN_HEAD_LITE:
         return CANDLE_STATE_BEAR;

      case CANDLE_PATTERN_SPINNING_TOP:
      case CANDLE_PATTERN_DOJI:
      case CANDLE_PATTERN_DRAGONFLY_DOJI:
      case CANDLE_PATTERN_GRAVESTONE_DOJI:
         return CANDLE_STATE_SIGNAL;

      default:
         return CANDLE_STATE_NEUTRAL;
     }
  };
//+------------------------------------------------------------------+
