//+------------------------------------------------------------------+
//|                                                  BBWidthRank.mqh |
//|                                    Copyright 2022, Michael Enudi |
//|                                             okmich2002@yahoo.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2022, Michael Enudi"
#property link      "okmich2002@yahoo.com"
#property version   "1.00"

#include "BaseIndicator.mqh"
#include <Okmich\Common\Common.mqh>

enum ENUM_BBRW_Filter_Type
  {
   BBRW_Above,  //Above level
   BBRW_Below   //Below level
  };

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
class CBBWidthRank : public CBaseIndicator
  {
private :
   int                mBarsToCopy;
   //--- indicator paramter
   int                m_MaPeriod, m_RankPeriod, m_Threshold;
   double             m_Deviation;
   //--- indicator
   int                m_Handle;
   //--- indicator buffer
   double             m_Buffer[];
   //--- other variables

public:
                     CBBWidthRank(string symbol, ENUM_TIMEFRAMES period,
                int InputMaPeriod=20, double InputDeviation=2.0,
                int InputRankSqueezePeriod=126, int InputThreshold=50, int historyBars=10): CBaseIndicator(symbol, period)
     {
      m_MaPeriod = InputMaPeriod;
      m_Deviation = InputDeviation;
      m_RankPeriod = InputRankSqueezePeriod;
      m_Threshold = InputThreshold;

      mBarsToCopy = historyBars;
     }

   virtual bool        Init();
   virtual bool        Refresh(int ShiftToUse=1);
   virtual void        Release();

   double              GetData(int shift=0);
   void                GetData(double &buffer[], int shift=0);

   double              RankedSqueeze(int shift=1);

   bool                Filter(ENUM_BBRW_Filter_Type filterType);
  };

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
bool CBBWidthRank::Init(void)
  {
   ArraySetAsSeries(m_Buffer, true);
   m_Handle = iCustom(m_Symbol, m_TF, "Okmich\\Ranked Bollinger Bands Width", m_MaPeriod, 0, m_Deviation, m_RankPeriod);
   return m_Handle != INVALID_HANDLE;
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void CBBWidthRank::Release(void)
  {
   IndicatorRelease(m_Handle);
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
bool CBBWidthRank::Refresh(int ShiftToUse=1)
  {
   m_ShiftToUse = ShiftToUse;
   int copied = CopyBuffer(m_Handle, 0, 0, mBarsToCopy, m_Buffer);

   return copied == mBarsToCopy;
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
double CBBWidthRank::GetData(int shift=0)
  {
   if(shift >= mBarsToCopy)
      return EMPTY_VALUE;

   return m_Buffer[shift];
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void CBBWidthRank::GetData(double &buffer[], int shift=0)
  {
   if(shift >= mBarsToCopy)
      return;

   ArraySetAsSeries(buffer, true);
   ArrayResize(buffer, mBarsToCopy - shift);

   ArrayCopy(buffer, m_Buffer, 0, shift);
  }


//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
double CBBWidthRank::RankedSqueeze(int shift=1)
  {
   return GetData(shift);
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
bool CBBWidthRank::Filter(ENUM_BBRW_Filter_Type filterType)
  {
   double currValue = RankedSqueeze(m_ShiftToUse);
   switch(filterType)
     {
      case BBRW_Above:
         return currValue > m_Threshold;
      case BBRW_Below:
         return currValue < m_Threshold;
      default:
         return false;
     }
  }
//+------------------------------------------------------------------+
