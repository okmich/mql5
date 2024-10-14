//+------------------------------------------------------------------+
//|                                   CRankedBollingerBandsWidth.mqh |
//|                                    Copyright 2022, Michael Enudi |
//|                                             okmich2002@yahoo.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2022, Michael Enudi"
#property link      "okmich2002@yahoo.com"
#property version   "1.00"

#include "BaseIndicator.mqh"
#include <Okmich\Common\Common.mqh>

enum ENUM_RBBW_Strategies
  {
   RBBW_Above_Level, //Value is above Predefined level
   RBBW_Below_Level, //Value is below Predefined level
   RBBW_Ascending,   //Value is rising
   RBBW_Descending   //Value is dropping
  };

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
class CRankedBBandsWidth : public CBaseIndicator
  {
private :
   //--- indicator paramter
   int                m_MaPeriod, m_RankPeriod, m_Level;
   double             m_Deviation;
   //--- indicator
   int                m_Handle;
   //--- indicator buffer
   double             m_Buffer[];
   //--- other variables

public:
                     CRankedBBandsWidth(string symbol, ENUM_TIMEFRAMES period,
                int InputMaPeriod, double InputDeviation, int InputRankPeriod,
                int InputLevel): CBaseIndicator(symbol, period)
     {
      m_MaPeriod = InputMaPeriod;
      m_Deviation = InputDeviation;
      m_Level = InputLevel;
      m_RankPeriod = InputRankPeriod;
     }

   virtual bool       Init();
   virtual bool       Refresh(int ShiftToUse=1);
   virtual void       Release();

   double             ValueAt(int shift=1);

   bool               TradeFilter(ENUM_RBBW_Strategies strategyOption);
  };

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
bool CRankedBBandsWidth::Init(void)
  {
   ArraySetAsSeries(m_Buffer, true);

   m_Handle = iCustom(m_Symbol, m_TF, "Okmich\\Ranked Bollinger Bands Width",
                      m_MaPeriod, 0, m_Deviation, m_RankPeriod);

   return m_Handle != INVALID_HANDLE;
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void CRankedBBandsWidth::Release(void)
  {
   IndicatorRelease(m_Handle);
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
bool CRankedBBandsWidth::Refresh(int ShiftToUse=1)
  {
   m_ShiftToUse = ShiftToUse;
   int copied = CopyBuffer(m_Handle, 0, 0, 5, m_Buffer);

   return copied == 5;
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
double CRankedBBandsWidth::ValueAt(int shift=1)
  {
   if(shift >= 5)
      return EMPTY_VALUE;

   return m_Buffer[shift];
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
bool CRankedBBandsWidth::TradeFilter(ENUM_RBBW_Strategies strategyOption)
  {
   double value = ValueAt(m_ShiftToUse);
   switch(strategyOption)
     {
      case RBBW_Above_Level:
         return value > m_Level;
      case RBBW_Below_Level:
         return value < m_Level;
      case RBBW_Ascending:
         return value > ValueAt(m_ShiftToUse+1);
      case RBBW_Descending:
         return value < ValueAt(m_ShiftToUse+1);
      default:
         return false;
     }
  }
//+------------------------------------------------------------------+
