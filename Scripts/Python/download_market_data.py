# Copyright 2023, Michael Enudi
# okmich2002@yahoo.com

import MetaTrader5 as mt5
import pandas as pd
import pytz

from datetime import datetime

is_synthetic = True
timeframe = mt5.TIMEFRAME_M1 if is_synthetic else mt5.TIMEFRAME_M5
timezone = pytz.timezone("Etc/GMT+2")
date_from = datetime(2011, 1, 1, tzinfo=timezone)
date_to = datetime(2022, 12, 31, hour = 23, minute=59, tzinfo=timezone)
file_location = "C:\\Users\\okmic\\AppData\\Roaming\\MetaQuotes\\Terminal\\C734FF1CA4CACD5026FF92845253E847\\MQL5\\Files"
dt_range_str = f"{date_to.strftime('%Y%m%d')}-{date_from.strftime('%Y%m%d')}"

def download(sym, tf):
    rates = mt5.copy_rates_range(sym.name, tf, date_from, date_to)
    if rates is None:
        print("Error occured copying rates, code=", mt5.last_error())

    rates_df = pd.DataFrame(rates)
    rates_df['time']=pd.to_datetime(rates_df['time'], unit='s')

    rates_df.to_hdf(f"{file_location}\\market_data-5M-{dt_range_str}.hd5", key=sym.name, mode='a', complib='bzip2')
    print(f"Copied rate data for '{sym.name}' from {date_from} to {date_to}")

# establish MetaTrader 5 connection to a specified trading account
if not mt5.initialize():
    print("initialize() failed, error code =",mt5.last_error())
    quit()

if is_synthetic: # derive symbols
   symbols=mt5.symbols_get()
else : # fx 
   symbols=mt5.symbols_get(group="!*SEK*,!*PLN*,!*micro*,!*.conv*")

sorted(symbols)
valid_path_prefix = ['Crypto', 'Energies', 'ETFs', 'Forex Major', 'Forex Minor', 'Metals', 'Stock Indices']
count = 0
for sym in symbols:
   sym_path = sym.path.split("\\")[0]
   if sym_path in valid_path_prefix:
      # download(sym, timeframe)
      print(f"name: {sym.name}, path={sym.path}")
      count = count + 1
   
print(f"Done copying {count} instruments. See all files in {file_location}")

# shut down connection to the MetaTrader 5 terminal
mt5.shutdown()