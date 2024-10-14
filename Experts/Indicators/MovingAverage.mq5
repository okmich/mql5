//+------------------------------------------------------------------+
//|                                                     MAFilter.mq5 |
//|                                    Copyright 2021, Michael Enudi |
//|                                             okmich2002@yahoo.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2021, Michael Enudi"
#property link      "okmich2002@yahoo.com"
#property version   "1.00"

#include <Okmich\Expert\SingleExpert.mqh>
#include <Okmich\Expert\TimeFilter.mqh>
#include <Okmich\Indicators\MovingAverage.mqh>

input group "********* Strategy settings *********";
input ENUM_TIMEFRAMES InpTimeframe = PERIOD_H1;             //Timeframe
input ENUM_LONG_SHORT_FLAG InpLongShortFlag = LONG_SHORT;   //Long/Short Flag
input bool InpUseExitFlag = true; //Use exit flag

//--- input parameters
input ENUM_MA_FILTER InpMAStratey = MA_FILTER_SLOPE; //Entry option
input int      InpPeriod=40;
input ENUM_MA_TYPE    InpSmoothingMethod=MA_TYPE_SMA;
input int InpSlopePeriod = 3;
input double   InpSlopeThreshold = 20.0;
input int      InpLotSizeMultiple=1;
input ulong    ExpertMagic           = 980023;              //Expert MagicNumbers

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
class CStrategyImpl : public CStrategy
  {
private :
   ENUM_ENTRY_SIGNAL signal;
   //--- indicator values
   double            mCloseShift1;
   //--- indicator settings
   int               mPeriod, mSlopePeriod;
   ENUM_MA_TYPE       mMaMethod;
   double            mSlopeThreshold;
   //--- indicators
   CMa               *m_CiMa;
   //--- indicator buffer
   double            m_CloseBuffer[];
   //-- others


public:
                     CStrategyImpl(string symbol, ENUM_TIMEFRAMES period,
                 int InptMaPeriod,
                 ENUM_MA_TYPE InptMaMethod,
                 int InptSlopePeriod, double slopeThreshold,
                 int InptTradeSizeMultiple): CStrategy(symbol, period)
     {
      mPeriod = InptMaPeriod;
      mMaMethod = InptMaMethod;
      mSlopePeriod = InptSlopePeriod;
      mSlopeThreshold = slopeThreshold;
      mLotSize = InptTradeSizeMultiple * SymbolInfoDouble(_Symbol, SYMBOL_VOLUME_MIN);
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
   CStrategy::Init(magic);
//--- price buffers
   ArraySetAsSeries(m_CloseBuffer, true);
//--- m_CiMa
   m_CiMa = new CMa(mSymbol, mTimeframe, mPeriod, mMaMethod, PRICE_CLOSE, 0, mSlopePeriod, mSlopeThreshold);
   return m_CiMa.Init();
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void CStrategyImpl::Release(void)
  {
   m_CiMa.Release();
   delete m_CiMa;
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void CStrategyImpl::CheckAndSetExitSignal(CPositionInfo &positionInfo, Position &position)
  {
   ENUM_POSITION_TYPE posType = positionInfo.PositionType();
   if(signal == ENTRY_SIGNAL_SELL && posType != POSITION_TYPE_SELL)
     {
      position.signal = EXIT_SIGNAL_EXIT;
     }
   else
      if(signal == ENTRY_SIGNAL_BUY && posType != POSITION_TYPE_BUY)
        {
         position.signal = EXIT_SIGNAL_EXIT;
        }
  }


//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void CStrategyImpl::Refresh(void)
  {
   if(IsNewBar())
     {
      int barsToCopy = 10;
      //--- price buffers
      int closeBarsCopied = CopyClose(mSymbol, mTimeframe, 0, barsToCopy, m_CloseBuffer);

      bool refreshed = m_CiMa.Refresh();

      //--- take values from indicator
      signal = m_CiMa.TradeFilter(InpMAStratey);
      mEntrySignal = SupportShortEntries(InpLongShortFlag) && signal == ENTRY_SIGNAL_SELL ? signal :
                     SupportLongEntries(InpLongShortFlag) && signal == ENTRY_SIGNAL_BUY ? signal :
                     ENTRY_SIGNAL_NONE;
     }
  }

// the expert to run our strategy
CSingleExpert singleExpert(ExpertMagic, "Moving Averages 001");

//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+
int OnInit()
  {
//--- set up Time Filter
   CTimeFilter *timeFilter = new CNoTimeFilter();
//singleExpert.SetTimeFilter(timeFilter);

   CPositionManager *positionManager = new CNoPositionManager(_Symbol, _Period);

//--- set up Trading Strategy Implementaion
   CStrategyImpl *strategy = new CStrategyImpl(_Symbol, _Period, InpPeriod, InpSmoothingMethod,
         InpSlopePeriod, InpSlopeThreshold, InpLotSizeMultiple);
   strategy.SetPositionManager(positionManager);
   singleExpert.SetStrategyImpl(strategy);

//---
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
//--- destroy timer
   singleExpert.OnDeinitHandler();
  }

//+------------------------------------------------------------------+
//| Expert tick function                                             |
//+------------------------------------------------------------------+
void OnTick()
  {
//---
   singleExpert.OnTickHandler();
  }
//+------------------------------------------------------------------+
