<!---

This file is used to generate your project datasheet. Please fill in the information below and delete any unused
sections.

You can also include images in this folder and reference them in the markdown. Each image must be less than
512 kb in size, and the combined size of all images must be less than 1 MB.
-->

## How it works

**Tiny Pixel Processor** is a custom processer designed to procedurally generate graphics.

**Specifications:**
- 640x480 VGA Output
- 64x48 pixels resolution
- 16-bit custom instruction set
- 8 registers (4 general purpose, 4 read-only)

### Instruction set

The processor uses a custom 16-bit instruction format, which is designed to be simple and efficient for graphics generation. The instruction set includes operations for arithmetic, logic, and control flow, as well as special instructions (sin, ramp, saw, rand) for generating procedural patterns.

**EBNF**  
The assembler language for this processor consists of several instruction types, each with their own syntax (look at the later code examples). 

```
Shader = {Instruction "\n"}.
Instruction = Type0 | Type1 | Type2 | Type3 | Type4 | Type5 | Type6 | Type7.

Type0 = "NOP".
Type1 = "SET" RDestination Immediate [Condition].
Type2 = ( "SL" | "SR" ) RSourceDestination Immediate [Condition].
Type3 = "MOV" RDestination RSource [Condition].
Type4 = ( "ADD" | "SUB" | "AND" | "NAND" | "OR" | "NOR" | "XOR" | "SIN" | "RAMP" | "SAW" ) RSourceDestination RSource [Condition].
Type5 = "COMP" RSource RSource [Condition].
Type6 = "OUT" RSource [Condition].
Type7 = ( "FH" | "TT" | "Credits" | "FlagP" ) RDestination [Condition].

Condition = "EQ" | "LT" | "GT"
RSource = "R" ( "0" | "1" | "2" | "3" | ( "4" | "X" ) | ( "5" | "Y" ) | ( "6" | "T" ) | ( "7" | "R" ) ).
RSourceDestination = RDestination.
RDestination = "R" ( "0" | "1" | "2" | "3" ).
Immediate = "#" 0 ... 63.
```

**Instruction Type 0 (for NOP)**  

| OP    | Unused  |
|-------|---------|
| 5 Bit | 11 Bit  |

- 5 Bit OP-Code 
- 11 Bit Unused
- 16 Bit Total

**Instruction Type 1 (for SET)**

| OP    | RD    | Immediate | Condition |
|-------|-------|-----------|-----------|
| 5 Bit | 3 Bit | 6 Bit     | 2 Bit     |

- 5 Bit OP-Code 
- 3 Bit Destination Register Selection
- 6 Bit Immediate
- 2 Bit Condition
- 16 Bit Total

**Instruction Type 2 (for SL, SR)**

| OP    | RSD    | Immediate | Condition |
|-------|--------|-----------|-----------|
| 5 Bit | 3 Bit  | 6 Bit     | 2 Bit     |

- 5 Bit OP-Code 
- 3 Bit Destination/Source Register Selection
- 6 Bit Immediate
- 2 Bit Condition

**Instruction Type 3 (for MOV)**

| OP    | RD    | RS    | Unused | Condition |
|-------|-------|-------|--------|-----------|
| 5 Bit | 3 Bit | 3 Bit | 3 Bit  | 2 Bit     |

- 5 Bit OP-Code 
- 3 Bit Destination Register Selection
- 3 Bit Source Register Selection
- 2 Bit Condition

**Instruction Type 4 (for Register-Register Operations)**

| OP    | RSD   | RS    | Unused | Condition |
|-------|-------|-------|--------|-----------|
| 5 Bit | 3 Bit | 3 Bit | 3 Bit  | 2 Bit     |

- 5 Bit OP-Code 
- 3 Bit Destination/Source Register Selection
- 3 Bit Source Register Selection
- 2 Bit Condition

**Instruction Type 5 (for COMP)**

| OP    | RS1   | RS2   | Unused | Condition |
|-------|-------|-------|--------|-----------|
| 5 Bit | 3 Bit | 3 Bit | 3 Bit  | 2 Bit     |

- 5 Bit OP-Code
- 3 Bit Source Register 1 Selection
- 3 Bit Source Register 2 Selection
- 2 Bit Condition

**Instruction Type 6 (for OUT)**

| OP    | RS    | Unused | Condition |
|-------|-------|--------|-----------|
| 5 Bit | 3 Bit | 6 Bit  | 2 Bit     |

- 5 Bit OP-Code 
- 3 Bit Source Register Selection
- 2 Bit Condition

**Instruction Type 7 (for ROMs)**

| OP    | RD    | Unused | Condition |
|-------|-------|--------|-----------|
| 5 Bit | 3 Bit | 6 Bit  | 2 Bit     |

- 5 Bit OP-Code 
- 3 Bit Destination Register Selection
- 2 Bit Condition


**Instruction descriptions**

