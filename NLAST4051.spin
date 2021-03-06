{{
''***********************************************************************************
''*  Title:                                                                         *
''*  NLAST4051.spin                                                                 *
''*  A DeMultiplexer 8x1 / Multiplexer 1x8 controller for the NLSAT4051 IC          *
''*  Author: Blaze Sanders                                                          *
''*  Copyright (c) 2014 Solar System Express LLC                                    *
''*  See end of file for terms of use.                                              *
''***********************************************************************************
''*  Brief Description:                                                             *
''*  Number of cogs/CPU's used: 1 out of 8                                          *
''*                                                                                 *   
''*  This code controls the NLSAT4051 IC which is part of the GDB an extreme        *
''*  enviroment open source electromechanical prototyping platform.                 *
''***********************************************************************************
''*  GDB circuit diagram can be found at www.solarsystemexpress.com/hardware.html   * 
''*  Datasheet can be found at www.onsemi.com/pub_link/Collateral/NLAST4051-D.PDF   *                                                          *
 ''**********************************************************************************                                                         
}}
CON 'Global Constants 

'---Useful constants--- 
HIGH = 1
LOW = 0

OUTPUT = 1
INPUT = 0 


VAR 'Global variables  

'Store number of cog running this object (0 to 7) 
long  cog

'Temporary memory, to hold operational data such as call stacks, parameters and intermediate expression results.
'Use an object like "Stack Length" to determine the optimal length and save memory. http://obex.parallax.com/object/574 
long  NLSAT4051StackPointer[128]

'Stores Parallax Propeller pins connected to the NLSAT4051 IC local to this object
byte ADDRESS_C
byte ADDRESS_B
byte ADDRESS_A
byte COM
byte INHIBIT

'Global boolean variable to help control the inifite loop in this object
byte LowSpeedIOLoopControl
  
PUB Start(ActiveLowInhibitPin, AddressApin, AddressBpin, AddressCpin, Data, LowSpeedIODirectionRegister, LowSpeedIOOutputRegister, LowSpeedIOInputRegister) : okay | CogNumber 'Prepares the GDB NLAST4051 IC for use

''     Action: Prepares the GDB NLAST4051 IC for use   
'' Parameters: ActiveLowInhibitPin - Parallax Propeller pin connected to INHIBIT on NLSAT4051
''             AddressApin - Parallax Propeller pin connected to Address A on NLSAT4051
''             AddressBpin - Parallax Propeller pin connected to Address B on NLSAT4051
''             AddressCpin - Parallax Propeller pin connected to Address C on NLSAT4051
''             Data - Parallax Propeller pin connected to COM on NLSAT4051                                                                     
''    Results: Starts a cog to control the NLSAT4051 DeMultiplexer / Multiplexers)                    
''+Reads/Uses: None                                               
''    +Writes: None
'' Local Vars: DigitalValue                                     
''      Calls: cognew( ) OR  ADC_DAC.average( ) functions
''      Calls: None
''        URL: http://www.onsemi.com/pub_link/Collateral/NLAST4051-D.PDF

'Store Parallax Propeller pin configuration inside this NLAST4051.spin object
ADDRESS_C := AddressCpin
ADDRESS_B := AddressBpin
ADDRESS_A := AddressApin
INHIBIT := ActiveLowInhibitPin
COM := Data

DIRA[INHIBIT..COM]~~ 'Make five Propeller pins connect to the MUX / DeMUX outputs  

stop 'Stop any cog running this object
'longmove(@NLSAT4051StackPointer, ptr, 4)    longmove(@ins, ptr, 4) ???
return CogNumber := COGNEW(MUX_DeMUXLoop(LowSpeedIODirectionRegister, LowSpeedIOOutputRegister, LowSpeedIOInputRegister), @NLSAT4051StackPointer)

PUB Stop 'Stops CPU running the NLSAT4051 DeMultiplexer / Multiplexer - LED's and low speed IO will STOP WORKING

''     Action: Stops CPU running the NLSAT4051 DeMultiplexer / Multiplexer - LED's and low speed IO will STOP WORKING  
'' Parameters: None                           
''    Results: CPU running NLSAT4051 DeMultiplexer / Multiplexer is free for use                   
''+Reads/Uses: None                                               
''    +Writes: None
'' Local Vars: None                                     
''      Calls: EndMUX_DeMUXAddressLoop( ) 
''        URL: http://www.digikey.com/schemeit/#nd7

EndMUX_DeMUXAddressLoop

'' Stop driver - frees a cog
if CogID > -1
  if cog
    cogstop(cog~ - 1)

return    
    
PRI MUX_DeMUXLoop(LowSpeedIODirectionRegister, LowSpeedIOOutputRegister, LowSpeedIOInputRegister)  | IOpin 'Start a short / low latency loop that reads IO state from memory

