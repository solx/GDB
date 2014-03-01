{Object_Title_and_Purpose}


CON 'Global Constants 

'---Useful constants--- 
HIGH = 1
LOW = 0
OUTPUT = 1
INPUT = 0
AVERAGE = 1
CURRENT = 0
FORWARD = 1
REVERSE = 0
INFINITY = 1
ENABLE = 1
DISABLE = 0

VAR  'Global variables 

long  ExampleVariable 
   
OBJ  'Additional files you would like imported / included  

'Sol-X API that controls all the GDB hardware function
GDB      : "GDB-API-V0.1.0"

'Used to control clock timing functions
TIMING   : "Clock"

PUB Main 'First method called, like in JAVA

''     Action: Initializes all the GDB hardware and firmware  
'' Parameters: None                                 
''    Results: Prepares the GDB for user interaction and test hardwares                   
''+Reads/Uses: None                                               
''    +Writes: None
'' Local Vars: None                                  
''      Calls: All the GDB API functions
''        URL: http://www.solarsystemexpress.com/store.html

GDB.Initialize

'REMOVE EVERYTHING BELOW HERE TO START WRITING YOUR OWN CODE. HAVE FUN :)

GDB.UnitTest  

GDB.MeasureAnalogVoltage(0, GDB#AVERAGE, 50)
GDB.OutputAnalogVoltage(4095, 0)
GDB.TurnOffADC_DAC

GDB.SetMotorDriver(GDB#FULL_H_BRIDGE_U1, GDB#FORWARD)   
TIMING.PauseMSec(2000) 'PAUSE TWO SECONDS
GDB.SetMotorDriver(GDB#FULL_H_BRIDGE_U1, GDB#REVERSE)
GDB.SetHighPowerDriverDutyCycle(GDB#FULL_H_BRIDGE_U2, 75, GDB#FORWARD, 2000)



PRI private_method_name


DAT
name    byte  "string_data",0        
        