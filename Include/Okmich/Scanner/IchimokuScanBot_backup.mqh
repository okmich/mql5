//+------------------------------------------------------------------+
//|                                              CIchimokuScanBot.mqh |
//|                                    Copyright 2020, Michael Enudi |
//|                                             okmich2002@yahoo.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2020, Michael Enudi"
#property link      "okmich2002@yahoo.com"

#include "MarketScanner.mqh"
#include <Indicators\Trend.mqh>
#include <Okmich\Common\LogNormalSeries.mqh>

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
   ENUM_ENTRY_SIGNAL resolveTenkanKijunCrossover(
      double previousTks, double tks, double previousKjs, double kjs);
   ENUM_ENTRY_SIGNAL resolvePriceKumoBreakout(
      ENUM_ENTRY_SIGNAL kumoStatus, double prevSenkouSpanA, double senkouSpanA);
   ENUM_ENTRY_SIGNAL resolveKumoTwist(ENUM_ENTRY_SIGNAL ftKumoStatus);
   ENUM_ENTRY_SIGNAL resolveKijunPriceBreakout(double prevKjs, double kjs);
   ENUM_ENTRY_SIGNAL resolveChikouKumoBreakout(double ckspan, int index);
   ENUM_ENTRY_SIGNAL resolveChikouPriceBreakout(double ckspan, int index);

   int               SignalToInt(ENUM_ENTRY_SIGNAL signal, int additional = 0);

   void              PrepareKumoCloudSizeStats();
   string            DescribeKumoCloudSize(int index);

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
   double previousTenkanSen = m_CiIchimoku.TenkanSen(mShiftIndex + 1);
   double previousKijunSen = m_CiIchimoku.KijunSen(mShiftIndex + 1);
   double previousSSA = m_CiIchimoku.SenkouSpanA(mShiftIndex-25);
   double previousSSB = m_CiIchimoku.SenkouSpanB(mShiftIndex-25);
   ENUM_SLOPE tenkanSlope = tenkanSen > previousTenkanSen ? UP :
                            previousTenkanSen > tenkanSen ? DOWN : FLAT;
   ENUM_SLOPE kijunSlope = kijunSen > previousKijunSen ? UP :
                           previousKijunSen > kijunSen ? DOWN : FLAT;
   ENUM_SLOPE ssASlope = futureSenkouSpanA > previousSSA ? UP :
                         previousSSA > futureSenkouSpanA ? DOWN : FLAT;
   ENUM_SLOPE ssBSlope = futureSenkouSpanB > previousSSB ? UP :
                         previousSSB > futureSenkouSpanB ? DOWN : FLAT;

//--- events
   ENUM_ENTRY_SIGNAL tenKanSenKijunCrossover = resolveTenkanKijunCrossover(
            previousTenkanSen, tenkanSen, previousKijunSen, kijunSen);
   ENUM_ENTRY_SIGNAL priceKumoBreakout = resolvePriceKumoBreakout(
         currKumoStatus, previousSSA, senkouSpanA);
   ENUM_ENTRY_SIGNAL kumoTwist = resolveKumoTwist(fwdKumoStatus);
   ENUM_ENTRY_SIGNAL kijunPriceBreakout = resolveKijunPriceBreakout(previousKijunSen, kijunSen);
   ENUM_ENTRY_SIGNAL chikouKumoBreakout = resolveChikouKumoBreakout(chinkouSpan, mShiftIndex+26);
   ENUM_ENTRY_SIGNAL chikouPriceBreakout = resolveChikouPriceBreakout(currKumoStatus, mShiftIndex+26);

   mScore = MathAbs(SignalToInt(tenKanSenKijunCrossover, 1) +
                    SignalToInt(priceKumoBreakout, 2) +
                    SignalToInt(kumoTwist, 2) +
                    SignalToInt(kijunPriceBreakout) +
                    SignalToInt(chikouKumoBreakout, 1) +
                    SignalToInt(chikouPriceBreakout));

