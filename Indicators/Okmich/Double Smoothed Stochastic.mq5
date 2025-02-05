//------------------------------------------------------------------
#property copyright   "© mladen, 2018"
#property link        "mladenfx@gmail.com"
#property description "Double Smoothed Stochastic"
//------------------------------------------------------------------
#property indicator_separate_window
#property indicator_buffers 5
#property indicator_plots   3
#property indicator_label1  "Fill area"
#property indicator_type1   DRAW_FILLING
#property indicator_color1  C'225,225,255',C'255,225,225'
#property indicator_label2  "DSS"
#property indicator_type2   DRAW_COLOR_LINE
#property indicator_color2  clrGray,clrDeepSkyBlue,clrDarkOrange
#property indicator_width2  2
#property indicator_label3  "DSS signal"
#property indicator_type3   DRAW_LINE
#property indicator_color3  clrSilver
#property indicator_level1  0
#property indicator_level2  100
#property indicator_minimum -5
#property indicator_maximum 105

//
//--- input parameters
//

enum enPrices
  {
   pr_close   =PRICE_CLOSE,    // Close
   pr_open    =PRICE_OPEN,     // Open
   pr_high    =PRICE_HIGH,     // High
   pr_low     =PRICE_LOW,      // Low
   pr_median  =PRICE_MEDIAN,   // Median
   pr_typical =PRICE_TYPICAL,  // Typical
   pr_weighted=PRICE_WEIGHTED, // Weighted
   pr_lowhigh =-99             // Low/High
  };
input int      inpStoPeriod  = 55;         // Stochastic period
input int      inpSmtPeriod  =  5;         // Smoothing period
input int      inpSigPeriod  =  5;         // Signal/trigger period
input enPrices inpPrice      = pr_lowhigh; // Price

//
//--- buffers declarations
//

double fillu[],filld[],stc[],stcc[],sig[],ª_sigAlpha;
int  ª_sigPeriod;

//------------------------------------------------------------------
// Custom indicator initialization function
//------------------------------------------------------------------

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
int OnInit()
  {
//
//--- indicator buffers mapping
//
   SetIndexBuffer(0,fillu,INDICATOR_DATA);
   SetIndexBuffer(1,filld,INDICATOR_DATA);
   SetIndexBuffer(2,stc,INDICATOR_DATA);
   SetIndexBuffer(3,stcc,INDICATOR_COLOR_INDEX);
   SetIndexBuffer(4,sig,INDICATOR_DATA);
   PlotIndexSetInteger(0,PLOT_SHOW_DATA,false);
   ª_sigPeriod = (inpSigPeriod>1) ? inpSigPeriod : 1;
   ª_sigAlpha  = 2.0 / (1.0+ª_sigPeriod);
   string _priceType = StringSubstr(EnumToString(inpPrice),3);
   _priceType = (_priceType!="lowhigh") ? _priceType+"/"+_priceType : "low/high";

//
//--- indicator short name assignment
//
   IndicatorSetString(INDICATOR_SHORTNAME,"Dss "+_priceType+" ("+(string)inpStoPeriod+","+(string)inpSmtPeriod+","+(string)ª_sigPeriod+")");
   return (INIT_SUCCEEDED);
  }
void OnDeinit(const int reason) { }

