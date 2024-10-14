//+------------------------------------------------------------------+
//|                                              AdxmVhfAdaptive.mqh |
//|                                                    Michael Enudi |
//|                                             okmich2002@yahoo.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2022, Michael Enudi"
#property link      "okmich2002@yahoo.com"
#property version   "1.00"

#include "BaseIndicator.mqh"


enum ENUM_ADXM_Strategies
  {
   ADXM_MidLineCross,
   ADXM_OnOuterLevels,
   ADXM_AdxmSlope
  };

enum enLevelType
  {
   lvl_floa,  // Floating levels
   lvl_quan   // Quantile levels
  };

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
class CADXm : public CBaseIndicator
  {
private :
   int                mBarsToCopy;
   //--- indicator paramter
   int                m_Period, m_SmoothingPeriod, m_LevelPeriod, m_UpLevel;
   enLevelType        m_LevelType;
   bool               m_UseAdaptiveAdxm;
   ENUM_MA_METHOD     m_SmoothingMethod;
   //--- indicator
   int                m_Handle;
   //--- indicator buffer
   double             mAdxmBuffer[];
   double             mTopBuffer[], mMidBuffer[], mBottomBuffer[];

   ENUM_ENTRY_SIGNAL  AdxmSlope();
   ENUM_ENTRY_SIGNAL  MidLineCross();
   ENUM_ENTRY_SIGNAL  OuterLevelCross();

public:
                     CADXm(string symbol, ENUM_TIMEFRAMES period, int InputPeriod=14,
         int InputSmoothingPeriod=9, bool InputUseAdaptiveAdxm=false, ENUM_MA_METHOD InputSmoothingMethod=MODE_LWMA,
         int InputLevelPeriod=25, int InputUpLevel=90, enLevelType inputLevelType=lvl_floa): CBaseIndicator(symbol, period)
     {
      m_Period = InputPeriod;
      m_SmoothingPeriod = InputSmoothingPeriod;
      m_UseAdaptiveAdxm = InputUseAdaptiveAdxm;
      m_SmoothingMethod = InputSmoothingMethod;
      m_LevelPeriod = InputLevelPeriod;
      m_UpLevel = InputUpLevel;
      m_LevelType = inputLevelType;

      mBarsToCopy = m_LevelPeriod;
     }

   virtual bool       Init();
   virtual bool       Refresh(int ShiftToUse=1);
   virtual void       Release();

   double             GetData(int buffer=0, int shift=0);
   void               GetData(double &buffer[], int buffer=0, int shift=0);

   ENUM_TRENDSTATE    TrendState();
   bool               IsTrending();
   ENUM_ENTRY_SIGNAL  TradeSignal(ENUM_ADXM_Strategies strategyOption);
  };

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
bool CADXm::Init(void)
  {
   ArraySetAsSeries(mAdxmBuffer, true);
   ArraySetAsSeries(mTopBuffer, true);
   ArraySetAsSeries(mBottomBuffer, true);
   ArraySetAsSeries(mMidBuffer, true);

   m_Handle = iCustom(m_Symbol, m_TF, "Articles\\ADXm (VHF Adaptive)", 0,
                      m_Period, 0, 2, 3, m_UseAdaptiveAdxm, m_SmoothingPeriod, 
                      m_SmoothingMethod,  m_LevelPeriod, m_UpLevel, 100-m_UpLevel,
                      m_LevelType, 0, true);

   return m_Handle != INVALID_HANDLE;
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
bool CADXm::Refresh(int ShiftToUse=1)
  {
   m_ShiftToUse = ShiftToUse;
   int adxCopied = CopyBuffer(m_Handle, 5, 0, mBarsToCopy, mAdxmBuffer);
   int tCopied = CopyBuffer(m_Handle, 2, 0, mBarsToCopy, mTopBuffer);
   int bCopied = CopyBuffer(m_Handle, 3, 0, mBarsToCopy, mBottomBuffer);
   int mopied = CopyBuffer(m_Handle, 4, 0, mBarsToCopy, mMidBuffer);

   return mBarsToCopy == adxCopied && adxCopied == tCopied && tCopied == bCopied && bCopied == mopied;
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void CADXm::Release(void)
  {
   IndicatorRelease(m_Handle);
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
double CADXm::GetData(int bufferIndx=0, int shift=0)
  {
   if(shift >= mBarsToCopy || bufferIndx > 3)
      return EMPTY_VALUE;

   switch(bufferIndx)
     {
      case 0:
         return mAdxmBuffer[shift];
      case 1:
         return mTopBuffer[shift];
      case 2:
         return mMidBuffer[shift];
      case 3:
         return mBottomBuffer[shift];
      default:
         return EMPTY_VALUE;
     }
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void CADXm::GetData(double &buffer[], int bufferIndx=0, int shift=0)
  {
   if(shift >= mBarsToCopy || bufferIndx > 3)
      return;

   ArraySetAsSeries(buffer, true);
   ArrayResize(buffer, mBarsToCopy - shift);

   switch(bufferIndx)
     {
      case 0:
         ArrayCopy(buffer, mAdxmBuffer, 0, shift);
         break;
      case 1:
         ArrayCopy(buffer, mTopBuffer, 0, shift);
         break;
      case 2:
         ArrayCopy(buffer, mMidBuffer, 0, shift);
         break;
      case 3:
         ArrayCopy(buffer, mBottomBuffer, 0, shift);
         break;
      default:
         break;
     }
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
ENUM_TRENDSTATE CADXm::TrendState()
  {
   return TS_FLAT;
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
bool CADXm::IsTrending(void)
  {
   return TrendState() == TS_TREND;
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
ENUM_ENTRY_SIGNAL CADXm::AdxmSlope(void)
  {
   if(mAdxmBuffer[m_ShiftToUse+1] > mAdxmBuffer[m_ShiftToUse])
      return ENTRY_SIGNAL_SELL;
   else
      if(mAdxmBuffer[m_ShiftToUse+1] < mAdxmBuffer[m_ShiftToUse])
         return ENTRY_SIGNAL_SELL;
         
   return ENTRY_SIGNAL_NONE;
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
ENUM_ENTRY_SIGNAL CADXm::MidLineCross(void)
  {
   if(mAdxmBuffer[m_ShiftToUse+1] < mMidBuffer[m_ShiftToUse+1] && mAdxmBuffer[m_ShiftToUse] > mMidBuffer[m_ShiftToUse])
      return ENTRY_SIGNAL_BUY;
   else
      if(mAdxmBuffer[m_ShiftToUse+1] > mMidBuffer[m_ShiftToUse+1] && mAdxmBuffer[m_ShiftToUse] < mMidBuffer[m_ShiftToUse])
         return ENTRY_SIGNAL_SELL;
      else
         return ENTRY_SIGNAL_NONE;
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
ENUM_ENTRY_SIGNAL CADXm::OuterLevelCross(void)
  {
   if(mAdxmBuffer[m_ShiftToUse+1] < mTopBuffer[m_ShiftToUse+1] && mAdxmBuffer[m_ShiftToUse] > mTopBuffer[m_ShiftToUse])
      return ENTRY_SIGNAL_BUY;
   else
      if(mAdxmBuffer[m_ShiftToUse+1] > mBottomBuffer[m_ShiftToUse+1] && mAdxmBuffer[m_ShiftToUse] < mBottomBuffer[m_ShiftToUse])
         return ENTRY_SIGNAL_SELL;
      else
         return ENTRY_SIGNAL_NONE;
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
ENUM_ENTRY_SIGNAL CADXm::TradeSignal(ENUM_ADXM_Strategies logicOption)
  {
   switch(logicOption)
     {
      case ADXM_AdxmSlope:
         return AdxmSlope();
      case ADXM_MidLineCross:
         return MidLineCross();
      case ADXM_OnOuterLevels:
         return OuterLevelCross();
      default:
         return ENTRY_SIGNAL_NONE;
     }
  }
//+------------------------------------------------------------------+
