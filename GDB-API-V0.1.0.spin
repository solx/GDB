{{
''***********************************************************************************
''*  Title:                                                                         *
''*  GDB API V0.1.0.spin                                                              *
''*  An extreme enviroment open source electromechanical prototyping platform.      *
''*  Author: Blaze Sanders                                                          *
''*  Copyright (c) 2011 Solar System Express (Sol-X) LLC                            *
''*  See end of file for terms of use.                                              *
''***********************************************************************************
''*  Brief Description:                                                             *
''*  Number of cogs/CPU's used: ?5? out of 8                                        *
''*                                                                                 *   
''*  This code controls the GDB open source hardware, creating a high level API for *
''*  the control of the following pieces of hardware:                               *
''*  1) Two STM Microelectronics L298P Full H-Bridges @ 3 Amps max per channel      *
''*  2) One Microchip Technology 32 kB CMOS Serial EEPROM @ 1 MHz                   *
''*  3) One Microchip Technology 12-Bit A/D & 32-Bit D/A Converter @ 100 kbps       *
''*  4) Four Lite-On Inc Bi-Color (Green & Red) Light Emitting Diodes @ 35 & 25 mcd *
''*  5) One ON Semiconductor DeMultiplexer 8x1 / Multiplexer 1x8 @ 80 MHz           *
''*  6) Twenty GPIO pins: SPI, I2C, PWM, VGA, USB and Digital & Analog communication*
''***********************************************************************************
''*  Circuit Diagram can be found at www.solarsystemexpress.com/hardware.html       *                                                                *
''***********************************************************************************
''*  Detailed Description:                                                          *
''*  Software IDE's, datasheets, getting start guides and demo code can be found at *
''*  www.solarsystemexpress.com/software.html                                       * 
''***********************************************************************************
''*  Theory of Operation:                                                           *
''*  See YourProject.spin and GDB Hello World.spin for demos using the GDB API      *
''***********************************************************************************                                                        
}}

CON 'Global Constants

'--Propeller pin configuration for the GDB E-Series Mark I---

'L298P Full H-Bridge U1
INPUT_U1_1 = 31
INPUT_U1_2 = 30
ENABLE_U1_A = 27
INPUT_U1_3 = 24
INPUT_U1_4 = 26 
ENABLE_U1_B = 25
FULL_H_BRIDGE_U1 = 1
 
'L298P Full H-Bridge U2
INPUT_U2_1 = 18
INPUT_U2_2 = 20 
ENABLE_U2_A = 19
INPUT_U2_3 = 17
INPUT_U2_4 = 15 
ENABLE_U2_B = 16
FULL_H_BRIDGE_U2 = 2

'MCP3208 Analog-To-Digital & Analog-To-Digital Convertor U5
ADC_DAC_CLK = 21
ADC_DAC_DATA = 22 
ADC_DAC_CS = 23 'Active Low
ADC_DAC_FIRST_PIN = 21
ADC_DAC_LAST_PIN = 23
DAC_OUTPUT1 = 31
DAC_OUTPUT2 = 30


'NLAST4051 MUX/DeMUX U6
INHIBIT = 14 'Active LOW
ADDRESS_A = 11
ADDRESS_B = 12
ADDRESS_C = 13
COM = 10 


'24LC256-E/MF I2C Electrically Erasable Programmable Read Only Memory U3
I2C_SCL = 28
I2C_SDA = 29


'---Program debugging constants---  
SURFACE_SERIAL_BUS = 31   'Only usable when Prop Plug is NOT plugged in  
DEBUG_OUTPUT_PIN = 31     'Only usable when Prop Plug is NOT plugged in
DEBUG_INPUT_PIN = 30      'Only usable when Prop Plug is NOT plugged in
DEBUG_BAUD_RATE = 1000000 'Make sure this matches Parallax Serial Terminal setting
LF = 10 'LINE_FEED - Move cursor down one line, but not to the beginning of line
CR = 13 'CARRIAGE_RETURN - Move cursor down one line and to the beginning of line


'---Useful constants--- 
HIGH = 1
LOW = 0
OUTPUT = 1
INPUT = 0
AVERAGE = 1
CURRENT = 0
FORWARD = 1
REVERSE = 0
INFINITY = -1
ENABLE = 1
DISABLE = 0

'Standard clock mode * crystal frequency = 16 * 5 MHz = 80 MHz
_clkmode = xtal1 + pll16x                                               
_xinfreq = 5_000_000

VAR 'Global variables

'Array to control direction of P0 - P9 general purpose I/O pins
byte HighSpeedIODirectionRegister[10]
'Array to control level output of the P0 - P9 general purpose I/O pins
byte HighSpeedIOOutputRegister[10]
'Array to readl input level on of P0 - P9 general purpose I/O pins 
byte HighSpeedIOInputRegister[10]   

'Array to control direction of P10 (aka MUX0 - MUX7) general purpose I/O pins   
byte LowSpeedIODirectionRegister[8]
'Array to control level output of the P10 (aka MUX0 - MUX7)general purpose I/O pins 
byte LowSpeedIOOutputRegister[8]
'Array to readl input level on P10 (aka MUX0 - MUX7)general purpose I/O pins 
byte LowSpeedIOInputRegister[8]  

'Global boolean variable that determines wheter debug text is displayed on Parallax Serial Terminal 
byte DEBUG_MODE

'Global decimal variable that determines what boot sequence is used during initialization   
byte BOOT_MODE

'Lock that stops two CPU's from drving the I2C bus at the same time
byte I2CLockNumber

'Global boolean variable to help control the inifite loop in this object
byte HighSpeedIOLoopControl

'Temporary memory, to hold operational data such as call stacks, parameters and intermediate expression results.
'Use an object like "Stack Length" to determine the optimal length and save memory. http://obex.parallax.com/object/574 
long  HighSpeedIOStackPointer[64]

OBJ  'Additional files you would like imported / included 

'Used to output debugging statments to the Serial Terminal
'Custom Sol-X file updating http://obex.parallax.com/object/521 
DEBUG           : "GDB-SerialMirror"

'Used to control GDB LED's and Low Speed general purpose I/O pins
'Custom Sol-X  file based losely off http://obex.parallax.com/object/170
MUX_DEMUX       : "NLAST4051"

'Used to Analog-to-Digital & Digital-to-Analog Conversion
'Source URL - http://obex.parallax.com/object/370  
ADC_DAC         : "MCP3208"

'Used to control the high power (72 Watt) GDB driver
'Source URL - http://obex.parallax.com/object/334
H_BRIDGE1        : "L298SetMotor"
H_BRIDGE2        : "L298SetMotor"

'A reconfiguration Object to allow code reuse between the Sol-X GDB and the Parallax Propeller Mini
PONGSAT   : "PongSat-API-V0.1.0"

'Used to control Electrically Erasable Programmable Read Only Memory
'Source URL - http://obex.parallax.com/object/23 
EEPROM          : "I2C_ROMEngine"

'Used to control CPU clock timing functions
'Source URL - http://obex.parallax.com/object/173
TIMING          : "Clock"

PUB Initialize | OK 'Initializes all the GDB hardware and firmware  

''     Action: Initializes all the GDB hardware and firmware  
'' Parameters: None                                 
''    Results: Prepares the GDB for user interaction                   
''+Reads/Uses: From Global Constants an Global Variables                                                
''    +Writes: To DEBUG_MODE variable
'' Local Vars: OK - Variable to check if initialization has gone good.                                  
''      Calls: InitializeADC_DAC( ), InitializeFullHBridge( ),
''             InitializeMUX_DEMUX( ), AND InitializeEEPROM( ) functions
''        URL: http://www.solarsystemexpress.com/hardware.html

DEBUG_MODE  := DEBUG#DEBUG_STATE

