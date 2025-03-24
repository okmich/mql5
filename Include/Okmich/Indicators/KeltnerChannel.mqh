//+------------------------------------------------------------------+
//|                                               KeltnerChannel.mqh |
//|                                    Copyright 2024, Michael Enudi |
//|                                             okmich2002@yahoo.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2024, Michael Enudi"
#property link      "okmich2002@yahoo.com"

#include "BaseIndicator.mqh"

enum ENUM_KTC_Strategy
  {
   KTC_Breakout,   //Channel Breakout
   KTC_PullBack,   //Pullback
  };

enum ENUM_KTC_FILTER
  {
   KTC_FILTER_ABOVE_BELOW_BAND,     //Above/Below Bands
   KTC_FILTER_ABOVE_BELOW_BAND_2,   //Above/Below Extreme Bands
   KTC_FILTER_ABOVE_BELOW_MA,       //Above/Below MA
   KTC_FILTER_SAME_BANDS_SLOPE,     //Bands Slope
  };

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
class CKeltnerChannel : public CBaseIndicator
  {
private :
   int                mBarsToCopy;
   //--- indicator paramter
   int                mMaPeriod, mSlopePeriod;
   double             mAtrMultiplier;
   ENUM_MA_TYPE       mMaType;
   ENUM_APPLIED_PRICE mAppliedPrice;
   //--- indicator
   int                m_Handle;
   //--- indicator buffer
   double             m_MaBuffer[], m_TopBuffer[], m_BottomBuffer[];

   ENUM_ENTRY_SIGNAL  BreakOutSignal(int shift=1);
   ENUM_ENTRY_SIGNAL  ObOsSignal(int shift=1);
   ENUM_ENTRY_SIGNAL  PullBackSignal(int shift=1);

   ENUM_ENTRY_SIGNAL  AboveBelowBandFilter(int shift=1);
   int                BandsSlopes(int shift=1);

public:
                     CKeltnerChannel(string symbol, ENUM_TIMEFRAMES period,
                   int InputMaPeriod=20, ENUM_MA_TYPE InputMaType=MA_TYPE_EMA, double InputAtrMultiplier=2.0,
                   ENUM_APPLIED_PRICE InputAppliedPrice=PRICE_CLOSE, int InputBarsToCopy=4,
                   int InputSlopePeriod=4): CBaseIndicator(symbol, period)
     {
      mMaPeriod = InputMaPeriod;
      mMaType = InputMaType;
      mAtrMultiplier = InputAtrMultiplier;
      mAppliedPrice = InputAppliedPrice;
      mSlopePeriod = InputSlopePeriod;
      mBarsToCopy = InputBarsToCopy+1;
     }

   virtual bool       Init();
   virtual bool       Refresh(int ShiftToUse=1);
   virtual void       Release();

   double             GetData(int bufferIndx, int shift=1);
   void               GetData(int bufferIndx, double &buffer[], int shift);

   ENUM_ENTRY_SIGNAL  TradeSignal(ENUM_KTC_Strategy signalStrategy);
   ENUM_ENTRY_SIGNAL  TradeFilter(ENUM_KTC_FILTER filterType);

   ENUM_ENTRY_SIGNAL  AboveBelowExtremeBandFilter(ENUM_ENTRY_SIGNAL currentFilterState, int shift=1);
  };

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
bool CKeltnerChannel::Init(void)
  {
   ArraySetAsSeries(m_TopBuffer, true);
   ArraySetAsSeries(m_MaBuffer, true);
   ArraySetAsSeries(m_BottomBuffer, true);
   m_Handle = iCustom(m_Symbol, m_TF, "Okmich\\Keltner Channel", mMaPeriod, mAtrMultiplier, mMaType, mAppliedPrice);

   return m_Handle != INVALID_HANDLE;
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
bool CKeltnerChannel::Refresh(int ShiftToUse=1)
  {
   m_ShiftToUse = ShiftToUse;
   int topCopied = CopyBuffer(m_Handle, 0, 0, mBarsToCopy, m_TopBuffer);
   int maCopied = CopyBuffer(m_Handle, 1, 0, mBarsToCopy, m_MaBuffer);
   int bottomCopied = CopyBuffer(m_Handle, 2, 0, mBarsToCopy, m_BottomBuffer);

   return mBarsToCopy == topCopied && topCopied == maCopied && maCopied == bottomCopied;
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void CKeltnerChannel::Release(void)
  {
   IndicatorRelease(m_Handle);
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
double CKeltnerChannel::GetData(int bufferIndx, int shift=1)
  {
   if(bufferIndx > 1 || shift >= mBarsToCopy)
      return EMPTY_VALUE;

   if(bufferIndx ==0)
      return m_TopBuffer[shift];
   else
      if(bufferIndx == 1)
         return m_MaBuffer[shift];
      else
         if(bufferIndx == 2)
            return m_BottomBuffer[shift];
         else
            return EMPTY_VALUE;
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void CKeltnerChannel::GetData(int bufferIndx, double &buffer[], int shift)
  {
   if(bufferIndx > 1 || shift >= mBarsToCopy)
      return;

   ArraySetAsSeries(buffer, true);
   ArrayResize(buffer, mBarsToCopy - shift);

   if(bufferIndx == 0)
      ArrayCopy(buffer, m_TopBuffer, 0, shift);
   else
      if(bufferIndx == 1)
         ArrayCopy(buffer, m_MaBuffer, 0, shift);
      else
         if(bufferIndx == 2)
            ArrayCopy(buffer, m_BottomBuffer, 0, shift);
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
ENUM_ENTRY_SIGNAL CKeltnerChannel::BreakOutSignal(int shift=1)
  {
   double closeShift1 = iClose(m_Symbol, m_TF, shift+1);
   double closeShift = iClose(m_Symbol, m_TF, shift);
//go long if price crosses the upper band,
   if(m_TopBuffer[shift+1] > closeShift1 && m_TopBuffer[shift] < closeShift)
      return ENTRY_SIGNAL_BUY;
//go short if price crosses the lower band,
   if(m_BottomBuffer[shift+1] < closeShift1 && m_BottomBuffer[shift] > closeShift)
      return ENTRY_SIGNAL_SELL;

   return ENTRY_SIGNAL_NONE;
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
int CKeltnerChannel::BandsSlopes(int shift=1)
  {
   double topBandSlope = RegressionSlope(m_TopBuffer, mSlopePeriod, shift);
   double maBandSlope = RegressionSlope(m_MaBuffer, mSlopePeriod, shift);
   double bottomBandSlope = RegressionSlope(m_BottomBuffer, mSlopePeriod, shift);

   if(topBandSlope > 0 && maBandSlope > 0 && bottomBandSlope > 0)
      return 1;
   else
      if(topBandSlope < 0 && maBandSlope < 0 && bottomBandSlope < 0)
         return -1;
      else
         return 0;
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
ENUM_ENTRY_SIGNAL CKeltnerChannel::ObOsSignal(int shift=1)
  {
   int allBandSlope = BandsSlopes(shift);

   double closeShift1 = iClose(m_Symbol, m_TF, shift+1);
   double closeShift = iClose(m_Symbol, m_TF, shift);

//go long when we break the lower band from above
   if(allBandSlope == 1 &&
      m_BottomBuffer[shift+1] < closeShift1 && m_BottomBuffer[shift] > closeShift)
      return ENTRY_SIGNAL_BUY;
   else
      //go short when we pullback from the middle band from above it
      if(allBandSlope == -1 &&
         m_TopBuffer[shift+1] > closeShift1 && m_TopBuffer[shift] < closeShift)
         return ENTRY_SIGNAL_SELL;

   return ENTRY_SIGNAL_NONE;
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
ENUM_ENTRY_SIGNAL CKeltnerChannel::PullBackSignal(int shift=1)
  {
   int allBandSlope = BandsSlopes(shift);

   double closeShift1 = iClose(m_Symbol, m_TF, shift+1);
   double closeShift = iClose(m_Symbol, m_TF, shift);

//go long when we pullback from the middle band from below it
   if(allBandSlope == 1 &&
      m_MaBuffer[shift+1] > closeShift1 && m_MaBuffer[shift] < closeShift)
      return ENTRY_SIGNAL_BUY;
   else
      //go short when we pullback from the middle band from above it
      if(allBandSlope == -1 &&
         m_MaBuffer[shift+1] < closeShift1 && m_MaBuffer[shift] > closeShift)
         return ENTRY_SIGNAL_SELL;

   return ENTRY_SIGNAL_NONE;
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
ENUM_ENTRY_SIGNAL CKeltnerChannel::AboveBelowBandFilter(int shift=1)
  {
   double closeShift = iClose(m_Symbol, m_TF, shift);
   double topShift = m_TopBuffer[shift];
   double bottomShift = m_BottomBuffer[shift];
//go long if price is above the upper band,
   if(closeShift > m_TopBuffer[shift])
      return ENTRY_SIGNAL_BUY;
//go short if price is below the lower band,
   if(closeShift < m_BottomBuffer[shift])
      return ENTRY_SIGNAL_SELL;

   return ENTRY_SIGNAL_NONE;
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
ENUM_ENTRY_SIGNAL CKeltnerChannel::AboveBelowExtremeBandFilter(ENUM_ENTRY_SIGNAL currentFilterState,int shift=1)
  {
   double closeShift = iClose(m_Symbol, m_TF, shift);
   double topBand = m_TopBuffer[shift];
   double bottomBand = m_BottomBuffer[shift];
   if(closeShift > bottomBand && currentFilterState == ENTRY_SIGNAL_BUY)
      return ENTRY_SIGNAL_BUY;
   if(closeShift < topBand && currentFilterState == ENTRY_SIGNAL_SELL)
      return ENTRY_SIGNAL_SELL;

   return ENTRY_SIGNAL_NONE;
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
ENUM_ENTRY_SIGNAL CKeltnerChannel::TradeSignal(ENUM_KTC_Strategy signalStrategy)
  {
   switch(signalStrategy)
     {
      case KTC_Breakout:
         return BreakOutSignal(m_ShiftToUse);
      case KTC_PullBack :
         return PullBackSignal(m_ShiftToUse);
      default:
         return ENTRY_SIGNAL_NONE;
     }
  }


//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
ENUM_ENTRY_SIGNAL CKeltnerChannel::TradeFilter(ENUM_KTC_FILTER filterType)
  {
   double closeShift = iClose(m_Symbol, m_TF, m_ShiftToUse);
   switch(filterType)
     {
      case KTC_FILTER_ABOVE_BELOW_BAND:
         return AboveBelowBandFilter(m_ShiftToUse);
      case KTC_FILTER_ABOVE_BELOW_BAND_2:
         return AboveBelowBandFilter(m_ShiftToUse);
      case KTC_FILTER_ABOVE_BELOW_MA:
         return closeShift > m_MaBuffer[m_ShiftToUse] ? ENTRY_SIGNAL_BUY :
                closeShift < m_MaBuffer[m_ShiftToUse] ? ENTRY_SIGNAL_SELL :
                ENTRY_SIGNAL_NONE;
      case KTC_FILTER_SAME_BANDS_SLOPE:
      default:
         return ENTRY_SIGNAL_NONE;
     }
  }
//+------------------------------------------------------------------+
