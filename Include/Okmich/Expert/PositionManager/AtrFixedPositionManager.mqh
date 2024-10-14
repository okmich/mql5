//+------------------------------------------------------------------+
//|                                      AtrFixedPositionManager.mqh |
//|                                                    Michael Enudi |
//|                                             okmich2002@yahoo.com |
//+------------------------------------------------------------------+
#property copyright "Michael Enudi"
#property link      "okmich2002@yahoo.com"

#include "FixedPositionManager.mqh"


//+-------------------------------------------------------------------------------------+
//| This type of position manager shares similar properties with the                    |
//| CFixedPositionManager, i.e. it has a fixed stop loss and profit                     |
//| target levels.                                |
//| However, the stop loss and take profit levels are determined by ATR value multiples.|
//+-------------------------------------------------------------------------------------+
class CAtrFixedPositionManager : public CFixedPositionManager
  {
private:
   CAtrReader             *mCAtrReader;
   //various multiples of ATR to use
   double            mBreakEvenMultiple;
   double            mStopLossMultiple;
   double            mTakeProfitMultiple;

protected:
   virtual void              manageLongPosition(CTrade &mTradeHandle, CPositionInfo &positionInfo)
     {
      Refresh();
      CFixedPositionManager::manageLongPosition(mTradeHandle, positionInfo);
     };

   virtual void              manageShortPosition(CTrade &mTradeHandle, CPositionInfo &positionInfo)
     {
      Refresh();
      CFixedPositionManager::manageShortPosition(mTradeHandle, positionInfo);
     };

public:
                     CAtrFixedPositionManager(string symbolName,
                            ENUM_TIMEFRAMES timeframe,
                            int atrPeriod,
                            double stopLossMultiple,
                            double breakEvenMultiple,
                            double takeProfitMultiple,
                            double maxLossAmnt,
                            bool isScratchBrkEven,
                            bool useHiddenStopLoss,
                            double hardStopLossMultiple): CFixedPositionManager(symbolName, timeframe,
                                     0, 0, 0,
                                     maxLossAmnt,
                                     isScratchBrkEven,
                                     useHiddenStopLoss,
                                     hardStopLossMultiple)
     {
      mCAtrReader = new CAtrReader(mSymbolInfo.Name(), timeframe, atrPeriod);

      mBreakEvenMultiple = breakEvenMultiple;
      mStopLossMultiple = stopLossMultiple;
      mTakeProfitMultiple = takeProfitMultiple;

      Refresh();
     };

                    ~CAtrFixedPositionManager(void);
                    
   void              SetBreakEvenMultiple(double beMult) { this.mBreakEvenMultiple=beMult; }
   void              SetStopLossMultiple(double slMult) { this.mStopLossMultiple=slMult; }
   void              SetTakeProfitMultiple(double tpMult) { this.mTakeProfitMultiple=tpMult; }

   virtual void      Refresh();

   virtual double    GetStopLoss(Entry &entry);
   virtual double    GetTakeProfit(Entry &entry);

   virtual double    atrPoints(int shift = 1) { return mCAtrReader.atr(shift);};
  };


//////////////////////// CAtrFixedPositionManager /////////////////////////
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
CAtrFixedPositionManager::~CAtrFixedPositionManager(void)
  {
   delete mCAtrReader;
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void CAtrFixedPositionManager::Refresh(void)
  {
   double mAtrPoints = mCAtrReader.atrPoints();

   mBreakEvenPoints = mBreakEvenMultiple * mAtrPoints;
   mStopLossPoints = mStopLossMultiple * mAtrPoints;
   mMaxFloatingPoints = mTakeProfitMultiple * mAtrPoints;
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
double CAtrFixedPositionManager::GetStopLoss(Entry &entry)
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
double CAtrFixedPositionManager::GetTakeProfit(Entry &entry)
  {
   double takeProfDist = ((mUseHiddenStopLoss) ? mMaxFloatingPoints * mHiddenStopLossMultiple : mMaxFloatingPoints)
                         * mSymbolInfo.Point();
   switch(entry.signal)
     {
      case ENTRY_SIGNAL_BUY:
         return entry.price + takeProfDist;
      case ENTRY_SIGNAL_SELL:
         return entry.price - takeProfDist;
      default:
         return 0;
     }
  }
//+------------------------------------------------------------------+