'     Action: Start a short / low latency loop that reads IO state and logic levels from memory 
' Parameters: LowSpeedIODirectionRegister - Pointer to memory holding low speed IO state (INPUT or OUTPUT)
'             LowSpeedIOOutputRegister - Pointer to memory holding low speed IO output logic level (HIGH or LOW)  
'             LowSpeedIOInputRegister - Pointer to memory holding low speed IO input logic level (HIGH or LOW)                            
'    Results: Infinite loop inside one GDB CPU                  
'+Reads/Uses: From LowSpeedIOOutputRegister[] and LowSpeedIODirectionRegister[] array                                                
'    +Writes: To LowSpeedIOInputRegister[] array 
' Local Vars: IOpin - Specific pin on IO0 connector to update                                    
'      Calls: DeActivateMUX_DEMUX( ), ActivateMUX_DEMUX( ), SetAddress( )
'             SetData( ), and ActivateMUX_DEMUX( ) functions.  
'        URL: http://www.digikey.com/schemeit/#nd7

'Global variable to control infinite loop
LowSpeedIOLoopControl := true

repeat
  repeat IOpin from 0 to 7
    DeActivateMUX_DEMUX

    'Change Parallax Propeller pin state and logic levels  
    DIRA[COM] := LowSpeedIODirectionRegister[IOpin]
    SetAddress(IOpin)
    
    if(IOpin == OUTPUT)
      'Change output logic level on P10 Parallax Propeller pins
      SetData(LowSpeedIOOutputRegister[IOpin])
    else
      'Read input logic level on P10 Parallax Propeller pin  
      LowSpeedIOInputRegister[IOpin] := INA[COM]  

    ActivateMUX_DEMUX
     
until(LowSpeedIOLoopControl)
 
PRI EndMUX_DeMUXAddressLoop 'Change LoopControl global variable 

'     Action: Change LoopControl global variable 
' Parameters: None                           
'    Results: Stop infinite loop inside NLSAT4051 object                 
'+Reads/Uses: None                                               
'    +Writes: To LoopControl global variable 
' Local Vars: None                                     
'      Calls: None 
'        URL: http://www.digikey.com/schemeit/#nd7

LowSpeedIOLoopControl := false

return

PRI SetAddress(Address) 'Reconfigure DeMultiplexer / Multiplexer circuitry 

'     Action: Reconfigure DeMultiplexer / Multiplexer circuitry 
' Parameters: Address - Input or output port you would like to control                           
'    Results: Changes output logic level on Parallax Propeller pins                  
'+Reads/Uses: None                                               
'    +Writes: To Output register Port A 
' Local Vars: None                                     
'      Calls: None 
'        URL: http://www.digikey.com/schemeit/#nd7

DeActivateMUX_DEMUX 

case Address
  0: OUTA[ADDRESS_C..ADDRESS_A] := %000 
  1: OUTA[ADDRESS_C..ADDRESS_A] := %001 
  2: OUTA[ADDRESS_C..ADDRESS_A] := %010 
  3: OUTA[ADDRESS_C..ADDRESS_A] := %011
  4: OUTA[ADDRESS_C..ADDRESS_A] := %100
  5: OUTA[ADDRESS_C..ADDRESS_A] := %101
  6: OUTA[ADDRESS_C..ADDRESS_A] := %110
  7: OUTA[ADDRESS_C..ADDRESS_A] := %111
  
ActivateMUX_DEMUX

return

PRI SetData(Data) 'Set logic level coming output of the DeMultiplexer / Multiplexer 

'     Action: Set logic level coming output of the DeMultiplexer / Multiplexer
' Parameters: Data - Logic level you want output                         
'    Results: Changes output logic level on the P10 Parallax Propeller pins                  
'+Reads/Uses: None                                               
'    +Writes: To Output register Port A 
' Local Vars: None                                     
'      Calls: None 
'        URL: http://www.digikey.com/schemeit/#nd7

DeActivateMUX_DEMUX

OUTA[COM] := Data

ActivateMUX_DEMUX

return 

PRI ActivateMUX_DEMUX 'Enable all inputs and outputs from the DeMultiplexer / Multiplexer 

'     Action: Enable all inputs and outputs from the DeMultiplexer / Multiplexer
' Parameters: None                         
'    Results: Changes output logic level on the P10 Parallax Propeller pins                  
'+Reads/Uses: None                                               
'    +Writes: To Output register Port A 
' Local Vars: None                                     
'      Calls: None 
'        URL: http://www.digikey.com/schemeit/#nd7

OUTA[INHIBIT] := LOW

return

PRI DeActivateMUX_DEMUX 'DisEnable all inputs and outputs from the DeMultiplexer / Multiplexer 

'     Action: DisEnable all inputs and outputs from the DeMultiplexer / Multiplexer
' Parameters: None                         
'    Results: Changes output logic level on the P10 Parallax Propeller pins                  
'+Reads/Uses: None                                               
'    +Writes: To Output register Port A 
' Local Vars: None                                     
'      Calls: None 
'        URL: http://www.digikey.com/schemeit/#nd7 

OUTA[INHIBIT] := HIGH  

return


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