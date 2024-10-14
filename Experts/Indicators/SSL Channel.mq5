//+------------------------------------------------------------------+
//|                                                  SSL Channel.mq5 |
//|                                    Copyright 2021, Michael Enudi |
//|                                             okmich2002@yahoo.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2021, Michael Enudi"
#property link      "okmich2002@yahoo.com"
#property version   "1.00"

#include <Okmich\Expert\SingleExpert.mqh>
#include <Okmich\Indicators\SSL.mqh>

//--- input parameters
input group "********* Setting **********";
input ENUM_TIMEFRAMES InpTimeframe = PERIOD_H1;             //Timeframe
input ENUM_LONG_SHORT_FLAG InpLongShortFlag = LONG;   //Long/Short Flag

input group "********* Strategy settings *********";
input int      InpMaPeriod=20;                        // Period
input ENUM_SSL_MODE      InpMaMethod=MODE_SSL_SMA;    // Smoothing Method

input group "********* Position management settings *********";
input ENUM_POSITION_MANAGEMENT InpPostManagmentType = POSITION_MGT_NONE;  // Type of Position Management Algorithm
input int InpATRPeriod = 14;                         // ATR Period
input double InpStopLossPoints = -1;                 // Stop loss distance
input double InpBreakEvenPoints = -1;                // Points to Break-even
input double InpMaxFloatingPoints = -1;              // Maximum floating points/Take profit points
input double InpMaxLossAmount = 30.00;               // Maximum allowable loss in dollars
input bool InpScratchBreakEvenFlag = true;           // Enable break-even with scratch profit
input bool InpUseHiddenStops = false;                // Enable hidden stops
input double InpHiddenStopMultiple = 3;              // Hardstops (applicable only when hidden stop is enabled)
input double InpStopLossMultiple = 2;                // ATR multiple for stop loss
input double InpBreakEvenMultiple = 2;               // ATR multiple for break-even
input double InpFloatPointsMultiple = 5;             // ATR multiple for Maximum floating/Take profit

input group "********* Trade Size settings *********";
input int   InpTradeVolMultiple = 1;               // Minimum Lot size multiple

input group "********* Other Settings *********";
input ulong    ExpertMagic             = 2983233;      //Expert MagicNumber

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
class CStrategyImpl : public CStrategy
  {
private :
   //--- indicator values
   ENUM_ENTRY_SIGNAL signal;
   //--- indicator settings
   int               mMaPeriod;
   ENUM_SSL_MODE     mSmoothingMethod;
   //--- indicators
   CSsl              *m_Ssl;
   //--- indicator buffer
   double            m_CloseBuffer[];
   //-- others

public:
                     CStrategyImpl(string symbol, ENUM_TIMEFRAMES period, 
                     int InptMaPeriod, ENUM_SSL_MODE InptSmoothingMethod,
                     int InptLotSizeMultiple): CStrategy(symbol, period)
     {
      mMaPeriod = InptMaPeriod;
      mSmoothingMethod = InptSmoothingMethod;

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
//--- price buffers
   ArraySetAsSeries(m_CloseBuffer, true);
//--- m_Ssl
   m_Ssl = new CSsl(mSymbol, mTimeframe, mMaPeriod, mSmoothingMethod);
   return m_Ssl.Init();
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void CStrategyImpl::Release(void)
  {
   m_Ssl.Release();
   delete m_Ssl;
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
   if(IsNewBar())
     {
      int barsToCopy = 10;
      //--- price buffers
      int closeBarsCopied = CopyClose(mSymbol, mTimeframe, 0, barsToCopy, m_CloseBuffer);

      m_Ssl.Refresh(mRefShift);

      //--- take values from indicator
      signal = m_Ssl.TradeSignal();
      mEntrySignal = SupportShortEntries(InpLongShortFlag) && signal == ENTRY_SIGNAL_SELL ? signal :
                     SupportLongEntries(InpLongShortFlag) && signal == ENTRY_SIGNAL_BUY ? signal : ENTRY_SIGNAL_NONE;
     }
  }

// the expert to run our strategy
CSingleExpert expert(ExpertMagic, "SSL Channel");

//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+
int OnInit()
  {
//--- set up Position manager Implementation
   CPositionManager *positionManager = CreatPositionManager(_Symbol, _Period, InpPostManagmentType,
                                       InpATRPeriod, InpStopLossPoints, InpBreakEvenPoints,
                                       InpMaxFloatingPoints, InpMaxLossAmount, InpScratchBreakEvenFlag,
                                       InpUseHiddenStops, InpHiddenStopMultiple, InpStopLossMultiple,
                                       InpBreakEvenMultiple, InpFloatPointsMultiple);
//--- set up Trading Strategy Implementaion
   CStrategyImpl *strategy = new CStrategyImpl(_Symbol, _Period,
                             InpMaPeriod, InpMaMethod, InpTradeVolMultiple);
   strategy.SetPositionManager(positionManager);
   expert.SetStrategyImpl(strategy);

//---

   if(expert.OnInitHandler())
      return INIT_SUCCEEDED ;
   else
      return INIT_FAILED;
  }

//+------------------------------------------------------------------+
//| Expert deinitialization function                                 |
//+------------------------------------------------------------------+
void OnDeinit(const int reason)
  {
   expert.OnDeinitHandler();
  }

//+------------------------------------------------------------------+
//| Expert tick function                                             |
//+------------------------------------------------------------------+
void OnTick()
  {
//---
   expert.OnTickHandler();
  }
//+------------------------------------------------------------------+