//--- prepare the result if worthreporting
   if(mScore > 4)
     {
      //evaluate size of cloud
      PrepareKumoCloudSizeStats();
      string kumoSize = DescribeKumoCloudSize(mShiftIndex);
      string fwdKumoSize = DescribeKumoCloudSize(mShiftIndex-26);

      mWorthReporting = true;
      double open = iOpen(mSymbol, mTimeFrame, mShiftIndex);
      double high = iHigh(mSymbol, mTimeFrame, mShiftIndex);
      double low = iLow(mSymbol, mTimeFrame, mShiftIndex);
      mScanValues = StringFormat("indices#tenkansen=%f,kijunsen=%f,ssA=%f,ssB=%f,chikouspan=%f,"+
                                 "fwd_ssA=%f,fwd_ssB=%f|" +
                                 "derivatives#tksenSlope=%s,kjsenSlope=%s,kumoStatus=%s,ftKumoStatus=%s, " +
                                 "ssASlope=%s,ssBSlope=%s,kumoSize=%s,ftKumoSize=%s|"+
                                 "events#tk_kj_crossover=%s,kumo_breakout=%s,ftKumo_twist=%s," +
                                 "kj_price_breakout=%s,cs_kumo_breakout=%s,cs_price_breakout=%s|",
                                 tenkanSen, kijunSen,senkouSpanA, senkouSpanB,chinkouSpan,
                                 futureSenkouSpanA,futureSenkouSpanB,
                                 EnumToString(tenkanSlope), EnumToString(kijunSlope), EnumToString(currKumoStatus),
                                 EnumToString(fwdKumoStatus), EnumToString(ssASlope), EnumToString(ssBSlope),
                                 kumoSize, fwdKumoSize,
                                 EnumToString(tenKanSenKijunCrossover),EnumToString(priceKumoBreakout),
                                 EnumToString(kumoTwist),EnumToString(kijunPriceBreakout),
                                 EnumToString(chikouKumoBreakout),EnumToString(chikouPriceBreakout)) +
                    CurrentCandleProperties(mShiftIndex);
     }

   m_CiIchimoku.FullRelease();
  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
