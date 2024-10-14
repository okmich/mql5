//+------------------------------------------------------------------+
//|                                ThomasCarter_06_15M301H_MAJOR.mq5 |
//|                                    Copyright 2021, Michael Enudi |
//|                                             okmich2002@yahoo.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2021, Michael Enudi"
#property link      "okmich2002@yahoo.com"
#property version   "1.00"
//--- input parameters
const ulong EXPERT_MAGIC = 98765;
//+------------------------------------------------------------------+
//| Input parameters                                                 |
//+------------------------------------------------------------------+
input int      InpHighLowMaParam=32;
input int      InpShortMaParam=100;
input int      InpLongMaParam=200;
input double   InpPsarStepParam=0.2;
input double   InpPsarMaxParam=0.02;

#include <Indicators\Trend.mqh>
#include <Okmich\Expert\SingleExpert.mqh>
#include <Okmich\Indicators\DoubleMovingAverages.mqh>

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
class CStrategyImpl : public CStrategy
  {
private :
   //--- indicator values
   double            mCloseShift1, mFastMaShift1, mSlowMaShift1, mHighMaShift1, mLowMaShift1, mPsarsShift1;

   //--- indicator settings
   int               mFastMaPeriod, mSlowMaPeriod, mHighLowMaPeriod;
   double            mPsarStep, mPsarMax;

   //--- indicators
   CiMA                 mHighMa, mLowMa;
   CiSAR                mPSar;
   CDoubleMovingAverages *m_DblMa;
   //--- indicator buffer
   double            m_CloseBuffer[];

public:
                     CStrategyImpl(string symbol, ENUM_TIMEFRAMES period,
             int InptShortMaPeriod,int InptLongMaPeriod, int InptHighLowMaPeriod,
             double InptPsarStep, double InptPsarMax): CStrategy(symbol, period)
     {
      mFastMaPeriod = InptShortMaPeriod;
      mSlowMaPeriod = InptLongMaPeriod;

      mHighLowMaPeriod = InptHighLowMaPeriod;

      mPsarStep = InptPsarStep;
      mPsarMax = InptPsarMax;
     };

   virtual bool      Init(ulong magic);
   virtual Entry     FindEntry(const double ask, const double bid);
   virtual void      Refresh();
   virtual bool      ManagePosition(CPositionInfo &positionInfo, Position &position);
   virtual void      Release();
  };

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
bool CStrategyImpl::Init(ulong magic)
  {
//--- mMas
   bool ma1Created = mHighMa.Create(mSymbol, mTimeframe, mHighLowMaPeriod, 0, MODE_SMA, PRICE_HIGH);
   bool ma2Created = mLowMa.Create(mSymbol, mTimeframe, mHighLowMaPeriod, 0, MODE_SMA, PRICE_LOW);
//--- m_DblMa
   m_DblMa = new CDoubleMovingAverages(mSymbol, mTimeframe, mFastMaPeriod, mSlowMaPeriod, MODE_SMA);
//--- psarsCreated
   bool psarsCreated = mPSar.Create(mSymbol, mTimeframe, mPsarStep, mPsarMax);

//--- price buffers
   ArraySetAsSeries(m_CloseBuffer, true);

   return m_DblMa.Init() && psarsCreated && ma1Created && ma2Created;
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void CStrategyImpl::Release(void)
  {
   mHighMa.FullRelease();
   mLowMa.FullRelease();
   mPSar.FullRelease();
   m_DblMa.Release();
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
      mHighMa.Refresh();
      mLowMa.Refresh();
      //-- psarsCreated
      mPSar.Refresh();
      //-- m_DblMa
      m_DblMa.Refresh();

      //--- price buffers
      int closeBarsCopied = CopyClose(mSymbol, mTimeframe, 0, barsToCopy, m_CloseBuffer);

      //--- take values from indicator
      mCloseShift1 = m_CloseBuffer[1];
      mHighMaShift1 = mHighMa.Main(1);
      mLowMaShift1 = mLowMa.Main(1);
      mFastMaShift1 = m_DblMa.GetData(0, 1);
      mSlowMaShift1 = m_DblMa.GetData(1, 1);
      mPsarsShift1 = mPSar.Main(1);
      mPsarsShift1 = mPSar.Main(1);
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

   if(mCloseShift1 > mCloseShift1)
     {
      bool goLong  = false;
      ////check macd
      //if(mMacdShift1 > mMacdSignalShift1)
      //   return createEntryObject(mSymbol, ask, bid, _Point, mTargetProfit, 0*mTargetProfit, 2, ENTRY_SIGNAL_BUY);
      //else
      //   return entry;

     }
   else
      if(mCloseShift1 < mCloseShift1)
        {
         ////check macd
         //bool goShort  = false;
         //if(mMacdShift1 < mMacdSignalShift1)
         //   return createEntryObject(mSymbol, ask, bid, _Point, mTargetProfit, 0*mTargetProfit, 2, ENTRY_SIGNAL_SELL);
         //else
         //   return entry;
        }

   return entry;
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
bool CStrategyImpl::ManagePosition(CPositionInfo &positionInfo,Position &position)
  {
   if(!mIsNewBar)
      return false;

   ENUM_POSITION_TYPE postType = positionInfo.PositionType();

//if(postType == POSITION_TYPE_SELL)
//  {
//   //bullish macd
//   if(mMacdShift1 > mMacdSignalShift1)
//      position.signal = EXIT_SIGNAL_EXIT;
//  }
//else
//   if(postType == POSITION_TYPE_BUY)
//      //bullish macd
//      if(mMacdShift1 < mMacdSignalShift1)
//         position.signal = EXIT_SIGNAL_EXIT;

//position manager

   return true;
  }
//+------------------------------------------------------------------+


// the expert to run our strategy
CSingleExpert singleExpert(EXPERT_MAGIC, 1);

//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+
int OnInit()
  {
   singleExpert.SetStrategyImpl(new CStrategyImpl(_Symbol, _Period,
                                InpShortMaParam,InpLongMaParam,
                                InpHighLowMaParam,
                                InpPsarStepParam, InpPsarMaxParam));

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
