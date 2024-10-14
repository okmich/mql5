//+------------------------------------------------------------------+
//|                                   AtrFlexiblePositionManager.mqh |
//|                                                    Michael Enudi |
//|                                             okmich2002@yahoo.com |
//+------------------------------------------------------------------+
#property copyright "Michael Enudi"
#property link      "okmich2002@yahoo.com"

#include "FlexiblePositionManager.mqh"

//+-------------------------------------------------------------------------------------+
//| This type of position manager shares similar properties with the                    |
//| CFlexiblePositionManager, i.e. it has a fixed stop loss but without profit          |
//| target levels                                                       	             |
//| However, the stop loss, breakeven and take profit levels are determined by ATR      |
//| value multiples.                                                                    |
//+-------------------------------------------------------------------------------------+
class CAtrFlexiblePositionManager : public CFlexiblePositionManager
  {
private:
   CAtrReader             *mCAtrReader;
   //various multiples of ATR to use
   double            mBreakEvenMultiple;
   double            mStopLossMultiple;
   double            mFloatPointMultiple;

protected:

protected:
   virtual void              manageLongPosition(CTrade &mTradeHandle, CPositionInfo &positionInfo)
     {
      Refresh();
      CFlexiblePositionManager::manageLongPosition(mTradeHandle, positionInfo);
     };

   virtual void              manageShortPosition(CTrade &mTradeHandle, CPositionInfo &positionInfo)
     {
      Refresh();
      CFlexiblePositionManager::manageShortPosition(mTradeHandle, positionInfo);
     };

public:
                     CAtrFlexiblePositionManager(string symbolName,
                               ENUM_TIMEFRAMES timeframe,
                               int atrPeriod,
                               double stopLossMultiple,
                               double breakEvenMultiple,
                               double floatPointsMultiple,
                               double maxLossAmnt,
                               bool isScratchBrkEven,
                               bool useHiddenStopLoss,
                               double hardStopLossMultiple): CFlexiblePositionManager(symbolName, timeframe,
                                        0, 0, 0,
                                        maxLossAmnt,
                                        isScratchBrkEven,
                                        useHiddenStopLoss,
                                        hardStopLossMultiple)
     {
      mCAtrReader = new CAtrReader(mSymbolInfo.Name(), timeframe, atrPeriod);

      mBreakEvenMultiple = breakEvenMultiple;
      mStopLossMultiple = stopLossMultiple;
      mFloatPointMultiple = floatPointsMultiple;

      Refresh();
     };

                    ~CAtrFlexiblePositionManager();

   virtual bool      TightenPosition(CTrade &mTradeHandle, CPositionInfo &positionInfo)
     {
      Refresh();
      return CFlexiblePositionManager::TightenPosition(mTradeHandle, positionInfo);
     };

   virtual void      Refresh();

   virtual double    GetStopLoss(Entry &entry);
   virtual double    GetTakeProfit(Entry &entry);

   virtual double    atrPoints(int shift = 1) { return mCAtrReader.atrPoints(shift);};
  };

//////////////////////// CAtrFlexiblePositionManager /////////////////////////
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
CAtrFlexiblePositionManager::~CAtrFlexiblePositionManager(void)
  {
   delete mCAtrReader;
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void CAtrFlexiblePositionManager::Refresh(void)
  {
   double mAtrPoints = atrPoints();

   SetBreakEvenPoints(mBreakEvenMultiple * mAtrPoints);
   SetStopLossPnts(mStopLossMultiple * mAtrPoints);
   SetTakeProfitPoints(mFloatPointMultiple * mAtrPoints);
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
double CAtrFlexiblePositionManager::GetStopLoss(Entry &entry)
  {
   double stopDist = ((mUseHiddenStopLoss) ? mStopLossPoints * mHiddenStopLossMultiple : mStopLossPoints) * mSymbolInfo.Point();
   switch(entry.signal)
     {
      case ENTRY_SIGNAL_BUY:
         return entry.price - stopDist;
      case ENTRY_SIGNAL_SELL:
         return entry.price + stopDist;
      default:
         return 0;
     }
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
double CAtrFlexiblePositionManager::GetTakeProfit(Entry &entry)
  {
   return 0;
  }
//+------------------------------------------------------------------+
