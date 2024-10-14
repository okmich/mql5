//+------------------------------------------------------------------+
//|                                    ThomasCarter_2_15M_GBPUSD.mq5 |
//|                                    Copyright 2021, Michael Enudi |
//|                                             okmich2002@yahoo.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2021, Michael Enudi"
#property link      "okmich2002@yahoo.com"
#property version   "1.00"

#include <Okmich\Expert\SingleExpert.mqh>
#include <Okmich\Indicators\Macd.mqh>
#include <Okmich\Indicators\MovingAverage.mqh>

//--- input parameters
const ulong EXPERT_MAGIC = 98765001;
//+------------------------------------------------------------------+
//| Input parameters       CURRENT SETTINGS IS FOR GBPUSD            |
//+------------------------------------------------------------------+
input group "********* Strategy settings *********";
input ENUM_TIMEFRAMES InpTimeframe = PERIOD_M15;            //Timeframe
input ENUM_LONG_SHORT_FLAG InpLongShortFlag = LONG_SHORT;   //Long/Short Flag

input group "********* Long Strategy settings *********";
input int      InpLongEmaParam=20;
input ENUM_MA_TYPE      InpLongEmaMethod= MA_DEMA;
input int      InpLongFastMACDParam=22;
input int      InpLongSlowMACDParam=54;
input int      InpLongSignalMACDParam=9;
input int      InpLongMacdNoLongerThanBars = 3;

input group "********* Short Strategy settings *********";
input int      InpShortEmaParam=27;
input ENUM_MA_TYPE      InpShortEmaMethod= MA_SMA;
input int      InpShortFastMACDParam=22;
input int      InpShortSlowMACDParam=75;
input int      InpShortSignalMACDParam=9;
input int      InpShortMacdNoLongerThanBars = 3;

input group "********* Volume setting **********";
input int InpLotSizeMultiple = 3;                     //Multiple of minimum lot size

input group "********* Position management settings *********";
input ENUM_POSITION_MANAGEMENT InpPostManagmentType = POSITION_MGT_FIXED_POINTS;  // Type of Position Management Algorithm
input int InpATRPeriod = 14;                          // ATR Period
input double InpStopLossPoints = 200;                  // Stop loss distance in points
input double InpBreakEvenPoints = 300;                 // Points to Break-even
input double InpTrailingOrTpPoints = 300;              // Trailing/Take profit points
input double InpMaxLossAmount = 100.00;               // Maximum allowable loss in dollars
input bool InpScratchBreakEvenFlag = true;            // Enable break-even with scratch profit
input double InpStopLossMultiple = 2;                 // ATR multiple for stop loss
input double InpBreakEvenMultiple = 1;                // ATR multiple for break-even
input double InpTrailingOrTpMultiple = 2;             // ATR multiple for Maximum floating/Take profit


