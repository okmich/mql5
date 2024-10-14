//+------------------------------------------------------------------+
//|                                                       CCI+MA.mq5 |
//|                                    Copyright 2024, Michael Enudi |
//|                                             okmich2002@yahoo.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2024, Michael Enudi"
#property link      "okmich2002@yahoo.com"
#property version   "1.00"

//--- includes directives here
#include <Okmich\Expert\SingleExpert.mqh>
#include <Okmich\Indicators\CCI.mqh>
#include <Okmich\Indicators\MovingAverage.mqh>

//--- input ATR_PERIOD
const int ATR_PERIOD = 40;
//--- input EXPERT_MAGIC
const ulong EXPERT_MAGIC = 1000000000;

//+------------------------------------------------------------------+
//| Input parameters                                                 |
//+------------------------------------------------------------------+
input group "********* Strategy settings *********";
input ENUM_TIMEFRAMES InpTimeframe = PERIOD_H1;             //Timeframe
input ENUM_LONG_SHORT_FLAG InpLongShortFlag = LONG_SHORT;   //Long/Short Flag

input group "********* Long Strategy settings *********";
input int      InpLongMaPeriod=200;
input ENUM_MA_TYPE      InpLongMaMethod=MA_TYPE_EMA;
input int      InpLongCciPeriod=14;
input int      InpLongCciLevel=144;
input double   InpLongTpAtrMultiples=2.25;
input double   InpLongSlAtrMultiples=3.75;

input group "********* Short Strategy settings *********";
input int      InpShortMaPeriod=220;
input ENUM_MA_TYPE      InpShortMaMethod=MA_TYPE_EMA;
input int      InpShortCciPeriod=38;
input int      InpShortCciLevel=176;
input double   InpShortTpAtrMultiples=3.5;
input double   InpShortSlAtrMultiples=4.75;

input group "********* Volume setting **********";
input int InpLotSizeMultiple = 1;                     //Multiple of minimum lot size

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
class CStrategyImpl : public CStrategy
  {
private :
   //--- indicators
   CCci              *m_BuyCci;
   CCci              *m_SellCci;
   CMa               *m_BuyMa;
   CMa               *m_SellMa;

   //--- indicator buffer

protected:
   virtual Entry     FindEntry(const double ask, const double bid);

public:
                     CStrategyImpl(string symbol, ENUM_TIMEFRAMES period, int InptVolMultiple): CStrategy(symbol, period)
     {
      mLotSize = InptVolMultiple*SymbolInfoDouble(symbol, SYMBOL_VOLUME_MIN);
      CAtrFixedPositionManager *posManager = new CAtrFixedPositionManager(
         symbol, InpTimeframe,
         ATR_PERIOD, InpLongSlAtrMultiples, 1000, InpLongTpAtrMultiples,1000,
         false, false, 100);
      SetPositionManager(posManager);
     };

   virtual bool      Init(ulong magic);
   virtual void      CheckAndSetExitSignal(CPositionInfo &positionInfo, Position &position);
   virtual void      Refresh();
   virtual void      Release();
  };

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
bool CStrategyImpl::Init(ulong magic)
  {
   CStrategy::Init(magic);
//--- price buffers
   m_BuyCci = new CCci(mSymbol, mTimeframe, InpLongCciPeriod, InpLongCciLevel);
   m_SellCci = new CCci(mSymbol, mTimeframe, InpShortCciPeriod, InpShortCciLevel);
//--- m_Mas
   m_BuyMa = new CMa(mSymbol, mTimeframe, InpLongMaPeriod, InpLongMaMethod, PRICE_CLOSE);
   m_SellMa = new CMa(mSymbol, mTimeframe, InpShortMaPeriod, InpShortMaMethod, PRICE_CLOSE);

   return m_BuyCci.Init() && m_SellCci.Init() && m_BuyMa.Init() && m_SellMa.Init();
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void CStrategyImpl::Release(void)
  {
//--- release indicators
   m_BuyCci.Release();
   m_SellCci.Release();
   delete m_BuyCci;
   delete m_SellCci;

   m_BuyMa.Release();
   m_SellMa.Release();
   delete m_BuyMa;
   delete m_SellMa;
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
      //-- refresh indicators
      m_BuyMa.Refresh(mRefShift);
      m_SellMa.Refresh(mRefShift);
      m_BuyCci.Refresh(mRefShift);
      m_SellCci.Refresh(mRefShift);
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
      ENUM_ENTRY_SIGNAL cciSignal = m_BuyCci.TradeSignal(CCI_EnterOsOBLevels);
      ENUM_ENTRY_SIGNAL maFilterSignal = m_BuyMa.TradeFilter(MA_FILTER_PRICE);

      if(maFilterSignal == cciSignal && cciSignal == ENTRY_SIGNAL_BUY)
        {
         entry.signal = cciSignal;
         entry.price = ask;
         
         CAtrFixedPositionManager *posManager = mPositionManager;
         posManager.SetStopLossMultiple(InpLongSlAtrMultiples);
         posManager.SetTakeProfitMultiple(InpLongTpAtrMultiples);
        }
     }

   if(SupportShortEntries(InpLongShortFlag))
     {
      ENUM_ENTRY_SIGNAL cciSignal = m_SellCci.TradeSignal(CCI_EnterOsOBLevels);
      ENUM_ENTRY_SIGNAL maFilterSignal = m_SellMa.TradeFilter(MA_FILTER_PRICE);
      if(maFilterSignal == cciSignal && cciSignal == ENTRY_SIGNAL_SELL)
        {
         entry.signal = cciSignal;
         entry.price = bid;

         CAtrFixedPositionManager *posManager = mPositionManager;
         posManager.SetStopLossMultiple(InpShortSlAtrMultiples);
         posManager.SetTakeProfitMultiple(InpShortTpAtrMultiples);
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
void CStrategyImpl::CheckAndSetExitSignal(CPositionInfo &positionInfo,Position &position)
  {
  }

// the expert to run our strategy
CSingleExpert singleExpert(EXPERT_MAGIC, "Name of strategy here");

//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+
int OnInit()
  {
   CStrategy *strategy = new CStrategyImpl(_Symbol, InpTimeframe, InpLotSizeMultiple);
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
