//+------------------------------------------------------------------+
//|                                                          CCI.mq5 |
//|                                    Copyright 2021, Michael Enudi |
//|                                             okmich2002@yahoo.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2021, Michael Enudi"
#property link      "okmich2002@yahoo.com"
#property version   "1.00"

#include <Okmich\Expert\SingleExpert.mqh>
#include <Okmich\Indicators\Cci.mqh>

//--- input parameters
input group "********* Strategy settings *********";
input ENUM_TIMEFRAMES InpTimeframe = PERIOD_H1;             //Timeframe
input ENUM_LONG_SHORT_FLAG InpLongShortFlag = LONG_SHORT;   //Long/Short Flag
input bool InpUseExitFlag = true; //Use exit flag

input group "********* Indicator settings *********";
input ENUM_CCI_Strategies InpHowToEnter = CCI_ContraEnterOsOBLevels; //Entry options
input ENUM_CCI_Strategies InpHowToExit = CCI_CrossMidLevel; //Exit options
input int      InpCciPeriod=40;
input int      InpObOsLevel=100;

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
   ENUM_ENTRY_SIGNAL mExitEntrySignal;
   //--- indicator values
   double            mCloseShift1;
   //--- indicator settings
   int               mCciPeriod;
   int               mObOsLevel;

   //--- indicators
   CCci              *m_Cci;
   //--- indicator buffer
   double            m_CloseBuffer[];
   //-- others

public:
                     CMrv(string symbol, ENUM_TIMEFRAMES period, int InptCciPeriod, int InptObOsLevel): CStrategy(symbol, period)
     {
      mCciPeriod = InptCciPeriod;
      mObOsLevel = InptObOsLevel;

      mLotSize = InpLotSizeMultiple * SymbolInfoDouble(_Symbol, SYMBOL_VOLUME_MIN);
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
//--- m_Cci
   m_Cci = new CCci(mSymbol, mTimeframe, mCciPeriod, mObOsLevel);
   return m_Cci.Init();
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void CMrv::Release(void)
  {
   m_Cci.Release();
   delete m_Cci;
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void CMrv::CheckAndSetExitSignal(CPositionInfo &positionInfo, Position &position)
  {
   if(InpUseExitFlag)
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

      m_Cci.Refresh();

      //--- take values from indicator
      ENUM_ENTRY_SIGNAL signal = m_Cci.TradeSignal(InpHowToEnter);
      mEntrySignal = SupportShortEntries(InpLongShortFlag) && signal == ENTRY_SIGNAL_SELL ? signal :
                     SupportLongEntries(InpLongShortFlag) && signal == ENTRY_SIGNAL_BUY ? signal : ENTRY_SIGNAL_NONE;
      mExitEntrySignal = m_Cci.TradeSignal(InpHowToExit);
     }
  }

// the expert to run our strategy
CSingleExpert singleExpert(ExpertMagic, "CCI");

//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+
int OnInit()
  {
//set position management
   CPositionManager *mPositionManager = CreatPositionManager(_Symbol, InpTimeframe,
                                        InpPostManagmentType,
                                        InpATRPeriod, InpStopLossPoints, InpBreakEvenPoints, InpTrailingOrTpPoints,
                                        InpMaxLossAmount, InpScratchBreakEvenFlag, false, 5,
                                        InpStopLossMultiple, InpBreakEvenMultiple, InpTrailingOrTpMultiple);

//--- set up Trading Strategy Implementaion
   CMrv *strategy = new CMrv(_Symbol, InpTimeframe, InpCciPeriod, InpObOsLevel);
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
