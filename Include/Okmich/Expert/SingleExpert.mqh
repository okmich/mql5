//+------------------------------------------------------------------+
//|                                                 SingleExpert.mqh |
//|                                    Copyright 2021, Michael Enudi |
//|                                             https://www.mql5.com |
//|                                                                  |
//| Expert runs one instance of StrategyImpl implementation          |
//+------------------------------------------------------------------+
#property copyright "Copyright 2021, Michael Enudi"
#property link      "okmich2002@yahoo.com"

#include "TimeFilter.mqh"
#include "Strategy.mqh"
#include <Okmich\Common\Common.mqh>
#include <Trade\PositionInfo.mqh>

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
class CSingleExpert
  {
private:
   bool                 _initialized;
   string               _ExpertName;
   ulong                mExpertMagic;
   CStrategy            *mStrategy;
   CTimeFilter          *mTimeFilter;
   PositionsAggregate   mStrategyPositionsAgg;

protected:
   string            DisplayMessage();
   bool              ExecutePositionOrder(CPositionInfo &positionInfo, Position &position);

public:
                     CSingleExpert(ulong expertMagic);
                     CSingleExpert(ulong expertMagic, string expertName);
   bool              OnInitHandler();
   void              OnTickHandler();
   void              OnDeinitHandler();

   bool              SetStrategyImpl(CStrategy* strategy);
   bool              SetTimeFilter(CTimeFilter* timeFilter);
   string            GetErrorMessage(int code);
  };

//+------------------------------------------------------------------+
//| constructor                                                      |
//+------------------------------------------------------------------+
CSingleExpert::CSingleExpert(ulong expertMagic) : _initialized(false)
  {
   mExpertMagic = expertMagic;
   _ExpertName = "Unnamed System";
  }

//+------------------------------------------------------------------+
//| constructor                                                      |
//+------------------------------------------------------------------+
CSingleExpert::CSingleExpert(ulong expertMagic, string expertName) : _initialized(false)
  {
   mExpertMagic = expertMagic;
   _ExpertName = expertName;
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
bool CSingleExpert::SetStrategyImpl(CStrategy* strategy)
  {
   ResetLastError();
   if(_initialized)
     {
      SetUserError(10);
      return false;
     }
   mStrategy = strategy;
   return true;
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
bool CSingleExpert::SetTimeFilter(CTimeFilter *timeFilter)
  {
   ResetLastError();
   if(_initialized)
     {
      SetUserError(11);
      return false;
     }
   mTimeFilter = timeFilter;
   return true;
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
bool CSingleExpert::OnInitHandler()
  {
   ResetLastError();
   if(!mStrategy.Init(mExpertMagic))
     {
      SetUserError(12);
      return false;
     }
   if(mTimeFilter == NULL)
     {
      mTimeFilter = new CNoTimeFilter();
     }
   if(!mTimeFilter.Init())
     {
      SetUserError(13);
      return false;
     }
   Comment(DisplayMessage());
   return true;
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void CSingleExpert::OnDeinitHandler(void)
  {
   mStrategy.Release();
   delete mStrategy;
   Comment("");
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void CSingleExpert::OnTickHandler(void)
  {
   if(!mTimeFilter.checkTime(TimeTradeServer()))
     {
      mStrategy.CloseAllPosition();
      return;
     }

   CPositionInfo positionInfo;
   Position position;
//calculate which shift is appropriate
   mStrategy.ShiftToUse();
   mStrategy.Refresh();
//---
   mStrategy.FindAndManagePositions();

//find and open position
   if(mStrategy.CanTakeNewPositions())
     {
      string sym = mStrategy.Symbol();
      double ask = SymbolInfoDouble(sym, SYMBOL_ASK);
      double bid = SymbolInfoDouble(sym, SYMBOL_BID);
      mStrategy.FindAndExecutionEntry(ask, bid);
     }
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
string CSingleExpert::DisplayMessage(void)
  {
   string message = StringFormat("\n\n\n\n\nAutomated Trading - %s (Running)", _ExpertName);
   message += "\n====================================";
   message += StringFormat("\n%s  %s", mStrategy.Symbol(), EnumToString(mStrategy.Timeframe()));
   return message;
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
string CSingleExpert::GetErrorMessage(int code)
  {
   switch(code)
     {
      case 10 :
         return "Error: You should not alter the strategy implementation after initializing this expert. [code: 10]";
      case 11 :
         return "Error: Unable to initialize default time filter for this expert. [code: 11]";
      case 12 :
         return "Error: Unable to initialize one the strategy implementation. [code: 12]";
      case 13 :
         return "Error: Unable to initialize time filter. [code: 13]";
      case 14 :
         return "";
      case 15 :
         return "";
      case 16 :
         return "";
      case 17 :
         return "";
      case 18 :
         return "";
      case 19 :
         return "";
      case 20 :
         return "";
      default :
         return StringFormat("Unknown error [code: %d]", code);
     }
   return "Unknown error";
  }
//+------------------------------------------------------------------+
