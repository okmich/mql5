//+------------------------------------------------------------------+
//|                                                       Common.mqh |
//|                                    Copyright 2020, Michael Enudi |
//|                                             okmich2002@yahoo.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2020, Michael Enudi"
#property link      "okmich2002@yahoo.com"

enum ENUM_LONG_SHORT_FLAG
  {
   LONG_SHORT,
   LONG,
   SHORT
  };

enum ENUM_SLOPE
  {
   DOWN,
   FLAT,
   UP
  };

enum ENUM_HIGHLOW
  {
   HIGHLOW_NA,
   HIGHLOW_HIGH,
   HIGHLOW_LOW
  };

enum ENUM_ENTRY_SIGNAL
  {
   ENTRY_SIGNAL_NONE,
   ENTRY_SIGNAL_BUY,
   ENTRY_SIGNAL_SELL,
   ENTRY_SIGNAL_BUY_STOP,
   ENTRY_SIGNAL_SELL_STOP,
   ENTRY_SIGNAL_BUY_LIMIT,
   ENTRY_SIGNAL_SELL_LIMIT
  };

enum ENUM_EXIT_SIGNAL
  {
   EXIT_SIGNAL_HOLD,
   EXIT_SIGNAL_EXIT,
   EXIT_SIGNAL_MODIFY,
   EXIT_SIGNAL_PARTIAL
  };

enum ENUM_TRENDSTATE
  {
   TS_NONE,
   TS_TREND,
   TS_FLAT
  };

struct Entry
  {
   string            sym;
   ENUM_ENTRY_SIGNAL signal;
   double            price;
   double            sl;
   double            tp;
   double            vol;
   ulong             magic;
   int               order_expiry;
  };

struct Position
  {
   string            sym;
   ENUM_EXIT_SIGNAL  signal;
   double            ask;
   double            bid;
   double            stopLoss;
   double            takeProfit;
   double            lots;
  };

struct LinReg
  {
   double            intercept;
   double            slope;
   double            rawSlope;
   double            error;
  };

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
bool SupportLongEntries(ENUM_LONG_SHORT_FLAG flag)
  {
   return flag == LONG || flag == LONG_SHORT;
  };

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
bool SupportShortEntries(ENUM_LONG_SHORT_FLAG flag)
  {
   return flag == SHORT || flag == LONG_SHORT;
  };

//+------------------------------------------------------------------+
//| convert numeric response codes to string mnemonics               |
//+------------------------------------------------------------------+
string GetRetcodeID(int retcode)
  {
   switch(retcode)
     {
      case 10004:
         return("TRADE_RETCODE_REQUOTE - Requote");
         break;
      case 10006:
         return("TRADE_RETCODE_REJECT - Request rejected");
         break;
      case 10007:
         return("TRADE_RETCODE_CANCEL - Request canceled by trader");
         break;
      case 10008:
         return("TRADE_RETCODE_PLACED - Order placed");
         break;
      case 10009:
         return("TRADE_RETCODE_DONE - Request completed");
         break;
      case 10010:
         return("TRADE_RETCODE_DONE_PARTIAL - Only part of the request was completed");
         break;
      case 10011:
         return("TRADE_RETCODE_ERROR - Request processing error");
         break;
      case 10012:
         return("TRADE_RETCODE_TIMEOUT - Request canceled by timeout");
         break;
      case 10013:
         return("TRADE_RETCODE_INVALID - Invalid request");
         break;
      case 10014:
         return("TRADE_RETCODE_INVALID_VOLUME - Invalid volume in the request");
         break;
      case 10015:
         return("TRADE_RETCODE_INVALID_PRICE - Invalid price in the request");
         break;
      case 10016:
         return("TRADE_RETCODE_INVALID_STOPS - Invalid stops in the request");
         break;
      case 10017:
         return("TRADE_RETCODE_TRADE_DISABLED - Trade is disabled");
         break;
      case 10018:
         return("TRADE_RETCODE_MARKET_CLOSED - Market is closed");
         break;
      case 10019:
         return("TRADE_RETCODE_NO_MONEY - There is not enough money to complete the request");
         break;
      case 10020:
         return("TRADE_RETCODE_PRICE_CHANGED - Prices changed");
         break;
      case 10021:
         return("TRADE_RETCODE_PRICE_OFF - There are no quotes to process the request");
         break;
      case 10022:
         return("TRADE_RETCODE_INVALID_EXPIRATION - Invalid order expiration date in the request");
         break;
      case 10023:
         return("TRADE_RETCODE_ORDER_CHANGED - Order state changed");
         break;
      case 10024:
         return("TRADE_RETCODE_TOO_MANY_REQUESTS - Too frequent requests");
         break;
      case 10025:
         return("TRADE_RETCODE_NO_CHANGES");
         break;
      case 10026:
         return("TRADE_RETCODE_SERVER_DISABLES_AT");
         break;
      case 10027:
         return("TRADE_RETCODE_CLIENT_DISABLES_AT");
         break;
      case 10028:
         return("TRADE_RETCODE_LOCKED");
         break;
      case 10029:
         return("TRADE_RETCODE_FROZEN");
         break;
      case 10030:
         return("TRADE_RETCODE_INVALID_FILL");
         break;
      case 10031:
         return("TRADE_RETCODE_CONNECTION");
         break;
      case 10032:
         return("TRADE_RETCODE_ONLY_REAL");
         break;
      case 10033:
         return("TRADE_RETCODE_LIMIT_ORDERS - The number of pending orders has reached the limit");
         break;
      case 10034:
         return("TRADE_RETCODE_LIMIT_VOLUME - The volume of orders and positions for the symbol has reached the limit");
         break;
      case 10035:
         return("TRADE_RETCODE_INVALID_ORDER - Incorrect or prohibited order type");
         break;
      case 10036:
         return("TRADE_RETCODE_POSITION_CLOSED");
         break;
      default:
         return("TRADE_RETCODE_UNKNOWN="+IntegerToString(retcode));
         break;
     }
  }

