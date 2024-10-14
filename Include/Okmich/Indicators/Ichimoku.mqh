//+------------------------------------------------------------------+
//|                                                     Ichimoku.mqh |
//|                                    Copyright 2020, Michael Enudi |
//|                                             okmich2002@yahoo.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2020, Michael Enudi"
#property link      "okmich2002@yahoo.com"
#property version   "1.00"

#include "BaseIndicator.mqh"
#include <Indicators\Trend.mqh>

enum ENUM_ICHIMOKU_Strategies
  {
   ICHIMOKU_TenkanSen_Kijunsen_state,
   ICHIMOKU_Price_Kumo_state,
   ICHIMOKU_Price_Kijunsen_state,
   ICHIMOKU_Price_TenkanSen_state,
   ICHIMOKU_Chikou_Kumo_state,
   ICHIMOKU_Chikou_Price_state,
   ICHIMOKU_Chikou_HHLL_state,
   ICHIMOKU_Future_Kumo_state,
   ICHIMOKU_Current_Kumo_state,
   ICHIMOKU_Kijunsen_slope,
   ICHIMOKU_TenkanSen_slope
  };

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
class CIchimoku : public CBaseIndicator
  {
private :
   int               mBarsToCopy;
   //--- indicator paramter
   int                m_TenkanSen;
   int                m_KijunSen;
   int                m_SenkouSpanB;
   //--- indicator
   CiIchimoku         m_CiIchimoku;
   //--- indicator buffers
   double            ssaBuffer[];
   double            ssbBuffer[];
   //-- others
   double            mClosePrice;
   double            tenkanSen, kijunSen;
   double            senkouSpanA, senkouSpanB;
   double            futureSenkouSpanA, futureSenkouSpanB;
   double            chinkouSpan;
   double            previousTenkanSen, previousKijunSen;
   double            ftSSBShift1;
   int               ftSSBSlope;

   ENUM_ENTRY_SIGNAL tenkanKijunStatus, kijunSenPriceStatus, tenkanSenPriceStatus;
   ENUM_ENTRY_SIGNAL currKumoStatus, fwdKumoStatus;
   ENUM_ENTRY_SIGNAL tenkanSenSlope, kijunSlope;

   ENUM_ENTRY_SIGNAL GetTenkanSenSlope() {return tenkanSenSlope;};
   ENUM_ENTRY_SIGNAL GetKijunsenSlope() {return kijunSlope;};
   ENUM_ENTRY_SIGNAL GetKumo() {return currKumoStatus;};

   ENUM_ENTRY_SIGNAL GetTenkanKijunStatus() { return tenkanKijunStatus; };
   ENUM_ENTRY_SIGNAL GetPriceKumoStatus();
   ENUM_ENTRY_SIGNAL GetKijunPriceStatus() { return kijunSenPriceStatus; };
   ENUM_ENTRY_SIGNAL GetPriceTenkenSenStatus() { return tenkanSenPriceStatus; };
   ENUM_ENTRY_SIGNAL GetChikouKumoStatus();
   ENUM_ENTRY_SIGNAL GetChikouPriceStatus();
   ENUM_ENTRY_SIGNAL GetChikouHHLLStatus();
   ENUM_ENTRY_SIGNAL GetFutureKumo() {return fwdKumoStatus;};

   bool              IsFtKumoConverging();

public:
                     CIchimoku(string symbol, ENUM_TIMEFRAMES period, int InpTenkanSen=9,
             int InpKijunSen=26, int InpSenkouSpanB=52): CBaseIndicator(symbol, period)
     {
      m_TenkanSen = InpTenkanSen;
      m_KijunSen = InpKijunSen;
      m_SenkouSpanB = InpSenkouSpanB;
      mBarsToCopy = 52;
     }

   virtual bool      Init();
   virtual bool      Refresh(int ShiftToUse=1);
   virtual void      Release();

   double            GetData(int bufferIndx=0, int shift=0);

   int               SignalStrength(ENUM_ENTRY_SIGNAL signal); //1=>Strong. 0=>Neutral, -1=>Weak
   ENUM_ENTRY_SIGNAL TradeSignal(ENUM_ICHIMOKU_Strategies entryOption);
  };

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
bool CIchimoku::Init(void)
  {
   ArraySetAsSeries(ssaBuffer, true);
   ArraySetAsSeries(ssbBuffer, true);
   return m_CiIchimoku.Create(m_Symbol, m_TF, m_TenkanSen, m_KijunSen, m_SenkouSpanB);
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
bool CIchimoku::Refresh(int ShiftToUse=1)
  {
   m_ShiftToUse = ShiftToUse;
   m_CiIchimoku.Refresh();

//--- copy data from buffers
   tenkanSen = m_CiIchimoku.TenkanSen(m_ShiftToUse);
   kijunSen =  m_CiIchimoku.KijunSen(m_ShiftToUse);
   senkouSpanA = m_CiIchimoku.SenkouSpanA(m_ShiftToUse);
   senkouSpanB = m_CiIchimoku.SenkouSpanB(m_ShiftToUse);
   futureSenkouSpanA = m_CiIchimoku.SenkouSpanA(m_ShiftToUse-m_KijunSen);
   futureSenkouSpanB = m_CiIchimoku.SenkouSpanB(m_ShiftToUse-m_KijunSen);
   chinkouSpan = m_CiIchimoku.ChinkouSpan(m_ShiftToUse+m_KijunSen);

//-- derived indices
   currKumoStatus = senkouSpanA > senkouSpanB ? ENTRY_SIGNAL_BUY :
                    senkouSpanB > senkouSpanA ? ENTRY_SIGNAL_SELL : ENTRY_SIGNAL_NONE;
   fwdKumoStatus = futureSenkouSpanA > futureSenkouSpanB ? ENTRY_SIGNAL_BUY :
                   futureSenkouSpanB > futureSenkouSpanA ? ENTRY_SIGNAL_SELL : ENTRY_SIGNAL_NONE;
   previousTenkanSen = m_CiIchimoku.TenkanSen(m_ShiftToUse+1);
   previousKijunSen = m_CiIchimoku.KijunSen(m_ShiftToUse+1);
   ftSSBShift1 = m_CiIchimoku.SenkouSpanB(m_ShiftToUse-m_KijunSen+1);
   tenkanSenSlope = (tenkanSen > previousTenkanSen) ? ENTRY_SIGNAL_BUY :
                    (previousTenkanSen > tenkanSen) ? ENTRY_SIGNAL_SELL : ENTRY_SIGNAL_NONE;
   kijunSlope = (kijunSen > previousKijunSen) ? ENTRY_SIGNAL_BUY :
                (previousKijunSen > kijunSen) ? ENTRY_SIGNAL_SELL : ENTRY_SIGNAL_NONE;
   ftSSBSlope = (futureSenkouSpanB > ftSSBShift1) ? ENTRY_SIGNAL_BUY :
                (ftSSBShift1 > futureSenkouSpanB) ? ENTRY_SIGNAL_SELL : ENTRY_SIGNAL_NONE;

//-- status
   tenkanKijunStatus = (tenkanSen >= kijunSen) ? ENTRY_SIGNAL_BUY :
                       (tenkanSen <= kijunSen) ? ENTRY_SIGNAL_SELL : ENTRY_SIGNAL_NONE;
   kijunSenPriceStatus = (mClosePrice > kijunSen) ? ENTRY_SIGNAL_BUY :
                         (mClosePrice < kijunSen) ? ENTRY_SIGNAL_SELL : ENTRY_SIGNAL_NONE;
   tenkanSenPriceStatus = (mClosePrice > tenkanSen) ? ENTRY_SIGNAL_BUY :
                          (mClosePrice < tenkanSen) ? ENTRY_SIGNAL_SELL : ENTRY_SIGNAL_NONE;
//-- price
   mClosePrice = iClose(m_Symbol, m_TF, m_ShiftToUse);

   return true;
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void CIchimoku::Release(void)
  {
   m_CiIchimoku.FullRelease();
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
double CIchimoku::GetData(int bufferIndx=0, int shift=0)
  {
   if(shift >= mBarsToCopy || bufferIndx > 4)
      return EMPTY_VALUE;

   switch(bufferIndx)
     {
      case 0:
         return m_CiIchimoku.TenkanSen(shift);
      case 1:
         return m_CiIchimoku.KijunSen(shift);
      case 2:
         return m_CiIchimoku.SenkouSpanA(shift);
      case 3:
         return m_CiIchimoku.SenkouSpanB(shift);
      case 4:
         return m_CiIchimoku.ChinkouSpan(shift);
      default:
         return EMPTY_VALUE;
     }

  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
ENUM_ENTRY_SIGNAL CIchimoku::GetPriceKumoStatus()
  {
   if(currKumoStatus == ENTRY_SIGNAL_BUY && mClosePrice > senkouSpanA)
      return ENTRY_SIGNAL_BUY;
   else
      if(currKumoStatus == ENTRY_SIGNAL_SELL && mClosePrice < senkouSpanA)
         return ENTRY_SIGNAL_SELL;
      else
         return ENTRY_SIGNAL_NONE;
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
ENUM_ENTRY_SIGNAL CIchimoku::GetChikouKumoStatus()
  {
   int shift = m_ShiftToUse+m_KijunSen; //1 + 26
   double ssA = m_CiIchimoku.SenkouSpanA(shift);
   double ssB = m_CiIchimoku.SenkouSpanB(shift);

   double upLimit = MathMax(ssA, ssB);
   if(chinkouSpan > upLimit)
      return ENTRY_SIGNAL_BUY;

   double downLimit = MathMin(ssA, ssB);
   if(chinkouSpan < downLimit)
      return ENTRY_SIGNAL_SELL;

   return ENTRY_SIGNAL_NONE;
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
ENUM_ENTRY_SIGNAL CIchimoku::GetChikouPriceStatus()
  {
   int shift = m_ShiftToUse+m_KijunSen+1;
   double prices[];
   ArraySetAsSeries(prices, true);

   if(currKumoStatus == ENTRY_SIGNAL_BUY)
     {
      CopyHigh(m_Symbol, m_TF, shift, 10, prices);
      int maxArg = ArrayMaximum(prices);
      if(maxArg > -1 && chinkouSpan > prices[maxArg])
         return ENTRY_SIGNAL_BUY;
     }
   else
      if(currKumoStatus == ENTRY_SIGNAL_SELL)
        {
         CopyLow(m_Symbol, m_TF, shift, 10, prices);
         int minArg = ArrayMinimum(prices);
         if(minArg > -1 && chinkouSpan < prices[minArg])
            return ENTRY_SIGNAL_SELL;
        }

   return ENTRY_SIGNAL_NONE;
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
ENUM_ENTRY_SIGNAL CIchimoku::GetChikouHHLLStatus()
  {
   int shift=m_ShiftToUse+m_KijunSen+1;
   ENUM_ENTRY_SIGNAL tenKanSenKijunState = GetTenkanKijunStatus();

   double chikou[];
   ArraySetAsSeries(chikou, true);
   m_CiIchimoku.GetData(shift, m_ShiftToUse+m_KijunSen, 4, chikou);
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
bool CIchimoku::IsFtKumoConverging(void)
  {
   double ftKumoWidth1 = MathAbs(futureSenkouSpanA - futureSenkouSpanB);
   double ftKumoWidth2 = MathAbs(m_CiIchimoku.SenkouSpanA(m_ShiftToUse-m_KijunSen+1) - m_CiIchimoku.SenkouSpanB(m_ShiftToUse-m_KijunSen+1));
   double ftKumoWidth3 = MathAbs(m_CiIchimoku.SenkouSpanA(m_ShiftToUse-m_KijunSen+2) - m_CiIchimoku.SenkouSpanB(m_ShiftToUse-m_KijunSen+2));

   return ftKumoWidth1 < ftKumoWidth2 < ftKumoWidth3;
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
ENUM_ENTRY_SIGNAL CIchimoku::TradeSignal(ENUM_ICHIMOKU_Strategies entryOption)
  {
   switch(entryOption)
     {
      case ICHIMOKU_Chikou_HHLL_state:
         return GetChikouHHLLStatus();
      case ICHIMOKU_Chikou_Kumo_state:
         return GetChikouKumoStatus();
      case ICHIMOKU_Chikou_Price_state:
         return GetChikouPriceStatus();
      case ICHIMOKU_Current_Kumo_state:
         return GetKumo();
      case ICHIMOKU_Future_Kumo_state:
         return GetFutureKumo();
      case ICHIMOKU_Kijunsen_slope:
         return GetKijunsenSlope();
      case ICHIMOKU_Price_Kijunsen_state:
         return GetKijunPriceStatus();
      case ICHIMOKU_Price_Kumo_state:
         return GetPriceKumoStatus();
      case ICHIMOKU_Price_TenkanSen_state:
         return GetPriceTenkenSenStatus();
      case ICHIMOKU_TenkanSen_Kijunsen_state:
         return GetTenkanKijunStatus();
      case ICHIMOKU_TenkanSen_slope:
         return GetTenkanSenSlope();
      default:
         return ENTRY_SIGNAL_NONE;
     }
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
int CIchimoku::SignalStrength(ENUM_ENTRY_SIGNAL signal)
  {
   
   switch(signal)
     {
      case ENTRY_SIGNAL_BUY:
        {
         double kumoTopEdge = MathMax(senkouSpanA, senkouSpanB);
         return tenkanSen > kumoTopEdge ? 1 :
                tenkanSen < kumoTopEdge ? -1 : 0;
        }
      case ENTRY_SIGNAL_SELL:
        {
         double kumoBottomEdge = MathMin(senkouSpanA, senkouSpanB);
         return tenkanSen > kumoBottomEdge ? 1 :
                tenkanSen < kumoBottomEdge ? -1 : 0;
        }
      default:
         return 0;
     }
  }
//+------------------------------------------------------------------+
//+------------------------------------------------------------------+
