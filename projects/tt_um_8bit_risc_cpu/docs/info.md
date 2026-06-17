## Overview

This project is an 8-bit RISC CPU written in Verilog for Tiny Tapeout GF. The
CPU is intentionally small and simple: it has no internal program ROM, so an
external controller provides one 16-bit instruction at a time through the Tiny
Tapeout input pins.

The design executes the instruction and returns either the instruction result or
the current program counter on the 8-bit output bus.

Main building blocks:

- 8-bit program counter
- 8 x 8-bit register file
- 8-bit ALU
- immediate generator
- branch-control logic
- 16-byte data memory

The target clock configured for this project is 5 MHz.

## Pin Interface

The instruction bus is 16 bits wide and is split across `ui_in` and `uio_in`.
The bidirectional `uio` pins are used only as inputs.

| Tiny Tapeout signal | Direction | CPU signal |
| --- | --- | --- |
| `ui_in[7:0]` | input | `instruction[15:8]` |
| `uio_in[7:0]` | input | `instruction[7:0]` |
| `uo_out[7:0]` | output | CPU result / PC output |
| `uio_out[7:0]` | output | Always `0` |
| `uio_oe[7:0]` | output | Always `0` |
| `clk` | input | system clock |
| `rst_n` | input | active-low reset |
| `ena` | input | Tiny Tapeout enable, unused internally |

To drive an instruction:

```text
ui_in  = instruction[15:8]
uio_in = instruction[7:0]
```

For example, instruction `0x1843` is driven as:

```text
ui_in  = 0x18
uio_in = 0x43
```

This means `ui_in[0]` carries `instruction[8]`, and `uio_in[0]` carries
`instruction[0]`.

## Execution Timing

The CPU alternates between two internal phases:

1. NOP / PC phase
2. execute phase

For normal use, keep each instruction stable for two clock cycles.

During the execute phase, `uo_out` shows the instruction result. On the next
clock edge, register, memory, and PC updates are committed. During the following
NOP / PC phase, `uo_out` shows the current program counter.

One instruction slot looks like this:

| Moment | External action / observation |
| --- | --- |
| Before clock edge 1 | Drive the 16-bit instruction and keep it stable |
| After clock edge 1 | `uo_out` shows the instruction result |
| Clock edge 2 | The register file, data memory, and PC update |
| After clock edge 2 | `uo_out` shows the updated PC |

Typical external-controller sequence:

1. Drive `rst_n = 0` for reset.
2. Release reset with `rst_n = 1`.
3. Put a 16-bit instruction on `{ui_in, uio_in}`.
4. Hold the instruction stable for two clock cycles.
5. Read the result from `uo_out`.
6. Change to the next instruction and repeat.

## Architecture Details

### Register File

There are eight 8-bit general-purpose registers, `r0` through `r7`.

After reset:

| Register | Value |
| --- | --- |
| `r0` | `0` |
| `r1` | `0` |
| `r2` | `0` |
| `r3` | `0` |
| `r4` | `0` |
| `r5` | `0` |
| `r6` | `0` |
| `r7` | `0` |

### Data Memory

The data memory contains 16 bytes. Address calculations are 8-bit, but only the
lower 4 address bits select the memory entry. In other words, data-memory
addresses wrap modulo 16.

Example:

```text
0x08, 0x18, and 0xF8 all access memory index 8
```

### Program Counter

The program counter is 8 bits wide. Normal instructions increment the PC by 1.
Taken branches update the PC using:

```text
next_pc = pc + imm6
```

PC arithmetic wraps modulo 256.

## Instruction Encoding

This is a compact custom ISA for this Tiny Tapeout design, not a standard
RISC-V-compatible encoding.

The opcode is always stored in `instruction[15:12]`.

### R-Type Format

R-type instructions use two source registers, one destination register, and a
3-bit ALU function field.

| Bits | Field |
| --- | --- |
| `[15:12]` | opcode, always `0000` |
| `[11:9]` | destination register `rd` |
| `[8:6]` | source register `rs1` |
| `[5:3]` | source register `rs2` |
| `[2:0]` | ALU function `funct3` |