//+------------------------------------------------------------------+
//| Position exitPosition()                                          |
//+------------------------------------------------------------------+
Position exitPosition()
  {
   Position position;
   position.signal = EXIT_SIGNAL_EXIT;
   return(position);
  };

//+------------------------------------------------------------------+
//| Position holdPosition()                                          |
//+------------------------------------------------------------------+
Position holdPosition()
  {
   Position position;
   position.signal = EXIT_SIGNAL_HOLD;
   return(position);
  };

//+------------------------------------------------------------------+
//| Position modifyPosition()                                        |
//+------------------------------------------------------------------+
Position modifyPosition()
  {
   Position position;
   position.signal = EXIT_SIGNAL_MODIFY;
   return(position);
  };

//+------------------------------------------------------------------+
//| Entry noEntry()                                                  |
//+------------------------------------------------------------------+
Entry noEntry(ulong _magic=0)
  {
   Entry entry;
   entry.magic =_magic;
   entry.signal = ENTRY_SIGNAL_NONE;
   entry.sl = 0.0;
   entry.tp = 0.0;
   entry.vol =0.0;
   return entry;
  };

//+------------------------------------------------------------------+
//| Entry anEntry()                                                  |
//+------------------------------------------------------------------+
Entry anEntry(string sym, ENUM_ENTRY_SIGNAL _signal, double price,
              double stop, double tp, double vol, ulong _magic=0)
  {
   Entry entry;
   entry.magic =_magic;
   entry.price = price;
   entry.signal = _signal;
   entry.sl = stop;
   entry.sym = sym;
   entry.tp = tp;
   entry.vol = vol;
   return entry;
  };

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
string formatDateToStringISO(datetime time)
  {

   MqlDateTime mqlDateTime;
   TimeToStruct(time, mqlDateTime);
   return StringFormat("%4d-%02d-%02d %02d:%02d:%02d",
                       mqlDateTime.year, mqlDateTime.mon, mqlDateTime.day,
                       mqlDateTime.hour, mqlDateTime.min, mqlDateTime.sec);
  }

/**
 * confirm that the proposed lot size is within the min and max for the symbol.
 */
