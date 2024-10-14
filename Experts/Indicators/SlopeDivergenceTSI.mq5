//+------------------------------------------------------------------+
//|                                                     FilterEA.mq5 |
//|                                    Copyright 2021, Michael Enudi |
//|                                             okmich2002@yahoo.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2021, Michael Enudi"
#property link      "okmich2002@yahoo.com"
#property version   "1.00"

#include <Okmich\Expert\StrategyExecExpert.mqh>
#include <Okmich\Indicators\SlopeDivergenceTSI.mqh>
#include <Indicators\Trend.mqh>

input int    InpSdTsiPeriod = 13;
input int    InpSdTsiSmooth1 = 25;
input int    InpSdTsiSmooth2 = 3;
input int    InpSdTsiMaPeriod = 25;
input int    InpSdTsiMaSmooth = 3;

input double InpDefaultVolume=0.2; //Lot size
input ulong    ExpertMagic           = 980023;              //Expert MagicNumbers


//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
class CFilter : public CStrategy
  {
private :
   //--- indicator values
   double            mCloseShift1, mMaShift1;
   bool              mIsTrending;
   //--- indicator settings
   int               mTsiPeriod, mTsiSmooth1, mTsiSmooth2, mTsiMaPeriod, mTsiMaSmooth;
   int               mPeriod;
   int               mOBLevel;
   int               mOSLevel;
   ENUM_OBOS_CRS_IMPL mOBOSStrategy;

   //--- indicators
   CSdTsi            *mSdTsi;
   CiMA              mCiMA;
   //--- indicator buffer
   double            m_CloseBuffer[];
   //-- others


public:
                     CFilter(string symbol, ENUM_TIMEFRAMES period,
           int InpTsiPeriod=13, int InpTsiSmooth1=25,
           int InpTsiSmooth2=2,  int InpPriceSmooth1=20, int InpPriceSmooth2=2): CStrategy(symbol, period)
     {
      mTsiPeriod = InpTsiPeriod;
      mTsiSmooth1 = InpTsiSmooth1;
      mTsiSmooth2 = InpTsiSmooth2;
      mTsiMaPeriod = InpPriceSmooth1;
      mTsiMaSmooth = InpPriceSmooth2;

      mLotSize = 2*SymbolInfoDouble(_Symbol, SYMBOL_VOLUME_MIN);
     };

   virtual bool      Init(ulong magic);
   virtual void      Refresh();
   virtual void      CheckAndSetExitSignal(CPositionInfo &positionInfo, Position &position);
   virtual void      Release();
  };

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
bool CFilter::Init(ulong magic)
  {
   CStrategy::Init(magic);
//--- price buffers
   ArraySetAsSeries(m_CloseBuffer, true);
//--- mSdTsi
   mSdTsi = new CSdTsi(mSymbol, mTimeframe, mTsiPeriod, mTsiSmooth1, mTsiSmooth2, mTsiMaPeriod, mTsiMaSmooth);
   bool maCreated = mCiMA.Create(mSymbol, mTimeframe, mTsiMaPeriod, 0, MODE_EMA, PRICE_CLOSE);

   return mSdTsi.Init() && maCreated;
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void CFilter::Release(void)
  {
   mSdTsi.Release();
   delete mSdTsi;
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void CFilter::CheckAndSetExitSignal(CPositionInfo &positionInfo, Position &position)
  {
   if(!mIsTrending)
     {
      position.signal = EXIT_SIGNAL_EXIT;
      return;
     }

   ENUM_POSITION_TYPE posType = positionInfo.PositionType();
   if(posType == POSITION_TYPE_BUY && mCloseShift1 < mMaShift1)
     {
      position.signal = EXIT_SIGNAL_EXIT;
     }
   else
      if(posType == POSITION_TYPE_SELL && mCloseShift1 > mMaShift1)
        {
         position.signal = EXIT_SIGNAL_EXIT;
        }
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void CFilter::Refresh(void)
  {
   if(IsNewBar())
     {
      int barsToCopy = 10;
      //--- price buffers
      int closeBarsCopied = CopyClose(mSymbol, mTimeframe, 0, barsToCopy, m_CloseBuffer);
      mCloseShift1 = m_CloseBuffer[1];
      //--- ma
      mCiMA.Refresh();
      mMaShift1 = mCiMA.Main(1);
      //--- sdtsi
      mSdTsi.Refresh();
      mIsTrending = mSdTsi.IsTrending();

      //signal logic
      if(mIsTrending)
         if(mCloseShift1 > mMaShift1)
            mEntrySignal = ENTRY_SIGNAL_BUY;
         else
            if(mCloseShift1 < mMaShift1)
               mEntrySignal = ENTRY_SIGNAL_SELL;
     }
  }

// the expert to run our strategy
CStrategyExecExpert expert(ExpertMagic, 0);
//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+
int OnInit()
  {
//--- set up Time Filter
   CTimeFilter *timeFilter = new CNoTimeFilter();
   expert.SetTimeFilter(timeFilter);

//--- set up Position manager Implementaion
   CPositionManager *positionManager = new CNoPositionManager(_Symbol, _Period);
   expert.SetPositionManager(new CNoPositionManager(_Symbol, _Period));

//--- set up Trading Strategy Implementaion
   CFilter *strategy = new CFilter(_Symbol, _Period, InpSdTsiPeriod, InpSdTsiSmooth1, InpSdTsiSmooth2,
                                   InpSdTsiMaPeriod, InpSdTsiMaSmooth);
   expert.SetTradeStrategy(strategy);

//---
   return expert.DoInit();
  }

//+------------------------------------------------------------------+
//| Expert deinitialization function                                 |
//+------------------------------------------------------------------+
void OnDeinit(const int reason)
  {
//--- destroy timer
   expert.Deinit();
  }

//+------------------------------------------------------------------+
//| Expert tick function                                             |
//+------------------------------------------------------------------+
void OnTick()
  {
//---
   expert.DoOnTick();
  }
//+------------------------------------------------------------------+
