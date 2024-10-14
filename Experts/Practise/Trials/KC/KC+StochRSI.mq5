//+------------------------------------------------------------------+
//|                                                  KC+StochRsi.mq5 |
//|                                    Copyright 2024, Michael Enudi |
//|                                             okmich2002@yahoo.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2024, Michael Enudi"
#property link      "okmich2002@yahoo.com"
#property version   "1.00"

#include <Okmich\Expert\SingleExpert.mqh>
#include <Okmich\Indicators\KeltnerChannel.mqh>
#include <Okmich\Indicators\StochasticRsi.mqh>

//+------------------------------------------------------------------+
//| Input parameters                                                 |
//+------------------------------------------------------------------+
input group "********* Settings *********";
input ENUM_TIMEFRAMES InpTimeframe = PERIOD_CURRENT;             //Timeframe
input ENUM_LONG_SHORT_FLAG InpLongShortFlag = LONG_SHORT;   //Long/Short Flag

input group "********* Long Strategy settings *********";
input ENUM_KTC_FILTER InpLongHowToFilter = KTC_FILTER_ABOVE_BELOW_BAND; //Filter strategy
input int            InpLongKcPeriod=32;            //KC Long period
input double         InpLongKcAtrMultiplier=2.0;    //KC Long ATR multiplier
input ENUM_MA_TYPE   InpLongKcMaMethod=MA_TYPE_EMA; //KC Long MA Type
input int         InpLongStochRsiPeriod=12;          //KC Long StochRsi period
input int         InpLongStochKPeriod=5;        //KC Long K period
input int         InpLongStochSmoothing=3;           //KC Long smoothing period
input int         InpLongStochSignal=3;      //KC Long signal period
input double      InpLongStochOBLevel=80;    //KC Long OB level
input double      InpLongStochOSLevel=20;    //KC Long OS level

input group "********* Short Strategy settings *********";
input ENUM_KTC_FILTER InpShortHowToFilter = KTC_FILTER_ABOVE_BELOW_BAND; //Short Filter strategy
input int            InpShortKcPeriod=32;            //KC Short period
input double         InpShortKcAtrMultiplier=2.0;    //KC Short ATR multiplier
input ENUM_MA_TYPE   InpShortKcMaMethod=MA_TYPE_EMA; //KC Short MA Type
input int         InpShortStochRsiPeriod=12;          //KC Short StochRsi period
input int         InpShortStochKPeriod=5;        //KC Short K period
input int         InpShortStochSmoothing=3;      //KC Short smoothing period
input int         InpShortStochSignal=3;      //KC Short Stoch signal
input double      InpShortStochOBLevel=80;    //KC Short OB level
input double      InpShortStochOSLevel=20;    //KC Short OS level

input group "********* Volume setting **********";
input int InpLotSizeMultiple = 1;                     //Multiple of minimum lot size

input group "********* Position management settings *********";
input ENUM_POSITION_MANAGEMENT InpPostManagmentType = POSITION_MGT_FIXED_ATR_MULTIPLES;  // Type of Position Management Algorithm
input double InpStopLossPoints = -1;                  // Stop loss distance in points
input double InpBreakEvenPoints = -1;                 // Points to Break-even
input double InpTrailingOrTpPoints = -1;              // Trailing/Take profit points
input double InpMaxLossAmount = 100.00;               // Maximum allowable loss in dollars
input bool InpScratchBreakEvenFlag = true;            // Enable break-even with scratch profit
input double InpStopLossMultiple = 4;                 // ATR multiple for stop loss
input double InpTrailingOrTpMultiple = 6;             // ATR multiple for Maximum floating/Take profit

