from datetime import datetime

import MetaTrader5 as mt5
import pandas as pd
import pytz

# display data on the MetaTrader 5 package
print("MetaTrader5 package author: ",mt5.__author__)
print("MetaTrader5 package version: ",mt5.__version__)
print("\n***** Begin******\n\n") 
# establish MetaTrader 5 connection to a specified trading account
if not mt5.initialize(""):
    print("initialize() failed, error code =",mt5.last_error())
    quit()
 
symbols_count=mt5.symbols_total()
if symbols_count>0:
    print("Total count of symbols =",symbols_count)
else:
    print("symbols not found")

print("\n\n")
sym="AUDUSD"

timezone = pytz.timezone("Etc/GMT+2")
date_from = datetime(2017, 1, 1, tzinfo=timezone)
date_to = datetime(2022, 5, 21, hour = 23, minute=59, tzinfo=timezone)
print(f"Copy 1M rate data for '{sym}' from {date_from} to {date_to}")

rates = mt5.copy_rates_range(sym, mt5.TIMEFRAME_M5, date_from, date_to)
# if rates != None:
#     print("Error occured copying rates, code=", mt5.last_error())

# shut down connection to the MetaTrader 5 terminal
mt5.shutdown()

rates_frame = pd.DataFrame(rates)
# convert time in seconds into the 'datetime' format
rates_frame['time']=pd.to_datetime(rates_frame['time'], unit='s')

print(rates_frame.head(20))
print(rates_frame.shape)