double verifyLots(string symbol, double proposedLotSize)
  {
   double minLotSize = SymbolInfoDouble(symbol,SYMBOL_VOLUME_MIN);
   double maxLotSize = SymbolInfoDouble(symbol,SYMBOL_VOLUME_MAX);
   double stepSize = SymbolInfoDouble(symbol,SYMBOL_VOLUME_STEP);

   double lotSize;
   if(proposedLotSize < minLotSize)
      lotSize = minLotSize;
   else
      if(proposedLotSize > maxLotSize)
         lotSize = maxLotSize;
      else
         lotSize = MathRound(proposedLotSize / stepSize) * stepSize;

   if(stepSize >= 0.1)
      lotSize = NormalizeDouble(lotSize,1);
   else
      lotSize = NormalizeDouble(lotSize,2);

   return lotSize;
  }

/**
 * calculate the lot size for a trade given the stop loss distance in points and the risk amount
 */
double calcLotSizeForRiskAmount(string symbol, double stopLossPoints, double riskAmount)
  {
   double tickValue = SymbolInfoDouble(symbol, SYMBOL_TRADE_TICK_VALUE) ;
   double tradeSize = (riskAmount / stopLossPoints) / tickValue;
   return verifyLots(symbol, tradeSize);
  }

/**
 * calculate the lot size for a trade given the stop loss distance in points and the risk percent
 * of free margin
 */
double calcLotSizeForRiskPercent(string symbol, double stopLossPoints, double riskPercent)
  {
   double riskAmount = (riskPercent / 100) * AccountInfoDouble(ACCOUNT_MARGIN_FREE);
   return calcLotSizeForRiskAmount(symbol, stopLossPoints, riskAmount);
  }

/**
 * calculate the stop loss distance (how far the stop should be)
 * given the amount to risk and the fixed lot size
 */
double GetStopDistanceForRisk(string symbol, double riskAmount, double vol)
  {
   double tickValue = SymbolInfoDouble(symbol, SYMBOL_TRADE_TICK_VALUE);
   double stopLossDist = riskAmount / (vol * tickValue);

   double minStopLoss = (double)SymbolInfoInteger(symbol, SYMBOL_TRADE_STOPS_LEVEL);
   if(stopLossDist < minStopLoss)
      stopLossDist = minStopLoss;

   return stopLossDist;
  }

/**
 * calculate the stop loss price (where the stop should be placed)
 * given the amount to risk and the fixed lot size
 */
double GetStopValueForVolumeAndRisk(ENUM_ENTRY_SIGNAL _signal, string symbol, double vol,
                                    double entryPrice, double riskAmount)
  {
   double distance = GetStopDistanceForRisk(symbol, riskAmount, vol);
   double _point = SymbolInfoDouble(symbol, SYMBOL_POINT);
   if(_signal == ENTRY_SIGNAL_BUY)
      return entryPrice - (distance * _point);
   else
      if(_signal == ENTRY_SIGNAL_SELL)
         return entryPrice + (distance * _point);

   return 0;
  }

//+------------------------------------------------------------------+
//| PointInRange - Used for data transformation                      |
//+------------------------------------------------------------------+
double PointInRange(const double &buffer[], int i, int period)
  {
   int start = i - period;
   if(start < 0)
      return EMPTY_VALUE;
   start = i-period + 1;
   double highestHigh = buffer[ArrayMaximum(buffer, start, period)];
   double lowestLow = buffer[ArrayMinimum(buffer, start, period)];
   double inputRange =  highestHigh - lowestLow;
   return (inputRange == 0) ? 0 : 100 * ((buffer[i] - lowestLow)/inputRange);
  }

//+------------------------------------------------------------------+
//| Scale - Used for data transformation to a new range scale        |
//+------------------------------------------------------------------+
double Scale(const double &buffer[], int i, int period, int scaleMax=100)
  {
   int start = i-period + 1;
   double highestHigh = buffer[ArrayMaximum(buffer, start, period)];
   double lowestLow = buffer[ArrayMinimum(buffer, start, period)];
   double inputRange =  highestHigh - lowestLow;

   return (inputRange == 0) ? 0 : (buffer[i] - lowestLow)*(scaleMax/inputRange);;
  }

//+------------------------------------------------------------------+
//| PercentRank                                                      |
//+------------------------------------------------------------------+
double PercentRank(double &buffer[], int idx, int period)
  {
   int start = idx - period;
   if(start < 0)
      return 0;
   double value = buffer[idx];
   int count=0;
   for(int i = start; i < idx; i++)
      count += (buffer[i] < value) ? 1 : 0;

   return (count/(period * 1.0))*100;
  }

