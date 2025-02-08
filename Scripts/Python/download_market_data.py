# Copyright 2023, Michael Enudi
# okmich2002@yahoo.com

import MetaTrader5 as mt5
import pandas as pd
import pytz

from datetime import datetime

broker = "Deriv"
interested_symbols= ['Volatility 25 (1s) Index', 'Volatility 75 (1s) Index', 'Volatility 250 (1s) Index', 
      'Step Index', 'Volatility 75 Index', 'EURJPY', 'BTCUSD', 'XAUUSD', 'EURUSD']
valid_path_prefix = ['Crypto', 'Energies', 'ETFs', 'Forex Major', 'Forex Minor', 'Metals', 'Stock Indices', 
      'Volatility Indices', 'Step Indices']

is_synthetic = True
timeframe = mt5.TIMEFRAME_M1 if is_synthetic else mt5.TIMEFRAME_M5
timezone = pytz.timezone("Etc/GMT+2")
date_from = datetime(2013, 10, 1, tzinfo=timezone)
date_to = datetime(2024, 12, 31, hour = 23, minute=59, tzinfo=timezone)
file_location = "C:\\Users\\okmic\\AppData\\Roaming\\MetaQuotes\\Terminal\\FB9A56D617EDDDFE29EE54EBEFFE96C1\\MQL5\\Files"
dt_range_str = f"{date_to.strftime('%Y%m%d')}-{date_from.strftime('%Y%m%d')}"

def download(sym, tf):
    rates = mt5.copy_rates_range(sym.name, tf, date_from, date_to)
    if rates is None:
        print("Error occured copying rates, code=", mt5.last_error())

    rates_df = pd.DataFrame(rates)
    rates_df['time']=pd.to_datetime(rates_df['time'], unit='s')

    # rates_df.to_hdf(f"{file_location}\\market_data-5M-{dt_range_str}.hd5", key=sym.name, mode='a', complib='bzip2')
    rates_df.to_parquet(f"{file_location}\\{sym.name}_{broker}_data-5M-{dt_range_str}.parquet")
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

count = 0
for sym in symbols:
   sym_path = sym.path.split("\\")[0]
   instr_name = sym.path.split("\\")[1]
   if sym_path in valid_path_prefix and instr_name in interested_symbols:
      download(sym, timeframe)
      print(f"name: {sym.name}, path={sym.path}")
      count = count + 1
   
print(f"Done copying {count} instruments. See all files in {file_location}")

# shut down connection to the MetaTrader 5 terminal
mt5.shutdown()
