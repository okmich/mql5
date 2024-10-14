//+------------------------------------------------------------------+
//|                                     ThomasCarter_1_30M_MAJOR.mq5 |
//|                                    Copyright 2021, Michael Enudi |
//|                                             okmich2002@yahoo.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2021, Michael Enudi"
#property link      "okmich2002@yahoo.com"
#property version   "1.00"

#include <Okmich\Expert\SingleExpert.mqh>
#include <Indicators\Trend.mqh>

//--- input parameters
const ulong EXPERT_MAGIC = 987650001;
//+------------------------------------------------------------------+
//| Input parameters                                                 |
//+------------------------------------------------------------------+
input group "********* Strategy settings *********";
input ENUM_TIMEFRAMES InpTimeframe = PERIOD_M30;            //Timeframe
input ENUM_LONG_SHORT_FLAG InpLongShortFlag = LONG_SHORT;   //Long/Short Flag

input group "********* Long Strategy settings *********";
input ENUM_MA_METHOD      InpBuyEmaMethod=MODE_SMMA;
input int      InpBuyFastMaParam=18;
input int      InpBuyMidMaParam=20;
input int      InpBuySlowMaParam=130;
input double   InpBuyPsarStepParam=0.02;
input double   InpBuyPsarMaxParam=0.2;

input group "********* Short Strategy settings *********";
input ENUM_MA_METHOD      InpSellEmaMethod=MODE_SMA;
input int      InpSellFastMaParam=20;
input int      InpSellMidMaParam=40;
input int      InpSellSlowMaParam=138;
input double   InpSellPsarStepParam=0.015;
input double   InpSellPsarMaxParam=0.2;

input group "********* Volume setting **********";
input int InpLotSizeMultiple = 3;                     //Multiple of minimum lot size

input group "********* Position management settings *********";
input ENUM_POSITION_MANAGEMENT InpPostManagmentType = POSITION_MGT_MAX_LOSS_AMOUNT;  // Type of Position Management Algorithm
input int InpATRPeriod = 14;                          // ATR Period
input double InpStopLossPoints = -1;                  // Stop loss distance in points
input double InpBreakEvenPoints = -1;                 // Points to Break-even
input double InpTrailingOrTpPoints = -1;              // Trailing/Take profit points
input double InpMaxLossAmount = 50.00;               // Maximum allowable loss in dollars
input bool InpScratchBreakEvenFlag = true;            // Enable break-even with scratch profit
input double InpStopLossMultiple = 1;                 // ATR multiple for stop loss
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
   CiMA              mSlowMa[2], mMidMa[2], mFastMa[2];
   CiSAR             mPSar[2];
   //--- indicator buffer

protected:
   virtual Entry     FindEntry(const double ask, const double bid);
public:
                     CStrategyImpl(string symbol, ENUM_TIMEFRAMES period): CStrategy(symbol, period)
     {};

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
//--- mMa
   bool ma1Created = mFastMa[0].Create(mSymbol, mTimeframe, InpBuyFastMaParam, 0, InpBuyEmaMethod, PRICE_CLOSE);
   bool ma1Created2 = mFastMa[1].Create(mSymbol, mTimeframe, InpSellFastMaParam, 0, InpSellEmaMethod, PRICE_CLOSE);

   bool ma2Created = mMidMa[0].Create(mSymbol, mTimeframe, InpBuyMidMaParam, 0, InpBuyEmaMethod, PRICE_CLOSE);
   bool ma2Created2 = mMidMa[1].Create(mSymbol, mTimeframe, InpSellMidMaParam, 0, InpSellEmaMethod, PRICE_CLOSE);

   bool ma3Created = mSlowMa[0].Create(mSymbol, mTimeframe, InpBuySlowMaParam, 0, InpBuyEmaMethod, PRICE_CLOSE);
   bool ma3Created2 = mSlowMa[1].Create(mSymbol, mTimeframe, InpSellSlowMaParam, 0, InpSellEmaMethod, PRICE_CLOSE);
