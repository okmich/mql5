//+------------------------------------------------------------------+
//|                                               BollingerBands.mq5 |
//|                                    Copyright 2020, Michael Enudi |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2020, Michael Enudi"
#property link      "https://www.mql5.com"
#property version   "1.00"
//+------------------------------------------------------------------+
//| Script program start function                                    |
//+------------------------------------------------------------------+
void OnStart()
  {
   string SD_TSI_IND  = "Okmich\\SD_TSI";
   int               m_SDTSI_Handle;
   double            m_SDTSI[];
   
   
   ArraySetAsSeries(m_SDTSI, true);
   m_SDTSI_Handle = iCustom(_Symbol, _Period, SD_TSI_IND);
   
   int len = CopyBuffer(m_SDTSI_Handle, 0, 0, 100, m_SDTSI);
   datetime dt;
   for (int i = 0 ; i < 100; i++){
      dt = iTime(_Symbol, _Period, i);
      Print("Time: ", TimeToString(dt), " SD TSI: ", NormalizeDouble(m_SDTSI[i], _Digits));
   }

  }
//+------------------------------------------------------------------+
