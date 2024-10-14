//+------------------------------------------------------------------+
//|                                              CIchimokuScanBot.mqh |
//|                                    Copyright 2020, Michael Enudi |
//|                                             okmich2002@yahoo.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2020, Michael Enudi"
#property link      "okmich2002@yahoo.com"

#include "MarketScanner.mqh"
#include <Indicators\Trend.mqh>
#include <Okmich\Common\Common.mqh>

const string SCAN_CODE = "ICHIMOKU";
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
class CIchimokuScanBot : public CBaseBot
  {
private:
   //--- indicator paramter
   int                m_TenkanSen;
   int                m_KijunSen;
   int                m_SenkouSpanB;
   //--- indicator
   CiIchimoku         m_CiIchimoku;
   //--- indicator buffers
   double             kumoCloudSizeStats[];
   //--- other buffers
   double            highs[], lows[];
   double            closePrice;

   bool              Setup();
   ENUM_ENTRY_SIGNAL resolveTenkanKijunStatus(double tks, double kjs);
   ENUM_ENTRY_SIGNAL resolvePriceKumoStatus(ENUM_ENTRY_SIGNAL kumoStatus, double senkouSpanA);
   ENUM_ENTRY_SIGNAL resolveKijunPriceStatus(double kjs);
   ENUM_ENTRY_SIGNAL resolveChikouKumoStatus(double ckspan, int index);
   ENUM_ENTRY_SIGNAL resolveChikouPriceStatus(ENUM_ENTRY_SIGNAL kumoStatus, double ckspan, int index);
   ENUM_ENTRY_SIGNAL resolveChikouHHLLStatus(
      ENUM_ENTRY_SIGNAL tenKanSenKijunState, double ckspan, int index);

   void               SignalToValue(ENUM_ENTRY_SIGNAL signal, double &runningSum, float value = 0.0);
public:
                     CIchimokuScanBot(string symbol, ENUM_TIMEFRAMES tf, int tenkanSen=9, int kijunSen=26, int senkouSpanB=52) :
                     CBaseBot(SCAN_CODE, tf, symbol)
     {
      m_TenkanSen = tenkanSen;
      m_KijunSen = kijunSen;
      m_SenkouSpanB = senkouSpanB;
     };

                    ~CIchimokuScanBot() {};

   //this is the main implementation for this bot.
   virtual void      Begin();
   //should return a the indices from the bot's indicators as well as the ohlcv values
   virtual string    BotScanValues();
  };

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
bool CIchimokuScanBot::Setup(void)
  {
   return m_CiIchimoku.Create(mSymbol, mTimeFrame, m_TenkanSen, m_KijunSen, m_SenkouSpanB);
  }


