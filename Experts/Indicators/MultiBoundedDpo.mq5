//+------------------------------------------------------------------+
//|                                              MultiBoundedDpo.mq5 |
//|                                                    Michael Enudi |
//|                                             okmich2002@yahoo.com |
//+------------------------------------------------------------------+
#property copyright "Michael Enudi"
#property link      "okmich2002@yahoo.com"
#property version   "1.00"

#include <Okmich\Expert\MultiExpert.mqh>
#include <Okmich\Indicators\BoundedDpo.mqh>

//--- input parameters (Symbols)
input string   InpSymbols = "EURUSD|GBPJPY|EURCAD|USDJPY|EURGBP";
input ENUM_TIMEFRAMES InpTimeframe = PERIOD_M12;
input int InpTimerFrequency = 60;
//--- input parameters
input ENUM_BDPO_Strategies InpHowToEnter = BDPO_EnterOsOBLevels; //Strategy entry option
input int      InpMaPeriod=10;
input int      InpPRankPeriod=252;
input int      InpOBLevel=85;

input ulong    ExpertMagic           = 980023;              //Expert MagicNumbers

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
class CStrategyImpl : public CStrategy
  {
private :
   //--- indicator values
   double            mCloseShift1;
   //--- indicator settings
   ENUM_BDPO_Strategies mIndLogic;
   int               mMaPeriod, mPRankPeriod, mOBLevel;
   //--- indicators
   CBoundedDpo       *m_BDpo;
   //--- indicator buffer
   //-- others

public:
                     CStrategyImpl(string symbol, ENUM_TIMEFRAMES period,
                 ENUM_BDPO_Strategies InptIndLogic,
                 int InptMaPeriod, int InptPRankPeriod, int InptOBLevel): CStrategy(symbol, period)
     {
      mIndLogic = InptIndLogic;
      mMaPeriod = InptMaPeriod;
      mPRankPeriod = InptPRankPeriod;
      mOBLevel = InptOBLevel;

      mLotSize = 2 * SymbolInfoDouble(mSymbol, SYMBOL_VOLUME_MIN);
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
//--- m_BDpo
   m_BDpo = new CBoundedDpo(mSymbol, mTimeframe, mMaPeriod, mPRankPeriod, mOBLevel, 100 - mOBLevel);
   return m_BDpo.Init();
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void CStrategyImpl::Release(void)
  {
   m_BDpo.Release();
   delete m_BDpo;
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void CStrategyImpl::CheckAndSetExitSignal(CPositionInfo &positionInfo, Position &position)
  {
   ENUM_POSITION_TYPE posType = positionInfo.PositionType();
   if(posType == POSITION_TYPE_BUY && mEntrySignal == ENTRY_SIGNAL_SELL)
     {
      position.signal = EXIT_SIGNAL_EXIT;
     }
   else
      if(posType == POSITION_TYPE_SELL && mEntrySignal == ENTRY_SIGNAL_BUY)
        {
         position.signal = EXIT_SIGNAL_EXIT;
        }
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void CStrategyImpl::Refresh(void)
  {
   Print("Refresh being called ", mSymbol);
   if(IsNewBar())
     {
      Print("Refresh being called - new bar ", mSymbol);
      m_BDpo.Refresh();

      //--- take values from indicator
      mEntrySignal = m_BDpo.TradeSignal(mIndLogic);
     }
  }

// the expert to run our strategy
CMultiExpert mMultiExpert(ExpertMagic, InpTimerFrequency, "Bounded DPO");
CStrategy  *allStrategyImpls[];
//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+
int OnInit()
  {
//-- get all the symbols
   string   tradingSymbols[];
   StringSplit(InpSymbols, '|', tradingSymbols);
   int noOfImpls =  ArraySize(tradingSymbols);

   ArrayResize(allStrategyImpls, noOfImpls);
   for(int i = 0; i < noOfImpls; i++)
     {
      allStrategyImpls[i] = new CStrategyImpl(tradingSymbols[i], InpTimeframe,
                                              InpHowToEnter, InpMaPeriod, InpPRankPeriod, InpOBLevel);
      allStrategyImpls[i].SetPositionManager(new CNoPositionManager(_Symbol, _Period));
     }
   mMultiExpert.LoadStrategyImpls(allStrategyImpls);

   if(mMultiExpert.OnInitHandler())
      return INIT_SUCCEEDED ;
   else
      return INIT_FAILED;
  }

//+------------------------------------------------------------------+
//| Expert deinitialization function                                 |
//+------------------------------------------------------------------+
void OnDeinit(const int reason)
  {
   mMultiExpert.OnDeinitHandler();
   for(int i = 0; i < ArraySize(allStrategyImpls); i++)
     {
      delete allStrategyImpls[i];
     }
  }

//+------------------------------------------------------------------+
//| Expert tick function                                             |
//+------------------------------------------------------------------+
void OnTimer()
  {
//---
   mMultiExpert.OnTimerHandler();
  }
//+------------------------------------------------------------------+