Encoding formula:

```text
instruction = (rd << 9) | (rs1 << 6) | (rs2 << 3) | funct3
```

### Immediate Format

Most non-R-type instructions use a source/base register and a 6-bit immediate.

| Bits | Field |
| --- | --- |
| `[15:12]` | opcode |
| `[11:9]` | destination register `rd`, or unused depending on instruction |
| `[8:6]` | source/base register `rs1` |
| `[5:0]` | immediate `imm6` |

Encoding formula:

```text
instruction = (opcode << 12) | (rd << 9) | (rs1 << 6) | (imm6 & 0x3F)
```

The `imm6` value is sign-extended to 8 bits before ALU use. For example,
`imm6 = 0x3F` represents `-1`, which becomes `0xFF` in the 8-bit datapath.

The `LI` instruction is a special case:

```text
instruction = (0x2 << 12) | (rd << 9) | imm8
```

### Store And Branch Format

Store and branch instructions use a split 6-bit immediate so that `rs2` can be
encoded independently.

| Bits | Field |
| --- | --- |
| `[15:12]` | opcode |
| `[11:9]` | immediate `imm6[5:3]` |
| `[8:6]` | source/base register `rs1` |
| `[5:3]` | source register `rs2` |
| `[2:0]` | immediate `imm6[2:0]` |

Encoding formula:

```text
instruction = (opcode << 12)
            | (((imm6 >> 3) & 0x7) << 9)
            | (rs1 << 6)
            | (rs2 << 3)
            | (imm6 & 0x7)
```

For `SW`, `rs2` selects the register whose value is written to data memory. For
branch instructions, `rs1` and `rs2` are compared, while `imm6` is used as the
signed PC offset when the branch is taken.

## Instruction Set

| Opcode | Mnemonic | Operation |
| --- | --- | --- |
| `0000` | R-type | ALU operation selected by `funct3` |
| `0001` | ADDI | `rd = rs1 + imm6` |
| `0010` | LI | `rd = imm8` |
| `0011` | LW | `rd = memory[rs1 + imm6]` |
| `0100` | SW | `memory[rs1 + imm6] = rs2` |
| `0101` | BEQ | branch when `rs1 == rs2` |
| `0110` | BNE | branch when `rs1 != rs2` |
| `0111` | BLT | branch when `rs1 < rs2` |
| `1000` | ANDI | `rd = rs1 & imm6` |
| `1001` | ORI | <code>rd = rs1 &#124; imm6</code> |
| `1010` | XORI | `rd = rs1 ^ imm6` |
| `1011` | SLLI | `rd = rs1 << imm6` |
| `1100` | SRLI | `rd = rs1 >> imm6` |
| `1111` | NOP | no operation |

NOP and unsupported opcodes leave the PC, registers, and data memory unchanged.

## ALU Functions

R-type instructions use `funct3`.

| `funct3` | Operation |
| --- | --- |
| `000` | ADD |
| `001` | SUB |
| `010` | AND |
| `011` | OR |
| `100` | XOR |
| `101` | Shift left |
| `110` | Shift right |
| `111` | Defaults to ADD |

Shift operations use the lower three bits of the second ALU operand as the
shift amount, giving a range from 0 to 7 positions.

The branch instructions use the SUB path internally to compare `rs1` and `rs2`
and generate comparison flags. The less-than comparison is signed, so both
operands are interpreted as 8-bit two's-complement values.

## Worked Examples

### Example 1: Basic Register And ALU Sequence

| Step | Instruction | Encoding | Result on `uo_out` |
| --- | --- | --- | --- |
| 1 | `LI r1, 4` | `0x2204` | `4` |
| 2 | `ADDI r4, r1, 3` | `0x1843` | `7` |
| 3 | `ADDI r5, r4, 2` | `0x1B02` | `9` |
| 4 | `ADD r6, r4, r5` | `0x0D28` | `16` |

Explanation:

```text
r1 = 4
r4 = 4 + 3 = 7
r5 = 7 + 2 = 9
r6 = 7 + 9 = 16
```

### Example 2: Load Immediate And Negative Immediate