| OP  | Usecase     | Description      |
|-----|-------------|------------------|
| NOP | NOP         | Does nothing     |
| SET | SET RD Imm  | RD = Imm         |
| MOV | MOV RD RS   | RD = RS          |
| ADD | ADD RDS RS  | RDS = RDS + RS   |
| SUB | SUB RDS RS  | RDS = RDS - RS   |
| SL  | SL RDS Imm  | RDS = RDS << Imm |
| SR  | SR RDS Imm  | RDS = RDS >> Imm |
| AND | AND RDS RS  | RDS = RDS & RS   |
| NAND| NAND RDS RS | RDS = RDS ~& RS  |
| OR  | OR RDS RS   | RDS = RDS \| RS  |
| NOR | NOR RDS RS  | RDS = RDS ~\| RS |
| XOR | XOR RDS RS  | RDS = RDS ^ RS   |
| SIN | SIN RDS RS  | RDS = sin(RS)    |
| RAMP| RAMP RDS RS | RDS = ramp(RS)   |
| SAW | SAW RDS RS  | RDS = saw(RS)    |
| COMP| COMP RS1 RS2| sets condition register |
| FH      | FH RD      | RD = BITMAP[RX][RY] |
| TT      | TT RD      | RD = BITMAP[RX][RY] |
| Credits | Credits RD | RD = BITMAP[RX][RY] |
| FlagP   | FlagP RD   | RD = BITMAP[RX][RY] |
| OUT | OUT RS      | Output RS to the VGA |

**ROM Instructions**
There are also a few special instructions that are used to load bitmap data from a ROM. 

- **FH** (University of Applied Sciences Upper Austria Logo)
- **TT** (TinyTapeout Logo)
- **Credits** (Project Credits)
- **FlagP** (Flag pole)

These Instructions can be called like every other instruction (including conditionals), but they will load the corresponding bitmap according to the current pixel coordinates (RX, RY) into the destination register.

### Registers

**General Purpose Registers**

Register 0-3 are general purpose registers that can be used for any purpose. They can be read and written by instructions.

**Read Only Registers**

Registers 4 (**RX**) and 5 (**RY**) contain the current pixel coordinates. Register 6 (**RT**) contains the current time (the count of frames divided by a programmable divisor). Register 7 (**RR**) contains a deterministic random value for every pixel (every frame is generated the same, so it is useful for generating a noise pattern).

The registers can only be read by the instruction, writing to them is not recommended, as it may cause unexpected behavior.


## UART

To reconfigure the processor, you can send commands via UART. The following table shows the available commands:

### Writing to the instruction memory

To reprogram the processor, you can send a sequence of 3 bytes via UART.
1. First byte: Command (see table below)
2. Second byte: First half of the instruction (bits 15-8)
3. Third byte: Second half of the instruction (bits 7-0)

| Command hex | Command bin | Description |
|-------------|-------------|-------------|
| 0x80        | 1000 0000   | Addr 0      |
| 0x81        | 1000 0001   | Addr 1      |
| 0x82        | 1000 0010   | Addr 2      |
| 0x83        | 1000 0011   | Addr 3      |
| 0x84        | 1000 0100   | Addr 4      |
| 0x85        | 1000 0101   | Addr 5      |
| 0x86        | 1000 0110   | Addr 6      |
| 0x87        | 1000 0111   | Addr 7      |
| 0x88        | 1000 1000   | Addr 8      |
| 0x89        | 1000 1001   | Addr 9      |
| 0x8A        | 1000 1010   | Addr 10     |
| 0x8B        | 1000 1011   | Addr 11     |
| 0x8C        | 1000 1100   | Addr 12     |
| 0x8D        | 1000 1101   | Addr 13     |
| 0x8E        | 1000 1110   | Addr 14     |
| 0x8F        | 1000 1111   | Addr 15     |
| 0x90        | 1001 0000   | Addr 16     |
| 0x91        | 1001 0001   | Addr 17     |
| 0x92        | 1001 0010   | Addr 18     |
| 0x93        | 1001 0011   | Addr 19     |


### Configuring the Time Register Divisor

The time register contains count of frames divided by a programmable divisor. This divisor can be changed via UART and ranges from 0 to 63. Default is 5.

| Command hex | Command bin | Time Counter |
|-------------|-------------|--------------|
| 0x40        | 0100 0000   | 0            |
| 0x41        | 0100 0001   | 1            |
| 0x42        | 0100 0010   | 2            |
| 0x43        | 0100 0011   | 3            |
| 0x44        | 0100 0100   | 4            |
| 0x45        | 0100 0101   | 5            |
| 0x46        | 0100 0110   | 6            |
| ...         | ...         | ...          |
| 0x7D        | 0111 1101   | 61           |
| 0x7E        | 0111 1110   | 62           |
| 0x7F        | 0111 1111   | 63           |


## How to test

The default configuration includes a simple program that generates a procedural pattern. You can plug a VGA monitor into the tiny-vga board and see the output from the processor. 

If you want to program the ASIC, you can use the `flash_gui.py` script in the `flash` folder. This program allows you to parse your assembly code and upload it via COM port (USB to UART converter is needed) to the processor. 

The following python packages are needed to run the script:
```
pip install customtkinter serial
```

### Code Examples

Code examples can be found [here](../flash/DemoPrograms/).

## External hardware

The [tiny-vga](https://github.com/mole99/tiny-vga) board is used to display the output of the Tiny Pixel Processor on a VGA monitor. 

Additionally, a USB to UART converter is needed to upload the program to the processor. The chip uses 9600 baud rate, 8 data bits, no parity, and 1 stop bit.

## Credits

This project was created by Patrick Pollak, Julian Schlager, Thomas Lindinger, Simon Vogelhuber and Sebastian Gmeiner.
The project was developed as part of a course at the University of Applied Sciences Upper Austria, Campus Hagenberg.
The course and project were supervised by Prof. DI Dr. Markus Pfaff.

This project was inspired by [TinyShader](https://github.com/mole99/tt06-tiny-shader) by [mole99](https://github.com/mole99), originally created for the TT06 Shuttle. While TinyShader served as a conceptual starting point, we made deliberate design decisions throughout development - including our own custom processor architecture and instruction set.