input ulong    ExpertMagic           = 980023;              //Expert MagicNumbers

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
class CStrategyImpl : public CStrategy
  {
private :
   //--- indicator values
   //--- indicator settings
   //--- indicators
   CKeltnerChannel   *m_KetChanl[2];
   CStochasticRSI    *m_StochRsi[2];
   //-- others

protected:
   virtual Entry     FindEntry(const double ask, const double bid);

public:
                     CStrategyImpl(string symbol, ENUM_TIMEFRAMES period,
                 int InptLotSizeMultiple): CStrategy(symbol, period)
     {
      mLotSize = InptLotSizeMultiple * SymbolInfoDouble(mSymbol, SYMBOL_VOLUME_MIN);
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
//--- m_KetChanl
   m_KetChanl[0] = new CKeltnerChannel(mSymbol, mTimeframe, InpLongKcPeriod, InpLongKcMaMethod,
                                       InpLongKcAtrMultiplier,PRICE_CLOSE);
   m_KetChanl[1] = new CKeltnerChannel(mSymbol, mTimeframe, InpShortKcPeriod, InpShortKcMaMethod,
                                       InpShortKcAtrMultiplier,PRICE_CLOSE);
   bool kcInited = m_KetChanl[0].Init() && m_KetChanl[1].Init();
//--- m_StochRsi
   m_StochRsi[0] = new CStochasticRSI(mSymbol, mTimeframe, InpLongStochRsiPeriod, InpLongStochKPeriod,
                                      InpLongStochSmoothing, InpLongStochSignal,
                                      InpLongStochOBLevel, InpLongStochOSLevel);
   m_StochRsi[1] = new CStochasticRSI(mSymbol, mTimeframe, InpShortStochRsiPeriod, InpShortStochKPeriod,
                                      InpShortStochSmoothing, InpShortStochSignal,
                                      InpShortStochOBLevel, InpShortStochOSLevel);
   bool stockRsiInited = m_StochRsi[0].Init() && m_StochRsi[1].Init();
   return kcInited && stockRsiInited;
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void CStrategyImpl::Release(void)
  {
   for(int i = 0; i < 2; i++)
     {
      m_StochRsi[i].Release();
      m_KetChanl[i].Release();

      delete m_StochRsi[i];
      delete m_KetChanl[i];
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

//--- implement entry logic
   if(SupportLongEntries(InpLongShortFlag))
     {
      ENUM_ENTRY_SIGNAL stochSignal = m_StochRsi[0].TradeSignal(STOCHRSI_EnterOsOBLevels);
      ENUM_ENTRY_SIGNAL filterSignal = m_KetChanl[0].TradeFilter(InpLongHowToFilter);

      if(filterSignal == stochSignal && stochSignal == ENTRY_SIGNAL_BUY)
        {
         entry.signal = stochSignal;
         entry.price = ask;
        }
     }

   if(SupportShortEntries(InpLongShortFlag))
     {
      ENUM_ENTRY_SIGNAL stochSignal = m_StochRsi[1].TradeSignal(STOCHRSI_EnterOsOBLevels);
      ENUM_ENTRY_SIGNAL filterSignal = m_KetChanl[1].TradeFilter(InpShortHowToFilter);

      if(filterSignal == stochSignal && stochSignal == ENTRY_SIGNAL_SELL)
        {
         entry.signal = stochSignal;
         entry.price = bid;
        }
     }

   if(entry.signal != ENTRY_SIGNAL_NONE)
     {
      entry.sym = mSymbol;
      entry.magic = _expertMagic;
      entry.vol = mLotSize;
     }

   return entry;
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void CStrategyImpl::CheckAndSetExitSignal(CPositionInfo &positionInfo, Position &position)
  {
   ENUM_POSITION_TYPE posType = positionInfo.PositionType();
   ENUM_ENTRY_SIGNAL filterSignal;

   if(posType == POSITION_TYPE_BUY)
     {
      filterSignal = GetFilterSignal(m_KetChanl[0], mRefShift, posType, InpLongHowToFilter);
      if(filterSignal != ENTRY_SIGNAL_BUY)
        {
         position.signal = EXIT_SIGNAL_EXIT;
        }
      else
        {
         ENUM_ENTRY_SIGNAL stochSignal = m_StochRsi[0].TradeSignal(STOCHRSI_EnterOsOBLevels);
         if(stochSignal == ENTRY_SIGNAL_SELL)
           {
            position.signal = EXIT_SIGNAL_EXIT;
           }
        }
     }
   else
      if(posType == POSITION_TYPE_SELL)
        {
         filterSignal = GetFilterSignal(m_KetChanl[1], mRefShift, posType, InpShortHowToFilter);
         if(filterSignal != ENTRY_SIGNAL_SELL)
           {
            position.signal = EXIT_SIGNAL_EXIT;
           }
         else
           {
            ENUM_ENTRY_SIGNAL stochSignal = m_StochRsi[1].TradeSignal(STOCHRSI_EnterOsOBLevels);
            if(stochSignal == ENTRY_SIGNAL_BUY)
              {
               position.signal = EXIT_SIGNAL_EXIT;
              }
           }
        }
  }


//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
ENUM_ENTRY_SIGNAL GetFilterSignal(CKeltnerChannel *m_KetChanl, int mRefShift, ENUM_POSITION_TYPE posType,
                                  ENUM_KTC_FILTER inpHowToFilter)
  {
   ENUM_ENTRY_SIGNAL filterSignal;
   if(inpHowToFilter == KTC_FILTER_ABOVE_BELOW_BAND_2)
     {
      ENUM_ENTRY_SIGNAL currentState = posType == POSITION_TYPE_BUY ? ENTRY_SIGNAL_BUY :
                                       posType == POSITION_TYPE_SELL ? ENTRY_SIGNAL_SELL: ENTRY_SIGNAL_NONE;
      filterSignal = m_KetChanl.AboveBelowExtremeBandFilter(currentState, mRefShift);
     }
   else
     {
      filterSignal = m_KetChanl.TradeFilter(inpHowToFilter);
     }
   return filterSignal;
  }


//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void CStrategyImpl::Refresh(void)
  {
   if(IsNewBar())
     {
      for(int i = 0; i < 2; i++)
        {
         m_StochRsi[i].Refresh(mRefShift);
         m_KetChanl[i].Refresh(mRefShift);
        }
     }
  }

// the expert to run our strategy
CSingleExpert singleExpert(ExpertMagic, "...");

//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+
int OnInit()
  {
//--- set up Trading Strategy Implementaion
   CStrategyImpl *strategy = new CStrategyImpl(_Symbol, InpTimeframe, InpLotSizeMultiple);
   CPositionManager *positionManager = CreatPositionManager(_Symbol, InpTimeframe,
                                       InpPostManagmentType, InpLongKcPeriod,
                                       InpStopLossPoints, InpBreakEvenPoints, InpTrailingOrTpPoints,
                                       InpMaxLossAmount, InpScratchBreakEvenFlag, false, 5,
                                       InpStopLossMultiple, InpTrailingOrTpMultiple, InpTrailingOrTpMultiple);
   strategy.SetPositionManager(positionManager);
   singleExpert.SetStrategyImpl(strategy);

   if(singleExpert.OnInitHandler())
      return INIT_SUCCEEDED;
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
//---
   singleExpert.OnTickHandler();
  }
//+------------------------------------------------------------------+
