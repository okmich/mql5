//+------------------------------------------------------------------+
//|                                                 CMultiExpert.mqh |
//|                                    Copyright 2021, Michael Enudi |
//|                                             okmich2002@yahoo.com |
//|                                                                  |
//| Expert can run multiple instances of StrategyImpl implementation |
//|   - all instance execution happens in OnTimer rather than onTick |
//+------------------------------------------------------------------+
#property copyright "Copyright 2021, Michael Enudi"
#property link      "okmich2002@yahoo.com"

#include "TimeFilter.mqh"
#include "Strategy.mqh"
#include <Okmich\Common\Common.mqh>
#include <Trade\PositionInfo.mqh>

#define STRATEGY_MAX_COUNT 10

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
class CMultiExpert
  {
private:
   bool              _initialized;
   string            mExpertName;
   ulong             mExpertMagic;
   int               mPeriodicity, mCount;
   CStrategy*        mStrategies[];
   CTimeFilter       *mTimeFilter;

   void              NormalTickCycle(CStrategy *iStrategy);

protected:
   string            DisplayMessage();

public:
                     CMultiExpert(ulong expertMagic, int timer, string expertName);
   bool              CheckForInvalidInstrument(string &instruments[]);
   bool              LoadStrategyImpls(CStrategy* &strategyImpls[]);
   bool              SetTimeFilter(CTimeFilter* timeFilter);
   bool              OnInitHandler();
   void              OnTimerHandler();
   void              OnDeinitHandler();

   string            GetErrorMessage(int code);
  };

//+------------------------------------------------------------------+
//| constructor                                                      |
//+------------------------------------------------------------------+
CMultiExpert::CMultiExpert(ulong expertMagic, int timer, string expertName) : _initialized(false)
  {
   mExpertMagic = expertMagic;
   mPeriodicity = timer;
   mExpertName = expertName;
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
bool CMultiExpert::CheckForInvalidInstrument(string &instruments[])
  {
   for(int i = 0; i < ArraySize(instruments); i++)
     {
      if(!SymbolSelect(instruments[i], true))
        {
         SetUserError(5);
         return true;
        }
     }
   return false;
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
bool CMultiExpert::LoadStrategyImpls(CStrategy* &strategyImpls[])
  {
   ResetLastError();
   if(_initialized)
     {
      SetUserError(1);
      return false;
     }
   mCount = ArraySize(strategyImpls);
   if(mCount >= STRATEGY_MAX_COUNT)
     {
      SetUserError(2);
      return false;
     }
   ArrayResize(mStrategies, mCount);
   for(int i = 0; i < mCount; i++)
     {
      string sym = strategyImpls[i].Symbol();
      if(!SymbolSelect(sym, true))
        {
         SetUserError(5);
         return false;
        }
      //start the bot
      mStrategies[i] = strategyImpls[i];
     }
   return true;
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
bool CMultiExpert::SetTimeFilter(CTimeFilter *timeFilter)
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
bool CMultiExpert::OnInitHandler()
  {
   ResetLastError();
   if (mTimeFilter == NULL){
      mTimeFilter = new CNoTimeFilter();
   }
   for(int i = 0; i < mCount; i++)
     {
      if(!mStrategies[i].Init(mExpertMagic))
        {
         SetUserError(3);
         return false;
        }
     }

   Print("Starting timer for ", mPeriodicity, " seconds");
   if(EventSetTimer(mPeriodicity))
     {
      _initialized =true;
      Comment(DisplayMessage());
      return true;
     }
   else
     {
      SetUserError(4);
      return false;
     }
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void CMultiExpert::OnDeinitHandler(void)
  {
   EventKillTimer();
   for(int i = 0; i < mCount; i++)
     {
      if(CheckPointer(mStrategies[i]) !=POINTER_INVALID)
        {
         mStrategies[i].Release();
         delete mStrategies[i];
        }
     }
   Comment("");
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void CMultiExpert::OnTimerHandler(void)
  {
   if (!mTimeFilter.checkTime(TimeTradeServer()))
      return;
      
   CPositionInfo positionInfo;
   Position position;
   for(int i = 0; i < mCount; i++)
     {
      NormalTickCycle(mStrategies[i]);
     }
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void CMultiExpert::NormalTickCycle(CStrategy *iStrategy)
  {
   CPositionInfo positionInfo;
   Position position;
//calculate which shift is appropriate
   iStrategy.ShiftToUse();
   iStrategy.Refresh();
// manage any positions
   iStrategy.FindAndManagePositions();
// find positions
   if(iStrategy.CanTakeNewPositions())
     {
      string sym = iStrategy.Symbol();
      //find and open position
      double ask = SymbolInfoDouble(sym, SYMBOL_ASK);
      double bid = SymbolInfoDouble(sym, SYMBOL_BID);
      iStrategy.FindAndExecutionEntry(ask, bid);
     }
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
string CMultiExpert::DisplayMessage(void)
  {
   string message = StringFormat("\n\n\nAutomated Trading running '%s' (%d instruments)", mExpertName, mCount);
   message += "\n====================================";

   for(int i = 0; i < mCount; i++)
      message += StringFormat("\n%d. %s  %s", i+1, mStrategies[i].Symbol(), EnumToString(mStrategies[i].Timeframe()));

   message += "\n\nLaunched Date : " + TimeToString(TimeCurrent());
   return message;
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
string CMultiExpert::GetErrorMessage(int code)
  {
   switch(code)
     {
      case 1 :
         return "Error: You should not add a new strategy after initializing the MultiExpert. [code: 10]";
      case 2 :
         return StringFormat("Error: MultiExpert can handle a maximum of %d strategy at a time. [code: 11]", STRATEGY_MAX_COUNT);
      case 3 :
         return "Error: Unable to initialize one or more strategy implementations. [code: 12]";
      case 4 :
         return "Error: Failed to start up the Event timer. [code: 13]";
      case 5 :
         return "Error: Strategy Implementation found with unknown Instrument. [code: 14]";
      case 6 :
         return "";
      case 7 :
         return "";
      case 8 :
         return "";
      case 9 :
         return "";
      case 10 :
         return "";
      default :
         return StringFormat("Unknown error [code: %d]", code);
     }
   return "Unknown error";
  }
//+------------------------------------------------------------------+