repeat 
  SendText(STRING("Hello Earthling,", DEBUG#CR))
  SendText(STRING("Type 3 and hit enter to boot GDB in standard mode.", DEBUG#CR))
  SendText(STRING("Type 2 and hit enter to boot GDB in DEBUG mode.", DEBUG#CR))
  SendText(STRING("Type 1 and hit enter to reconfigure software for the Propeller Mini.", DEBUG#CR))  
  SendText(STRING("Type 0 and hit enter to reconfigure software for the Propeller Mini in DEBUG mode.", DEBUG#CR))  
  TIMING.PauseSec(5)      'Pause 5 seconds 
until(GetNumber)

TIMING.init(_xinfreq)  'Initializes Clock Software Object

case BOOT_MODE
  0: 'Initializes debug mode and infite loop for Propeller Mini hardware
       DEBUG.start(DEBUG_OUTPUT_PIN, DEBUG_INPUT_PIN, 0, DEBUG_BAUD_RATE) 
       PONGSAT.Initialize
       Stop 'Stop the GDB API CPU
  1: 'Initializes infite loop for Propeller Mini hardware
      PONGSAT.Initialize
      Stop 'Stop the GDB API CPU  
  2:
     'Initializes connection to the Parallax Serial Terminal     
       DEBUG.start(DEBUG_OUTPUT_PIN, DEBUG_INPUT_PIN, 0, DEBUG_BAUD_RATE)
  3: 'DO NOTHING

OK := TRUE 
OK AND= InitializeADC_DAC      'Initializes MCP3208 GDB hardware
OK AND= InitializeFullHBridges 'Initializes L298P hardware 
OK AND= InitializeEEPROM       'Initializes I2C bus hardware and I2C_ROMEngine Software Object
OK AND= InitializeMUX_DEMUX    'Initializes NLAST4051 GDB hardware
OK AND= InitializeHighSpeedIO  'Starts infinte loop in a GDB CPU 

if (NOT OK)
  DEBUG.Str(STRING("GDB initialization failed - Stuck on Earth!", DEBUG#CR))
  ResetGDB
else  
  DEBUG.Str(STRING("GDB initialized - On to Mars!", DEBUG#CR))

if(DEBUG_MODE)
  DEBUG.Str(STRING("GDB Debug function is ON", DEBUG#CR)) 
else    
  DEBUG.Str(STRING("GDB Debug function is OFF", DEBUG#CR))
  'Turning DEBUG mode OFF enables the use on P30 and P31 as general purpose I/O pins

return

PUB Stop 'Stops CPU running the NLSAT4051 DeMultiplexer / Multiplexer - LED's and low speed IO will STOP WORKING

''     Action: Stops CPU running the NLSAT4051 DeMultiplexer / Multiplexer - LED's and low speed IO will STOP WORKING  
'' Parameters: None                           
''    Results: CPU running NLSAT4051 DeMultiplexer / Multiplexer is free for use                   
''+Reads/Uses: None                                               
''    +Writes: None
'' Local Vars: None                                     
''      Calls: EndMUX_DeMUXAddressLoop( ) 
''        URL: http://www.digikey.com/schemeit/#nd7

DEBUG.Str(STRING("WRITE THIS CODE!!!", DEBUG#CR))

{{
'' Stop driver - frees a cog
if CogID > -1
  if cog
    cogstop(cog~ - 1)
}}
return    


PUB ResetGDB 'Reset all the GDB hardware 

''     Action: Reset all the GDB hardware
'' Parameters: None                                 
''    Results: Resets the Propeller chip to its power-up state (Same as hardware reset)                   
''+Reads/Uses: None                                              
''    +Writes: None
'' Local Vars: None                                  
''      Calls: None
''        URL: http://www.parallaxsemiconductor.com/sites/default/files/parallax/Web-PropellerManual-v1.2_0.pdf PAGE 187

if(DEBUG_MODE) 
  DEBUG.Str(STRING("GDB will reset in 2 seconds", DEBUG#CR)) 'DISPLAYED JUST BEFOR RESET
  TIMING.PauseSec(2)      'Pause 2 seconds
  
REBOOT



PUB ChangeDebugOutputState(State) 'Select whether debug text is displayed in the Parallax Serial Terminal   

''     Action: Select whether debug text is displayed in the Parallax Serial Terminal 
'' Parameters: State - Sets debug display state
''                     ENABLE = Debug text is displayed / on
''                     DISABLE = Debug text is NOT displayed  / off                  
''    Results: Changes the DEBUG_MODE variable                   
''+Reads/Uses: None                                               
''    +Writes: To DEBUG_MODE global Variables  
'' Local Vars: None                                  
''      Calls: None
''        URL: http://media.digikey.com/pdf/Data%20Sheets/Parallax%20PDFs/32200,01.pdf

case State
  0: DEBUG_MODE := false  
  1: DEBUG_MODE := true

return

PUB SendText(StringPTR) 'Send debug text string to the Parallax Serial Terminal 

''     Action: Send debug text string to the Parallax Serial Terminal  
'' Parameters: StringPTR - Text to output, called using the following code
''                         SendText(STRING("TEXT TO OUTPUT", DEBUG#CR))                               
''    Results: Sends ANSI text string to the Parallax Serial Terminal                 
''+Reads/Uses: None                                               
''    +Writes: None
'' Local Vars: None                                  
''      Calls: DEBUG.tx( ) and DEBUG.Str( ) functions
''        URL: http://obex.parallax.com/object/521  

repeat strsize(StringPTR)
  DEBUG.tx(byte[StringPTR++])

DEBUG.Str(STRING(" ", DEBUG#CR))

return

PUB SendNumber(Value) 'Send debug number string to the Parallax Serial Terminal 

''     Action: Send debug number string to the Parallax Serial Terminal  
'' Parameters: Value - Number to output                            
''    Results: Sends ANSI number string to the Parallax Serial Terminal                 
''+Reads/Uses: None                                               
''    +Writes: None
'' Local Vars: None                                  
''      Calls: DEBUG.dec( ) function
''        URL: http://obex.parallax.com/object/521  

DEBUG.dec(value)

return

PUB GetNumber 'Get a positive or negative number in Decimal, Binary, or HexDecimal format from the Parallax Serial Terminal

''     Action: Get a positive or negative number in Decimal, Binary, or HexDecimal format from the Parallax Serial Terminal  
'' Parameters: None                           
''    Results: Updates a user variable                
''+Reads/Uses: None                                               
''    +Writes: None
'' Local Vars: None                                  
''      Calls: DEBUG.GetNumber( ) function
''        URL: http://obex.parallax.com/object/521  

return DEBUG.GetNumber   

PRI InitializeEEPROM : OK 'Prepares the GDB 24LC256-E/MF IC for use 

'     Action: Prepares the GDB 24LC256-E/MF IC for use
' Parameters: None                                
'    Results: Start a cog and initializes the GDB pins connected to the 24LC256-E/MF IC                    
'+Reads/Uses: None                                               
'    +Writes: None
' Local Vars: OK - Variable to check if initialization has gone good.                                    
'      Calls: EEPROM.ROMEngineStart( )
'        URL: http://www.digikey.com/schemeit/#nd7

return EEPROM.ROMEngineStart(I2C_SDA, I2C_SCL, 0)

PUB TurnOffEEPROM 'Stops CPU running the EEPROM controller 
                                     
''     Action: Stops CPU running the EEPROM controller 
'' Parameters: None                           
''    Results: CPU running EEPROM controller is free for use                   
''+Reads/Uses: None                                               
''    +Writes: None
'' Local Vars: None                                     
''      Calls: EEPROM.ROMEngineStop( ) 
''        URL: http://www.digikey.com/schemeit/#nd7

EEPROM.ROMEngineStop

return 

PUB LEDControl(LEDnumber, State) 'Turns the 4 bi-color (Green & Red) GDB LED's on or off 

''     Action: Turns the 4 bi-color (Green & Red) GDB LED's on or off 
'' Parameters: LEDnumber -  LED to control (Even #'s are Red Odd #'s are Green)
''             State - Sets LED level (HIGH = LED on or LOW = LED off)                                 
''    Results: Changes the state of GDB LED's                     
''+Reads/Uses: None                                               
''    +Writes: None
'' Local Vars: None                                     
''      Calls: GreenLEDcontrol( ) OR  RedLEDcontrol( ) functions
''        URL: http://www.digikey.com/schemeit/#nd7

case LEDnumber
  0: RedLEDcontrol(0, state)  
  1: GreenLEDcontrol(0, state)
  2: RedLEDcontrol(1, state)  
  3: GreenLEDcontrol(1, state)
  4: RedLEDcontrol(2, state)  
  5: GreenLEDcontrol(2, state)
  6: RedLEDcontrol(3, state)  
  7: GreenLEDcontrol(3, state)

return

PRI GreenLEDcontrol(LEDnumber, State) 'Turns the Red GDB LED's on or off   

'     Action: Turns the Green GDB LED's on or off 
' Parameters: LEDnumber - Sets Green LED to control 
'             State - Sets LED level (HIGH = LED on or LOW = LED off)                                 
'    Results: Changes the state of GDB LED's                     
'+Reads/Uses: None                                               
'    +Writes: LowSpeedIODirectionRegister[] & LowSpeedIOOutputRegister[]
' Local Vars: None                                     
'      Calls: None
'        URL: http://www.digikey.com/schemeit/#nd7

case LEDnumber
  0: LowSpeedIODirectionRegister[0] := OUTPUT    
  1: LowSpeedIODirectionRegister[2] := OUTPUT  
  2: LowSpeedIODirectionRegister[4] := OUTPUT  
  3: LowSpeedIODirectionRegister[6] := OUTPUT 

case LEDnumber
  0: LowSpeedIOOutputRegister[0] := State    
  1: LowSpeedIOOutputRegister[2] := State  
  2: LowSpeedIOOutputRegister[4] := State  
  3: LowSpeedIOOutputRegister[6] := State 

return
  
PRI RedLEDcontrol(LEDnumber, State) 'Turns the Red GDB LED's on or off   

'     Action: Turns the Red GDB LED's on or off 
' Parameters: LEDnumber - Sets Red LED to control 
'             State - Sets LED level (HIGH = LED on or LOW = LED off)                                 
'    Results: Changes the state of GDB LED's                     
'+Reads/Uses: None                                               
'    +Writes: LowSpeedIODirectionRegister[] & LowSpeedIOOutputRegister[]
' Local Vars: None                                     
'      Calls: None
'        URL: http://www.digikey.com/schemeit/#nd7

case LEDnumber
  0: LowSpeedIODirectionRegister[1] := OUTPUT    
  1: LowSpeedIODirectionRegister[3] := OUTPUT  
  2: LowSpeedIODirectionRegister[5] := OUTPUT  
  3: LowSpeedIODirectionRegister[7] := OUTPUT 

case LEDnumber
  0: LowSpeedIOOutputRegister[1] := State    
  1: LowSpeedIOOutputRegister[3] := State  
  2: LowSpeedIOOutputRegister[5] := State  
  3: LowSpeedIOOutputRegister[7] := State 

return

PRI InitializeMUX_DEMUX : OK 'Prepares the GDB NLAST4051 IC for use  

'     Action: Prepares the GDB NLAST4051 IC for use
' Parameters: None                                
'    Results: Start a cog and initializes the GDB pins connected to the NLAST4051 IC                    
'+Reads/Uses: None                                               
'    +Writes: None 
' Local Vars: OK - Variable to check if initialization has gone good. (one add since cog #0 starting would make OK = 0 = FALSE)                                   
'      Calls: MUX_DEMUX.start( )
'        URL: http://www.digikey.com/schemeit/#nd7

return (MUX_DEMUX.Start(INHIBIT, ADDRESS_A,ADDRESS_B, ADDRESS_C, COM, @LowSpeedIODirectionRegister, @LowSpeedIOOutputRegister, @LowSpeedIOInputRegister) + 1)

PUB TurnOffMUX_DEMUX 'Stops CPU running the NLSAT4051 DeMultiplexer / Multiplexer - LED's and low speed IO will STOP WORKING    

''     Action: Stops CPU running the NLSAT4051 DeMultiplexer / Multiplexer - LED's and low speed IO will STOP WORKING  
'' Parameters: None                           
''    Results: CPU running NLSAT4051 DeMultiplexer / Multiplexer is free for use                   
''+Reads/Uses: None                                               
''    +Writes: None
'' Local Vars: None                                     
''      Calls: MUX_DEMUX.Stop ( ) 
''        URL: http://www.digikey.com/schemeit/#nd7

MUX_DEMUX.Stop

PUB ReadLowSpeedGPIOInputState(Pin): InputState 'Read logic level at one pin on the GDB General Purpose Input / Output at IO0 connector   

''     Action: Read logic level at one pin on the GDB General Purpose Input / Output at IO0 connector  
'' Parameters: Pin - Pin number on IO0 connector to read from (0 to 7)                                                                  
''    Results: Reads logic level at P10 on Parallax Propeller chip                    
''+Reads/Uses: From LowSpeedIOInputRegister[] array                                                
''    +Writes: To LowSpeedIODirectionRegister[] array 
'' Local Vars: None                                     
''      Calls: None
''      Calls: None
''        URL: http://www.digikey.com/schemeit/#nd

LowSpeedIODirectionRegister[Pin] := INPUT
TIMING.PauseUSec(500) ' Pause 500 uS to allow DeMultiplexer / Multiplexer levels to settle
InputState := LowSpeedIOInputRegister[Pin] 

return InputState 


PUB SetLowSpeedGPIOOuputState(Pin, State) ' Set state (Input or Output) of one pin on the GDB General Purpose Input / Output at IO0 connector 

''     Action: Set state (Input or Output) of one pin on the GDB General Purpose Input / Output at IO0 connector  
'' Parameters: Pin - Pin number on IO0 connector to change (Uses constants OUTPUT or INPUT)
''             State - Output logic level of selected pin (Uses constants HIGH or LOW)                                                                  
''    Results: Changes the output logic level of P10 on Parallax Propeller chip                    
''+Reads/Uses: None                                               
''    +Writes: To LowSpeedIODirectionRegister[] and LowSpeedIOOutputRegister[] array 
'' Local Vars: None                                     
''      Calls: None
''      Calls: None
''        URL: http://www.digikey.com/schemeit/#nd

LowSpeedIODirectionRegister[Pin] := OUTPUT
LowSpeedIOOutputRegister[Pin] := State

return  

PUB SetLowSpeedGPIOState(DirectionRegister) 'Set state (Input or Output) of all GDB the General Purpose Input / Output pins at IO0 connector  

''     Action: Set state (Input or Output) of all the GDB General Purpose Input / Output pins at IO0 connector  
'' Parameters: DirectionRegister - Array with new state of IO0 connector (Uses constants OUTPUT or INPUT)                                                               
''    Results: Changes the state of the P10 on Parallax Propeller chip                    
''+Reads/Uses: None                                               
''    +Writes: To LowSpeedIODirectionRegister[] array 
'' Local Vars: None                                     
''      Calls: None
''      Calls: None
''        URL: http://www.digikey.com/schemeit/#nd

LowSpeedIODirectionRegister[0] := DirectionRegister[0]
LowSpeedIODirectionRegister[1] := DirectionRegister[1]
LowSpeedIODirectionRegister[2] := DirectionRegister[2]
LowSpeedIODirectionRegister[3] := DirectionRegister[3]
LowSpeedIODirectionRegister[4] := DirectionRegister[4]
LowSpeedIODirectionRegister[5] := DirectionRegister[5]
LowSpeedIODirectionRegister[6] := DirectionRegister[6]
LowSpeedIODirectionRegister[7] := DirectionRegister[7]

return

PUB SetLowSpeedGPIOOutputLevels(OutputRegister)'Set output level (High or Low) of all the GDB General Purpose Input / Output pins at IO0 connector

''     Action: Set output level (High or Low) of all the GDB General Purpose Input / Output pins at IO0 connector    
'' Parameters: OutputRegister - Array with new logic levels of IO0 connector (Uses constants HIGH or LOW)                                                               
''    Results: Changes the output logic level of the P10 on Parallax Propeller chip                    
''+Reads/Uses: None                                               
''    +Writes: To LowSpeedIOOutputRegister[] array 
'' Local Vars: None                                     
''      Calls: None
''      Calls: None
''        URL: http://www.digikey.com/schemeit/#nd

LowSpeedIOOutputRegister[0] := OutputRegister[0]
LowSpeedIOOutputRegister[1] := OutputRegister[1]
LowSpeedIOOutputRegister[2] := OutputRegister[2]
LowSpeedIOOutputRegister[3] := OutputRegister[3]
LowSpeedIOOutputRegister[4] := OutputRegister[4]
LowSpeedIOOutputRegister[5] := OutputRegister[5]
LowSpeedIOOutputRegister[6] := OutputRegister[6]
LowSpeedIOOutputRegister[7] := OutputRegister[7]

return 

PRI InitializeHighSpeedIO : OK | CogNumber 'Starts infinte loop in a GDB CPU

'     Action: Starts infinte loop in a GDB CPU 
' Parameters: None                                
'    Results: Start a cog and initializes the high speed (upto 128 Mhz) GDB pins                     
'+Reads/Uses: None                                               
'    +Writes: None 
' Local Vars: None                                     
'      Calls: cognew( ) function
'        URL: http://www.digikey.com/schemeit/#nd7

return CogNumber := COGNEW(HighSpeedIOLoop(@HighSpeedIODirectionRegister, @HighSpeedIOOutputRegister, @HighSpeedIOInputRegister), @HighSpeedIOStackPointer)

PRI HighSpeedIOLoop(HighSpeedDirectionRegister, HighSpeedOutputRegister, HighSpeedInputRegister) | IOpin 'Start a short / low latency loop that reads IO state and logic levels from memory 

'     Action: Start a short / low latency loop that reads IO state and logic levels from memory  
' Parameters: HighSpeedIODirectionRegister - Pointer to memory holding high speed IO state (INPUT or OUTPUT)
'             HighSpeedIOOutputRegister - Pointer to memory holding high speed IO output logic level (HIGH or LOW)  
'             HighSpeedIOInputRegister - Pointer to memory holding high speed IO input logic level (HIGH or LOW)                         
'    Results: Infinite loop inside one GDB CPU                  
'+Reads/Uses: From HighSpeedIOOutputRegister[] and HighSpeedIODirectionRegister[] array                                                
'    +Writes: To HighSpeedIOInputRegister[] array 
' Local Vars: IOpin - Specific pin on IO0 connector to update                                     
'      Calls: None
'        URL: http://www.digikey.com/schemeit/#nd7

'Global variable to control infinite loop
HighSpeedIOLoopControl := true

repeat
  repeat IOpin from 0 to 9
    'Change Parallax Propeller pin state and logic levels to value in memory    
    DIRA[IOpin] := HighSpeedDirectionRegister[IOpin]
    
    if(IOpin == OUTPUT)
      'Change output logic level on a Parallax Propeller pin to value in memory
      OUTA[IOpin] := HighSpeedOutputRegister[IOpin]
    else
      'Read input logic level on a Parallax Propeller pin and store in memory  
      HighSpeedInputRegister[IOpin] := INA[IOpin]  

until(HighSpeedIOLoopControl)

PUB ReadHighSpeedGPIOInputState(Pin): InputState 'Read logic level at one pin on the GDB General Purpose Input / Output at IO2 connector   

''     Action: Read logic level at one pin on the GDB General Purpose Input / Output at IO2 connector  
'' Parameters: Pin - Pin number on IO2 connector to read from (0 to 7)                                                                  
''    Results: Reads logic level at one pin (P0 to P9) on Parallax Propeller chip                    
''+Reads/Uses: From HighSpeedIOInputRegister[] array                                                
''    +Writes: To HighSpeedIODirectionRegister[] array 
'' Local Vars: None                                     
''      Calls: None
''      Calls: None
''        URL: http://www.digikey.com/schemeit/#nd

HighSpeedIOInputRegister[Pin] := INPUT
TIMING.PauseUSec(5) ' Pause 5 uS to allow logic levels to settle
InputState := HighSpeedIOInputRegister[Pin] 

return InputState 


PUB SetHighSpeedGPIOOuputState(Pin, State) ' Set state (Input or Output) of one pin on the GDB General Purpose Input / Output at IO2 connector 

''     Action: Set state (Input or Output) of one pin on the GDB General Purpose Input / Output at IO2 connector  
'' Parameters: Pin - Pin number on IO2 connector to change (Uses constants OUTPUT or INPUT)
''             State - Output logic level of selected pin (Uses constants HIGH or LOW)                                                                  
''    Results: Changes the output logic level at one pin (P0 to P9) on Parallax Propeller chip                   
''+Reads/Uses: None                                               
''    +Writes: To HighSpeedIODirectionRegister[] and HighSpeedIOOutputRegister[] array 
'' Local Vars: None                                     
''      Calls: None
''      Calls: None
''        URL: http://www.digikey.com/schemeit/#nd

HighSpeedIODirectionRegister[Pin] := OUTPUT
HighSpeedIOOutputRegister[Pin] := State

return  


PUB SetHighSpeedGPIOState(DirectionRegister) 'Set state (Input or Output) of all GDB the General Purpose Input / Output pins at IO2 connector  

''     Action: Set state (Input or Output) of all the GDB General Purpose Input / Output pins at IO2 connector  
'' Parameters: DirectionRegister - Array with new state of IO2 connector (Uses constants OUTPUT or INPUT)                                                               
''    Results: Changes the state of pins P0 to P9 on Parallax Propeller chip                    
''+Reads/Uses: None                                               
''    +Writes: To HighSpeedIODirectionRegister[] array 
'' Local Vars: None                                     
''      Calls: None
''      Calls: None
''        URL: http://www.digikey.com/schemeit/#nd

HighSpeedIODirectionRegister[0] := DirectionRegister[0]
HighSpeedIODirectionRegister[1] := DirectionRegister[1]
HighSpeedIODirectionRegister[2] := DirectionRegister[2]
HighSpeedIODirectionRegister[3] := DirectionRegister[3]
HighSpeedIODirectionRegister[4] := DirectionRegister[4]
HighSpeedIODirectionRegister[5] := DirectionRegister[5]
HighSpeedIODirectionRegister[6] := DirectionRegister[6]
HighSpeedIODirectionRegister[7] := DirectionRegister[7]
HighSpeedIODirectionRegister[8] := DirectionRegister[9]
HighSpeedIODirectionRegister[8] := DirectionRegister[9]

return


PUB SetHighSpeedGPIOOutputLevels(OutputRegister)'Set output level (High or Low) of all the GDB General Purpose Input / Output pins at IO2 connector

''     Action: Set output level (High or Low) of all the GDB General Purpose Input / Output pins at IO2 connector    
'' Parameters: OutputRegister - Array with new logic levels of IO2 connector (Uses constants HIGH or LOW)                                                               
''    Results: Changes the output logic level of pins P0 to P9 on Parallax Propeller chip                   
''+Reads/Uses: None                                               
''    +Writes: To HighSpeedIOOutputRegister[] array 
'' Local Vars: None                                     
''      Calls: None
''      Calls: None
''        URL: http://www.digikey.com/schemeit/#nd

HighSpeedIOOutputRegister[0] := OutputRegister[0]
HighSpeedIOOutputRegister[1] := OutputRegister[1]
HighSpeedIOOutputRegister[2] := OutputRegister[2]
HighSpeedIOOutputRegister[3] := OutputRegister[3]
HighSpeedIOOutputRegister[4] := OutputRegister[4]
HighSpeedIOOutputRegister[5] := OutputRegister[5]
HighSpeedIOOutputRegister[6] := OutputRegister[6]
HighSpeedIOOutputRegister[7] := OutputRegister[7]
HighSpeedIOOutputRegister[8] := OutputRegister[8]
HighSpeedIOOutputRegister[9] := OutputRegister[9]

return


PUB MeasureAnalogVoltage(Channel, SampleType, NumberOfSamples) : DigitalValue 'Measures the analog voltage on any channel on connector ADC_DAC0 

''     Action: Measures the analog voltage on any channel on connector ADC_DAC0
'' Parameters: Channel - Selects the channel (ADC0.0 to ADC0.7) to measure analog voltage on
''             SampleType - CURRENT: Read the current voltage level from an ADC channel (0..7)
''                          AVERAGE: Average n samples from an ADC channel (0..7)                              
''    Results: DigitalValue variable set to value between -1 and 4095 (12-Bits)                    
''+Reads/Uses: None                                               
''    +Writes: None
'' Local Vars: DigitalValue                                     
''      Calls: ADC_DAC.in( ) OR  ADC_DAC.average( ) and DEBUG.Str( ) functions
''      Calls: None
''        URL: http://www.digikey.com/schemeit/#nd7

if(DEBUG_MODE)
  if (NumberOfSamples == 0)
    DEBUG.Str(STRING("ERROR: You tried to average 0 samples, please increase the number of ADC samples.", DEBUG#CR))

DigitalValue  := -1 'Initialize return variable

if(SampleType == CURRENT)
  DigitalValue := ADC_DAC.in(Channel) 
elseif (SampleType == AVERAGE)
  DigitalValue := ADC_DAC.average(Channel, NumberOfSamples)

return DigitalValue    

PUB OutputAnalogVoltage(DigitalValue1, DigitalValue2) 'Outputs an analog voltage on general purpose I/O pins IO1.2 and IO1.3 

''     Action: Outputs an analog voltage on general purpose I/O pins IO1.2 and IO1.3
'' Parameters: DigitalValue1 - Analog voltage output = 3.3 * DigitalValue1 / 4,294,967,295
''             DigitalValue2 - Analog voltage output = 3.3 * DigitalValue2 / 4,294,967,295                          
''    Results: Two digital values become two analog voltages                    
''+Reads/Uses: None                                               
''    +Writes: None
'' Local Vars: None                                     
''      Calls: ADC_DAC.start2( ) AND ADC_DAC.out( )
''        URL: http://www.digikey.com/schemeit/#nd7

if(DEBUG_MODE)
  if (DigitalValue1 < 0 OR DigitalValue2 < 0)
    DEBUG.Str(STRING("ERROR: You tried to convert a negative digital value to an analog voltage", DEBUG#CR))
    return
    
'Start CPU to allow Digital-to-Analog Conversion
ADC_DAC.start2(ADC_DAC_DATA, ADC_DAC_CLK, ADC_DAC_CS, LOW, DAC_OUTPUT1, DAC_OUTPUT2)

'Output analog voltages to general purpose I/O pins IO1.2 (P31) and IO1.3 (P30)     
ADC_DAC.out(DigitalValue1, DigitalValue2)
 
return

PUB TurnOffADC_DAC 'Stops CPU running the Analog-to-Digital & Digital-to-Analog Convertor 
                                     
''     Action: Stops CPU running the Analog-to-Digital & Digital-to-Analog Convertor
'' Parameters: None                           
''    Results: CPU running Analog-to-Digital & Digital-to-Analog Convertor is free for use                   
''+Reads/Uses: None                                               
''    +Writes: None
'' Local Vars: None                                     
''      Calls: ADC_DAC.stop( ) 
''        URL: http://www.digikey.com/schemeit/#nd7

ADC_DAC.stop

return 

PRI InitializeADC_DAC 'Prepares the GDB MCP3208 IC for use 

'     Action: Prepares the GDB MCP3208 IC for use
' Parameters: None                                
'    Results: Initializes the GDB pins connected to the MCP3208 IC                    
'+Reads/Uses: None                                               
'    +Writes: None
' Local Vars: None                                     
'      Calls: ADC_DAC.start( )
'        URL: http://www.digikey.com/schemeit/#nd7

return ADC_DAC.start(ADC_DAC_DATA, ADC_DAC_CLK, ADC_DAC_CS, LOW)

PUB ChangeCPUspeed(ClockFrequency) : SystemClockFrequency 'Allows for the change of GDB the system clock frequency   

''     Action: Allows for the change of GDB the system clock frequency
''             One of the most powerful features of the Propeller chip is the ability to change the clock
''             behavior at run time. Your application can choose to toggle back and forth between a slow clock
''             speed (for low-power consumption) and a fast clock speed (for high-bandwidth operations)
''             XTAL1 2 kΩ 36 pF  External low-speed crystal (4 MHz to 16 MHz) - A standard GDB has a 5 MHz crystal
''             If the crystal hardware is replaced on a GDB XTAL1 must be replaced with XTAL2 or XTAL3 in the code below 
''             XTAL2 1 kΩ  26 pF External medium-speed crystal (8 MHz to 32 MHz) - 
''             XTAL3 500 Ω 16 pF External high-speed crystal (20 MHz to 60 MHz)
'' Parameters: ClockFrequency - Desired new system clock frequency                                
''    Results: Changes the CLKFREQ internal to the Parallax Propeller chip                     
''+Reads/Uses: None                                               
''    +Writes: To CLK register 
'' Local Vars: None                                     
''      Calls: CLKSET( ) 
''        URL: http://www.parallaxsemiconductor.com/sites/default/files/parallax/Web-PropellerManual-v1.2_0.pdf PAGE 71

case ClockFrequency 
  20000:
    if (DEBUG_MODE)
      DEBUG.Str(STRING("Average CPU current draw is approximately 0.00700 mA @ 3.30 V = 0.0231 milliWatts", DEBUG#CR))
   CLKSET(RCSLOW, 20000)

  12000000:
    if (DEBUG_MODE)
      DEBUG.Str(STRING("Average CPU current draw is approximately 0.800 mA @ 3.30 V = 2.64 milliWatts", DEBUG#CR))
   CLKSET(RCFAST, 12000000)

  20000000:
    if (DEBUG_MODE)
      DEBUG.Str(STRING("Average CPU current draw is approximately ?.?? mA @ 3.30 V = ?.?? milliWatts", DEBUG#CR))
   CLKSET(XTAL1 + PLL4X, 20000000)
   
  40000000:
    if (DEBUG_MODE)
      DEBUG.Str(STRING("Average CPU current draw is approximately 2.90 mA @ 3.30 V = 9.57 milliWatts", DEBUG#CR))
   CLKSET(XTAL1 + PLL8X, 40000000)    

  80000000:
    if (DEBUG_MODE)
      DEBUG.Str(STRING("Average CPU current draw is approximately 4.80 milliAmps @ 3.3 V = 15.8 milliWatts", DEBUG#CR))
   CLKSET(XTAL1 + PLL16X, 80000000)

  OTHER:
    DEBUG.Str(STRING("ERROR: Invalid system frequency selected", DEBUG#CR))
    DEBUG.Str(STRING("Possible clock frequencies include 20 kHz, 12 MHz, 20 MHz, 40 MHz, and 80 MHz", DEBUG#CR))

SystemClockFrequency  := CLKFREQ
    
return  SystemClockFrequency

PUB SetMotorDriver(HBridgeNumber, Direction) 'Simplest function to control actuator movement 

''     Action: Simplest function to control actuator movement 
'' Parameters: Direction - Sets direction of actuator movement using contsants FORWARD or REVERSE
''             HBridgeNumber - Reference Designator of Full H-Bridge to control (U1 / 1 or U2 / 2)                                  
''    Results: Changes the direction of current flow in the L298 IC                     
''+Reads/Uses: None                                               
''    +Writes: None
'' Local Vars: None                                     
''      Calls: H_BRIDGE.setMotor( ) 
''        URL: http://www.digikey.com/schemeit/#nd7

if(HBridgeNumber == FULL_H_BRIDGE_U1)
  'Uses predetermined values of 90% duty cycle and 1500 mS ramp up for actuator steps
  H_BRIDGE1.setMotor(90, Direction, 1500) 'COMMENT OUT FOR BETA HARDWARE
  'SetMotorShield(0, 1, 2, Direction) UNCOMMENT FOR BETA HARDWARE
  'SetMotorShield(3, 4, 5, Direction) UNCOMMENT FOR BETA HARDWARE
elseif(HBridgeNumber == FULL_H_BRIDGE_U2)
  H_BRIDGE2.setMotor(90, Direction, 1500)
else
  DEBUG.Str(STRING("ERROR: Invalid Full H-Bridge selected", DEBUG#CR))
  DEBUG.Str(STRING("Possible paramters include 1 or 2", DEBUG#CR))
  

return 

PUB SetHighPowerDriverDutyCycle(HBridgeNumber, DutyCycle, Direction, DelayPerStep) 'More complex function to control actuator movement 

''     Action: More complex function to control actuator movement
'' Parameters: HBridgeNumber - Reference Designator of Full H-Bridge to control (U1 / 1 or U2 / 2) 
''             DutyCycle - Value 0 to 100% that control actuator speed via PWM
''             Direction - Sets direction of actuator movement is contsant FORWARD or REVERSE
''             DelayPerStep - Value in mS that controls delay between actuator steps                                 
''    Results: Changes the direction of current flow in the L298 IC                     
''+Reads/Uses: None                                               
''    +Writes: None
'' Local Vars: None                                     
''      Calls: H_BRIDGE.setMotor( )
''        URL: http://www.digikey.com/schemeit/#nd7

if(HBridgeNumber == FULL_H_BRIDGE_U1)
  H_BRIDGE1.setMotor(DutyCycle, Direction, DelayPerStep)
elseif(HBridgeNumber == FULL_H_BRIDGE_U2)
  H_BRIDGE2.setMotor(DutyCycle, Direction, DelayPerStep)
else
  DEBUG.Str(STRING("ERROR: Invalid Full H-Bridge selected", DEBUG#CR))
  DEBUG.Str(STRING("Possible paramters include 1 or 2", DEBUG#CR))
  
return

PUB SetMotorShield(EnablePin, Input1Pin, Input2Pin, Direction) 'More complex function to control actuator movement    

''     Action: More complex function to control actuator movement
'' Parameters: EnablePin - GDB GPIO pin connected to the "Enable Motor X Connector" on Seeed Studio Motor Driver
''             Input1Pin - GDB GPIO pin connected to the J7.1 (Channel A) or J7.5 (Channel B) on Seeed Studio Motor Driver
''             Input2Pin - GDB GPIO pin connected to the J7.4 (Channel A) or J7.6 (Channel B) on Seeed Studio Motor Driver
''             Direction - Sets direction of actuator movement using contsant FORWARD or REVERSE                               
''    Results: Changes the direction of current flow in the Seeed Studio Motor Driver                     
''+Reads/Uses: None                                               
''    +Writes: None
'' Local Vars: None                                     
''      Calls: SetExternalFullH_Bridge( )
''        URL: www.seeedstudio.com/wiki/Motor_Shield_V1.0 

SetExternalFullH_Bridge(EnablePin, Input1Pin, Input2Pin, Direction)    

return

PRI InitializeFullHBridges | OK 'Prepares the GDB L298P IC's for use

'     Action: Prepares the GDB L298P IC's for use
' Parameters: None                                
'    Results: Initializes the GDB pins connected to the L298P IC's and PWM frequency to 1 KHz                    
'+Reads/Uses: None                                               
'    +Writes: None
' Local Vars: OK - Variable to check if Initialization has gone good.                                     
'      Calls: H_BRIDGE.init( )
'        URL: http://www.digikey.com/schemeit/#nd7

OK := TRUE  
OK AND= H_BRIDGE1.init(ENABLE_U1_A, INPUT_U1_1, INPUT_U1_2, 1000, 1)
OK AND= H_BRIDGE1.init(ENABLE_U1_B, INPUT_U1_3, INPUT_U1_4, 1000, 2) 
OK AND= H_BRIDGE2.init(ENABLE_U2_A, INPUT_U2_1, INPUT_U2_2, 1000, 1)
OK AND= H_BRIDGE2.init(ENABLE_U2_B, INPUT_U2_3, INPUT_U2_4, 1000, 2)

return OK

PRI SetExternalFullH_Bridge(EnablePin, Input1Pin, Input2Pin, Direction) 'More complex function to control actuator movement      

'     Action: More complex function to control actuator movement
' Parameters: Channel 1 is Channel A in the L298 Full H-Bridge IC
'             Channel 2 is Channel B in the L298 Full H-Bridge IC
'             Polarity == 0 means disable Full H-Bridge Channel
'             Polarity == 1 means POSTIVE current flow (Conventional current out of OUT1 & OUT3 pin) 
'             Polarity == 2 means NEGATIVE current flow (Conventional current into OUT1 & OUT3 pin)
'             Time <= 0 means steady state ouput for INFINITY time, unless acted upon
'             Time > 0 represents time actuator output is non-zero (in miliseconds)                                 
'    Results: Changes the direction of current flow in the L298 IC                     
'+Reads/Uses: None                                               
'    +Writes: None
' Local Vars: None                                     
'      Calls: None
'        URL: http://www.digikey.com/schemeit/#nd7

'Initalize GDB pins
OUTA[EnablePin] := LOW   
OUTA[Input1Pin]  := LOW  
OUTA[Input2Pin]  := LOW  
  
if(Direction == FORWARD)
  if(DEBUG_MODE)
    DEBUG.Str(STRING("Move actuator forward", CR)) 
  OUTA[Input1Pin] := HIGH  'Connects OUT1 to Power (+5V to +12V) 
  OUTA[Input2Pin] := LOW   'Connects OUT2 on to Ground through sensing resistor 
  OUTA[EnablePin] := HIGH  'TURN ON Channel X 
elseif(Direction == REVERSE)    
  if(DEBUG_MODE)
    DEBUG.Str(STRING("Move actuator in reverse", CR)) 
  OUTA[Input1Pin] := LOW   'Connects OUT1 to Ground through sensing resistor 
  OUTA[Input2Pin] := HIGH  'Connects OUT2 to Power (+5V to +12V)   
  OUTA[EnablePin] := HIGH  'TURN ON Channel X
else
  DEBUG.Str(STRING("ERROR: INVALID CHANNEL SELECTED", CR))
    
return 

PRI SetInternalU1FullH_Bridge(channel, polarity, time) 'More complex function to control actuator movement   

'     Action: More complex function to control actuator movement
' Parameters: Channel 1 is Channel A in the L298 Full H-Bridge IC
'             Channel 2 is Channel B in the L298 Full H-Bridge IC
'             Polarity == -1 means disable Full H-Bridge Channel
'             Polarity == 1 means POSTIVE current flow (Conventional current out of OUT1 & OUT3 pin) 
'             Polarity == 0 means NEGATIVE current flow (Conventional current into OUT1 & OUT3 pin)
'             Time <= 0 means steady state ouput for INFINITY time, unless acted upon
'             Time > 0 represents time actuator output is non-zero (in miliseconds)                                 
'    Results: Changes the direction of current flow in the L298 IC                     
'+Reads/Uses: None                                               
'    +Writes: None
' Local Vars: None                                     
'      Calls: None
'        URL: http://www.digikey.com/schemeit/#nd7

if(polarity == -1)
  case channel   
    1: OUTA[ENABLE_U1_A] := LOW  'TURN OFF Channel A on U1 
    2: OUTA[ENABLE_U1_B] := LOW  'TURN OFF Channel B on U1

  if(DEBUG_MODE)
    DEBUG.Str(STRING("U1 H-Bridge Disabled ", CR))
     
else
  OUTA[ENABLE_U1_A] := LOW  'TURN OFF Channel A on U1 
  OUTA[ENABLE_U1_B] := LOW  'TURN OFF Channel B on U1

  if(channel == 1 and polarity == FORWARD)
    if(DEBUG_MODE)
      DEBUG.Str(STRING("U1, Channel A Forward", CR)) 
    OUTA[INPUT_U1_1]  := HIGH  'Connects OUT1 on U1 to Power (+5V to +12V)
    OUTA[INPUT_U1_2]  := LOW   'Connects OUT2 on U1 to Ground through sensing resistor
    OUTA[ENABLE_U1_A] := HIGH  'TURN ON Channel A on U1

  elseif(channel == 1 and polarity == REVERSE)  
    if(DEBUG_MODE)
      DEBUG.Str(STRING("U1, Channel A Reverse", CR))
    OUTA[INPUT_U1_1] := LOW   'Connects OUT1 on U1 to Ground through sensing resistor 
    OUTA[INPUT_U1_2] := HIGH  'Connects OUT2 on U1 to Power (+5V to +12V)   
    OUTA[ENABLE_U1_A] := HIGH 'TURN ON Channel A on U1

  elseif(channel == 2 and polarity == FORWARD)  
    if(DEBUG_MODE)
      DEBUG.Str(STRING("U1, Channel B Forward", CR))
    OUTA[INPUT_U1_3]  := HIGH 'Connects OUT3 on U1 to Power (+5V to +12V)   
    OUTA[INPUT_U1_4]  := LOW  'Connects OUT4 on U1 to Ground through sensing resistor 
    OUTA[ENABLE_U1_B] := HIGH 'TURN ON Channel B on U1

  elseif(channel == 2 and polarity == REVERSE)  
    if(DEBUG_MODE)
      DEBUG.Str(STRING("U1, Channel B Reverse", CR))
    OUTA[INPUT_U1_3]  := LOW  'Connects OUT3 on U1 to Ground through sensing resistor 
    OUTA[INPUT_U1_4]  := HIGH 'Connects OUT4 on U1 to Power (+5V to +12V)   
    OUTA[ENABLE_U1_B] := HIGH 'TURN ON Channel B on U1

  else
    if(DEBUG_MODE)
      DEBUG.Str(STRING("ERROR: INVALID channel of U1 L298 Full H-Bridge selected", CR))
    
return 

PRI SetInternalU2FullH_Bridge(channel, polarity, time) 'More complex function to control actuator movement

'     Action: More complex function to control actuator movement
' Parameters: Channel 1 is Channel A in the L298 Full H-Bridge IC
'             Channel 2 is Channel B in the L298 Full H-Bridge IC
'             Polarity == -1 means disable Full H-Bridge Channel
'             Polarity == 1 means POSTIVE current flow (Conventional current out of OUT1 & OUT3 pin) 
'             Polarity == 0 means NEGATIVE current flow (Conventional current into OUT1 & OUT3 pin)
'             Time <= 0 means steady state ouput for INFINITY time, unless acted upon
'             Time > 0 represents time actuator output is non-zero (in miliseconds)                                 
'    Results: Changes the direction of current flow in the L298 IC                     
'+Reads/Uses: None                                               
'    +Writes: None
' Local Vars: None                                     
'      Calls: None
'        URL: http://www.digikey.com/schemeit/#nd7

if(polarity == -1)
  case channel  
    1: OUTA[ENABLE_U2_A] := LOW  'TURN OFF Channel A on U2 
    2: OUTA[ENABLE_U2_B] := LOW  'TURN OFF Channel B on U2

  if(DEBUG_MODE)
    DEBUG.Str(STRING("U2 H-Bridge Disabled ", CR))
     
else
  OUTA[ENABLE_U2_A] := LOW  'TURN OFF Channel A on U2
  OUTA[ENABLE_U2_B] := LOW  'TURN OFF Channel B on U2

  if(channel == 1 and polarity == FORWARD)
    if(DEBUG_MODE)
      DEBUG.Str(STRING("U2, Channel A Forward", CR)) 
    OUTA[INPUT_U2_1]  := HIGH  'Connects OUT1 on U1 to Power (+5V to +12V)
    OUTA[INPUT_U2_2]  := LOW   'Connects OUT2 on U1 to Ground through sensing resistor
    OUTA[ENABLE_U2_A] := HIGH  'TURN ON Channel A on U1

  elseif(channel == 1 and polarity == REVERSE)  
    if(DEBUG_MODE)
      DEBUG.Str(STRING("U2, Channel A Reverse", CR))
    OUTA[INPUT_U2_1] := LOW   'Connects OUT1 on U1 to Ground through sensing resistor 
    OUTA[INPUT_U2_2] := HIGH  'Connects OUT2 on U1 to Power (+5V to +12V)   
    OUTA[ENABLE_U2_A] := HIGH 'TURN ON Channel A on U1

  elseif(channel == 2 and polarity == FORWARD)  
    if(DEBUG_MODE)
      DEBUG.Str(STRING("U2, Channel B Forward", CR))
    OUTA[INPUT_U2_3]  := HIGH 'Connects OUT3 on U1 to Power (+5V to +12V)   
    OUTA[INPUT_U2_4]  := LOW  'Connects OUT4 on U1 to Ground through sensing resistor 
    OUTA[ENABLE_U2_B] := HIGH 'TURN ON Channel B on U1

  elseif(channel == 2 and polarity == REVERSE)  
    if(DEBUG_MODE)
      DEBUG.Str(STRING("U2, Channel B Reverse", CR))
    OUTA[INPUT_U2_3]  := LOW  'Connects OUT3 on U1 to Ground through sensing resistor 
    OUTA[INPUT_U2_4]  := HIGH 'Connects OUT4 on U1 to Power (+5V to +12V)   
    OUTA[ENABLE_U2_B] := HIGH 'TURN ON Channel B on U1

  else
    DEBUG.Str(STRING("ERROR: INVALID channel of U2 L298 Full H-Bridge selected", CR))
    
return

PUB UnitTest | i 'Tests all GDB Hardware with easy to following outputs

''     Action: Tests all GDB Hardware with easy to following outputs 
'' Parameters: None                                 
''    Results: Performs a hardware test of all GDB systems                  
''+Reads/Uses: ??? From Global Constants an Global Variables                                                
''    +Writes: ??? To Output register Port A and Direction Register Port A
'' Local Vars: i - loop index variable                                  
''      Calls: ??? 
''        URL: http://www.solarsystemexpress.com/hardware.html

'Reset all the GDB hardware with scaling LED display
SendText(STRING("Reseting all the GDB hardware with scaling LED display.", DEBUG#CR))
TIMING.PauseSec(1)      'Pause 1 seconds

repeat i from 0 to 7
  LEDControl(i, HIGH)
  TIMING.PauseMSec(500) 'Pause 0.5 seconds
  
repeat i from 7 to 0
  LEDControl(i, LOW)
  TIMING.PauseMSec(500) 'Pause 0.5 seconds

DEBUG.Str(STRING("GDB will reset in 2 seconds", DEBUG#CR)) 'DISPLAYED JUST BEFOR RESET
TIMING.PauseSec(2)      'Pause 2 seconds       
ResetGDB

'-------------------------------------------------------------------------

'Turn debug text on and off
SendText(STRING("Turning debug text on and off.", DEBUG#CR))
TIMING.PauseSec(1)      'Pause 1 seconds
 
ChangeDebugOutputState(ENABLE)
if(DEBUG_MODE)
  DEBUG.Str(STRING("GDB Debug function is ON", DEBUG#CR))

TIMING.PauseSec(1)      'Pause 1 seconds

ChangeDebugOutputState(DISABLE)
if(DEBUG_MODE)
  DEBUG.Str(STRING("THIS SHOULD NOT BE DISPLAYED", DEBUG#CR))

TIMING.PauseSec(1)      'Pause 1 seconds

ChangeDebugOutputState(ENABLE)
if(DEBUG_MODE)
  SendText(STRING("GDB Debug function is back ON", DEBUG#CR))
  SendText(STRING("The Answer to the Ultimate Question of Life, the Universe, and Everything is ", DEBUG#CR)) 
  SendNumber(42)

TIMING.PauseSec(2)      'Pause 2 seconds  

'-------------------------------------------------------------------------

'Grab user input and change LED start
SendText(STRING("Lets grab some user input and change the output status on some LED's.", DEBUG#CR))
TIMING.PauseSec(1)      'Pause 1 seconds

SendText(STRING("Please enter the LED number (0 to 7) you would like to turn ON and hit enter: ", DEBUG#CR)) 
LEDControl(GetNumber, HIGH)
SendText(STRING("Please enter the LED number (0 to 7) you would like to turn OFF and hit enter: ", DEBUG#CR))
LEDControl(GetNumber, LOW)

TIMING.PauseSec(2)      'Pause 2 seconds

'-------------------------------------------------------------------------

'Test EEPROM software
SendText(STRING("Testing the EEPROM software.", DEBUG#CR))
TIMING.PauseSec(1)      'Pause 1 seconds

SendText(STRING("Please enter EEPROM memory address (Decimal format 0 to 8000) you would like read from and hit enter: ", DEBUG#CR))
SendNumber(EEPROM.readByte(GetNumber))
SendText(STRING("We are turning off the EEPROM to save CPU cycles.", DEBUG#CR))
SendText(STRING("Please enter the same EEPROM memory address (Decimal format 0 to 8000) and hit enter: ", DEBUG#CR))  
TurnOffEEPROM
SendNumber(EEPROM.readByte(GetNumber))
SendText(STRING("The two values printed should NOT be the same.", DEBUG#CR))

TIMING.PauseSec(2)      'Pause 2 seconds

'-------------------------------------------------------------------------

'Test DeMultiplexer / Multiplexer software
SendText(STRING("Testing the DeMultiplexer / Multiplexer software.", DEBUG#CR))
TIMING.PauseSec(1)      'Pause 1 seconds

SendText(STRING("LED #6, the third red LED should be on", DEBUG#CR)) 
LEDControl(6, HIGH)

TIMING.PauseSec(1)      'Pause 1 seconds

SendText(STRING("We are turning off the DeMultiplexer / Multiplexer to save CPU cycles.", DEBUG#CR))
SendText(STRING("LED #1, the first gree LED should NOT be on", DEBUG#CR)) 
TurnOffMUX_DEMUX     
LEDControl(1, HIGH)

TIMING.PauseSec(2)      'Pause 2 seconds

SendText(STRING("We are turning ON the DeMultiplexer / Multiplexer to test the low speed IO pins.", DEBUG#CR))
SendText(STRING("Please connect 3.3V to pin IO0.0", DEBUG#CR))
SendText(STRING("Please connect a digital multimeter to pin IO0.7 to measure DC voltage less than 5 Volts.", DEBUG#CR)) 
InitializeMUX_DEMUX    'Initializes NLAST4051 GDB hardware

repeat
  SendText(STRING("TYPE 1 and hit enter when you are ready to continue", DEBUG#CR))
  TIMING.PauseSec(5)      'Pause 5 seconds 
until(GetNumber)

SendText(STRING("Logic level on IO0.0 (should be 1) = ", DEBUG#CR)) 
SendNumber(ReadLowSpeedGPIOInputState(0))

TIMING.PauseSec(3)      'Pause 3 seconds 

SendText(STRING("Voltage measurement on digital multimeter at pin IO0.7 should be 3.3 V", DEBUG#CR)) 
SetLowSpeedGPIOOuputState(7, HIGH)

TIMING.PauseSec(3)      'Pause 3 seconds

'PUB SetLowSpeedGPIOState(DirectionRegister) 'Set state (Input or Output) of all GDB the General Purpose Input / Output pins at IO0 connector  
'PUB SetLowSpeedGPIOOutputLevels(OutputRegister)'Set output level (High or Low) of all the GDB General Purpose Input / Output pins at IO0 connector

'-------------------------------------------------------------------------

'Test High Speed IO
SendText(STRING("Testing the High Speed (upto 128 MHz) IO.", DEBUG#CR))
TIMING.PauseSec(1)      'Pause 1 seconds




'-------------------------------------------------------------------------

'Test MCP3208 Analog-to-Digital & Digital-to-Analog Conversion software
SendText(STRING("Testing the MCP3208 Analog-to-Digital & Digital-to-Analog Conversion software.", DEBUG#CR))
SendText(STRING("Please connect 2.29V to pin ADC0.0", DEBUG#CR))
SendText(STRING("Please connect sin wave with Vpp = 6.6V to pin ADC0.7", DEBUG#CR)) 
TIMING.PauseSec(1)      'Pause 1 seconds

repeat
  SendText(STRING("TYPE 1 and hit enter when you are ready to continue", DEBUG#CR))
  TIMING.PauseSec(5)      'Pause 5 seconds 
until(GetNumber)

SendText(STRING("Voltage measured on ADC0.0  (should be 2.29V) = ", DEBUG#CR))
SendNumber(MeasureAnalogVoltage(0, CURRENT, 1))

TIMING.PauseSec(3)      'Pause 3 seconds  

SendText(STRING("Average voltage measured on ADC0.7 (should be near zero) = ", DEBUG#CR)) 
SendNumber(MeasureAnalogVoltage(7, AVERAGE, 100))

TIMING.PauseSec(3)      'Pause 3 seconds 

SendText(STRING("ERROR MESSAGE SHOULD BE DISPLAYED NEXT ", DEBUG#CR))  
MeasureAnalogVoltage(7, AVERAGE, -1)

TIMING.PauseSec(2)      'Pause 2 seconds

SendText(STRING("Please connect a digital multimeter to pin IO1.0 to measure DC voltage less than 5 Volts.", DEBUG#CR))
SendText(STRING("Please enter a digital value (0 = 0V to 4,294,967,295 = 3.3V) to output on to the and hit enter: ", DEBUG#CR))
SendText(STRING("Voltage measured on IO1.0 (should be (3.3 * digital value entered / 4,294,967,295) = ", DEBUG#CR)) 
SendNumber(OutputAnalogVoltage(GetNumber, 0))

TIMING.PauseSec(2)      'Pause 2 seconds   

SendText(STRING("Please connect a digital multimeter to pin IO1.1 to measure DC voltage less than 5 Volts.", DEBUG#CR))
SendText(STRING("Please enter a second digital value (0 = 0V to 4,294,967,295 = 3.3V) to output on to the and hit enter: ", DEBUG#CR))
SendText(STRING("Voltage measured on IO1.1 (should be (3.3 * digital value entered / 4,294,967,295) = ", DEBUG#CR))
SendNumber(OutputAnalogVoltage(0, GetNumber)) 
 
SendText(STRING("We are turning off the MCP3208 Analog-to-Digital & Digital-to-Analog Conversion to save CPU cycles.", DEBUG#CR))
TurnOffADC_DAC

TIMING.PauseSec(2)      'Pause 2 seconds

SendText(STRING("Please enter a third digital value (0 = 0V to 4,294,967,295 = 3.3V) to output on to the and hit enter: ", DEBUG#CR))
SendText(STRING("Voltage measured on IO1.1 (should be (3.3 * digital value entered / 4,294,967,295) = ", DEBUG#CR))
SendNumber(OutputAnalogVoltage(0, GetNumber))
SendText(STRING("The last two analog values printed should NOT be the same.", DEBUG#CR))   

TIMING.PauseSec(2)      'Pause 2 seconds

'-------------------------------------------------------------------------

'Test changing CPU clock frequency
SendText(STRING("Testing changing CPU clock frequency 5 times.", DEBUG#CR))
TIMING.PauseSec(1)      'Pause 1 seconds

repeat i from 1 to 5
  SendText(STRING("Please enter one of the following frequencies and hit enter (20000, 12000000, 20000000, 40000000, and 80000000): ", DEBUG#CR)) 
  ChangeCPUspeed(GetNumber)

'-------------------------------------------------------------------------

'Test L298 Full H-Bridges 
SendText(STRING("Testing L298 Full H-Bridge software.", DEBUG#CR))
TIMING.PauseSec(1)      'Pause 1 seconds

SendText(STRING("Please connect a simple DC motor to FHB0.0 and FHB0.1", DEBUG#CR)) 
repeat
  SendText(STRING("TYPE 1 and hit enter when you are ready to continue", DEBUG#CR))
  TIMING.PauseSec(5)      'Pause 5 seconds 
until(GetNumber)

SendText(STRING("Rotate motor in forward direction, with simple function call - SetMotorDriver(FORWARD).", DEBUG#CR))
SetMotorDriver(1, FORWARD)

TIMING.PauseSec(5)      'Pause 5 seconds

SendText(STRING("Rotate motor in reverse direction, with simple function call - SetMotorDriver(REVERSE).", DEBUG#CR))
SetMotorDriver(1, REVERSE)

TIMING.PauseSec(5)      'Pause 5 seconds

SendText(STRING("Rotate motor in forward direction for 10.237 seconds, with simple private function call - SetInternalU1FullH_Bridge(1, FORWARD, 10237).", DEBUG#CR))
SetInternalU1FullH_Bridge(1, FORWARD, 10237)

TIMING.PauseSec(5)      'Pause 5 seconds

SendText(STRING("Rotate motor in reverse direction for 4.187 seconds, with simple private function call - SetInternalU1FullH_Bridge(1, REVERSE, 10187).", DEBUG#CR))
SetInternalU1FullH_Bridge(1, REVERSE, 4187)

TIMING.PauseSec(5)      'Pause 5 seconds 

SendText(STRING("Rotate motor in forward direction at 50% max speed, with more a complex function call - SetHighPowerDriverDutyCycle(50, FORWARD, 1000).", DEBUG#CR))
SetHighPowerDriverDutyCycle(1, 50, FORWARD, 1000)

TIMING.PauseSec(5)      'Pause 5 seconds

SendText(STRING("Rotate motor in forward direction at 24% max speed, with more a complex function call - SetHighPowerDriverDutyCycle(50, REVERSE, 1000).", DEBUG#CR))
SetHighPowerDriverDutyCycle(1, 24, REVERSE, 1000)

TIMING.PauseSec(5)      'Pause 5 seconds

SendText(STRING("Connect the following and hit.", DEBUG#CR))
SendText(STRING("Enable pin on Seeed Studio Motor Shield to IO0.0 on the GDB.:", DEBUG#CR))  
SendText(STRING("Input 1 pin on Seeed Studio Motor Shield to IO0.1 on the GDB.:", DEBUG#CR))
SendText(STRING("Input 2 pin on Seeed Studio Motor Shield to IO0.2 on the GDB.:", DEBUG#CR))  

repeat
  SendText(STRING("TYPE 1 and hit enter when you are ready to continue", DEBUG#CR))
  TIMING.PauseSec(5)      'Pause 5 seconds 
until(GetNumber)

SendText(STRING("Rotate motor in forward direction, with Seeed Studio Motor Shield.", DEBUG#CR))
SetMotorShield(0, 1, 2, FORWARD)

TIMING.PauseSec(5)      'Pause 5 seconds

SendText(STRING("Rotate motor in reverse direction, with Seeed Studio Motor Shield.", DEBUG#CR))
SetMotorShield(0, 1, 2, REVERSE)

'PRI SetExternalFullH_Bridge(EnablePin, Input1Pin, Input2Pin, Direction) 'More complex function to control actuator movement

{{

┌───────────────────────────────────────────────────────────────────────────┐
│               Terms of use: MIT License                                   │
├───────────────────────────────────────────────────────────────────────────┤ 
│  Permission is hereby granted, free of charge, to any person obtaining a  │
│ copy of this software and associated documentation files (the "Software"),│
│ to deal in the Software without restriction, including without limitation │
│ the rights to use, copy, modify, merge, publish, distribute, sublicense,  │
│   and/or sell copies of the Software, and to permit persons to whom the   │
│   Software is furnished to do so, subject to the following conditions:    │
│                                                                           │
│  The above copyright notice and this permission notice shall be included  │
│          in all copies or substantial portions of the Software.           │
│                                                                           │
│THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR │
│ IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,  │
│FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE│
│  AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER   │
│ LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING   │
│   FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER     │
│                      DEALINGS IN THE SOFTWARE.                            │
└───────────────────────────────────────────────────────────────────────────┘ 

}}