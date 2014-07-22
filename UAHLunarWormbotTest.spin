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

HIGH_SPEED_IO0 = 0 
HIGH_SPEED_IO1 = 1
HIGH_SPEED_IO2 = 2
HIGH_SPEED_IO3 = 3
HIGH_SPEED_IO4 = 4
HIGH_SPEED_IO5 = 5
 

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
''    Results: Prepares the GDB for user interaction                    
''+Reads/Uses: None                                               
''    +Writes: None
'' Local Vars: None                                  
''      Calls: GDB.Initialize( ), GDB.SendText( ), TIMING.PauseSec( )
''             GDB.GetNumber( ), and GDB.SetMotorShield( ) functions
''        URL: http://www.solarsystemexpress.com/store.html

GDB.Initialize

repeat 'Infinte Loop

  repeat
    GDB.SendText(STRING("TYPE 1 and hit enter to extend L-16 actuators."))
    TIMING.PauseSec(5)      'Pause 5 seconds before outputing promote again 
  until(GDB.GetNumber)

  GDB.SetMotorShield(HIGH_SPEED_IO0, HIGH_SPEED_IO1, HIGH_SPEED_IO2, FORWARD)
  GDB.SetMotorShield(HIGH_SPEED_IO3, HIGH_SPEED_IO4, HIGH_SPEED_IO5, FORWARD)

  repeat
    GDB.SendText(STRING("TYPE 2 and hit enter to contract  L-16 actuators."))
    TIMING.PauseSec(5)      'Pause 5 seconds before outputing promote again  
  until(GDB.GetNumber)

  GDB.SetMotorShield(HIGH_SPEED_IO0, HIGH_SPEED_IO1, HIGH_SPEED_IO2, REVERSE)
  GDB.SetMotorShield(HIGH_SPEED_IO3, HIGH_SPEED_IO4, HIGH_SPEED_IO5, REVERSE)

{{ See GDB-API-V.0.1
PUB  SetMotorShield(EnablePin, Input1Pin, Input2Pin, Direction)

     Action: More complex function to control actuator movement
 Parameters: EnablePin - GDB GPIO pin connected to the "Enable Motor X Connector" on Seeed Studio Motor Driver
             Input1Pin - GDB GPIO pin connected to the J7.1 (Channel A) or J7.5 (Channel B) on Seeed Studio Motor Driver
             Input2Pin - GDB GPIO pin connected to the J7.4 (Channel A) or J7.6 (Channel B) on Seeed Studio Motor Driver
             Direction - Sets direction of actuator movement using contsant FORWARD or REVERSE                               
    Results: Changes the direction of current flow in the Seeed Studio Motor Driver                     
+Reads/Uses: None                                               
    +Writes: None
 Local Vars: None                                     
      Calls: FullH_BridgeSubroutine( )
        URL: www.seeedstudio.com/wiki/Motor_Shield_V1.0
}}

PRI private_method_name


DAT
name    byte  "string_data",0        
        