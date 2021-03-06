{{
''***********************************************************************************
''*  Title:                                                                         *
''*  GDB Hello World.spin                                                           *
''*  The first program you should run to get started with the Sol-X GDB             *
''*  Author: Blaze Sanders                                                          *
''*  Copyright (c) 2014 Solar System Express (Sol-X) LLC                            *
''*  See end of file for terms of use.                                              *
''***********************************************************************************
''*  Brief Description:                                                             *
''*  Number of cogs/CPU's used: 5 out of 8                                          *
''*                                                                                 *   
''*  This code controls the GDB open source hardware:                               *
''*  After to run this program, your GDB will be fully up and running. It will be   *
''*  flashing LEDs and outputting text via the Parallax Series Terminal window.     *
''*  FULL GDB CODE CAN BE FOUND AT https://github.com/solx/GDB                      *
'************************************************************************************
''*  Circuit Diagram can be found at www.solarsystemexpress.com/hardware.html       *                                                                *
''*********************************************************************************** 
}}
CON 'Global Constants 

'Standard clock mode * crystal frequency = 16 * 5 MHz = 80 MHz
_clkmode = xtal1 + pll16x                                               
_xinfreq = 5_000_000

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

'Used to control CPU clock timing functions
'Source URL - http://obex.parallax.com/object/173
TIMING   : "Clock"

PUB Main 'First method called, like in JAVA 

''     Action: Initializes all the GDB hardware and firmware  
'' Parameters: None                                 
''    Results: Prepares the GDB for user interaction                   
''+Reads/Uses: None                                               
''    +Writes: None
'' Local Vars: None                                  
''      Calls: GDB.LEDControl( ), TIMING.PauseSec( ),
''             TIMING.PauseMSec( ), and GDB.SendText( ) functions
''        URL: http://www.solarsystemexpress.com/store.html

GDB.Initialize 

'First Yellow LED (Green & Red LED both on through light pipe)
GDB.LEDControl(7, HIGH)
GDB.LEDControl(6, HIGH)
TIMING.PauseSec(1) ' Pause one second

'Second Yellow LED (Green & Red LED both on through light pipe)  
GDB.LEDControl(5, HIGH)
GDB.LEDControl(4, HIGH)
TIMING.PauseSec(1) ' Pause one second

'Green LED (Go!)
GDB.LEDControl(2, HIGH) 
TIMING.PauseMSec(250) ' Pause 1/4 second

'Red LED (False Start)
GDB.LEDControl(1, HIGH)

'Turn off other LED's
GDB.LEDControl(7, LOW)
GDB.LEDControl(6, LOW)
GDB.LEDControl(5, LOW)
GDB.LEDControl(4, LOW)
GDB.LEDControl(2, LOW) 


TIMING.PauseSec(3) ' Pause three seconds

GDB.SendText(STRING("HAL 9000 TEST: Hello World… Daisy, Daisy, give me your answer, do, I'm half"))
GDB.SendText(STRING("crazy all for the love of you. It won't be a stylish marriage, I can't afford a"))
GDB.SendText(STRING("carriage, But you'd look sweet upon the seat Of a bicycle built for two."))

return