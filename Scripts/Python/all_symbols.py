import MetaTrader5 as mt5

# display data on the MetaTrader 5 package
print("MetaTrader5 package author: ",mt5.__author__)
print("MetaTrader5 package version: ",mt5.__version__)
print("\n***** Begin******\n\n") 
# establish MetaTrader 5 connection to a specified trading account
if not mt5.initialize():
    print("initialize() failed, error code =",mt5.last_error())
    quit()
 
symbols_count=mt5.symbols_total()
if symbols_count>0:
    print("Total count of symbols =", symbols_count)
else:
    print("symbols not found")

print("\n\n")
symbols=mt5.symbols_get(group="*,!*micro*,!*conv*") 
# symbols=mt5.symbols_get("Volatility*") # a wildcard variant 
for sym in symbols:
    print(sym.name, sym.trade_calc_mode)
 
# shut down connection to the MetaTrader 5 terminal
mt5.shutdown()