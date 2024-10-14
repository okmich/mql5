//+------------------------------------------------------------------+
//|                                                   TimeFilter.mqh |
//|                                    Copyright 2020, Michael Enudi |
//|                                             okmich2002@yahoo.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2020, Michael Enudi"
#property link      "okmich2002@yahoo.com"

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
class CTimeFilter
  {
protected:
   bool              m_active;

public:
                     CTimeFilter(): m_active(true) {};
                    ~CTimeFilter() {};
   void              setActive(bool flag) {m_active = flag;}
   bool              isActive() {return m_active;}

   virtual bool      Init() {return true;};
   virtual bool      checkTime(datetime currenttime=0)=0;
  };

//+------------------------------------------------------------------+
//| CDayTimeRangesTimeFilter                                         |
//|     - used to filter out non-desireable trading sessions         |
//|     - expected parameters are two strings                        |
//|     -   dayRange (example: SUN-SAT or SUN,SAT,WED)               |
//|     -   timeRange (example: 0000-1600,2000-2330)                 |
//+------------------------------------------------------------------+
class CDayTimeRangesTimeFilter : public CTimeFilter
  {
private:
   string            mDayRange, mTimeRange;

   int               getTimeAsInt(datetime &time);
   short             dayOfWeekToNumber(string day);

   bool              InitDayRange();
   bool              InitDaysSelected();
   bool              InitTimeRange();
   int               ArrayFind(int &searchArr[], int matchingValue);
   bool              IsTradingTimeValid(int tradingTime);

   int               m_TradingDays[];
   int               m_TradingTimes[][2];

public:
                     CDayTimeRangesTimeFilter(string InptDayRange, string InptTimeRange): CTimeFilter()
     {
      this.mDayRange = InptDayRange;
      this.mTimeRange = InptTimeRange;
     };
                    ~CDayTimeRangesTimeFilter() {};

   virtual bool              Init();
   virtual bool              checkTime(datetime currenttime= 0);

  };

//+------------------------------------------------------------------+
//| CNoTimeFilter                                                    |
//|     - Represents absence of time filter. Always returns true     |
//+------------------------------------------------------------------+
class CNoTimeFilter : public CTimeFilter
  {
public:
                     CNoTimeFilter(): CTimeFilter() {};
                    ~CNoTimeFilter() {};

   virtual bool      checkTime(datetime currenttime= 0) {return true;};
  };


