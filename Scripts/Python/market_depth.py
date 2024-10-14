import MetaTrader5 as mt5

# display data on the MetaTrader 5 package
print("MetaTrader5 package author: ",mt5.__author__)
print("MetaTrader5 package version: ",mt5.__version__)
print("\n***** Begin******\n\n") 
# establish MetaTrader 5 connection to a specified trading account
if not mt5.initialize(login=2462378, server="Deriv-Demo",password="82SweetZ82"):
    print("initialize() failed, error code =",mt5.last_error())
    quit()

instrument = 'Volatility 10 Index'
if mt5.market_book_add(instrument):
  # get the market depth data 10 times in a loop
   for i in range(10):
        # get the market depth content (Depth of Market)
        items = mt5.market_book_get(instrument)
        # display the entire market depth 'as is' in a single string
        print(items)
        # now display each order separately for more clarity
        if items:
            for it in items:
                # order content
                print(it._asdict())
        # pause for 5 seconds before the next request of the market depth data
        time.sleep(5)
  # cancel the subscription to the market depth updates (Depth of Market)
   mt5.market_book_release(instrument)
else:
    print(f"mt5.market_book_add({instrument}) failed, error code ={mt5.last_error()}")


# shut down connection to the MetaTrader 5 terminal
mt5.shutdown()