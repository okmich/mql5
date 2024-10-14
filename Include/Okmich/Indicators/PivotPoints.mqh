//+------------------------------------------------------------------+
//|                                                  PivotPoints.mqh |
//|                                                    Michael Enudi |
//|                                             okmich2002@yahoo.com |
//+------------------------------------------------------------------+
#property copyright "Michael Enudi"
#property link      "okmich2002@yahoo.com"
#property copyright "Copyright 2022, Michael Enudi"
#property link      "okmich2002@yahoo.com"

#include "BaseIndicator.mqh"

//+------------------------------------------------------------------+
//| ENUM_PP_PERIOD                                                   |
//+------------------------------------------------------------------+
enum ENUM_PP_PERIOD
  {
   ppDay,   // Day
   ppWeek,  // Week
   ppMonth  // Month
  };

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
class CPivotPoints : public CBaseIndicator
  {
private :
   int               mBarsToCopy;
   //--- indicator paramter
   ENUM_PP_PERIOD     m_ppPeriod;
   //--- indicator
   int                m_Handle;
   //--- indicator buffer
   double             m_PpBuffer[], m_R1Buffer[], m_R2Buffer[], m_R3Buffer[], m_S1Buffer[], m_S2Buffer[], m_S3Buffer[];

   void              SetBarsToCopy(ENUM_TIMEFRAMES period);

public:
                     CPivotPoints(string symbol, ENUM_TIMEFRAMES period,
                ENUM_PP_PERIOD InputPeriod=ppDay): CBaseIndicator(symbol, period)
     {
      m_ppPeriod = InputPeriod;
      SetBarsToCopy(period);
     }

   virtual bool       Init();
   virtual bool       Refresh(int ShiftToUse=1);
   virtual void       Release();

   double             GetData(int buffer=0, int shift=0);
   void               GetData(double &buffer[], int buffer=0, int shift=0);
  };

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
bool CPivotPoints::Init(void)
  {
   ArraySetAsSeries(m_PpBuffer, true);
   ArraySetAsSeries(m_R1Buffer, true);
   ArraySetAsSeries(m_R2Buffer, true);
   ArraySetAsSeries(m_R3Buffer, true);
   ArraySetAsSeries(m_S1Buffer, true);
   ArraySetAsSeries(m_S2Buffer, true);
   ArraySetAsSeries(m_S3Buffer, true);

   m_Handle = iCustom(m_Symbol, m_TF, "Articles\\Pivot Points", m_ppPeriod);
   return m_Handle != INVALID_HANDLE;
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
bool CPivotPoints::Refresh(int ShiftToUse=1)
  {
   m_ShiftToUse = ShiftToUse;
   int r3Copied = CopyBuffer(m_Handle, 0, 0, mBarsToCopy, m_R3Buffer);
   int r2Copied = CopyBuffer(m_Handle, 1, 0, mBarsToCopy, m_R2Buffer);
   int r1Copied = CopyBuffer(m_Handle, 2, 0, mBarsToCopy, m_R1Buffer);
   int ppCopied = CopyBuffer(m_Handle, 3, 0, mBarsToCopy, m_PpBuffer);
   int s1Copied = CopyBuffer(m_Handle, 4, 0, mBarsToCopy, m_S1Buffer);
   int s2Copied = CopyBuffer(m_Handle, 5, 0, mBarsToCopy, m_S2Buffer);
   int s3Copied = CopyBuffer(m_Handle, 6, 0, mBarsToCopy, m_S3Buffer);

   return mBarsToCopy == r3Copied && r3Copied == r2Copied && r2Copied == r1Copied && r1Copied == ppCopied
          && ppCopied == s1Copied && s1Copied == s2Copied && s2Copied == s3Copied;
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void CPivotPoints::Release(void)
  {
   IndicatorRelease(m_Handle);
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
double CPivotPoints::GetData(int bufferIndx=0, int shift=0)
  {
   if(shift >= mBarsToCopy || bufferIndx > 6)
      return EMPTY_VALUE;

   switch(bufferIndx)
     {
      case 0:
         return m_R3Buffer[shift];
      case 1:
         return m_R2Buffer[shift];
      case 2:
         return m_R1Buffer[shift];
      case 3:
         return m_PpBuffer[shift];
      case 4:
         return m_S1Buffer[shift];
      case 5:
         return m_S2Buffer[shift];
      case 6:
         return m_S3Buffer[shift];
      default:
         return EMPTY_VALUE;
     }
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void CPivotPoints::GetData(double &buffer[], int bufferIndx=0, int shift=0)
  {
   if(shift >= mBarsToCopy || bufferIndx > 6)
      return;

   ArraySetAsSeries(buffer, true);
   ArrayResize(buffer, mBarsToCopy - shift);

   switch(bufferIndx)
     {
      case 0:
         ArrayCopy(buffer, m_R3Buffer, 0, shift);
         break;
      case 1:
         ArrayCopy(buffer, m_R2Buffer, 0, shift);
         break;
      case 2:
         ArrayCopy(buffer, m_R1Buffer, 0, shift);
         break;
      case 3:
         ArrayCopy(buffer, m_PpBuffer, 0, shift);
         break;
      case 4:
         ArrayCopy(buffer, m_S1Buffer, 0, shift);
         break;
      case 5:
         ArrayCopy(buffer, m_S2Buffer, 0, shift);
         break;
      case 6:
         ArrayCopy(buffer, m_S3Buffer, 0, shift);
         break;
      default:
         ArrayCopy(buffer, m_PpBuffer, 0, shift);
         break;
     }
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void CPivotPoints::SetBarsToCopy(ENUM_TIMEFRAMES period)
  {
// because I would like to get the previous periods pivot points
   datetime currentDateTime  = TimeCurrent(), previousDateTime;
   switch(m_ppPeriod)
     {
      case ppWeek:
         previousDateTime = currentDateTime - PeriodSeconds(PERIOD_W1);
         break;
      case ppMonth:
         previousDateTime = currentDateTime - PeriodSeconds(PERIOD_M1);
         break;
      case ppDay:
      default:
         previousDateTime = currentDateTime - PeriodSeconds(PERIOD_D1);
     }
   mBarsToCopy = Bars(m_Symbol, m_TF, previousDateTime, currentDateTime);
  }
//+------------------------------------------------------------------+