ENUM_ENTRY_SIGNAL CIchimokuScanBot::resolveChikouKumoBreakout(double ckspan, int index)
  {
   double prevCs = m_CiIchimoku.ChinkouSpan(index+1);
   double prevSsA = m_CiIchimoku.SenkouSpanA(index+1);
   double prevSsB = m_CiIchimoku.SenkouSpanB(index+1);
   double prevUpLimit = MathMax(prevSsA, prevSsB);

   double ssA = m_CiIchimoku.SenkouSpanA(index);
   double ssB = m_CiIchimoku.SenkouSpanB(index);
   double upLimit = MathMax(ssA, ssB);

   if(prevCs < prevUpLimit && ckspan > upLimit)
      return ENTRY_SIGNAL_BUY;

   double prevDwnLimit = MathMax(prevSsA, prevSsB);
   double downLimit = MathMax(ssA, ssB);

   if(prevCs > prevDwnLimit && ckspan < downLimit)
      return ENTRY_SIGNAL_SELL;

   return ENTRY_SIGNAL_NONE;
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
ENUM_ENTRY_SIGNAL CIchimokuScanBot::resolveChikouPriceBreakout(double ckspan, int index)
  {
   double prices[];
   ArraySetAsSeries(prices, true);

   double prevCkspan = m_CiIchimoku.ChinkouSpan(index+1);

   if(ckspan > prevCkspan)
     {
      CopyHigh(mSymbol, mTimeFrame, index, 26, prices);
      int maxArg = ArrayMaximum(prices);
      if(maxArg > -1 && ckspan >= prices[maxArg] && prevCkspan < prices[maxArg])
         return ENTRY_SIGNAL_BUY;
     }
   else
      if(ckspan < prevCkspan)
        {
         CopyLow(mSymbol, mTimeFrame, index, 26, prices);
         int maxArg = ArrayMinimum(prices);
         if(maxArg > -1 && ckspan < prices[maxArg] && prevCkspan > prices[maxArg])
            return ENTRY_SIGNAL_SELL;
        }

   return ENTRY_SIGNAL_NONE;
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
ENUM_ENTRY_SIGNAL CIchimokuScanBot::resolveKijunPriceBreakout(double prevKjs, double kjs)
  {
   double oneCloseAgo = iClose(mSymbol, mTimeFrame, mShiftIndex+1);
   if(oneCloseAgo < prevKjs && closePrice > kjs)
      return ENTRY_SIGNAL_BUY;
   if(oneCloseAgo > prevKjs && closePrice < kjs)
      return ENTRY_SIGNAL_SELL;

   return ENTRY_SIGNAL_NONE;
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
ENUM_ENTRY_SIGNAL CIchimokuScanBot::resolveKumoTwist(ENUM_ENTRY_SIGNAL ftKumoStatus)
  {
   double twoSSABefore = m_CiIchimoku.SenkouSpanA(mShiftIndex - 24);
   double twoSSBBefore = m_CiIchimoku.SenkouSpanB(mShiftIndex - 24);

   if(twoSSABefore < twoSSBBefore && ftKumoStatus == ENTRY_SIGNAL_BUY)
      return ftKumoStatus;
   if(twoSSABefore > twoSSBBefore && ftKumoStatus == ENTRY_SIGNAL_SELL)
      return ftKumoStatus;

   return ENTRY_SIGNAL_NONE;
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
ENUM_ENTRY_SIGNAL CIchimokuScanBot::resolvePriceKumoBreakout(
   ENUM_ENTRY_SIGNAL kumoStatus, double prevSenkouSpanA, double senkouSpanA)
  {
   double oneCloseAgo = iClose(mSymbol, mTimeFrame, mShiftIndex+1);
   if(kumoStatus == ENTRY_SIGNAL_BUY &&
      oneCloseAgo < prevSenkouSpanA && closePrice > senkouSpanA)
      return kumoStatus;
   else
      if(kumoStatus == ENTRY_SIGNAL_SELL &&
         oneCloseAgo > prevSenkouSpanA &&  closePrice < senkouSpanA)
         return kumoStatus;
      else
         return ENTRY_SIGNAL_NONE;
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
ENUM_ENTRY_SIGNAL CIchimokuScanBot::resolveTenkanKijunCrossover(
   double previousTks, double tks, double previousKjs, double kjs)
  {
   double twoTksAgo = m_CiIchimoku.TenkanSen(mShiftIndex + 2);
   double twoKjsAgo = m_CiIchimoku.KijunSen(mShiftIndex + 2);

   if(twoTksAgo < twoKjsAgo && tks > kjs)
      return ENTRY_SIGNAL_BUY;
   if(twoTksAgo > twoKjsAgo && tks < kjs)
      return ENTRY_SIGNAL_SELL;

   return ENTRY_SIGNAL_NONE;
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
int CIchimokuScanBot::SignalToInt(ENUM_ENTRY_SIGNAL signal, int additional = 0)
  {
   switch(signal)
     {
      case ENTRY_SIGNAL_BUY:
         return 1 + additional;
      case ENTRY_SIGNAL_SELL:
         return -1 - additional;
      default:
         return 0;
     }
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void CIchimokuScanBot::PrepareKumoCloudSizeStats(void)
  {
   const int bufferSize = 104;
   double kumoBuffer[104];
   for(int i = -26; i < bufferSize - 26; i++)
     {
      double sksA = m_CiIchimoku.SenkouSpanA(mShiftIndex);
      double sksB = m_CiIchimoku.SenkouSpanB(mShiftIndex);
      kumoBuffer[i+26] = sksA - sksB;
     }
   CLogNormalSeries<double> mLogSeriesStat(bufferSize);
   mLogSeriesStat.Refresh(kumoBuffer, 0, bufferSize);
   double probs[3];
   probs[0] = 0.33;
   probs[1] = 0.50;
   probs[2] = 0.75;
   mLogSeriesStat.QuantileDistribution(probs, kumoCloudSizeStats);
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
string CIchimokuScanBot::DescribeKumoCloudSize(int index)
  {
   double sksA = m_CiIchimoku.SenkouSpanA(mShiftIndex);
   double sksB = m_CiIchimoku.SenkouSpanB(mShiftIndex);
   double kumoSize = MathAbs(sksA - sksB);
   if(kumoSize < kumoCloudSizeStats[0])
      return "VERY_THIN";

   if(kumoSize >= kumoCloudSizeStats[2])
      return "VERY_THICK";

   if(kumoSize >= kumoCloudSizeStats[0] && kumoSize < kumoCloudSizeStats[1])
      return "VERY_THICK";


   if(kumoSize >= kumoCloudSizeStats[1] && kumoSize < kumoCloudSizeStats[2])
      return "VERY_THICK";

   return "";
  }
//+------------------------------------------------------------------+
