//+------------------------------------------------------------------+
//|                                    ThomasCarter_04_Any_MAJOR.mq5 |
//|                                    Copyright 2021, Michael Enudi |
//|                                             okmich2002@yahoo.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2021, Michael Enudi"
#property link      "okmich2002@yahoo.com"
#property version   "1.00"

#include <Okmich\Expert\SingleExpert.mqh>
#include <Okmich\Indicators\DoubleMovingAverages.mqh>
#include <Okmich\Indicators\RSI.mqh>
#include <Okmich\Indicators\StochasticOscillator.mqh>

//--- input parameters
const ulong EXPERT_MAGIC = 98765004;
//+------------------------------------------------------------------+
//| Input parameters                                                 |
//+------------------------------------------------------------------+
input group "********* Strategy settings *********";
input ENUM_TIMEFRAMES InpTimeframe = PERIOD_M30;            //Timeframe
input ENUM_LONG_SHORT_FLAG InpLongShortFlag = LONG_SHORT;   //Long/Short Flag

input group "********* Long Strategy settings *********";
input int      InpBuyShortEmaParam=5;
input int      InpBuyLongEmaParam=10;
input ENUM_MA_TYPE      InpBuyEmaMethod=MA_EMA;
input int      InpBuyRSIParam=14;
input int      InpBuyStochKParam=14;
input int      InpBuyStochSlowingParam=3;
input int      InpBuyStochOBParam=80;

input group "********* Short Strategy settings *********";
input int      InpSellShortEmaParam=5;
input int      InpSellLongEmaParam=10;
input ENUM_MA_TYPE      InpSellEmaMethod=MA_EMA;
input int      InpSellRSIParam=14;
input int      InpSellStochKParam=14;
input int      InpSellStochSlowingParam=3;
input int      InpSellStochOSParam=20;

input group "********* Volume setting **********";
input int InpLotSizeMultiple = 2;                     //Multiple of minimum lot size

input group "********* Position management settings *********";
input ENUM_POSITION_MANAGEMENT InpPostManagmentType = POSITION_MGT_FIXED_POINTS;  // Type of Position Management Algorithm
input int InpATRPeriod = 14;                          // ATR Period
input double InpStopLossPoints = 600;                 // Stop loss distance in points
input double InpBreakEvenPoints = 1400;               // Points to Break-even
input double InpTrailingOrTpPoints = 1500;            // Trailing/Take profit points
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
   //--- indicator settings

   //--- indicators
   CDoubleMovingAverages *m_DblMa[2];
   CRsi              *m_Rsi[2];
   CStochastic       *m_Stochastic[2];
   //--- indicator buffer