//--- psarsCreated
   bool psarsCreated = mPSar[0].Create(mSymbol, mTimeframe, InpBuyPsarStepParam, InpBuyPsarMaxParam);
   bool psarsCreated2 = mPSar[1].Create(mSymbol, mTimeframe, InpSellPsarStepParam, InpSellPsarMaxParam);

   return ma1Created && ma1Created2 && ma2Created && ma2Created2 &&
          ma3Created && ma3Created2 && psarsCreated && psarsCreated2;
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void CStrategyImpl::Release(void)
  {
   for(int i = 0; i < 2; i++)
     {
      mFastMa[i].FullRelease();
      mMidMa[i].FullRelease();
      mSlowMa[i].FullRelease();

      mPSar[i].FullRelease();
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
      for(int i = 0; i < 2; i++)
        {
         //-- mMa
         mFastMa[i].Refresh();
         mMidMa[i].Refresh();
         mSlowMa[i].Refresh();
         //-- mPSar
         mPSar[i].Refresh();
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

   bool smallEmaBreakOtherEmasUpward = mFastMa[0].Main(mRefShift) > mMidMa[0].Main(mRefShift) &&
                                       mFastMa[0].Main(mRefShift) > mSlowMa[0].Main(mRefShift);
   bool pSarIsBelowPrice = mPSar[0].Main(mRefShift) < iLow(mSymbol, mTimeframe, mRefShift);
   if(SupportLongEntries(InpLongShortFlag) && smallEmaBreakOtherEmasUpward && pSarIsBelowPrice)
     {
      entry.signal = ENTRY_SIGNAL_BUY;
      entry.price = ask;
      entry.sl = mMidMa[0].Main(mRefShift) - (OnePoint()*10);
     }

   bool smallEmaBreakOtherEmasDownward = mFastMa[1].Main(mRefShift) < mMidMa[1].Main(mRefShift) &&
                                         mFastMa[1].Main(mRefShift) < mSlowMa[1].Main(mRefShift);
   bool pSarIsAbovePrice = mPSar[1].Main(mRefShift) > iHigh(mSymbol, mTimeframe, mRefShift);
   if(SupportShortEntries(InpLongShortFlag) && smallEmaBreakOtherEmasDownward && pSarIsAbovePrice)
     {
      entry.signal = ENTRY_SIGNAL_SELL;
      entry.price = bid;
      entry.sl = mMidMa[1].Main(mRefShift) + (OnePoint()*10);
     }

   entry.vol = InpLotSizeMultiple*SymbolInfoDouble(mSymbol, SYMBOL_VOLUME_MIN);
   entry.magic = EXPERT_MAGIC;
   entry.sym = mSymbol;

   return entry;
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void CStrategyImpl::CheckAndSetExitSignal(CPositionInfo &positionInfo, Position &position)
  {
   ENUM_POSITION_TYPE posType = positionInfo.PositionType();
   double closePriceShift = iClose(mSymbol, mTimeframe, mRefShift);
   if(posType == POSITION_TYPE_BUY)
     {
      bool smallEmaBreakOtherEmasDownward = closePriceShift < mFastMa[0].Main(mRefShift) &&
                                            closePriceShift < mMidMa[0].Main(mRefShift) &&
                                            closePriceShift < mSlowMa[0].Main(mRefShift);
      position.signal = smallEmaBreakOtherEmasDownward ? EXIT_SIGNAL_EXIT : EXIT_SIGNAL_HOLD;
     }
   else
      if(posType == POSITION_TYPE_SELL)
        {
         bool smallEmaBreakOtherEmasUpward = closePriceShift > mFastMa[1].Main(mRefShift) &&
                                             closePriceShift > mMidMa[1].Main(mRefShift) &&
                                             closePriceShift > mSlowMa[1].Main(mRefShift);
         position.signal = smallEmaBreakOtherEmasUpward ? EXIT_SIGNAL_EXIT : EXIT_SIGNAL_HOLD;
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

   CStrategyImpl *strategy = new CStrategyImpl(_Symbol, InpTimeframe);
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