//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void CIchimokuScanBot::Begin(void)
  {
   if(!Setup())
     {
      mWorthReporting = false;
      return ;
     }
   m_CiIchimoku.Refresh();
   closePrice = iClose(mSymbol, mTimeFrame, mShiftIndex);
//indices
   double tenkanSen = m_CiIchimoku.TenkanSen(mShiftIndex);
   double kijunSen =  m_CiIchimoku.KijunSen(mShiftIndex);
   double senkouSpanA = m_CiIchimoku.SenkouSpanA(mShiftIndex);
   double senkouSpanB = m_CiIchimoku.SenkouSpanB(mShiftIndex);
   double futureSenkouSpanA = m_CiIchimoku.SenkouSpanA(mShiftIndex-26);
   double futureSenkouSpanB = m_CiIchimoku.SenkouSpanB(mShiftIndex-26);
   double chinkouSpan = m_CiIchimoku.ChinkouSpan(mShiftIndex+26);

//derivatives
   ENUM_ENTRY_SIGNAL currKumoStatus = senkouSpanA > senkouSpanB ? ENTRY_SIGNAL_BUY :
                                      senkouSpanB > senkouSpanA ? ENTRY_SIGNAL_SELL : ENTRY_SIGNAL_NONE;
   ENUM_ENTRY_SIGNAL fwdKumoStatus = futureSenkouSpanA > futureSenkouSpanB ? ENTRY_SIGNAL_BUY :
                                     futureSenkouSpanB > futureSenkouSpanA ? ENTRY_SIGNAL_SELL :
                                     ENTRY_SIGNAL_NONE;

   double previousKijunSen = m_CiIchimoku.KijunSen(mShiftIndex + 1);
   double ftSSBShift1 = m_CiIchimoku.SenkouSpanB(mShiftIndex-25);

   ENUM_SLOPE kijunSlope = kijunSen > previousKijunSen ? SLOPE_UP :
                           previousKijunSen > kijunSen ? SLOPE_DOWN : SLOPE_FLAT;
   ENUM_SLOPE ftSSBSlope = futureSenkouSpanB > ftSSBShift1 ? SLOPE_UP :
                           ftSSBShift1 > futureSenkouSpanB ? SLOPE_DOWN : SLOPE_FLAT;
//--- events
   ENUM_ENTRY_SIGNAL tenKanSenKijunState = resolveTenkanKijunStatus(tenkanSen, kijunSen);
   ENUM_ENTRY_SIGNAL priceKumoState = resolvePriceKumoStatus(currKumoStatus, senkouSpanA);
   ENUM_ENTRY_SIGNAL kijunPriceState = resolveKijunPriceStatus(kijunSen);
   ENUM_ENTRY_SIGNAL chikouKumoState = resolveChikouKumoStatus(chinkouSpan, 26);
   ENUM_ENTRY_SIGNAL chikouPriceState = resolveChikouPriceStatus(currKumoStatus, chinkouSpan, 26);
   ENUM_ENTRY_SIGNAL hhLLChikouState = resolveChikouHHLLStatus(tenKanSenKijunState, chinkouSpan, 26);

   double sumScore = 0.0;
   SignalToValue(tenKanSenKijunState, sumScore, 1.0);
   SignalToValue(priceKumoState, sumScore, 3.0);
   SignalToValue(fwdKumoStatus, sumScore, 3.0);
   SignalToValue(kijunPriceState, sumScore, 1.0);
   SignalToValue(chikouKumoState, sumScore, 0.5);
   SignalToValue(chikouPriceState, sumScore, 0.5);
   SignalToValue(hhLLChikouState, sumScore, 1.0);

   mScore = MathAbs(sumScore);
//--- prepare the result if worthreporting
   if(mScore > 7)
     {
      //summary signal
      mSignal = sumScore > 0 ?  ENTRY_SIGNAL_BUY : ENTRY_SIGNAL_SELL;
      //worth reporting
      mWorthReporting = true;
      double open = iOpen(mSymbol, mTimeFrame, mShiftIndex);
      double high = iHigh(mSymbol, mTimeFrame, mShiftIndex);
      double low = iLow(mSymbol, mTimeFrame, mShiftIndex);
      mScanValues = StringFormat("indices#tenkansen=%f,kijunsen=%f,ssA=%f,ssB=%f,chikouspan=%f,"+
                                 "fwd_ssA=%f,fwd_ssB=%f|" +
                                 "derivatives#kjsenSlope=%s,kumoStatus=%s,ftKumoStatus=%s, " +
                                 "ftSSBSlope=%s|"+
                                 "events#tk_kj_crossover=%s,kumo_breakout=%s," +
                                 "kj_price_breakout=%s,cs_kumo_breakout=%s,cs_price_breakout=%s|",
                                 tenkanSen, kijunSen,senkouSpanA, senkouSpanB,chinkouSpan,
                                 futureSenkouSpanA,futureSenkouSpanB,
                                 EnumToString(kijunSlope), EnumToString(currKumoStatus),
                                 EnumToString(fwdKumoStatus), EnumToString(ftSSBSlope),
                                 EnumToString(tenKanSenKijunState),EnumToString(priceKumoState),
                                 EnumToString(kijunPriceState), EnumToString(chikouKumoState),
                                 EnumToString(chikouPriceState)) +
                    CurrentCandleProperties(mShiftIndex);
     }

   m_CiIchimoku.FullRelease();
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
ENUM_ENTRY_SIGNAL CIchimokuScanBot::resolveKijunPriceStatus(double kjs)
  {
   if(closePrice > kjs)
      return ENTRY_SIGNAL_BUY;
   if(closePrice < kjs)
      return ENTRY_SIGNAL_SELL;

   return ENTRY_SIGNAL_NONE;
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
ENUM_ENTRY_SIGNAL CIchimokuScanBot::resolveChikouKumoStatus(double ckspan, int index)
  {
   double ssA = m_CiIchimoku.SenkouSpanA(index);
   double ssB = m_CiIchimoku.SenkouSpanB(index);
   double upLimit = MathMax(ssA, ssB);

   if(ckspan > upLimit)
      return ENTRY_SIGNAL_BUY;

   double downLimit = MathMin(ssA, ssB);

   if(ckspan < downLimit)
      return ENTRY_SIGNAL_SELL;

   return ENTRY_SIGNAL_NONE;
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
ENUM_ENTRY_SIGNAL CIchimokuScanBot::resolveChikouPriceStatus(
   ENUM_ENTRY_SIGNAL kumoStatus, double ckspan, int index)
  {
   double prices[];
   ArraySetAsSeries(prices, true);

   if(kumoStatus == ENTRY_SIGNAL_BUY)
     {
      CopyHigh(mSymbol, mTimeFrame, index, 10, prices);
      int maxArg = ArrayMaximum(prices);
      if(maxArg > -1 && ckspan > prices[maxArg])
         return ENTRY_SIGNAL_BUY;
     }
   else
      if(kumoStatus == ENTRY_SIGNAL_SELL)
        {
         CopyLow(mSymbol, mTimeFrame, index, 10, prices);
         int minArg = ArrayMinimum(prices);
         if(minArg > -1 && ckspan < prices[minArg])
            return ENTRY_SIGNAL_SELL;
        }

   return ENTRY_SIGNAL_NONE;
  }


//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
ENUM_ENTRY_SIGNAL CIchimokuScanBot::resolveTenkanKijunStatus(double tks, double kjs)
  {

   if(tks > kjs)
      return ENTRY_SIGNAL_BUY;
   if(tks < kjs)
      return ENTRY_SIGNAL_SELL;

   return ENTRY_SIGNAL_NONE;
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
ENUM_ENTRY_SIGNAL CIchimokuScanBot::resolvePriceKumoStatus(
   ENUM_ENTRY_SIGNAL kumoStatus, double senkouSpanA)
  {
   double oneCloseAgo = iClose(mSymbol, mTimeFrame, mShiftIndex);
   if(kumoStatus == ENTRY_SIGNAL_BUY && closePrice > senkouSpanA)
      return kumoStatus;
   else
      if(kumoStatus == ENTRY_SIGNAL_SELL && closePrice < senkouSpanA)
         return kumoStatus;
      else
         return ENTRY_SIGNAL_NONE;
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
ENUM_ENTRY_SIGNAL CIchimokuScanBot::resolveChikouHHLLStatus(
   ENUM_ENTRY_SIGNAL tenKanSenKijunState,double ckspan,int index)
  {
   double chikou[];
   ArraySetAsSeries(chikou, true);
   m_CiIchimoku.GetData(index, 26+1, 4, chikou);
   if(tenKanSenKijunState == ENTRY_SIGNAL_BUY)
     {
      // chikous must be the highest it has been in the last 26 bars
      int maxArg = ArrayMaximum(chikou);
      if(maxArg == 0)
         return tenKanSenKijunState;
     }
   else
      if(tenKanSenKijunState == ENTRY_SIGNAL_SELL)
        {
         // chikous must be the lowest it has been in the last 26 bars
         int minArg = ArrayMinimum(chikou);
         if(minArg == 0)
            return tenKanSenKijunState;
        }
   return ENTRY_SIGNAL_NONE;
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void CIchimokuScanBot::SignalToValue(ENUM_ENTRY_SIGNAL signal, double &runningSum, float value = 0.0)
  {
   if(signal == ENTRY_SIGNAL_BUY)
      runningSum += value;
   else
      if(signal == ENTRY_SIGNAL_SELL)
         runningSum += -value;
  }
//+------------------------------------------------------------------+
