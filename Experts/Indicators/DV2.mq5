//+------------------------------------------------------------------+
//|                                                          RSI.mq5 |
//|                                    Copyright 2021, Michael Enudi |
//|                                             okmich2002@yahoo.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2021, Michael Enudi"
#property link      "okmich2002@yahoo.com"
#property version   "1.00"

#include <Okmich\Expert\SingleExpert.mqh>
#include <Okmich\Indicators\DV2.mqh>

//--- input parameters
input group "********* Strategy settings *********";
input ENUM_TIMEFRAMES InpTimeframe = PERIOD_H1;             //Timeframe
input ENUM_LONG_SHORT_FLAG InpLongShortFlag = LONG_SHORT;   //Long/Short Flag

input group "********* Indicator settings *********";
input ENUM_DVO_Strategies InpHowTo = DVO_EnterOsOBLevels; //Strategy for entry
input int      InpMaPeriod=2;
input int      InpPRankPeriod=252;
input int      InpOBLevel=85;
input int      InpOSLevel=15;
input ulong    ExpertMagic           = 980023;              //Expert MagicNumbers

input group "********* Volume setting **********";
input int InpLotSizeMultiple = 1;                     //Multiple of minimum lot size

input group "********* Position management settings *********";
input ENUM_POSITION_MANAGEMENT InpPostManagmentType = POSITION_MGT_FIXED_ATR_MULTIPLES;  // Type of Position Management Algorithm
input int InpATRPeriod = 14;                          // ATR Period
input double InpStopLossPoints = -1;                  // Stop loss distance in points
input double InpBreakEvenPoints = -1;                 // Points to Break-even
input double InpTrailingOrTpPoints = -1;              // Trailing/Take profit points
input double InpMaxLossAmount = 100.00;               // Maximum allowable loss in dollars
input bool InpScratchBreakEvenFlag = true;            // Enable break-even with scratch profit
input double InpStopLossMultiple = 2;                 // ATR multiple for stop loss
input double InpBreakEvenMultiple = 1;                // ATR multiple for break-even
input double InpTrailingOrTpMultiple = 2;             // ATR multiple for Maximum floating/Take profit

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
class CMrv : public CStrategy
  {
private :
   //--- indicator values
   ENUM_ENTRY_SIGNAL signal;
   double            mCloseShift1;
   double            mCloseShift2;
   //--- indicator settings
   int               mMaPeriod, mPRankPeriod;
   int               mOBLevel;
   int               mOSLevel;

   //--- indicators
   CDvo              *m_Dv2;
   //--- indicator buffer
   double            m_CloseBuffer[];
   //-- others

public:
                     CMrv(string symbol, ENUM_TIMEFRAMES period,
        int InptMaPeriod, int InptPRankPeriod, int InptOBLevel, int InptOSLevel): CStrategy(symbol, period)
     {
      mMaPeriod = InptMaPeriod;
      mPRankPeriod = InptPRankPeriod;
      mOBLevel = InptOBLevel;
      mOSLevel = InptOSLevel;

      mLotSize = InpLotSizeMultiple * SymbolInfoDouble(mSymbol, SYMBOL_VOLUME_MIN);
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
//--- dv2
   m_Dv2 = new CDvo(mSymbol, mTimeframe, mMaPeriod, mPRankPeriod, mOBLevel, mOSLevel,10);
   return m_Dv2.Init();
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void CMrv::Release(void)
  {
   m_Dv2.Release();
   delete m_Dv2;
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

      m_Dv2.Refresh(mRefShift);

      //--- take values from indicator
      signal = m_Dv2.TradeSignal(InpHowTo);
      mEntrySignal = SupportShortEntries(InpLongShortFlag) && signal == ENTRY_SIGNAL_SELL ? signal :
                     SupportLongEntries(InpLongShortFlag) && signal == ENTRY_SIGNAL_BUY ? signal : ENTRY_SIGNAL_NONE;
     }
  }

// the expert to run our strategy
CSingleExpert singleExpert(ExpertMagic, "DV2");

//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+
int OnInit()
  {
//--- set up Trading Strategy Implementaion
   CMrv *strategy = new CMrv(_Symbol, InpTimeframe,
                             InpMaPeriod, InpPRankPeriod, InpOBLevel, InpOSLevel);

//set position management
   CPositionManager *mPositionManager = CreatPositionManager(_Symbol, InpTimeframe,
                                        InpPostManagmentType,
                                        InpATRPeriod, InpStopLossPoints, InpBreakEvenPoints, InpTrailingOrTpPoints,
                                        InpMaxLossAmount, InpScratchBreakEvenFlag, false, 5,
                                        InpStopLossMultiple, InpBreakEvenMultiple, InpTrailingOrTpMultiple);
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
//---
   singleExpert.OnTickHandler();
  }
//+------------------------------------------------------------------+
