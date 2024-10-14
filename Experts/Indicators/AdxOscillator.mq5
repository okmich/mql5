//+------------------------------------------------------------------+
//|                                                     FilterEA.mq5 |
//|                                    Copyright 2021, Michael Enudi |
//|                                             okmich2002@yahoo.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2021, Michael Enudi"
#property link      "okmich2002@yahoo.com"
#property version   "1.00"

#include <Okmich\Expert\SingleExpert.mqh>
#include <Okmich\Indicators\ADXOscillator.mqh>

input ENUM_ADXOSC_Strategies InpHowTo = ADXOSC_AboveBelowZeroLine; //Strategy for entry
input int InpADXPeriod = 14;
input int InpOscSlopePeriod = 3;
input ulong    ExpertMagic           = 980023;              //Expert MagicNumbers


//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
class CFilter : public CStrategy
  {
private :
   //--- indicator values
   bool              mIsTrending;
   double            mAdxOscShift1;
   //--- indicator settings
   int               mAdxPeriod,mOscSlopePeriod;
   //--- indicators
   CADXOscillator    *mAdxOsc;
   //--- indicator buffer
   double            m_CloseBuffer[];
   //-- others


public:
                     CFilter(string symbol, ENUM_TIMEFRAMES period, int InptAdxPeriod,
           int InptOscSlopePeriod): CStrategy(symbol, period)
     {
      mAdxPeriod = InptAdxPeriod;
      mOscSlopePeriod =InptOscSlopePeriod;
      mLotSize = SymbolInfoDouble(_Symbol, SYMBOL_VOLUME_MIN);
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
//--- mAdxOsc
   mAdxOsc = new CADXOscillator(mSymbol, mTimeframe, mAdxPeriod,20,3.0,mOscSlopePeriod);

   return mAdxOsc.Init();
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void CFilter::Release(void)
  {
   mAdxOsc.Release();
   delete mAdxOsc;
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void CFilter::CheckAndSetExitSignal(CPositionInfo &positionInfo, Position &position)
  {
   ENUM_POSITION_TYPE posType = positionInfo.PositionType();
   if(posType == POSITION_TYPE_BUY && mAdxOscShift1 < 0)
     {
      position.signal = EXIT_SIGNAL_EXIT;
     }
   else
      if(posType == POSITION_TYPE_SELL && mAdxOscShift1 > 0)
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

      mAdxOsc.Refresh();
      mAdxOscShift1 = mAdxOsc.GetData(1, 1);
      mIsTrending = mAdxOsc.IsTrending();

      //signal logic
      mEntrySignal = mAdxOsc.TradeSignal(InpHowTo);
     }
  }

// the expert to run our strategy
CSingleExpert singleExpert(ExpertMagic, 10);

//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+
int OnInit()
  {
//--- set up Trading Strategy Implementaion
   CFilter *strategy = new CFilter(_Symbol, _Period, InpADXPeriod, InpOscSlopePeriod);
   CPositionManager *positionManager = new CNoPositionManager(_Symbol, _Period);
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