//------------------------------------------------------------------
//  Custom indicator iteration function
//------------------------------------------------------------------
//
//---
//

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
int OnCalculate(const int rates_total,const int prev_calculated,const datetime &time[],
                const double &open[],
                const double &high[],
                const double &low[],
                const double &close[],
                const long &tick_volume[],
                const long &volume[],
                const int &spread[])
  {
   int i= prev_calculated-1;
   if(i<0)
      i=0;
   for(; i<rates_total && !_StopFlag; i++)
     {
      double _price,_priceh,_pricel;
      switch(inpPrice)
        {
         case pr_close:
            _price = _priceh = _pricel = close[i];
            break;
         case pr_open:
            _price = _priceh = _pricel = open[i];
            break;
         case pr_high:
            _price = _priceh = _pricel = high[i];
            break;
         case pr_low:
            _price = _priceh = _pricel = low[i];
            break;
         case pr_median:
            _price = _priceh = _pricel = (high[i]+low[i])/2.0;
            break;
         case pr_typical:
            _price = _priceh = _pricel = (high[i]+low[i]+close[i])/3.0;
            break;
         case pr_weighted:
            _price = _priceh = _pricel = (high[i]+low[i]+close[i]+close[i])/4.0;
            break;
         default :
            _price  = close[i];
            _priceh = high[i];
            _pricel = low[i];
        }
      fillu[i] = stc[i] = iDssStoch(_price,_priceh,_pricel,inpStoPeriod,inpSmtPeriod,i);
      filld[i] = sig[i] = (i>0) ?  sig[i-1]+ª_sigAlpha*(stc[i]-sig[i-1]) : 0;
      stcc[i] = stc[i]>sig[i] ? 1 : 2;
     }
   return (i);
  }

//------------------------------------------------------------------
//    Custom function(s)
//------------------------------------------------------------------
//
//---
//

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
double iDssStoch(double price, double priceHigh, double priceLow, int period, int smoothing, int i,int instance=0)
  {
#define ¤ instance
#define _functionInstances 1
#define _functionRingSize 32

   class cDssStochasticWork
     {
   public :
      int            originalPeriod;
      int            period;
      double         alpha;
      double         ema1[_functionRingSize];
      double         ema2[_functionRingSize];
      double         maxArray[];
      double         minArray[];
      double         workArray[];

                     cDssStochasticWork() { originalPeriod=-1; return; }
                    ~cDssStochasticWork() { ArrayFree(maxArray); ArrayFree(minArray); ArrayFree(workArray); return; }
     };
   static cDssStochasticWork  m_work[_functionInstances];
   if(m_work[¤].originalPeriod!=period)
     {
      m_work[¤].originalPeriod =  period;
      m_work[¤].period         = (period>0) ? period : 1;
      m_work[¤].alpha          = 2.0 / (1.0+(smoothing>1?smoothing:1));
      ArrayResize(m_work[¤].maxArray,m_work[¤].period);
      ArrayInitialize(m_work[¤].maxArray,priceHigh);
      ArrayResize(m_work[¤].minArray,m_work[¤].period);
      ArrayInitialize(m_work[¤].minArray,priceLow);
      ArrayResize(m_work[¤].workArray,m_work[¤].period);
      ArrayInitialize(m_work[¤].workArray,0.5);
     }

//
//---
//

   int _poe = (i) % _functionRingSize;
   int _pos = (i) % m_work[¤].period;
   m_work[¤].minArray[_pos]=priceLow;
   m_work[¤].maxArray[_pos]=priceHigh;
   if(i>0)
     {
      int _pop = (i-1)% _functionRingSize;

      double min = m_work[¤].minArray[ArrayMinimum(m_work[¤].minArray)];
      double div = m_work[¤].maxArray[ArrayMaximum(m_work[¤].maxArray)]-min;
      m_work[¤].ema1[_poe] = m_work[¤].ema1[_pop]+m_work[¤].alpha*((div ? (price-min)/div : 0)-m_work[¤].ema1[_pop]);
      m_work[¤].workArray[_pos] = m_work[¤].ema1[_poe];
      min = m_work[¤].workArray[ArrayMinimum(m_work[¤].workArray)];
      div = m_work[¤].workArray[ArrayMaximum(m_work[¤].workArray)]-min;
      m_work[¤].ema2[_poe] = m_work[¤].ema2[_pop]+m_work[¤].alpha*((div ? (m_work[¤].ema1[_poe]-min)/div : m_work[¤].ema1[_poe])-m_work[¤].ema2[_pop]);
     }
   else
      m_work[¤].ema2[_poe] = m_work[¤].ema1[_poe] = 0;
   return(100*m_work[¤].ema2[_poe]);

//
//---
//

#undef ¤ #undef _functionInstances #undef _functionRingSize
  }
//------------------------------------------------------------------
