//+------------------------------------------------------------------+
//|                                               BollingerBands.mq5 |
//|                                    Copyright 2021, Michael Enudi |
//|                                             okmich2002@yahoo.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2021, Michael Enudi"
#property link      "okmich2002@yahoo.com"
#property version   "1.00"

#include <Okmich\Expert\SingleExpert.mqh>
#include <Okmich\Indicators\BollingerBands.mqh>

//--- input parameters
input ENUM_BB_Strategies InpHowToEnter = BB_AboveBelow_Bands; //Entry options
input ENUM_BB_Strategies InpHowToExit = BB_AboveBelow_MidLine; //Exit options
input int      InpPeriod=20;
input double   InpDeviation=2.0;
input ENUM_MA_METHOD      InpMaMethod=MODE_SMA;

input group "********* Trade Size settings *********";
input int   InpTradeVolMultiple = 1;               // Minimum Lot size multiple

input ulong    ExpertMagic           = 980023;              //Expert MagicNumbers

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
class CMrv : public CStrategy
  {
private :
   ENUM_ENTRY_SIGNAL mExitEntrySignal;
   //--- indicator values
   double            mCloseShift1;
   double            mCloseShift2;
   //--- indicator settings
   int               mPeriod;
   double            mDeviation;
   ENUM_MA_METHOD    mMaMethod;

   //--- indicators
   CBollingerBands   *m_BBands;
   //--- indicator buffer
   double            m_CloseBuffer[];
   //-- others

public:
                     CMrv(string symbol, ENUM_TIMEFRAMES period,
        int InptPeriod, double InptDeviatn, ENUM_MA_METHOD InptMaMethod,
        int InptLotSizeMultiple): CStrategy(symbol, period)
     {
      mPeriod = InptPeriod;
      mDeviation = InptDeviatn;
      mMaMethod = InptMaMethod;
      
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
bool CMrv::Init(ulong magic)
  {
   CStrategy::Init(magic);
//--- price buffers
   ArraySetAsSeries(m_CloseBuffer, true);
//--- bbands
   m_BBands = new CBollingerBands(mSymbol, mTimeframe, mPeriod, mDeviation, mMaMethod);
   return m_BBands.Init();
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void CMrv::Release(void)
  {
   m_BBands.Release();
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void CMrv::CheckAndSetExitSignal(CPositionInfo &positionInfo, Position &position)
  {
   ENUM_POSITION_TYPE posType = positionInfo.PositionType();
   if(posType == POSITION_TYPE_BUY && mExitEntrySignal == ENTRY_SIGNAL_SELL)
     {
      position.signal = EXIT_SIGNAL_EXIT;
     }
   else
      if(posType == POSITION_TYPE_SELL && mExitEntrySignal == ENTRY_SIGNAL_BUY)
        {
         position.signal = EXIT_SIGNAL_EXIT;
        }
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void CMrv::Refresh(void)
  {
   if(IsNewBar())
     {
      int barsToCopy = 10;
      //--- price buffers
      int closeBarsCopied = CopyClose(mSymbol, mTimeframe, 0, barsToCopy, m_CloseBuffer);

      bool bbRefreshed = m_BBands.Refresh();
      //--- take values from indicator
      mEntrySignal = m_BBands.TradeSignal(InpHowToEnter);
      mExitEntrySignal = m_BBands.TradeSignal(InpHowToExit);
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
   CMrv *strategy = new CMrv(_Symbol, _Period,
                             InpPeriod, InpDeviation, InpMaMethod, InpTradeVolMultiple);
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
