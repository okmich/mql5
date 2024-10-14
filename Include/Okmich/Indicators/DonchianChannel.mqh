//+------------------------------------------------------------------+
//|                                               DochianChannel.mqh |
//|                                    Copyright 2021, Michael Enudi |
//|                                             okmich2002@yahoo.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2020, Michael Enudi"
#property link      "okmich2002@yahoo.com"
#property version   "1.00"

#include "BaseIndicator.mqh"

//--- enums
enum ENUM_MODE_DC_CALCULATION
  {
   MODE_CLOSECLOSE,    // Close
   MODE_HIGHLOW        // High/Low
  };


enum ENUM_DONCHNL_Strategies
  {
   DONCHNL_AboveBelowMidLevel,
   DONCHNL_Bias,
   DONCHNL_Breakout,
   DONCHNL_Phase
  };

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
class CDonchianChannel : public CBaseIndicator
  {
private :
   int               mBarsToCopy;
   int               mHistory;
   //--- indicator setting
   int               m_Period;
   ENUM_MODE_DC_CALCULATION   m_CalcMode;
   //--- indicator buffer
   double            m_HighBuffer[], m_CloseBuffer[], m_DCHighBuffer[], m_DCLowBuffer[];

   void              CalculateDonchianChannel();

   ENUM_ENTRY_SIGNAL             AboveBelowMidLevelSignal();
   ENUM_ENTRY_SIGNAL             Bias(void);
   ENUM_ENTRY_SIGNAL             BreakoutSignal();
   ENUM_ENTRY_SIGNAL             Phase(void);

public:
                     CDonchianChannel(string symbol, ENUM_TIMEFRAMES period, int InputPeriod, ENUM_MODE_DC_CALCULATION InputCalcMode, int history=5):
                     CBaseIndicator(symbol, period)
     {
      m_Period = InputPeriod;
      m_CalcMode = InputCalcMode;

      mHistory = history;
      mBarsToCopy = InputPeriod + mHistory + 1;
     };

   virtual bool                  Init();
   virtual bool                  Refresh(int ShiftToUse=1);
   virtual void                  Release();

   double                        GetData(int bufferIndx=0, int shift=0);

   double                        ChannelCenter(int shift=0);

   ENUM_ENTRY_SIGNAL             TradeFilter(ENUM_DONCHNL_Strategies strategyOption);
   ENUM_ENTRY_SIGNAL             TradeSignal(ENUM_DONCHNL_Strategies strategyOption);
  };

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
bool CDonchianChannel::Init(void)
  {
   ArraySetAsSeries(m_CloseBuffer, true);
   ArraySetAsSeries(m_HighBuffer, true);
   ArraySetAsSeries(m_DCLowBuffer, true);
   ArraySetAsSeries(m_DCHighBuffer, true);

   return true;
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void CDonchianChannel::Release(void)
  {
   ArrayFree(m_CloseBuffer);
   ArrayFree(m_HighBuffer);
   ArrayFree(m_DCHighBuffer);
   ArrayFree(m_DCLowBuffer);
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
bool CDonchianChannel::Refresh(int ShiftToUse=1)
  {
   m_ShiftToUse = ShiftToUse;
   int copied = 0;
   switch(m_CalcMode)
     {
      case MODE_HIGHLOW :
        {
         int highCopied = CopyHigh(m_Symbol, m_TF, 0, mBarsToCopy, m_HighBuffer);
         int lowCopied = CopyLow(m_Symbol, m_TF, 0, mBarsToCopy, m_CloseBuffer);

         copied = (highCopied == lowCopied) ? lowCopied : 0;
        }
      break;
      default:
      case MODE_CLOSECLOSE :
        {
         copied = CopyClose(m_Symbol, m_TF, 0, mBarsToCopy, m_CloseBuffer);
        }
     }

   CalculateDonchianChannel();
   return mBarsToCopy == copied;
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void CDonchianChannel::CalculateDonchianChannel(void)
  {
   ArrayResize(m_DCHighBuffer, m_Period);
   ArrayResize(m_DCLowBuffer, m_Period);
   for(int i=0; i<mHistory; i++)
     {
      if(m_CalcMode == MODE_HIGHLOW)
         m_DCHighBuffer[i]= m_HighBuffer[ArrayMaximum(m_HighBuffer,i+1,m_Period)];
      else
         m_DCHighBuffer[i]= m_CloseBuffer[ArrayMaximum(m_CloseBuffer,i+1,m_Period)];

      m_DCLowBuffer[i]=m_CloseBuffer[ArrayMinimum(m_CloseBuffer,i+1,m_Period)];
     }
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
double CDonchianChannel::GetData(int bufferIndx=0, int shift=0)
  {
   if(shift >= mHistory || bufferIndx > 2)
      return EMPTY_VALUE;

   return bufferIndx == 0 ? m_DCHighBuffer[shift] : m_DCLowBuffer[shift];
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
double CDonchianChannel::ChannelCenter(int shift=0)
  {
   if(shift >= mHistory)
      return EMPTY_VALUE;

   return (m_DCHighBuffer[shift] + m_DCLowBuffer[shift])/2;
  }


//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
ENUM_ENTRY_SIGNAL CDonchianChannel::BreakoutSignal(void)
  {
   if(m_CloseBuffer[1] > m_DCHighBuffer[1])
      return ENTRY_SIGNAL_BUY;
   else
      if(m_CloseBuffer[1] < m_DCLowBuffer[1])
         return ENTRY_SIGNAL_SELL;

   return ENTRY_SIGNAL_NONE;
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
ENUM_ENTRY_SIGNAL CDonchianChannel::AboveBelowMidLevelSignal()
  {
   double midShift2 = ChannelCenter(m_ShiftToUse+1), midShift1 = ChannelCenter(m_ShiftToUse);
   double closeShift2 = iClose(m_Symbol, m_TF, m_ShiftToUse+1);
   double closeShift1 = iClose(m_Symbol, m_TF, m_ShiftToUse);
   if(closeShift2 < midShift2 && closeShift1 > midShift1)
      return ENTRY_SIGNAL_BUY;

   if(closeShift2 > midShift2 && closeShift1 < midShift1)
      return ENTRY_SIGNAL_SELL;

   return ENTRY_SIGNAL_NONE;
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
ENUM_ENTRY_SIGNAL CDonchianChannel::Bias(void)
  {
   int upLevelDirection = (m_DCHighBuffer[2] < m_DCHighBuffer[1]) ? 1 :
                          (m_DCHighBuffer[2]  > m_DCHighBuffer[1]) ? -1 : 0;
   int downLevelDirection = (m_DCLowBuffer[2] < m_DCLowBuffer[1]) ? 1 :
                            (m_DCLowBuffer[2]  > m_DCLowBuffer[1]) ? -1 : 0;
   if(upLevelDirection == 1 && downLevelDirection != -1)
      return ENTRY_SIGNAL_BUY;

   if(upLevelDirection != -1 && downLevelDirection == -1)
      return ENTRY_SIGNAL_SELL;

   return ENTRY_SIGNAL_NONE;
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
ENUM_ENTRY_SIGNAL CDonchianChannel::Phase()
  {
   int upLevelDirection = (m_DCHighBuffer[2] < m_DCHighBuffer[1]) ? 1 :
                          (m_DCHighBuffer[2]  > m_DCHighBuffer[1]) ? -1 : 0;
   int downLevelDirection = (m_DCLowBuffer[2] < m_DCLowBuffer[1]) ? 1 :
                            (m_DCLowBuffer[2]  > m_DCLowBuffer[1]) ? -1 : 0;
   if(upLevelDirection == 1 && downLevelDirection == 1)
      return ENTRY_SIGNAL_BUY;

   if(upLevelDirection == -1 && downLevelDirection == -1)
      return ENTRY_SIGNAL_SELL;

   return ENTRY_SIGNAL_NONE;
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
ENUM_ENTRY_SIGNAL CDonchianChannel::TradeFilter(ENUM_DONCHNL_Strategies strategyOption)
  {
   switch(strategyOption)
     {
      case DONCHNL_AboveBelowMidLevel:
        {
         double mid = ChannelCenter(m_ShiftToUse);
         return m_CloseBuffer[m_ShiftToUse] < mid ? ENTRY_SIGNAL_SELL :
                m_CloseBuffer[m_ShiftToUse] > mid ? ENTRY_SIGNAL_BUY: ENTRY_SIGNAL_NONE;
        }
      case DONCHNL_Bias:
         return Bias();
      case DONCHNL_Breakout:
         return BreakoutSignal();
      case DONCHNL_Phase:
         return Phase();
      default:
         return ENTRY_SIGNAL_NONE;
     }
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
ENUM_ENTRY_SIGNAL CDonchianChannel::TradeSignal(ENUM_DONCHNL_Strategies strategyOption)
  {
   switch(strategyOption)
     {
      case DONCHNL_AboveBelowMidLevel:
         return AboveBelowMidLevelSignal();
      case DONCHNL_Bias:
         return Bias();
      case DONCHNL_Breakout:
         return BreakoutSignal();
      case DONCHNL_Phase:
         return Phase();
      default:
         return ENTRY_SIGNAL_NONE;
     }
  }
//+------------------------------------------------------------------+
