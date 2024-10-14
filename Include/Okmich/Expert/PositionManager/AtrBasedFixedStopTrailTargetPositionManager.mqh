//+------------------------------------------------------------------+
//|                  AtrBasedFixedStopTrailTargetPositionManager.mqh |
//|                                                    Michael Enudi |
//|                                             okmich2002@yahoo.com |
//+------------------------------------------------------------------+
#property copyright "Michael Enudi"
#property link      "okmich2002@yahoo.com"

#include "FixedStopTrailTargetPositionManager.mqh"

//+-------------------------------------------------------------------------------------+
//| This type of position manager shares similar properties with the                    |
//| CFixedStopTrailTargetPositionManager, i.e. it has a fixed stop loss and profit      |
//| target levels but uses the breakEvenPnts value to trail the stop until either       |
//| levels are hit.																			             |
//| However, the stop loss, break even and take profit levels are determined by ATR     |
//| value multiples.																			             |
//+-------------------------------------------------------------------------------------+
class CAtrBasedFixedStopTrailTargetPositionManager : public CFixedStopTrailTargetPositionManager
  {
private:
   CAtrReader        *mCAtrReader;
   //various multiples of ATR to use
   double            mBreakEvenMultiple;
   double            mStopLossMultiple;
   double            mFloatPointMultiple;

protected:
   virtual void              manageLongPosition(CTrade &mTradeHandle, CPositionInfo &positionInfo)
     {
      Refresh();
      CFixedStopTrailTargetPositionManager::manageLongPosition(mTradeHandle, positionInfo);
     };

   virtual void              manageShortPosition(CTrade &mTradeHandle, CPositionInfo &positionInfo)
     {
      Refresh();
      CFixedStopTrailTargetPositionManager::manageShortPosition(mTradeHandle, positionInfo);
     };

public:
                     CAtrBasedFixedStopTrailTargetPositionManager(string symbolName,
         ENUM_TIMEFRAMES timeframe,
         int atrPeriod,
         double stopLossMultiple,
         double breakEvenMultiple,
         double floatPointsMultiple,
         double maxLossAmnt,
         bool isScratchBrkEven,
         bool useHiddenStopLoss,
         double hardStopLossMultiple): CFixedStopTrailTargetPositionManager(symbolName, timeframe,
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

                    ~CAtrBasedFixedStopTrailTargetPositionManager()
     {
      delete mCAtrReader;
     };

   virtual void      Refresh();
  };

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void CAtrBasedFixedStopTrailTargetPositionManager::Refresh(void)
  {
   double mAtrPoints = mCAtrReader.atrPoints(0);

   mBreakEvenPoints = mBreakEvenMultiple * mAtrPoints;
   mStopLossPoints = mStopLossMultiple * mAtrPoints;
   mMaxFloatingPoints = mFloatPointMultiple * mAtrPoints;
  }
//+------------------------------------------------------------------+
