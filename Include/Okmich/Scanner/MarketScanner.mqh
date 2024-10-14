//+------------------------------------------------------------------+
//|                                                MarketScanner.mqh |
//|                                    Copyright 2020, Michael Enudi |
//|                                             okmich2002@yahoo.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2020, Michael Enudi"
#property link      "okmich2002@yahoo.com"

#include <JAson.mqh>
#include <Generic\ArrayList.mqh>
#include <Okmich\Common\Common.mqh>

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
class CBaseBot
  {
private:
   string            mScanCode;
   string            mID;

   void              evaluateShiftIndex();

protected:
   ENUM_TIMEFRAMES   mTimeFrame;
   string            mSymbol;
   //--- bot defined signal from a scan
   ENUM_ENTRY_SIGNAL mSignal;
   //--- bot score of a single scan
   double            mScore;
   int               mShiftIndex;
   const string      CurrentCandleProperties(const int index, const double open=0,
         const double high=0, const double low=0, const double close=0);
   //--- a variable that is set to true if the outcome of the span is noteworthy
   //--- if a bot sees identifies a good market opportunity, this should report
   //--- true, else false
   bool              mWorthReporting;
   string            mScanValues;
   string            ResultHeader();

public:
                     CBaseBot(string scanCode, ENUM_TIMEFRAMES tf, string symbol)
     {
      this.mScanCode = scanCode;
      this.mTimeFrame = tf;
      this.mSymbol = symbol;
      this.mWorthReporting = false;
      this.mID = StringFormat("%s.%s.%d", mScanCode, mSymbol, rand());
      this.mScanValues = "";
      //evaluate which shift index to use
      evaluateShiftIndex();
     };
                    ~CBaseBot() {};

   string            ID() const {return mID;}
   ENUM_TIMEFRAMES   Timeframe() const {return mTimeFrame;}
   string            Instrument() const {return mSymbol;}
   string            ScanCode() const {return mScanCode;};

   virtual bool      IsWorthReporting() {return mWorthReporting;}
   //this is the main implementation for this bot.
   virtual void      Begin() {};
   //should return the indices from the bot's indicators as well as the ohlcv values
   virtual string    ScanValues() {return mScanValues;};
   //presenting the result
   virtual string    Result(long timeCode);
  };

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void CBaseBot::evaluateShiftIndex(void)
  {
   mShiftIndex = 1;
   datetime currentTime = TimeCurrent();
   datetime openTime = iTime(mSymbol, mTimeFrame,0);
   if(isPastNPercentWithinTF(mTimeFrame, 80,currentTime, openTime))
      mShiftIndex = 0;
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
string CBaseBot::ResultHeader(void)
  {
   string dateFormat = formatDateToStringISO(TimeLocal());
   return StringFormat("%s;%s;%s;%s;%.2f;%s",
                       mScanCode, mSymbol,
                       EnumToString(mTimeFrame),EnumToString(mSignal),
                       mScore, dateFormat);
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
string CBaseBot::Result(long timeCode)
  {
   return StringFormat("%s;%s;%s", IntegerToString(timeCode), ResultHeader(), ScanValues());
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
const string CBaseBot::CurrentCandleProperties(const int index, const double open=0,
      const double high=0, const double low=0, const double close=0)
  {
   datetime time = iTime(mSymbol,mTimeFrame,index);
   double _open = open == 0 ? iOpen(mSymbol, mTimeFrame, mShiftIndex) : open;
   double _high = high == 0 ? iHigh(mSymbol, mTimeFrame, mShiftIndex) : high;
   double _low = low == 0 ? iLow(mSymbol, mTimeFrame, mShiftIndex) : low;
   double _close = close == 0 ? iClose(mSymbol, mTimeFrame, mShiftIndex) : close;
   long _tickVol = iTickVolume(mSymbol, mTimeFrame, mShiftIndex);
   long _vol = iVolume(mSymbol, mTimeFrame, mShiftIndex);

   string props = StringFormat("candle#time=%s,open=%f,high=%f,low=%f,close=%f,tick=%d,vol=%d",
                               formatDateToStringISO(time),
                               _open, _high, _low, _close, _tickVol, _vol);
   return props;
  }



//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
class CScanReportSink
  {
protected:
   string               mBotID;
   CArrayList<string>   *mListBuffer;
public:
                     CScanReportSink()
     {
      mListBuffer = new CArrayList<string>();
     }
                    ~CScanReportSink()
     {
      delete mListBuffer;
     }

   bool              ClearReportBuffer()
     {
      mListBuffer.Clear();
      mBotID="";
      return true;
     };

   void              BufferResult(string result)
     {
      mListBuffer.Add(result);
     };


   void              BufferResult(long timeCode, CBaseBot &bot)
     {
      if(mBotID == "")
         mBotID = bot.ID();
      BufferResult(bot.Result(timeCode));
     };

   virtual bool         Save() {return false;};
  };


//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
class CPrintReportSink : public CScanReportSink
  {

public:
                     CPrintReportSink() {};

   virtual bool      Save()
     {
      string _Buffer = "";
      string temp;
      for(int i = 0; i < mListBuffer.Count(); i++)
         if(mListBuffer.TryGetValue(i, temp))
            Print(temp);
         else
            break;
      mListBuffer.Clear();
      return true;
     };
  };

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
class CFileScanReportSink : public CScanReportSink
  {

public:
                     CFileScanReportSink() {};

   bool              WriteToFile(string content, string fileName)
     {
      int fileHandle=FileOpen(fileName,FILE_WRITE|FILE_CSV);
      if(fileHandle != INVALID_HANDLE)
        {
         uint len = FileWriteString(fileHandle, content);
         if(len > 0)
           {
            FileClose(fileHandle);
            Print("Scan results written to file ", fileName);

            return true;
           }
        }
      else
        {
         string message = StringFormat("Unable to open file - %s for writing!!!", fileName);
         Print("FATAL:: ", message);
        }
      return false;
     };

   virtual bool      Save()
     {
      string _Buffer = "";
      string temp;
      for(int i = 0; i < mListBuffer.Count(); i++)
         if(mListBuffer.TryGetValue(i, temp))
            _Buffer += temp + "\n";
         else
            break;
      mListBuffer.Clear();
      return WriteToFile(_Buffer, mBotID);
     };
  };

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
class CRestApiScanReportSink : public CScanReportSink
  {
private:
   string            m_UrlEndpoint;
public:
                     CRestApiScanReportSink(string urlEndpoint)
     {
      m_UrlEndpoint = urlEndpoint;
     };

   bool              WriteToEndpoint(const string values)
     {
      string requestHeader = "Content-Type:application/json";
      char charArrayBuffer[];
      CJAVal json(NULL,jtUNDEF);
      json["payload"]=values;
      string payload = "";
      json.Serialize(payload);
      ArrayResize(charArrayBuffer, StringToCharArray(payload, charArrayBuffer, 0, WHOLE_ARRAY)-1);
      char result[];
      string headers;
      int WebResult = WebRequest("POST", m_UrlEndpoint, requestHeader, NULL,
                                 50, charArrayBuffer, ArraySize(charArrayBuffer), result,headers);
      if(WebResult == -1)
        {
         Print("Error occured sending message to server: ",GetLastError());
         ResetLastError();
         return false;
        }
      else
        {
         string response = CharArrayToString(result);
         if(StringLen(response) == 0)
            return true;
         else
           {
            Print("Server error occured: ",response);
            return false;
           }
        }
     };

   virtual bool      Save()
     {
      string _Buffer = "";
      string temp;
      int count = mListBuffer.Count();
      if(count < 1)
         return true;

      for(int i = 0; i < count; i++)
         if(mListBuffer.TryGetValue(i, temp))
            _Buffer += temp + "~";
         else
            break;

      return WriteToEndpoint(_Buffer);
     };
  };

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
class CMarketScanner
  {
private:
   //--- to be used to reporting the results of a bot.
   CScanReportSink   *mScanReportSink;

public:
                     CMarketScanner(CScanReportSink *reportSink)
     {
      this.mScanReportSink = reportSink;
     }
                    ~CMarketScanner()
     {
      delete mScanReportSink;
     };

   long               GetTimeCode();
   void               GetTimeframes(ENUM_TIMEFRAMES &tf[]);
   //--- run a single bot and report the result
   virtual void      RunBot(long timeCode, CBaseBot &bot);
   //--- run a number of bots and report their results
   virtual void      RunBots(long timeCode, CBaseBot* &bot[]);
  };

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
long CMarketScanner::GetTimeCode()
  {
   MqlDateTime mqlDateTime;
   datetime current15minsBarOpenTime = iTime(_Symbol, PERIOD_M15, 0);
   TimeToStruct(current15minsBarOpenTime, mqlDateTime);
   string value = StringFormat("%4d%02d%02d%02d%02d",
                               mqlDateTime.year, mqlDateTime.mon, mqlDateTime.day,
                               mqlDateTime.hour, mqlDateTime.min);
   return StringToInteger(value);
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void CMarketScanner::GetTimeframes(ENUM_TIMEFRAMES &tf[])
  {
   ArrayResize(tf, 6);
   tf[0] = PERIOD_M15;
   tf[1] = PERIOD_M30;
   tf[2] = PERIOD_H1;
   tf[3] = PERIOD_H4;
   tf[4] = PERIOD_H12;
   tf[5] = PERIOD_D1;
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void CMarketScanner::RunBot(long timeCode, CBaseBot &bot)
  {
   if(CheckPointer(mScanReportSink) != POINTER_INVALID)
     {
      mScanReportSink.ClearReportBuffer();
      //start the bot
      bot.Begin();
      //report the result
      if(bot.IsWorthReporting())
        {
         mScanReportSink.BufferResult(timeCode, bot);
         mScanReportSink.Save();
        }
     }
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void CMarketScanner::RunBots(long timeCode, CBaseBot* &bots[])
  {
   if(CheckPointer(mScanReportSink) != POINTER_INVALID)
     {
      mScanReportSink.ClearReportBuffer();
      for(int i = 0; i < ArraySize(bots); i++)
        {
         //start the bot
         bots[i].Begin();
         //report the result
         if(bots[i].IsWorthReporting())
            mScanReportSink.BufferResult(timeCode, bots[i]);

         //cleanup the bot
         delete bots[i];
        }
      mScanReportSink.Save();
     }
  }
//+------------------------------------------------------------------+
