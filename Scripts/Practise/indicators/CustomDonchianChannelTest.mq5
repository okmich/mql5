//+------------------------------------------------------------------+
//|                                    CustomDonchianChannelTest.mq5 |
//|                                    Copyright 2021, Michael Enudi |
//|                                             okmich2002@yahoo.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2021, Michael Enudi"
#property link      "okmich2002@yahoo.com"
#property version   "1.00"
//+------------------------------------------------------------------+
//| Script program start function                                    |
//+------------------------------------------------------------------+
#include <Okmich\Expert\Indicators\DonchianChannel.mqh>

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void OnStart()
  {
   CDonchianChannel *m_CiDonChl = new CDonchianChannel(_Symbol, _Period, 20, MODE_HIGHLOW, 30);
   double high, low;
   m_CiDonChl.Init();
   m_CiDonChl.Refresh();
   for(int i = 0; i<20; i++)
     {
      high = m_CiDonChl.GetData(0, i);
      low = m_CiDonChl.GetData(1, i);

      Print("Shift is ", i," :::: DC High ", NormalizeDouble(high, _Digits), " and Low is ", NormalizeDouble(low, _Digits),
             " and midline is ", NormalizeDouble(m_CiDonChl.ChannelCenter(i), _Digits));
     }

   m_CiDonChl.Release();
   delete m_CiDonChl;
  }
//+------------------------------------------------------------------+
