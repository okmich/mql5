//+------------------------------------------------------------------+
//|                                       sample_dll_integration.mq5 |
//|                                    Copyright 2024, Michael Enudi |
//|                                             okmich2002@yahoo.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2024, Michael Enudi"
#property link      "okmich2002@yahoo.com"
#property version   "1.00"

struct MqlPrice
{
    string symbol;
    double   open;
    double   high;
    double   low;
    double   close;
    long     volume;
    int      spread;
};

//---
#import "mql5_dll_example.dll"
   int Add(int a, int b);
   double Multiply(double a, double b);
      
   int  fnCalculateSpeed(long &res1,double &res2);
   void fnFillArray(int &arr[],int arr_size);
   void fnReplaceString(string text,string from,string to);
   void fnCrashTest(int arr);
   
   int fnStringLen(string text);
   double selectField(MqlPrice& mqlPrice, int i);
   void processStruct(MqlPrice& mqlPrice, double& res);
#import

//void callProcessStruct(){
//   MqlPrice mqlPrice;
//   mqlPrice.symbol = _Symbol;
//   mqlPrice.close = iClose(NULL,0, 0);
//   mqlPrice.high = iHigh(NULL,0, 0);
//   mqlPrice.low = iLow(NULL,0, 0);
//   mqlPrice.open = iOpen(NULL,0, 0);
//   mqlPrice.spread = iSpread(NULL,0, 0); 
//   mqlPrice.volume = iVolume(NULL,0, 0); 
//   
//   double w=0;
//   processStruct(mqlPrice, w);
//   double actual = ((mqlPrice.close * 2) + mqlPrice.high + mqlPrice.low) / 4;
//   Print("callProcessStruct::: C++ dll result is ", w, " while the actual is ", actual);
//};

//void callProcessSelectFieldFromStruct(){
//   MqlPrice mqlPrice;
//   mqlPrice.symbol = _Symbol;
//   mqlPrice.close = iClose(NULL,0, 0);
//   mqlPrice.high = iHigh(NULL,0, 0);
//   mqlPrice.low = iLow(NULL,0, 0);
//   mqlPrice.open = iOpen(NULL,0, 0);
//   mqlPrice.spread = iSpread(NULL,0, 0); 
//   mqlPrice.volume = iVolume(NULL,0, 0); 
//   
//   double w = selectField(mqlPrice, 1);
//   Print("C++ dll selectField result is ", w, " while the actual is ", mqlPrice.high, " or ", iHigh(NULL,0, 0));
//};

void callFuncs(){
//--- calling the function for calculations
   int    speed=0;
   long   res_int=0;
   double res_double=0.0;

   speed=fnCalculateSpeed(res_int,res_double);
   Print("Time ",speed," msec, int: ",res_int," double: ",res_double);
//--- call for the array filling
   int    arr[];
   string result="Array: "; 
   ArrayResize(arr,10);
   
   fnFillArray(arr,ArraySize(arr));
   for(int i=0;i<ArraySize(arr);i++) result=result+IntegerToString(arr[i])+" ";
   Print(result);
//--- modifying the string
   string text="A quick brown fox jumps over the lazy dog"; 
   
   fnReplaceString(text,"fox","cat");
   Print("Replace: ",text);
//--- and finally call a crash
//--- (the execution environment will catch the exception and prevent the client terminal crush)
   //fnCrashTest(NULL);
   Print("You won't see this text!");
   
   Print("From C++: ", fnStringLen("You won't see this text!"), 
   " while MQL is ", StringLen("You won't see this text!"));
}

//+------------------------------------------------------------------+
//| Script program start function                                    |
//+------------------------------------------------------------------+
void OnStart()
  {
//---
   int sum = Add(5, 3);
   double product = Multiply(2.5, 4.0);
   
   Print("Sum: ", sum);
   Print("Product: ", product);
   
   callFuncs();
 
   //callProcessStruct();

   //callProcessSelectFieldFromStruct();
  }
//+------------------------------------------------------------------+
