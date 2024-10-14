//+------------------------------------------------------------------+
//|                                                   Stochastic.mq5 |
//|                                    Copyright 2021, Michael Enudi |
//|                                             okmich2002@yahoo.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2021, Michael Enudi"
#property link      "okmich2002@yahoo.com"
#property version   "1.00"

#include <Okmich\Expert\SingleExpert.mqh>
#include <Okmich\Indicators\StochasticOscillator.mqh>

//--- input parameters
input group "********* Strategy settings *********";
input ENUM_TIMEFRAMES InpTimeframe = PERIOD_H1;             //Timeframe
input ENUM_LONG_SHORT_FLAG InpLongShortFlag = LONG_SHORT;   //Long/Short Flag

input group "********* Trading strategy settings *********";
input ENUM_STOCH_Strategies InpHowToEnter = STOCH_EnterOsOBLevels; //Entry strategy
input int      InpKPeriod=5;
input int      InpDPeriod=3;
input int      InpSlowing=3;
input double      InpOBLevel=80;
input ENUM_STO_PRICE InpFieldType = STO_LOWHIGH;
input ENUM_MA_METHOD InpSmoothing = MODE_SMA;
input double InpDefaultVolume=0.1; //Lot size

input ulong    ExpertMagic           = 980023;              //Expert MagicNumbers

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
class CMrv : public CStrategy
  {
private :
   //--- indicator values
   ENUM_ENTRY_SIGNAL signal;
   double            mCloseShift1;
   //--- indicator settings
   int               mKPeriod, mDPeriod, mSlowing;
   double            mOBLevel, mOSLevel;
   ENUM_STO_PRICE    mFieldType;
   ENUM_MA_METHOD    mSmoothing;

   //--- indicators
   CStochastic       *m_Stoch;
   //--- indicator buffer
   double            m_CloseBuffer[];
   //-- others


public:
                     CMrv(string symbol, ENUM_TIMEFRAMES period,
        int InptKPeriod, int InptDPeriod, int InptSlowing,
        double InptOBLevel, double InptOSLevel, ENUM_STO_PRICE InptFieldType,
        ENUM_MA_METHOD InptSmoothing): CStrategy(symbol, period)
     {
      mKPeriod = InptKPeriod;
      mDPeriod = InptDPeriod;
      mSlowing = InptSlowing;
      mOBLevel = InptOBLevel;
      mOSLevel = InptOSLevel;
      mFieldType = InptFieldType;
      mSmoothing = InptSmoothing;

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
bool CMrv::Init(ulong magic)
  {
   CStrategy::Init(magic);
//--- price buffers
   ArraySetAsSeries(m_CloseBuffer, true);
//--- stoch_rsi
   m_Stoch = new CStochastic(mSymbol, mTimeframe, mKPeriod, mDPeriod, mSlowing, mFieldType, mSmoothing,
                             mOBLevel, mOSLevel);
   return m_Stoch.Init();
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void CMrv::Release(void)
  {
   m_Stoch.Release();
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void CMrv::CheckAndSetExitSignal(CPositionInfo &positionInfo, Position &position)
  {
   ENUM_POSITION_TYPE posType = positionInfo.PositionType();
   if(posType == POSITION_TYPE_BUY && signal == ENTRY_SIGNAL_SELL)
     {
      position.signal = EXIT_SIGNAL_EXIT;
     }
   else
      if(posType == POSITION_TYPE_SELL && signal == ENTRY_SIGNAL_BUY)
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

      m_Stoch.Refresh();

      //--- take values from indicator
      signal = m_Stoch.TradeSignal(InpHowToEnter);
      mEntrySignal = SupportShortEntries(InpLongShortFlag) && signal == ENTRY_SIGNAL_SELL ? signal :
                     SupportLongEntries(InpLongShortFlag) && signal == ENTRY_SIGNAL_BUY ? signal : ENTRY_SIGNAL_NONE;
     }
  }

// the expert to run our strategy
CSingleExpert singleExpert(ExpertMagic, "...");

//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+
int OnInit()
  {
//--- set up Position manager Implementaion
   CPositionManager *positionManager = new CNoPositionManager(_Symbol, _Period);
//--- set up Trading Strategy Implementaion
   CMrv *strategy = new CMrv(_Symbol, _Period,
                             InpKPeriod, InpDPeriod, InpSlowing,
                             InpOBLevel, 100-InpOBLevel,
                             InpFieldType, InpSmoothing);
   strategy.SetPositionManager(positionManager);
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
//---
   singleExpert.OnTickHandler();
  }
//+------------------------------------------------------------------+
