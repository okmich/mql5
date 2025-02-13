//+------------------------------------------------------------------+
//|                             ThomasCarter_18_4HDaily_GBPMAJOR.mq5 |
//|                                    Copyright 2021, Michael Enudi |
//|                                             okmich2002@yahoo.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2021, Michael Enudi"
#property link      "okmich2002@yahoo.com"
#property version   "1.00"

#include <Okmich\Expert\SingleExpert.mqh>
#include <Okmich\Indicators\DoubleMovingAverages.mqh>
#include <Okmich\Indicators\Macd.mqh>
#include <Indicators\Trend.mqh>

//--- input parameters
const ulong EXPERT_MAGIC = 987650018;
//+------------------------------------------------------------------+
//| Input parameters                                                 |
//+------------------------------------------------------------------+
input group "********* Strategy settings *********";
input ENUM_TIMEFRAMES InpTimeframe = PERIOD_H4;             //Timeframe
input ENUM_LONG_SHORT_FLAG InpLongShortFlag = LONG_SHORT;   //Long/Short Flag

input group "********* Strategy settings *********";
input int      InpFastEmaParam=50;
input int      InpSlowEmaParam=100;
input ENUM_MA_TYPE      InpEmaMethod=MA_EMA;
input int      InpFastMACDParam=12;
input int      InpSlowMACDParam=26;
input int      InpSignalMACDParam=9;
input double   InpPsarStepParam=0.2;
input double   InpPsarMaxParam=0.02;
input int      InpTargetPointParam=150;

input group "********* Volume setting **********";
input int InpLotSizeMultiple = 1;                     //Multiple of minimum lot size

input group "********* Position management settings *********";
input ENUM_POSITION_MANAGEMENT InpPostManagmentType = POSITION_MGT_FIXED_ATR_MULTIPLES;  // Type of Position Management Algorithm
input int InpATRPeriod = 14;                          // ATR Period
input double InpStopLossPoints = -1;                  // Stop loss distance in points
input double InpBreakEvenPoints = -1;                 // Points to Break-even
input double InpTrailingOrTpPoints = -1;              // Trailing/Take profit points
input double InpMaxLossAmount = 100.00;               // Maximum allowable loss in dollars
input bool InpScratchBreakEvenFlag = true;            // Enable break-even with scratch profit
input double InpStopLossMultiple = 2;                 // ATR multiple for stop loss
input double InpBreakEvenMultiple = 1;                // ATR multiple for break-even
input double InpTrailingOrTpMultiple = 2;             // ATR multiple for Maximum floating/Take profit


