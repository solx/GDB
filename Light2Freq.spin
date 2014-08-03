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
''*  Number of cogs/CPU's used: ? out of 8                                          *
''*                                                                                 *   
''*  This code controls the GDB open source hardware:                               *
''*  After to run this program, your GDB will be fully up and running. It will be   *
''*  flashing LEDs and outputting text via the Parallax Series Terminal window.     *
''*  FULL GDB CODE CAN BE FOUND AT https://github.com/solx/GDB                      *
'************************************************************************************
''*  Circuit Diagram can be found at http://www.parallax.com/product/604-00085      *                                                                *
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

'---Program debugging constants---  
SURFACE_SERIAL_BUS = 31   'Only usable when Prop Plug is NOT plugged in  
DEBUG_OUTPUT_PIN = 31     'Only usable when Prop Plug is NOT plugged in
DEBUG_INPUT_PIN = 30      'Only usable when Prop Plug is NOT plugged in
DEBUG_BAUD_RATE = 1000000 'Make sure this matches Parallax Serial Terminal setting
LF = 10 'LINE_FEED - Move cursor down one line, but not to the beginning of line
CR = 13 'CARRIAGE_RETURN - Move cursor down one line and to the beginning of line

VAR  'Global variables

'Array to store samples of output pin of L2F converter
byte L2FSamples[1000]  
long sample_index

long  ExampleVariable
   
OBJ  'Additional files you would like imported / included  

'Sol-X API that controls all the GDB hardware function
GDB      : "GDB-API-V0.1.0"

'Sol-X API that controls all the hardware functions of the PongSat kits  
'PongSat  : "PongSat-API-V0.1.0"   

'Used to control CPU clock timing functions
'Source URL - http://obex.parallax.com/object/173
TIMING   : "Clock"

''''''''''IS THIS NEEDED?????? """""""""
'Used to output debugging statments to the Serial Terminal
'Custom Sol-X file updating http://obex.parallax.com/object/521 
DEBUG           : "GDB-SerialMirror"

''Time parameter in Full H-Bridge is not implemented 

PUB Main 'First method called, like in JAVA 

''     Action: Initializes all the GDB hardware and firmware  
'' Parameters: None                                 
''    Results: Prepares the GDB for user interaction                   
''+Reads/Uses: None                                               
''    +Writes: None
'' Local Vars: None                                  
''      Calls: PongSat.LEDControl( ), TIMING.PauseSec( ),
''             TIMING.PauseMSec( ), and PongSat.SendText( ) functions
''        URL: http://www.solarsystemexpress.com/store.html

''PongSat.Initialize
DEBUG.start(DEBUG_OUTPUT_PIN, DEBUG_INPUT_PIN, 0, DEBUG_BAUD_RATE)

repeat
  TIMING.PauseSec(1) ' Pause one second
  'PongSat.SendText(STRING("Here is a L2F demo"))

  DIRA[5] := INPUT
  DIRA[6] := OUTPUT
  DIRA[7] := OUTPUT
  OUTA[6] := HIGH
  OUTA[7] := LOW                                            

  repeat sample_index from 0 to 1000
    L2FSamples[sample_index] := LOW
    L2FSamples[sample_index] := INA[5]
    TIMING.PauseUSec(10) ' Pause 10us to sample a signal whose highest freq can be 40KHz
     
  repeat sample_index from 0 to 1000
    if (L2FSamples[sample_index] == HIGH)
      'PongSat.SendText(STRING("|"))
    else
      'PongSat.SendText(STRING("."))
 
return