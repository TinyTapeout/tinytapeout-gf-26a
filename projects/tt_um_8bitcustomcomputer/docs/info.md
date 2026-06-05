## SAP 8 Bit Computer

This project implements a custom 8-bit computer inspired by the SAP (Simple-As-Possible) architecture, designed and realized entirely at the Register Transfer Level (RTL) using Verilog HDL.
The processor is constructed using a collection of independent, well-defined hardware modules that together form a complete and functional CPU.

The design follows a classical computer organization model consisting of a centralized internal data bus, a multi-cycle control unit, and explicit datapath elements such as registers, an arithmetic logic unit (ALU), program counter, memory interface, and input/output registers.
Instruction execution is driven by a micro-sequenced control strategy, ensuring deterministic and cycle-accurate operation.

A modified instruction set architecture (ISA) is implemented, extending beyond traditional SAP-1 and SAP-2 designs to include immediate arithmetic operations, logical instructions, conditional branching, and basic input/output support.
The system is fully synthesizable and suitable for both functional simulation and FPGA-based implementation.

## Features

- Custom 8-Bit CPU Architecture inspired by SAP design principles

- Fully Modular RTL Design with clear separation of control and datapath

- Centralized Internal Data Bus for all register and ALU transactions

- Custom Instruction Set Architecture (ISA) with memory, immediate, control, and I/O instructions

- Multi-Cycle Instruction Execution using T-state based micro-operations

- Arithmetic and Logic Unit (ALU) supporting ADD, SUB, XOR, AND operations

- Flag Register Support with Zero and Carry flag updates

- Conditional and Unconditional Branching (JMP, JC, JZ instructions)

- Input / Output Instruction Support

## Instruction Set Architecture 


| Opcode (bin) | Mnemonic | T-Cycles | Type        | Description |
|-------------|----------|-------------|-------------|------------|
| `0000` | NOP | 3 | Control | Includes Delay in Program Execution |
| `0001` | LDA | 5 | Memory | Load accumulator from memory |
| `0010` | ADD | 6 | Memory | Add memory value to accumulator |
| `0011` | SUB | 6 | Memory | Subtract memory value from accumulator |
| `0100` | STA | 5 | Memory | Store accumulator to memory |
| `0101` | LDI | 4 | Immediate | Load immediate value into accumulator |
| `0110` | JMP | 4 | Control | Unconditional jump |
| `0111` | JC  | 4 (if CF=1 else 3) | Control | Jump if carry flag is set |
| `1000` | JZ  | 4 (if ZF=1 else 3) | Control | Jump if zero flag is set |
| `1001` | ADI | 5 | Immediate | Add immediate value to accumulator |
| `1010` | SUI | 5 | Immediate | Subtract immediate value from accumulator |
| `1011` | XRA | 6 | Memory | Bitwise XOR between accumulator and memory value|
| `1100` | ANA | 6 | Memory | Bitwise AND between accumulator and memory value|
| `1101` | INP | 7 | I/O | Load external input into accumulator |
| `1110` | OUT | 4 | I/O | Output accumulator to output register |
| `1111` | HLT | 4 | Control | Halt CPU execution |

**Note:** Every instruction runs all 6 T-cycles except **INP** (7 T-cycles) . The table mentions the operation T-cycle

## Verification

The complete CPU design was developed and verified at the RTL level using Verilog HDL. Functional verification was performed through simulation and the design was subsequently implemented and tested on an FPGA platform to validate instruction execution, control sequencing, arithmetic and logic operations, branching behavior, memory access, and input/output functionality prior to ASIC submission.

