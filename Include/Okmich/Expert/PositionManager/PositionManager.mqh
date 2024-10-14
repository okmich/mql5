//+------------------------------------------------------------------+
//|                                          BasePositionManager.mqh |
//|                                                    Michael Enudi |
//|                                             okmich2002@yahoo.com |
//+------------------------------------------------------------------+
#property copyright "Michael Enudi"
#property link      "okmich2002@yahoo.com"

#include <Okmich\Common\AtrReader.mqh>
#include <Okmich\Common\Common.mqh>
#include <Trade\AccountInfo.mqh>
#include <Trade\PositionInfo.mqh>
#include <Trade\SymbolInfo.mqh>
#include <Trade\Trade.mqh>

enum ENUM_POSITION_MANAGEMENT
  {
   POSITION_MGT_FIXED_POINTS,             // Point-Based Fixed Stop/Target
   POSITION_MGT_FLEX_POINTS,              // Point-Based Flexible
   POSITION_MGT_FIXED_SL_TRAIL_TP_POINTS, // Point-Based Fixed Stop/Target with Trailing
   POSITION_MGT_FIXED_ATR_MULTIPLES,      // ATR-Based Fixed Stop/Target
   POSITION_MGT_FLEX_ATR_MULTIPLES,       // ATR-Based Flexible
   POSITION_MGT_FIXED_SL_TRAIL_TP_ATR,    // ATR-Based Fixed Stop/Target with Trailing
   POSITION_MGT_MAX_LOSS_AMOUNT,          // Max Loss Amount Exit
   POSITION_MGT_NONE                      // None
  };


