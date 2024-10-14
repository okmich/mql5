//+------------------------------------------------------------------+
//|                                                 StrategyImpl.mqh |
//|                                    Copyright 2021, Michael Enudi |
//|                                             okmich2002@yahoo.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2021, Michael Enudi"
#property link      "okmich2002@yahoo.com"

#include "PositionManager.mqh"
#include <Okmich\Common\Common.mqh>
#include <Okmich\Expert\Orders.mqh>
#include <Trade\AccountInfo.mqh>
#include <Trade\OrderInfo.mqh>
#include <Trade\PositionInfo.mqh>

struct PositionsAggregate
  {
   int               buyPositions;
   double            buyProfit;
   double            buySwap;
   int               sellPositions;
   double            sellProfit;
   double            sellSwap;
   int               positions;
   double            profit;
   double            swap;
   double            totalProfit;
  };

//+------------------------------------------------------------------+
//| The base class for strategy implementation                       |
//+------------------------------------------------------------------+
class CStrategy
  {
private:
   datetime           m_LastBarTime;

protected:
   bool               takeLongPositions, takeShortPositions;
   ulong              _expertMagic;
   string             mSymbol;
   ENUM_TIMEFRAMES    mTimeframe;

   CTrade             mCTradeHandle;
   CAccountInfo       mAccountInfo;
   CPositionManager   *mPositionManager;

   PositionsAggregate mPosAgg;

   int                mMaxOpenPositionsAllowed;

   int               mRefShift;
   double            m_Point;
   double            m_MinStopLevel;
   double            mLotSize, mStopLoss, mTakeProfit;
   ENUM_ENTRY_SIGNAL mEntrySignal;
   ENUM_EXIT_SIGNAL  mExitSignal;

   ///--- POSITION SIZING
   double            VerifyLots(double proposed);
   bool              IsNewBar();
   void              InitPositionProps();

   virtual Entry     FindEntry(const double ask, const double bid);
   virtual void      CheckAndSetExitSignal(CPositionInfo &positionInfo, Position &position)=0;

   bool              PartialClose(const ulong ticket, const double vol);
   //-- others
   bool              mIsNewBar;
public:
                     CStrategy(string symbol, ENUM_TIMEFRAMES timeFrame, int maxOpenPositionAllowed=1)
     {
      mSymbol = symbol;
      mTimeframe = timeFrame;
      mMaxOpenPositionsAllowed = maxOpenPositionAllowed;

      m_Point = SymbolInfoDouble(mSymbol, SYMBOL_POINT);
      m_MinStopLevel = m_Point * SymbolInfoInteger(mSymbol, SYMBOL_TRADE_STOPS_LEVEL);
     };

                    ~CStrategy()
     {
      delete mPositionManager;
     }

   string            Symbol() { return mSymbol;};
   double            MinStopLevel() {return m_MinStopLevel;};
   double            OnePoint() {return m_Point;};
   ENUM_TIMEFRAMES   Timeframe() { return mTimeframe;};

   virtual bool      Init(ulong magic);
   virtual bool      CanTakeNewPositions(); //return true if based on this strategy, a position can be open
   virtual void      ManagePosition(CPositionInfo &positionInfo, Position &position);
   virtual void      CloseAllPosition() {};
   virtual void      Refresh()=0;
   virtual void      Release()=0;

   int               ShiftToUse();

   ///--- POSITION management
   void              FindAndExecutionEntry(const double ask, const double bid);
   void              FindAndManagePositions();
   CPositionManager* GetPositionManager() { return mPositionManager; };
   PositionsAggregate GetPositionsAggregate();
   void              SetPositionManager(CPositionManager *PositionManager) {mPositionManager = PositionManager;};
  };

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
bool CStrategy::Init(ulong magic)
  {
   _expertMagic = magic;
   if(mPositionManager == NULL)
     {
      SetUserError(13);
      return false;
     }
   mCTradeHandle.SetExpertMagicNumber(_expertMagic);

//set these flags to default
   takeLongPositions=true;
   takeShortPositions=true;

   return true;
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
Entry CStrategy::FindEntry(const double ask,const double bid)
  {
   Entry entry = noEntry(_expertMagic);
   if(!mIsNewBar || mEntrySignal == ENTRY_SIGNAL_NONE)
      return entry;

   entry.price = mEntrySignal == ENTRY_SIGNAL_BUY ? ask : bid;
   entry.signal = mEntrySignal;
   entry.sl = mStopLoss;
   entry.sym = mSymbol;
   entry.tp = mTakeProfit;
   entry.vol = mLotSize;

   return entry;
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void CStrategy::FindAndExecutionEntry(const double ask, const double bid)
  {
   Entry entry = FindEntry(ask, bid);
   if(entry.signal != ENTRY_SIGNAL_NONE)
      ExecuteEntryOrder(mCTradeHandle, entry, mTimeframe);

   ZeroMemory(entry);
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void CStrategy::FindAndManagePositions(void)
  {
   CPositionInfo positionInfo;
   Position position;
//---
   for(int i = PositionsTotal() - 1; i >= 0; i--)
     {
      positionInfo.SelectByIndex(i);
      if(positionInfo.Symbol() == mSymbol &&  positionInfo.Magic() == _expertMagic)
        {
         //select the position
         positionInfo.SelectByIndex(i);
         //set the symbol for this
         position.sym = mSymbol;
         //set default signal
         position.signal = EXIT_SIGNAL_HOLD;
         //manage position
         ManagePosition(positionInfo, position);
        }
     }
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void CStrategy::ManagePosition(CPositionInfo &positionInfo, Position &position)
  {
   if(mIsNewBar)
     {
      mPositionManager.Refresh();
      CheckAndSetExitSignal(positionInfo, position);
      mPositionManager.ExecutePositionOrder(mCTradeHandle, positionInfo, position);
     }
   else
     {
      mPositionManager.ManagePosition(mCTradeHandle, positionInfo);
     }
   ZeroMemory(position);
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
bool CStrategy::PartialClose(const ulong ticket, const double vol)
  {
   return mPositionManager.PartialClose(mCTradeHandle, ticket, vol);
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
bool CStrategy::CanTakeNewPositions(void)
  {
   GetPositionsAggregate();
   return mPosAgg.positions < mMaxOpenPositionsAllowed;
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
int CStrategy::ShiftToUse(void)
  {
   datetime currentTime = TimeCurrent();
   datetime openTime = iTime(mSymbol, mTimeframe,0);
   if(isPastNPercentWithinTF(mTimeframe, 85,currentTime, openTime))
      mRefShift = 0;
   else
      mRefShift = 1;

   return mRefShift;
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
bool CStrategy::IsNewBar()
  {
   mIsNewBar = false;
   datetime currentBarTime = iTime(mSymbol, mTimeframe, 0);
   if(m_LastBarTime == 0 || m_LastBarTime != currentBarTime)
     {
      m_LastBarTime = currentBarTime;
      mIsNewBar = true;
      return mIsNewBar;
     }

   return mIsNewBar;
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
PositionsAggregate CStrategy::GetPositionsAggregate(void)
  {
   CPositionInfo positionInfo;
   mPosAgg.buyPositions = 0;
   mPosAgg.buyProfit = 0;
   mPosAgg.buySwap = 0;
   mPosAgg.sellPositions = 0;
   mPosAgg.sellProfit = 0;
   mPosAgg.sellSwap = 0;
//---
   for(int i = PositionsTotal() - 1; i >= 0; i--)
     {
      positionInfo.SelectByIndex(i);
      if(positionInfo.Symbol() == mSymbol &&  positionInfo.Magic() == _expertMagic)
        {
         if(positionInfo.PositionType() == POSITION_TYPE_SELL)
           {
            mPosAgg.sellPositions++;
            mPosAgg.sellProfit += positionInfo.Profit();
            mPosAgg.sellSwap += positionInfo.Swap() + positionInfo.Commission();
           }
         else
            if(positionInfo.PositionType() == POSITION_TYPE_BUY)
              {
               mPosAgg.buyPositions++;
               mPosAgg.buyProfit += positionInfo.Profit();
               mPosAgg.buySwap += positionInfo.Swap() + positionInfo.Commission();
              }
        }
     }
   mPosAgg.positions =  mPosAgg.sellPositions+ mPosAgg.buyPositions;
   mPosAgg.profit = mPosAgg.sellProfit + mPosAgg.buyProfit;
   mPosAgg.swap  =  mPosAgg.sellSwap + mPosAgg.buySwap;
   mPosAgg.totalProfit = mPosAgg.profit + mPosAgg.swap;

   return mPosAgg;
  }
//+------------------------------------------------------------------+