//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
class CStrategyImpl : public CStrategy
  {
private :
   //--- indicator values
   double            mCloseShift1;

   //--- indicator settings
   ENUM_MA_TYPE    mMaMethod;
   int               mFastEmaPeriod, mSlowEmaPeriod, m_MacdShortEmaPeriod, m_MacdLongEmaPeriod, m_MacdSignalPeriod;
   double            mPsarStep, mPsarMax;

   //--- indicators
   CDoubleMovingAverages *m_DblMa;
   CMacd             *m_Macd;
   CiSAR                  mPSar;
   //--- indicator buffer
   double            m_CloseBuffer[];

protected:
   virtual Entry     FindEntry(const double ask, const double bid);

public:
                     CStrategyImpl(string symbol, ENUM_TIMEFRAMES period, int InptVolMultiple,
             int InptShortMa, int InptLongMa, ENUM_MA_TYPE InptMaMethod,
             int InptMacdShort, int InptMacdLong, int InptMacdSignal,
             double InptPsarStep, double InptPsarMax): CStrategy(symbol, period)
     {
      mLotSize = InptVolMultiple*SymbolInfoDouble(_Symbol, SYMBOL_VOLUME_MIN);

      mFastEmaPeriod = InptShortMa;
      mSlowEmaPeriod = InptLongMa;
      mMaMethod = InptMaMethod;

      m_MacdShortEmaPeriod = InptMacdShort;
      m_MacdLongEmaPeriod = InptMacdLong;
      m_MacdSignalPeriod = InptMacdSignal;

      mPsarStep = InptPsarStep;
      mPsarMax = InptPsarMax;
     };

   virtual bool      Init(ulong magic);
   virtual void      Refresh();
   virtual void      CheckAndSetExitSignal(CPositionInfo &positionInfo, Position &position);
   virtual void      Release();
  };

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
bool CStrategyImpl::Init(ulong magic)
  {
//--- m_DblMa
   m_DblMa = new CDoubleMovingAverages(mSymbol, mTimeframe, mFastEmaPeriod, mSlowEmaPeriod, mMaMethod);
//--- m_Macd
   m_Macd = new CMacd(mSymbol, mTimeframe, m_MacdShortEmaPeriod, m_MacdLongEmaPeriod, m_MacdSignalPeriod);
//--- psarsCreated
   bool psarsCreated = mPSar.Create(mSymbol, mTimeframe, mPsarStep, mPsarMax);

//--- price buffers
   ArraySetAsSeries(m_CloseBuffer, true);

   return m_DblMa.Init() && m_Macd.Init() && psarsCreated;
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void CStrategyImpl::Release(void)
  {
   m_DblMa.Release();
   mPSar.FullRelease();
   m_Macd.Release();
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void CStrategyImpl::Refresh(void)
  {
   int barsToCopy = 4;
//--- Check for new bar
   if(IsNewBar())
     {
      //-- m_DblMa
      m_DblMa.Refresh();
      //-- m_Macd
      m_Macd.Refresh();
      //-- mPSar
      mPSar.Refresh();
      //--- price buffers
      int closeBarsCopied = CopyClose(mSymbol, mTimeframe, 0, barsToCopy, m_CloseBuffer);
     }
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
Entry CStrategyImpl::FindEntry(const double ask, const double bid)
  {
   Entry entry = noEntry();

   if(!mIsNewBar)
      return entry;

   return entry;
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void CStrategyImpl::CheckAndSetExitSignal(CPositionInfo &positionInfo,Position &position)
  {
   if(!mIsNewBar)
      return;

   ENUM_POSITION_TYPE postType = positionInfo.PositionType();
  }

// the expert to run our strategy
CSingleExpert singleExpert(EXPERT_MAGIC, "");

//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+
int OnInit()
  {
   CStrategy *strategy = new CStrategyImpl(_Symbol, InpTimeframe, InpLotSizeMultiple,
                                InpFastEmaParam, InpSlowEmaParam, InpEmaMethod,
                                InpFastMACDParam, InpSlowMACDParam, InpSignalMACDParam,
                                InpPsarStepParam, InpPsarMaxParam);
   CPositionManager *mPositionManager = CreatPositionManager(_Symbol, InpTimeframe,
                                        InpPostManagmentType,
                                        InpATRPeriod, InpStopLossPoints, InpBreakEvenPoints, InpTrailingOrTpPoints,
                                        InpMaxLossAmount, InpScratchBreakEvenFlag, false, 5,
                                        InpStopLossMultiple, InpBreakEvenMultiple, InpTrailingOrTpMultiple);
   strategy.SetPositionManager(mPositionManager);

   singleExpert.SetStrategyImpl(strategy);
   if(singleExpert.OnInitHandler())
      return INIT_SUCCEEDED ;
   else
      return INIT_FAILED;
  }
  
//+------------------------------------------------------------------+
//| Expert deinitialization function                                 |
//+------------------------------------------------------------------+
void OnDeinit(const int reason)
  {
   singleExpert.OnDeinitHandler();
  }
  
//+------------------------------------------------------------------+
//| Expert tick function                                             |
//+------------------------------------------------------------------+
void OnTick()
  {
   singleExpert.OnTickHandler();
  }
//+------------------------------------------------------------------+