//+------------------------------------------------------------------+
//| //////////////////// Class definitions ///////////////////////// |
//+------------------------------------------------------------------+
class CPositionManager : public CObject
  {
protected:
   double            mStopLossPoints;    //stop loss for a single position on a trade
   double            mBreakEvenPoints;    //dictates the price level at which we must break even
   double            mMaxFloatingPoints;  //dictates the price level at which we must lock in profit or take profit price
   double            mMaxLossAmount;     //dictate how much we can lose in case our stop loss was not filled
   bool              mUseScratchBreakEven;  //dictates if we must add spread points when breaking even
   bool              mUseHiddenStopLoss;   //dictates whether to use a hidden stop loss
   double            mHiddenStopLossMultiple; //dictates how far the hard stop loss should be
   ENUM_TIMEFRAMES   mTimeframe;
   CSymbolInfo       mSymbolInfo;

   virtual void      manageLongPosition(CTrade &mTradeHandle, CPositionInfo &positionInfo) {};
   virtual void      manageShortPosition(CTrade &mTradeHandle, CPositionInfo &positionInfo) {};

public:
                     CPositionManager(string symbolName,
                    ENUM_TIMEFRAMES timeframe,
                    double stopLoss,
                    double breakEven,
                    double maxFloatingPoint,
                    double maxLoss,
                    bool isScratchBrkEven=true,
                    bool useHiddenStopLoss=false,
                    double hardStopLossMultiple=1)
     {
      mTimeframe = timeframe;
      mStopLossPoints = stopLoss;
      mBreakEvenPoints = breakEven;
      mMaxFloatingPoints = maxFloatingPoint;
      mMaxLossAmount = maxLoss;
      mUseScratchBreakEven = isScratchBrkEven;
      //virtual stop loss
      mUseHiddenStopLoss = useHiddenStopLoss;
      mHiddenStopLossMultiple = hardStopLossMultiple;
      //set up symbolinfo object
      mSymbolInfo.Name(symbolName);
      mSymbolInfo.Refresh();
     };

   //--- the main call from EAs to this class.
   bool              ClosePosition(CTrade &mTradeHandle, const ulong ticket);
   bool              ModifyPosition(CTrade &mTradeHandle, const ulong ticket, const double sl, const double tp);
   bool              PartialClose(CTrade &mTradeHandle, const ulong ticket, const double vol);
   
   //--- It loops through all positions, determines the position type and
   //--- execute management rules on each
   void              ManagePositions(CTrade &mTradeHandle);
   void              ManagePosition(CTrade &mTradeHandle, CPositionInfo &positionInfo);
   bool              BreakEven(CTrade &mTradeHandle, CPositionInfo &positionInfo);

   virtual void      Refresh() {};
   //--- position properties

   void              ExecutePositionOrder(CTrade &mTradeHandle, CPositionInfo &positionInfo, Position &position);

   virtual double    GetStopLoss(Entry &entry) {return 0;};
   virtual double    GetTakeProfit(Entry &entry) {return 0;};

   //--- the TightenPosition method should be call to trail existing position by mStopLossPoints
   //--- or exit the position if distance is less than mStopLossPoints
   virtual bool      TightenPosition(CTrade &mTradeHandle, CPositionInfo &positionInfo) { return false;};

   virtual double    atrPoints(int shift = 1) { return EMPTY_VALUE;};
  };

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void CPositionManager::ManagePositions(CTrade &mTradeHandle)
  {
   uint total=PositionsTotal();
   for(uint i=0; i<total; i++)
     {
      string position_symbol=PositionGetSymbol(i);
      if(position_symbol == mSymbolInfo.Name())
        {
         CPositionInfo positionInfo;
         positionInfo.SelectByIndex(i);

         ManagePosition(mTradeHandle, positionInfo);
        }
     }
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void CPositionManager::ManagePosition(CTrade &mTradeHandle, CPositionInfo &positionInfo)
  {
   mSymbolInfo.Refresh();
   ENUM_POSITION_TYPE positionType = positionInfo.PositionType();
   if(positionType == POSITION_TYPE_BUY)
      manageLongPosition(mTradeHandle, positionInfo);
   else
      if(positionType == POSITION_TYPE_SELL)
         manageShortPosition(mTradeHandle, positionInfo);
      else
         Print(__FUNCTION__, " Illegal Position Type");
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
bool CPositionManager::BreakEven(CTrade &mTradeHandle, CPositionInfo &positionInfo)
  {
   double priceOpen = positionInfo.PriceOpen();
   double currentPrice = positionInfo.PriceCurrent();
   double stopLoss=0;
   double symStopLevel = mSymbolInfo.StopsLevel();
   switch(positionInfo.PositionType())
     {
      case POSITION_TYPE_BUY:
        {
         stopLoss = (mUseScratchBreakEven) ? priceOpen + mBreakEvenPoints : priceOpen;
         //I think we should return false if stopLoss is too close for execution
         if(currentPrice - stopLoss < symStopLevel)
            return false;
        }
      case POSITION_TYPE_SELL:
        {
         stopLoss = (mUseScratchBreakEven) ? priceOpen - mBreakEvenPoints : priceOpen;
         if(stopLoss - currentPrice < symStopLevel)
            return false;
        }
     }

   return ModifyPosition(mTradeHandle, positionInfo.Ticket(), stopLoss, 0);
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void CPositionManager::ExecutePositionOrder(CTrade &mTradeHandle, CPositionInfo &positionInfo, Position &position)
  {
   ulong ticket = positionInfo.Ticket();
   switch(position.signal)
     {
      case EXIT_SIGNAL_EXIT:
         //close 100% of the position
         ClosePosition(mTradeHandle, ticket);
         break;
      case EXIT_SIGNAL_MODIFY:
         //move your stop loss to secure as much profit as possible while still holding the position.
         ModifyPosition(mTradeHandle, ticket, position.stopLoss, position.takeProfit);
         break;
      case EXIT_SIGNAL_PARTIAL:
         //close part of the position.
         PartialClose(mTradeHandle, ticket, position.lots);
         break;
      default:
      case EXIT_SIGNAL_HOLD:
         return;
     }
  }


//+------------------------------------------------------------------+
//| ModifyPosition(CTrade &mTradeHandle, const ulong ticket, const double sl, const double tp)     |
//+------------------------------------------------------------------+
bool CPositionManager::ModifyPosition(CTrade &mTradeHandle, const ulong ticket, const double sl, const double tp)
  {
   mTradeHandle.PositionModify(ticket, sl, tp);
   uint returnCode = mTradeHandle.ResultRetcode();
   if(returnCode == TRADE_RETCODE_PLACED || returnCode == TRADE_RETCODE_DONE)
     {
      Print(StringFormat("Modified position for ticket #%d. Lastest position - {sl : %f, tp: %f}",
                         ticket, sl, tp));
      return true;
     }
   else
     {
      Print("Failed to modify position for ticket #",  ticket, ". Reason:", GetRetcodeID(returnCode));
      ResetLastError();
      return false;
     }
  }

//+------------------------------------------------------------------+
//| ClosePosition(CTrade &mTradeHandle, const ulong ticket)          |
//+------------------------------------------------------------------+
bool CPositionManager::ClosePosition(CTrade &mTradeHandle, const ulong ticket)
  {
   mTradeHandle.PositionClose(ticket);
   uint returnCode = mTradeHandle.ResultRetcode();
   if(returnCode == TRADE_RETCODE_PLACED || returnCode == TRADE_RETCODE_DONE)
     {
      Print(StringFormat("Closed position for ticket #%d", ticket));
      return true;
     }
   else
     {
      Print("Failed to close position for ticket #",  ticket, ". Reason:", GetRetcodeID(returnCode));
      ResetLastError();
      return false;
     }
  }

//+------------------------------------------------------------------+
//| PartialClose(CTrade &mTradeHandle, const ulong ticket, const double vol)
//+------------------------------------------------------------------+
bool CPositionManager::PartialClose(CTrade &mTradeHandle, const ulong ticket, const double vol)
  {
   mTradeHandle.PositionClosePartial(ticket, vol);
   uint returnCode = mTradeHandle.ResultRetcode();
   if(returnCode == TRADE_RETCODE_PLACED || returnCode == TRADE_RETCODE_DONE)
     {
      Print(StringFormat("Partial close position for ticket #%d. Volume closed - %f",
                         ticket, vol));
      return true;
     }
   else
     {
      Print("Failed to partially close position for ticket #",  ticket, ". Reason:", GetRetcodeID(returnCode));
      ResetLastError();
      return false;
     }
  }
