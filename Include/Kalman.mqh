//+------------------------------------------------------------------+
//|                                                       Kalman.mqh |
//|                                              Copyright 2017, DNG |
//|                                 http://www.mql5.com/ru/users/dng |
//+------------------------------------------------------------------+
#property copyright "Copyright 2017, DNG"
#property link      "http://www.mql5.com/ru/users/dng"
#property version   "1.00"
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
#include <Math\\Stat\\Math.mqh>
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
class CKalman
  {
private:
//---
   uint              ci_HistoryBars;               //Bars for analysis
   uint              ci_Shift;                     //Shift of autoregression calculation
   string            cs_Symbol;                    //Symbol
   ENUM_TIMEFRAMES   ce_Timeframe;                 //Timeframe
   double            cda_AR[];                     //Autoregression coefficients
   int               ci_IP;                        //Number of autoregression coefficients
   
   bool              cb_AR_Flag;                   //Flag of autoregression calculation
//--- Values of Kalman's filter
   double            cd_X;                         // X
   double            cda_F[];                      // F array
   double            cd_P;                         // P
   double            cd_Q;                         // Q
   double            cd_y;                         // y
   double            cd_S;                         // S
   double            cd_R;                         // R
   double            cd_K;                         // K
//---
   
   bool              Autoregression(void);
   bool              LevinsonRecursion(const double &R[],double &A[],double &K[]);
   bool              Shift(double &array[]);
   
public:
                     CKalman(uint bars=6240, uint shift=0, string symbol=NULL, ENUM_TIMEFRAMES period=PERIOD_H1);
                    ~CKalman();
   bool              GetAR_Coefficients(double &AR[]);
   double            Forecast(void);
   double            Correction(double z);
   void              Clear_AR_Flag(void)  {  cb_AR_Flag=false; }
  };
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
CKalman::CKalman(uint bars, uint shift, string symbol, ENUM_TIMEFRAMES period)
  {
   ci_HistoryBars =  bars;
   cs_Symbol      =  (symbol==NULL ? _Symbol : symbol);
   ce_Timeframe   =  period;
   cb_AR_Flag     =  false;
   ci_Shift       =  shift;
   cd_P           =  1;
   cd_K           =  0.9;
  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
CKalman::~CKalman()
  {
  
  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
bool CKalman::Autoregression(void)
  {
   //--- check for insufficient data
   if(Bars(cs_Symbol,ce_Timeframe)<(int)ci_HistoryBars)
      return false;
//---
   double   cda_QuotesCenter[];                                //Data to calculate

//--- make all prices available
   double close[];
   int NumTS=CopyClose(cs_Symbol,ce_Timeframe,ci_Shift+1,ci_HistoryBars+1,close)-1;
   if(NumTS<=0)
      return false;
   ArraySetAsSeries(close,true);
   if(ArraySize(cda_QuotesCenter)!=NumTS)
     {
      if(ArrayResize(cda_QuotesCenter,NumTS)<NumTS)
         return false;
     }
   for(int i=0;i<NumTS;i++)
      cda_QuotesCenter[i]=close[i]/close[i+1];                 // Calculate coefficients
  
   ci_IP=(int)MathRound(50*MathLog10(NumTS));
   if(ci_IP>NumTS*0.5)
      ci_IP=(int)MathRound(NumTS*0.5);                         // Autoregressive model order
  
   double cor[],tdat[];
   if(ci_IP<=0 || ArrayResize(cor,ci_IP)<ci_IP || ArrayResize(cda_AR,ci_IP)<ci_IP || ArrayResize(tdat,ci_IP)<ci_IP)
      return false;
   double a=0;
   for(int i=0;i<NumTS;i++)
      a+=cda_QuotesCenter[i]*cda_QuotesCenter[i];    
   for(int i=1;i<=ci_IP;i++)
     {  
      double c=0;
      for(int k=i;k<NumTS;k++)
         c+=cda_QuotesCenter[k]*cda_QuotesCenter[k-i];
      cor[i-1]=c/a;                                            // Autocorrelation
     } 
  
   if(!LevinsonRecursion(cor,cda_AR,tdat))                     // Levinson-Durbin recursion
      return false;
   
   double sum=0;
   for(int i=0;i<ci_IP;i++)
     {
      sum+=cda_AR[i];
     }
   if(sum==0)
      return false;
  
   double k=1/sum;
   for(int i=0;i<ci_IP;i++)
      cda_AR[i]*=k;
   
   cb_AR_Flag=true;
   
   cd_R=MathStandardDeviation(close);
//---
   double auto_reg[];
   ArrayResize(auto_reg,NumTS-ci_IP);
   for(int i=(NumTS-ci_IP)-2;i>=0;i--)
     {
      auto_reg[i]=0;
      for(int c=0;c<ci_IP;c++)
        {
         auto_reg[i]+=cda_AR[c]*cda_QuotesCenter[i+c];
        }
     }
   cd_Q=MathStandardDeviation(auto_reg);
//---
   ArrayFree(cda_F);
   if(ArrayResize(cda_F,(ci_IP+1))<=0)
      return false;
   ArrayCopy(cda_F,cda_QuotesCenter,0,NumTS-ci_IP,ci_IP+1);
   cd_X=MathMean(close,0,10);
//---
   return true;
  }
//+-----------------------------------------------------------------------------------+
//| Calculate the Levinson-Durbin recursion for the autocorrelation sequence R[]      |
//| and return the autoregression coefficients A[] and partial autocorrelation        |
//| coefficients K[]                                                                  |
//+-----------------------------------------------------------------------------------+
bool CKalman::LevinsonRecursion(const double &R[],double &A[],double &K[])
  {
   int p,i,m;
   double km,Em,Am1[],err;
   
   p=ArraySize(R);
   if(ArrayResize(Am1,p)<=0 || (ArraySize(A)<p && ArrayResize(A,p)<=0) || (ArraySize(K)<p && ArrayResize(K,p)<=0))
      return false;
   ArrayInitialize(Am1,0);
   ArrayInitialize(A,0);
   ArrayInitialize(K,0);
   km=0;
   Em=1;
   for(m=0;m<p;m++)
     {
      err=0;
      for(i=0;i<m;i++)
         err+=Am1[i]*R[m-i-1];
      km=(R[m]-err)/Em;
      K[m]=km; A[m]=km;
      for(i=0;i<m;i++)
         A[i]=(Am1[i]-km*Am1[m-i-1]);
      Em=(1-km*km)*Em;
      ArrayCopy(Am1,A);
     }
   return true;
  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
bool CKalman::GetAR_Coefficients(double &AR[])
  {
   ArrayFree(AR);
   if(!cb_AR_Flag)
     {
      if(!Autoregression())
        {
         return false;
        }
     }
   return (ArrayCopy(AR,cda_AR)>0);
  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
double CKalman::Forecast()
  {
   if(!cb_AR_Flag)
     {
      ArrayFree(cda_AR);
      if(!Autoregression())
        {
         return EMPTY_VALUE;
        }
     }
   Shift(cda_F);
   cda_F[0]=0;
   for(int i=0;i<ci_IP;i++)
      cda_F[0]+=cda_F[i+1]*cda_AR[i];
   
   cd_X=cd_X*cda_F[0];
   cd_P=MathPow(cda_F[0],2)*cd_P+cd_Q;
   
   return cd_X;
  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
double   CKalman::Correction(double z)
  {
   if(z<=0 || z==EMPTY_VALUE)
      return EMPTY_VALUE;
   
   if(!cb_AR_Flag)
     {
      ArrayFree(cda_AR);
      if(!Autoregression())
        {
         return EMPTY_VALUE;
        }
     }
   
   cd_y=z-cd_X;
   cd_S=cd_P+cd_R;
   cd_K=(cd_S!=0 ? cd_P/cd_S : 1);
   cd_X=cd_X+cd_K*cd_y;
   cd_P=(1-cd_K)*cd_P;
   if(cd_P<=0)
      cb_AR_Flag=false;
   
   return cd_X;
  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
bool  CKalman::Shift(double &array[])
  {
   int size=ArraySize(array)-1;
   double temp[];
   if(ArrayCopy(temp,array,0,0,size)<size)
      return false;
   if(ArrayCopy(array,temp,1,0,size)<size)
      return false;

   array[0]=0;
   return true;
  }
//+------------------------------------------------------------------+
//| Computes the mean value of the values in array[]                 |
//+------------------------------------------------------------------+
double MathMean(const double&  array[],               // массив с данными 
                  const int      start=0,               // начальный индекс  
                  const int      count=WHOLE_ARRAY      // количество элементов  
                  )
  {
   int size=ArraySize(array);
//--- check data range
   if(size<(fmax(start,0)+fmax(count,1)))
      return(QNaN); // need at least 1 observation
//--- calculate mean
   double mean=0.0;
   int counted=0;
   for(int i=fmax(start,0); (i<size && (count<=0 || i<fmax(start,0)+fmax(count,1))); i++)
     {
      mean+=array[i];
      counted++;
     }
   mean=mean/counted;
//--- return mean
   return(mean);
  }
//+------------------------------------------------------------------+