public:
                     CStrategyImpl(string symbol, ENUM_TIMEFRAMES period, int InptVolMultiple): CStrategy(symbol, period)
     {
      mLotSize = InptVolMultiple*SymbolInfoDouble(_Symbol, SYMBOL_VOLUME_MIN);
     };

   virtual bool      Init(ulong magic);
   virtual Entry     FindEntry(const double ask, const double bid);
   virtual void      Refresh();
   virtual void      CheckAndSetExitSignal(CPositionInfo &positionInfo,Position &position);
   virtual void      Release();
  };

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
bool CStrategyImpl::Init(ulong magic)
  {
//--- m_DblMa
   m_DblMa[0] = new CDoubleMovingAverages(mSymbol, mTimeframe, InpBuyShortEmaParam, InpBuyLongEmaParam, InpBuyEmaMethod);
   m_DblMa[1] = new CDoubleMovingAverages(mSymbol, mTimeframe, InpSellShortEmaParam, InpSellLongEmaParam, InpSellEmaMethod);
   bool dblMasOk = m_DblMa[0].Init() && m_DblMa[1].Init();
//--- m_Rsi
   m_Rsi[0] = new CRsi(mSymbol, mTimeframe, InpBuyRSIParam);
   m_Rsi[1] = new CRsi(mSymbol, mTimeframe, InpSellRSIParam);
   bool mRsisOk = m_Rsi[0].Init() && m_Rsi[1].Init();
//--- mStochastic
   m_Stochastic[0] = new CStochastic(mSymbol, mTimeframe, InpBuyStochKParam, InpBuyStochSlowingParam,
                                     InpBuyStochSlowingParam,STO_CLOSECLOSE,MODE_SMA,
                                     InpBuyStochOBParam, 100-InpBuyStochOBParam);
   m_Stochastic[1] = new CStochastic(mSymbol, mTimeframe, InpSellStochKParam, InpSellStochSlowingParam,
                                     InpSellStochSlowingParam,STO_CLOSECLOSE,MODE_SMA,
                                     100-InpSellStochOSParam, InpSellStochOSParam);
   bool mStochsOk = m_Stochastic[0].Init() && m_Stochastic[1].Init();

   return dblMasOk && mRsisOk && mStochsOk;
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void CStrategyImpl::Release(void)
  {
   for(int i = 0; i< 2; i++)
     {
      m_DblMa[i].Release();
      delete m_DblMa[i];

      m_Rsi[i].Release();
      delete m_Rsi[i];

      m_Stochastic[i].Release();
      delete m_Stochastic[i];
     }
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
      for(int i = 0; i< 2; i++)
        {
         m_DblMa[i].Refresh();
         m_Rsi[i].Refresh();
         m_Stochastic[i].Refresh();
        }
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

   ENUM_ENTRY_SIGNAL mDblSignal = m_DblMa[0].TradeFilter(DBLMA_CrossOver),
                     mStochSignal = m_Stochastic[0].TradeSignal(STOCH_Directional);
   bool isRsiRight = m_Rsi[0].GetData(mRefShift) > 50;
   bool isStochObOsRight = m_Stochastic[0].GetData(0, mRefShift) < InpBuyStochOBParam;
   if(SupportLongEntries(InpLongShortFlag) && mDblSignal == ENTRY_SIGNAL_BUY &&
      mStochSignal == mDblSignal && isRsiRight && isStochObOsRight)
     {
      entry = anEntry(mSymbol, ENTRY_SIGNAL_BUY, ask, 0, 0, mLotSize, EXPERT_MAGIC);
      return entry;
     }

   mDblSignal = m_DblMa[1].TradeFilter(DBLMA_CrossOver);
   mStochSignal = m_Stochastic[1].TradeSignal(STOCH_Directional);
   if(SupportShortEntries(InpLongShortFlag) && mDblSignal == ENTRY_SIGNAL_SELL &&
      mStochSignal == mDblSignal &&
      m_Rsi[0].GetData(mRefShift) < 50 &&
      m_Stochastic[0].GetData(0, mRefShift) > InpSellStochOSParam)
     {
      entry = anEntry(mSymbol, ENTRY_SIGNAL_SELL, bid, 0, 0, mLotSize, EXPERT_MAGIC);
      return entry;
     }

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
   ENUM_ENTRY_SIGNAL mDblSignal, mRsiSignal;
   if(postType == POSITION_TYPE_BUY)
     {
      mDblSignal = m_DblMa[0].TradeSignal(DBLMA_CrossOver);
      mRsiSignal = m_Rsi[0].TradeSignal(RSI_CrossMidLevel);
      if(mDblSignal == ENTRY_SIGNAL_SELL || mRsiSignal == ENTRY_SIGNAL_SELL)
         position.signal = EXIT_SIGNAL_EXIT;
     }
   else
      if(postType == POSITION_TYPE_SELL)
        {
         mDblSignal = m_DblMa[1].TradeSignal(DBLMA_CrossOver);
         mRsiSignal = m_Rsi[1].TradeSignal(RSI_CrossMidLevel);
         if(mDblSignal == ENTRY_SIGNAL_BUY || mRsiSignal == ENTRY_SIGNAL_BUY)
            position.signal = EXIT_SIGNAL_EXIT;
        }

  }

// the expert to run our strategy
CSingleExpert singleExpert(EXPERT_MAGIC, "");

//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+
int OnInit()
  {
   CPositionManager *mPositionManager = CreatPositionManager(_Symbol, InpTimeframe,
                                        InpPostManagmentType,
                                        InpATRPeriod, InpStopLossPoints, InpBreakEvenPoints, InpTrailingOrTpPoints,
                                        InpMaxLossAmount, InpScratchBreakEvenFlag, false, 5,
                                        InpStopLossMultiple, InpBreakEvenMultiple, InpTrailingOrTpMultiple);

   CStrategyImpl *strategy = new CStrategyImpl(_Symbol, InpTimeframe, InpLotSizeMultiple);
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
