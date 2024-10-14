//+------------------------------------------------------------------+
//|                                                     Pointers.mq5 |
//|                                    Copyright 2020, Michael Enudi |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2020, Michael Enudi"
#property link      "https://www.mql5.com"
#property version   "1.00"
//+------------------------------------------------------------------+
//| Script program start function                                    |
//+------------------------------------------------------------------+
class Foo
  {
public:
   string            m_name;
   int               m_id;
   static int        s_counter;
   //--- constructors and desctructors
                     Foo(void) {Setup("noname");};
                     Foo(string name) {Setup(name);};
                    ~Foo(void) {};
   //--- initializes object of type Foo
   void              Setup(string name)
     {
      m_name=name;
      s_counter++;
      m_id=s_counter;
     }
  };
int Foo::s_counter=0;
//+------------------------------------------------------------------+
//| Script program start function                                    |
//+------------------------------------------------------------------+
void OnStart()
  {
//--- declare an object as variable with its automatic creation
   Foo foo1;
//--- variant of passing an object by reference
   PrintObject(foo1);

//--- declare a pointer to an object and create it using the 'new' operator
   Foo *foo2=new Foo("foo2");
//--- variant of passing a pointer to an object by reference
   PrintObject(foo2); // pointer to an object is converted automatically by compiler

//--- declare an array of objects of type Foo
   Foo foo_objects[5];
//--- variant of passing an array of objects
   PrintObjectsArray(foo_objects); // separate function for passing an array of objects

//--- declare an array of pointers to objects of type Foo
   Foo *foo_pointers[5];
   for(int i=0; i<5; i++)
     {
      foo_pointers[i]=new Foo("foo_pointer");
     }
//--- variant of passing an array of pointers
   PrintPointersArray(foo_pointers); // separate function for passing an array of pointers

//--- it is obligatory to delete objects created as pointers before termination
   delete(foo2);
//--- delete array of pointers
   int size=ArraySize(foo_pointers);
   for(int i=0; i<5; i++)
      delete(foo_pointers[i]);
//---
  }
//+------------------------------------------------------------------+
//| Objects are always passed by reference                           |
//+------------------------------------------------------------------+
void PrintObject(Foo &object)
  {
   Print(__FUNCTION__,": ",object.m_id," Object name=",object.m_name);
  }
//+------------------------------------------------------------------+
//| Passing an array of objects                                      |
//+------------------------------------------------------------------+
void PrintObjectsArray(Foo &objects[])
  {
   int size=ArraySize(objects);
   for(int i=0; i<size; i++)
     {
      PrintObject(objects[i]);
     }
  }
//+------------------------------------------------------------------+
//| Passing an array of pointers to object                           |
//+------------------------------------------------------------------+
void PrintPointersArray(Foo* &objects[])
  {
   int size=ArraySize(objects);
   for(int i=0; i<size; i++)
     {
      PrintObject(objects[i]);
     }
  }
//+------------------------------------------------------------------+
//+------------------------------------------------------------------+
