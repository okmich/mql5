//+------------------------------------------------------------------+
//|                                           DailyCloseStrategy.mqh |
//|                                   Copyright 2023, Michael Enudi. |
//|                                             okmich2002@yahoo.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2023, Michael Enudi"
#property link      "okmich2002@yahoo.com"

#include "Strategy.mqh"

//+------------------------------------------------------------------+
//| The base class for strategy implementation                       |
//+------------------------------------------------------------------+
class CDailyCloseStrategy
  {
private:
   int               mHoldingBars;

protected:

   ///--- POSITION SIZING
   double            VerifyLots(double proposed);
   bool              IsNewBar();
   void              InitPositionProps();

   virtual Entry     FindEntry(const double ask, const double bid);
   virtual void      CheckAndSetExitSignal(CPositionInfo &positionInfo, Position &position)=0;
   //-- others
   bool              mIsNewBar;
public:
                     CDailyCloseStrategy(string symbol, ENUM_TIMEFRAMES timeFrame, int holdingBars = 1, int maxOpenPositionAllowed=1) : CStrategy(symbol, period, maxOpenPositionAllowed)
     {
      mHoldingBars = holdingBars;
     };

                    ~CDailyCloseStrategy()
     {
     }
  };

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void      CheckAndSetExitSignal(CPositionInfo &positionInfo, Position &position)
  {
   if(mPositionPros)
     {
      position.signal = EXIT_SIGNAL_EXIT;
     }
  }
//+------------------------------------------------------------------+