//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
bool CDayTimeRangesTimeFilter::Init()
  {
   bool dayInited = false;
   if(StringFind(mDayRange, "-", 0) != -1)  // we are using range
      dayInited = this.InitDayRange();
   else   // we are using selected comma-separated days
      dayInited = InitDaysSelected();

   bool timeInited = InitTimeRange();

   return timeInited && dayInited;
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
bool CDayTimeRangesTimeFilter::checkTime(datetime currenttime= 0)
  {
//if this filter is deactivated, it will alway return true
   if(!isActive())
      return true;
//get the time to measure against
   datetime time = currenttime == 0 ? TimeLocal() : currenttime;
   MqlDateTime mqldt;
   TimeToStruct(time, mqldt);
   if(ArrayFind(m_TradingDays, mqldt.day_of_week) == -1)
      return false;

   int timeAsInt = getTimeAsInt(time);
   return IsTradingTimeValid(timeAsInt);
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
short CDayTimeRangesTimeFilter::dayOfWeekToNumber(string day)
  {
   if(day == "SUN")
      return 0;
   if(day == "MON")
      return 1;
   if(day == "TUES" || day == "TUE")
      return 2;
   if(day == "WED")
      return 3;
   if(day == "THURS")
      return 4;
   if(day == "FRI")
      return 5;
   if(day == "SAT")
      return 6;

   return -1;
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
int CDayTimeRangesTimeFilter::getTimeAsInt(datetime &time)
  {
   MqlDateTime mqldt;
   TimeToStruct(time, mqldt);
   string s = "";
   string minute = mqldt.min == 0 ? "00" : IntegerToString(mqldt.min);
   StringConcatenate(s, IntegerToString(mqldt.hour), minute);
   return (int)s;
  }


//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
bool CDayTimeRangesTimeFilter::InitDayRange(void)
  {
   string days[];
   StringSplit(mDayRange, '-', days);
//check if the values are fine
   if(ArraySize(days) != 2)
     {
      //incorrect time filter parameter error
      SetUserError(-730);
      return false;
     }

   ushort m_start_day, m_end_day;
   m_start_day = dayOfWeekToNumber(days[0]);
   m_end_day = dayOfWeekToNumber(days[1]);

   if(m_start_day > 6 || m_end_day > 6)
     {
      //incorrect time filter parameter error
      Print("Incorrect time filter parameter error - either start_day or end_day is beyond SAT (6)");
      SetUserError(-731);
      return false;
     }

   if(m_start_day > m_end_day)
     {
      //incorrect time filter parameter error - start_day cannot be greater than end_day
      Print("Incorrect time filter parameter error - start_day cannot be greater than end_day");
      SetUserError(-732);
      return false;
     }

   ArrayResize(m_TradingDays, m_end_day-m_start_day+1);
   for(int i=m_start_day-m_start_day; i<=m_end_day-m_start_day; i++)
      m_TradingDays[i] = i+m_start_day;

   return ArraySize(m_TradingDays) > 0;
  }


//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
bool CDayTimeRangesTimeFilter::InitDaysSelected(void)
  {
   string days[];
   StringSplit(mDayRange, ',', days);
//check if the values are fine
   if(ArraySize(days) < 1)
     {
      Print("Incorrect time filter parameter error - Trading days not specified or incorrectly specified. (use either SUN-SAT or SUN,MON,...SAT");
      SetUserError(-735);
      return false;
     }
   ArrayResize(m_TradingDays, ArraySize(days));

   for(int i=0; i<ArraySize(days); i++)
      m_TradingDays[i] = this.dayOfWeekToNumber(days[i]);

   return ArraySize(m_TradingDays) > 0;
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
bool CDayTimeRangesTimeFilter::InitTimeRange(void)
  {
   string timesParts[];
   StringSplit(mTimeRange, ',', timesParts);
   if(ArraySize(timesParts) < 1)
     {
      Print("Incorrect time filter parameter error - Trading times not specified or incorrectly specified. (0000-1600[,2000-2330]");
      SetUserError(-736);
      return false;
     }

   string times[];
   ArrayResize(m_TradingTimes, ArraySize(timesParts));
   for(int i=0; i<ArraySize(timesParts); i++)
     {
      short m_start_time, m_end_time;

      StringSplit(timesParts[i], '-', times);
      //check if the values are fine
      if(ArraySize(times) != 2)
        {
         //incorrect time filter parameter error
         Print("Incorrect time filter parameter error - Invalid Trading times range specified");
         SetUserError(-737);
         return false;
        }

      //apply the time range values
      m_start_time = (short)times[0];
      m_end_time = (short)times[1];
      //double check time range values
      if(m_start_time < 0 || m_end_time < 0)
        {
         Print("Incorrect time filter parameter error - either start_time or end_time is less than 0");
         //incorrect time filter parameter error
         SetUserError(-733);
         return false;
        }

      if(m_start_time > 2359 || m_end_time > 2359)
        {
         Print("Incorrect time filter parameter error - either start_time or end_time is beyond 2359");
         //incorrect time filter parameter error
         SetUserError(-734);
         return false;
        }

      if(m_start_time > m_end_time)
        {
         Print("Incorrect time filter parameter error - start_time cannot be greater than end_time");
         //incorrect time filter parameter error
         SetUserError(-738);
         return false;
        }
      m_TradingTimes[i][0] = m_start_time;
      m_TradingTimes[i][1] = m_end_time;
     }

   return ArraySize(m_TradingTimes) > 0;
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
int CDayTimeRangesTimeFilter::ArrayFind(int &searchArr[],int matchingValue)
  {
   for(int i = 0; i < ArraySize(searchArr); i++)
      if(searchArr[i] == matchingValue)
         return i;

   return -1;
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
bool CDayTimeRangesTimeFilter::IsTradingTimeValid(int tradingTime)
  {
   for(int i=0; i<ArrayRange(m_TradingTimes, 0); i++)
      if(m_TradingTimes[i][0] <= tradingTime && m_TradingTimes[i][1] >= tradingTime)
         return true;

   return false;
  }
//+------------------------------------------------------------------+