| Instruction | Encoding | Result |
| --- | --- | --- |
| `LI r6, 42` | `0x2C2A` | `r6 = 42` |
| `ADDI r7, r6, -1` | `0x1FBF` | `r7 = 41` |

The second instruction uses `imm6 = 0x3F`, which sign-extends to `0xFF`
and acts as `-1` in the 8-bit datapath.

### Example 3: Store And Load

| Step | Instruction | Encoding | Effect |
| --- | --- | --- | --- |
| 1 | `LI r1, 4` | `0x2204` | `r1 = 4` |
| 2 | `ADDI r4, r4, 16` | `0x1910` | `r4 = 16` |
| 3 | `SW r1, [r4 + 8]` | `0x4308` | writes `4` to memory index `8` |
| 4 | `LW r6, [r4 + 8]` | `0x3D08` | `r6 = 4` |

The address is `16 + 8 = 24`. Because data memory uses only the lower 4 address
bits, address `24` accesses memory index `8`.

### Example 4: Taken Branch

| Step | Instruction | Encoding | Behavior |
| --- | --- | --- | --- |
| 1 | `LI r1, 4` | `0x2204` | `r1 = 4` |
| 2 | `BEQ r1, r1, +4` | `0x504C` | branch is taken |

After `LI`, the current PC is `1`, so the taken branch updates it to:

```text
pc + imm6 = 1 + 4 = 5
```

## Running The RTL Simulation

The repository includes a cocotb end-to-end testbench that drives instructions
through the Tiny Tapeout top-level pins and checks reset behavior, ALU
instructions, immediate instructions, memory access, branches, and PC updates.

From the repository root:

```sh
cd test
python3 -m venv .venv
source .venv/bin/activate
pip install -r requirements.txt
make
```

The expected result is:

```text
TESTS=1 PASS=1 FAIL=0
```

## Running Gate-Level Simulation

After local hardening or a successful GDS flow, copy the powered netlist into the
test directory and run the test with `GATES=yes`.

For GF180 local hardening, the netlist is normally:

```text
runs/wokwi/final/pnl/tt_um_8bit_risc_cpu.pnl.v
```

Example:

```sh
export PDK=gf180mcuD
export PDK_ROOT=/path/to/pdk/root

cp runs/wokwi/final/pnl/tt_um_8bit_risc_cpu.pnl.v test/gate_level_netlist.v
cd test
make -B GATES=yes
```

The expected result is again:

```text
TESTS=1 PASS=1 FAIL=0
```

## Running Local Hardening

This project targets Tiny Tapeout GF, so Tiny Tapeout tooling should be run with
the `--gf` flag.

If the `tt/` support-tools directory is not present, clone it first:

```sh
git clone https://github.com/TinyTapeout/tt-support-tools tt
```

Typical local setup:

```sh
python3 -m venv ~/ttsetup/venv
source ~/ttsetup/venv/bin/activate
pip install --upgrade pip
pip install -r tt/requirements.txt

export PDK_ROOT=~/ttsetup/pdk
export PDK=gf180mcuD
export LIBRELANE_TAG=3.0.3
pip install librelane==$LIBRELANE_TAG
```

Create the merged config and run hardening:

```sh
./tt/tt_tool.py --create-user-config --gf
./tt/tt_tool.py --harden --gf
./tt/tt_tool.py --print-warnings --gf
```

If the PDK is installed through Ciel but gate-level simulation cannot find
`gf180mcuD`, enable the installed GF180 PDK:

```sh
ciel enable --pdk-root ~/ttsetup/pdk --pdk-family gf180mcu <version>
```

Then rerun the hardening or gate-level simulation command.

If hardening succeeds, the final GDS, LEF, netlists, and metrics are placed
under:

```text
runs/wokwi/final/
```

## Hardware Usage

On real Tiny Tapeout hardware, an external controller such as a microcontroller,
FPGA, or test setup must provide the clock, reset, and instruction input.

The most important rule is to hold each instruction stable for two clock cycles.
Then read `uo_out` during the execute phase for the result and during the next
NOP / PC phase for the updated program counter.