//+------------------------------------------------------------------+
//| https://www.mql5.com/en/forum/240466                             |
//+------------------------------------------------------------------+
double RadToDegrees(double rad)
  {
   double degree = rad*180/M_PI;
   return(degree);
  }

//+------------------------------------------------------------------+
//| Trend Line Equation(y) = a + bx                                  |
//|                                                                  |
//| Where,                                                           |
//| Slope(b) = (NΣXY - (ΣX)(ΣY)) / (NΣX2 - (ΣX)2)                    |
//| Intercept(a) = (ΣY - b(ΣX)) / N                                  |
//| https://www.easycalculation.com/statistics/trend-line.php        |
//| next_val = linReg.intercept + linReg.slope * next_period         |
//+------------------------------------------------------------------+
LinReg CalculateLinearRegression(const double& array[], int period, int shift)
  {
   LinReg linReg;
   double sx = 0, sy = 0, sxy = 0, sxx = 0, syy = 0, x, y;
   int param = (ArrayIsSeries(array))? -1: 1;

   double maxY = array[ArrayMaximum(array, shift, period)];
   double minY = array[ArrayMinimum(array, shift, period)];

   for(int i = 0; i < period; i++)
     {
      x = (i - 0.0) / ((period - 1.0)); //scaled value of x
      y = maxY == minY ? 0 : (array[shift + param * i] - minY) / (maxY - minY); //scaled value of y
      sx  += x;
      sy  += y;
      sxx += x * x;
      sxy += x * y;
      syy += y * y;
     }

   linReg.rawSlope = (period * sxy - sx * sy) / (period * sxx - sx * sx);
   linReg.intercept = (sy - linReg.rawSlope * sx) / period;
   linReg.error = MathSqrt((period * syy - sy * sy - linReg.slope * linReg.slope * (period * sxx - sx*sx)) /
                           (period * (period - 2)));
   linReg.slope = RadToDegrees(MathArctan(linReg.rawSlope));

   return linReg;
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
double GetYFromLinReg(LinReg &linReg, double xValue)
  {
   return linReg.intercept + linReg.rawSlope * xValue;
  }
//+------------------------------------------------------------------+


//+------------------------------------------------------------------+
//| Calculate Standard Deviation                                     |
//+------------------------------------------------------------------+
double StdDev_Func(const int position,const double &price[],const double &ma_price[],const int period)
  {
   double std_dev=0.0;
//--- calcualte StdDev
   if(position>=period)
     {
      for(int i=0; i<period; i++)
         std_dev+=MathPow(price[position-i]-ma_price[position],2.0);
      std_dev=MathSqrt(std_dev/period);
     }
//--- return calculated value
   return(std_dev);
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
int lastSwingHigh(double& ihighs[], int fromIdx=0, int depth=1)
  {
   int start = fromIdx + depth;
   int end = ArraySize(ihighs) - depth;
   for(int i = start; i < end; i++)
     {
      bool leftSideFlag = true;
      bool rightSideFlag = true;
      for(int j = 1; j <= depth; j++)
        {
         leftSideFlag = leftSideFlag && ihighs[i-j] < ihighs[i];
         rightSideFlag = leftSideFlag && ihighs[i] > ihighs[i+j];
        }
      if(leftSideFlag && rightSideFlag)
         return i;
     }

   return -1;
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
int lastSwingLow(double& ilows[], int fromIdx=0, int depth=1)
  {
   int start = fromIdx + depth;
   int end = ArraySize(ilows) - depth;
   for(int i = start; i < end; i++)
     {
      bool leftSideFlag = true;
      bool rightSideFlag = true;
      for(int j = 1; j <= depth; j++)
        {
         leftSideFlag = leftSideFlag && ilows[i-j] > ilows[i];
         rightSideFlag = leftSideFlag && ilows[i] < ilows[i+j];
        }
      if(leftSideFlag && rightSideFlag)
         return i;
     }

   return -1;
  }

//+------------------------------------------------------------------+
//| returns true if time is past percent of baseDt on a timeframe    |
//+------------------------------------------------------------------+
bool isPastNPercentWithinTF(ENUM_TIMEFRAMES period, double percent, datetime &time, datetime &baseDt)
  {
   if(baseDt > time)
      return false;
   if(percent > 100)
      return false;

   double threshHoldInSecs = percent/100 * PeriodSeconds(period);
   double pastSeconds = (double)((long)time) - ((long)baseDt);

   return pastSeconds > threshHoldInSecs;
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
bool isTimeWithinBar(ENUM_TIMEFRAMES period, datetime &openTime, datetime &time)
  {
   long openTimeLng = (long)openTime, timeLng = (long)time ;
   long closeTime = openTimeLng + PeriodSeconds(period);

   return openTimeLng <= timeLng && closeTime >= timeLng;
  }

//+------------------------------------------------------------------+
//| ArrayMax                                                         |
//+------------------------------------------------------------------+
double ArrayMax(const double &array[],int period,int start=0)
  {
   double Highest=array[start];
   int endIndex = start+period;
   for(int i=start; i < endIndex; i++)
     {
      if(Highest<array[i])
         Highest=array[i];
     }
   return(Highest);
  }

//+------------------------------------------------------------------+
//| ArrayMin                                                         |
//+------------------------------------------------------------------+
double ArrayMin(const double &array[],int period,int start=0)
  {
   double Lowest=array[start];
   int endIndex = start+period;
   for(int i=start; i < endIndex; i++)
     {
      if(Lowest>array[i])
         Lowest=array[i];
     }
   return(Lowest);
  }
//+------------------------------------------------------------------+

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
ENUM_TIMEFRAMES higherTF(ENUM_TIMEFRAMES tf)
  {
   switch(tf)
     {
      case PERIOD_W1:
         return PERIOD_MN1;
      case PERIOD_D1:
         return PERIOD_W1;
      case PERIOD_H12:
         return PERIOD_D1;
      case PERIOD_H4:
         return PERIOD_H12;
      case PERIOD_H1:
         return PERIOD_H4;
      case PERIOD_M30:
         return PERIOD_H1;
      case PERIOD_M15:
         return PERIOD_M30;
      case PERIOD_M5:
         return PERIOD_M15;
      case PERIOD_M1:
         return PERIOD_M5;
      default :
         return tf;
     }
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
ENUM_TIMEFRAMES lowerTF(ENUM_TIMEFRAMES tf)
  {
   switch(tf)
     {
      case PERIOD_MN1:
         return PERIOD_W1;
      case PERIOD_W1:
         return PERIOD_D1;
      case PERIOD_D1:
         return PERIOD_H12;
      case PERIOD_H12:
         return PERIOD_H4;
      case PERIOD_H4:
         return PERIOD_H1;
      case PERIOD_H1:
         return PERIOD_M30;
      case PERIOD_M30:
         return PERIOD_M15;
      case PERIOD_M15:
         return PERIOD_M5;
      case PERIOD_M5:
         return PERIOD_M1;
      default :
         return tf;
     }
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
int fibonacci(int n)
  {
   if(n <= 1)
      return 1;
   else
      return fibonacci(n-1) + fibonacci(n-2);
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
bool IsVolumeAbovePriorAverage(string symbol, ENUM_TIMEFRAMES timeFrame, int currentIndex, int period)
  {
   if(period <= 0 || currentIndex < 0)
      return false;

   long sumVolume = 0.0;
   int endIndex = currentIndex + period;
   for(int i = currentIndex; i < endIndex; i++)
     {
      sumVolume += iTickVolume(symbol, timeFrame, i);
     }

   double avgVolume = (sumVolume * 1.0) / period;
   long currVolume = iTickVolume(symbol, timeFrame, currentIndex);
   return currVolume > avgVolume;
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
bool IsVolumeAbovePriorPercentile(string symbol, ENUM_TIMEFRAMES timeFrame, int currentIndex,
                                  int period, double percentile)
  {
   if(period <= 0 || percentile <= 0 || percentile > 1)
      return false;

   double volumes[];
   ArrayResize(volumes, period);
   int endIndex = currentIndex + period;
   for(int i = currentIndex; i < endIndex; i++)
     {
      volumes[i-currentIndex] = (double)iTickVolume(symbol, timeFrame, i);
     }

   ArraySort(volumes);
   int index = (int)(period * (percentile / 100.0));
   double threshold = volumes[index];

   return iTickVolume(symbol, timeFrame, currentIndex) > threshold;  // Compare current volume with the 40% percentile threshold
  }

//+------------------------------------------------------------------+