//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
class CStrategyImpl : public CStrategy
  {
private :
   //--- indicator values
   //--- indicators
   CMacd             *m_Macd[2];
   CMa               *m_Ma[2];
   //--- indicator buffer

protected:
   virtual Entry     FindEntry(const double ask, const double bid);

public:
                     CStrategyImpl(string symbol, ENUM_TIMEFRAMES period, int InptVolMultiple): CStrategy(symbol, period)
     {
      mLotSize = InptVolMultiple*SymbolInfoDouble(_Symbol, SYMBOL_VOLUME_MIN);
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
//--- m_Macds
   m_Macd[0] = new CMacd(mSymbol, mTimeframe, InpLongFastMACDParam, InpLongSlowMACDParam, InpLongSignalMACDParam);
   m_Macd[1] = new CMacd(mSymbol, mTimeframe, InpShortFastMACDParam, InpShortSlowMACDParam, InpShortSignalMACDParam);
   bool macdsOk = m_Macd[0].Init() && m_Macd[1].Init();
//--- m_Mas
   m_Ma[0] = new CMa(mSymbol, mTimeframe, InpLongEmaParam, InpLongEmaMethod, PRICE_CLOSE);
   m_Ma[1] = new CMa(mSymbol, mTimeframe, InpShortEmaParam, InpShortEmaMethod, PRICE_CLOSE);
   bool m_MasOk = m_Ma[0].Init() && m_Ma[1].Init();

   return macdsOk && m_MasOk;
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void CStrategyImpl::Release(void)
  {
   for(int i = 0; i< 2; i++)
     {
      m_Ma[i].Release();
      delete m_Ma[i];

      m_Macd[i].Release();
      delete m_Macd[i];
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
     {
      for(int i = 0; i< 2; i++)
        {
         //-- m_Ma
         m_Ma[i].Refresh(mRefShift);
         //-- m_Macd
         m_Macd[i].Refresh(mRefShift);
        }
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

   bool goLongerThanBarsAgo  = false;
   double prevPrice2 = iClose(mSymbol, mTimeframe, mRefShift+1);
   double prevPrice = iClose(mSymbol, mTimeframe, mRefShift);
   long spread = SymbolInfoInteger(mSymbol, SYMBOL_SPREAD);

   if(SupportLongEntries(InpLongShortFlag) &&
      prevPrice2 < m_Ma[0].GetData(mRefShift+1) &&
      prevPrice > m_Ma[0].GetData(mRefShift) &&
      m_Macd[0].GetData(0, mRefShift) > 0)
     {
      //check that the macd cross into position territory no longer than 5 bars ago
      for(int i = 0; i < InpLongMacdNoLongerThanBars; i++)
         if(m_Macd[0].GetData(0, mRefShift+1+i) < 0)
           {
            goLongerThanBarsAgo = true;
            break;
           }
      if(goLongerThanBarsAgo)
        {
         //enter x pip above ema
         double emaShift1 = m_Ma[0].GetData(mRefShift);
         double price = emaShift1 + 100 * OnePoint();
         double stop = emaShift1 - InpStopLossPoints * OnePoint();
         double tp = price + (spread + InpTrailingOrTpPoints) * OnePoint();
         entry = anEntry(mSymbol, ENTRY_SIGNAL_BUY_STOP, price, stop, tp, mLotSize, EXPERT_MAGIC);
         entry.order_expiry = 150 * 60;
        }
      else
         return entry;
     }

   if(SupportShortEntries(InpLongShortFlag) &&
      prevPrice2 > m_Ma[1].GetData(mRefShift+1) &&
      prevPrice < m_Ma[1].GetData(mRefShift) &&
      m_Macd[1].GetData(0, mRefShift) < 0)
     {
      //check that the macd cross into position territory no longer than 5 bars ago
      for(int i = 0; i < InpShortMacdNoLongerThanBars; i++)
         if(m_Macd[1].GetData(0, mRefShift+1+i) > 0)
           {
            goLongerThanBarsAgo = true;
            break;
           }
      if(goLongerThanBarsAgo)
        {
         //enter x pip below ema
         double emaShift1 = m_Ma[1].GetData(mRefShift);
         double price = emaShift1 - 100 * OnePoint();
         double stop = emaShift1 + InpStopLossPoints * OnePoint();
         double tp = price - (spread + InpTrailingOrTpPoints) * OnePoint();
         entry = anEntry(mSymbol, ENTRY_SIGNAL_SELL_STOP, price, stop, tp, mLotSize, EXPERT_MAGIC);
         entry.order_expiry = 150 * 60;
        }
      else
         return entry;
     }

   return entry;
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void CStrategyImpl::CheckAndSetExitSignal(CPositionInfo &positionInfo, Position &position)
  {
   ENUM_POSITION_TYPE postType = positionInfo.PositionType();
  }


// the expert to run our strategy
CSingleExpert singleExpert(EXPERT_MAGIC, "");

//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+
int OnInit()
  {
   CStrategy *strategy = new CStrategyImpl(_Symbol, InpTimeframe, InpLotSizeMultiple);
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
   singleExpert.OnTickHandler();
  }
//+------------------------------------------------------------------+