**GitHub Repository:** [8-Bit Computer on FPGA](https://github.com/MOHAMMEDRIYAJ/8-Bit-Computer-on-FPGA/)

## How it works

The processor implements a 16-instruction, 8-bit ISA inspired by SAP-style architectures, with support for memory access, immediate operations, arithmetic/logic operations, control flow, and basic input/output.

### Operating modes

Program mode (ui_in[0] = 1): The 8 uio pins are driven by the design and display the CPU output byte. Use this mode while running a program.

Load mode (ui_in[0] = 0): The uio pins become inputs. Use them to enter bytes into RAM or provide input data requested by the CPU.

### Pin usage

| Pin(s)       | Function                                                          |
| ------------ | ----------------------------------------------------------------- |
| ui_in[7:4]   | RAM address for manual loading.                                   |
| ui_in[3]     | load_ram - write the byte on uio_in into the selected RAM address. |
| ui_in[2]     | inp_loaded – acknowledge that external input data is ready.        |
| ui_in[1]     | start – start or continue CPU execution.                           |
| ui_in[0]     | prog_mode – selects load mode or program mode.                     |
| uio_in[7:0]  | Data byte supplied by the user (RAM data or CPU input).           |
| uio_out[7:0] | Output/display byte from the CPU when in program mode.            |
| uo_out[7]    | CPU input request flag (inp_req).                                 |
| uo_out[6]    | CPU halted flag.                                                  |
| uo_out[5:2]  | Current program counter value.                       |

### Registers and Flags

The CPU contains the following registers:

- **Program Counter (PC)** – Holds the address of the next instruction.
- **Instruction Register (IR)** – Stores the currently executing instruction.
- **Accumulator (A)** – Primary working register used for arithmetic and logic operations.
- **B Register** – Temporary operand register for ALU operations.
- **Carry Flag** – Set when an arithmetic operation generates a carry/borrow.
- **Zero Flag** – Set when an ALU operation produces a result of zero.

### Input Handling

The `INP` instruction uses a simple hardware handshake:

1. The CPU asserts `inp_req`.
2. External logic places a byte on the input bus.
3. The user asserts `inp_loaded`.
4. The CPU loads the value into the accumulator.
5. The value is then written to the RAM address specified by the instruction.

Execution pauses while waiting for input, enabling interactive programs.

### Execution Status Outputs

Several status signals are exposed for debugging and monitoring:

| Signal | Description |
|---------|-------------|
| `uo_out[5:2]` | Current Program Counter (`PC[3:0]`) |
| `uo_out[6]` | CPU HALT status |
| `uo_out[7]` | Input request (`inp_req`) |
| `uio_out[7:0]` | CPU output value (Program Mode) |


## How to Test

### Important Notes

Before programming or running the CPU:

- Apply an **active-low reset** by driving `rst_n = 0`.
- Release reset by setting `rst_n = 1`.
- Always reset the design before loading a new program.
- Use a **10 Hz clock** so execution can be observed easily.
- Ensure the CPU is not running while loading RAM (`prog_mode = 0`).


### 1. Program the RAM

Load Mode is selected with:

```text
prog_mode = 0
```

For each instruction:

1. Select the target RAM address using `ui_in[7:4]`.
2. Place the instruction byte on `uio_in[7:0]`.
3. Pulse `load_ram` (`ui_in[3]`) high for one clock cycle.
4. Repeat until the entire program has been loaded.


### Example Program: Add Two User Inputs

This program:

1. Reads the first input value and stores it in RAM address `E`.
2. Reads the second input value and stores it in RAM address `F`.
3. Loads the first value.
4. Adds the second value.
5. Outputs the result.
6. Halts.

| Address | Instruction | Binary |
|----------|------------|----------|
| 0 | INP E | `1101_1110` |
| 1 | INP F | `1101_1111` |
| 2 | LDA E | `0001_1110` |
| 3 | ADD F | `0010_1111` |
| 4 | OUT | `1110_0000` |
| 5 | HLT | `1111_0000` |

Load the program into RAM addresses `0` through `5`.

### Running the Program

1. Load the program into RAM.
2. Set `prog_mode = 1`.
3. Pulse `start`.

The CPU will immediately request the first input by asserting `inp_req` (`uo_out[7]`).

### Example Test: 5 + 3

#### First Input

When `inp_req` goes high:

- Place `0x05` on `uio_in[7:0]`.
- Pulse `inp_loaded`.

The CPU stores `5` in RAM address `E`.

#### Second Input

When `inp_req` goes high again:

- Place `0x03` on `uio_in[7:0]`.
- Pulse `inp_loaded`.

The CPU stores `3` in RAM address `F`.

### Expected Result

The CPU executes:

```text
A ← RAM[E] = 5
A ← A + RAM[F] = 5 + 3 = 8
OUT A
```

### Expected outputs:

| Signal         | Value               |
| -------------- | ------------------- |
| `uio_out[7:0]` | `00001000` (`0x08`) |
| `uo_out[6]`    | `1` (HALT asserted) |

The output value 8 should remain visible on uio_out[7:0] after the program halts.


## External Hardware

No external hardware is required.

For easier testing:

- DIP switches or push buttons for entering program data and control signals
- LEDs connected to `uo_out` and `uio_out`
- A logic analyzer for debugging and observing execution
- An 8-bit binary-to-7-segment decoder/display for viewing CPU outputs as decimal values

## Contact

* [Navneet Prasad](https://www.linkedin.com/in/navneetprasad1311), III year, ECE, Bannari Amman Institute of Technology
* [Mohammed Riyaj J](https://www.linkedin.com/in/mohammedriyaj786), III year, ECE, Bannari Amman Institute of Technology
* [Akash P](https://www.linkedin.com/in/akash-p-092423309), III year, ECE, Bannari Amman Institute of Technology
* [Vikash R](https://www.linkedin.com/in/vikashr1409), III year, ECE, Bannari Amman Institute of Technology


## Acknowledgements

This project was inspired by the educational work of Albert Malvino and Ben Eater. The overall architecture and learning approach draw from the SAP (Simple-As-Possible) computer concepts presented in *Digital Computer Electronics* by Albert Malvino, as well as the practical computer-building demonstrations and educational content created by Ben Eater. Their work has been an invaluable resource in understanding computer architecture and digital system design.

We would also like to acknowledge the [Centre for SoC & FPGA Design Laboratory](https://www.linkedin.com/in/bit-centre-for-soc-and-fpga-design-52a50b3a3) at [Bannari Amman Institute of Technology](https://www.bitsathy.ac.in/), Erode, Tamil Nadu, India, for providing a supportive environment for learning and experimentation in digital design and VLSI development. Special thanks to [Dr. Elango S](https://www.linkedin.com/in/elango-sekar-8973b958), Associate Professor, ECE, Bannari Amman Institute of Technology for his guidance, encouragement, and support throughout the development of this project.
