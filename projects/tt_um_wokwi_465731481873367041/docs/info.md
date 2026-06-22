# MIPS-Lite 8-bit Processor

## How it works

This is an 8-bit MIPS-inspired single-cycle processor designed for Tiny Tapeout. It preserves the core architectural concepts of a full 32-bit MIPS processor, scaled down to fit in a single tile:

### Architecture
- **8 general-purpose registers** (R0 hardwired to 0, R1-R7 writable)
- **8-bit ALU** with ADD, SUB, AND, OR, SLT operations
- **16-bit instruction format** supporting R-type, I-type, and J-type instructions
- **5-bit Program Counter** addressing 32 instruction ROM entries
- **Single-cycle execution** — one instruction per clock cycle

### Instruction Set
| Opcode | Name | Format | Operation |
|--------|------|--------|-----------|
| 0000 | R-type | R | ADD, SUB, AND, OR, SLT (based on funct field) |
| 0001 | ADDI | I | R[rt] ← R[rs] + sign_ext(imm) |
| 0010 | ANDI | I | R[rt] ← R[rs] & zero_ext(imm) |
| 0011 | ORI  | I | R[rt] ← R[rs] \| zero_ext(imm) |
| 0100 | BEQ  | I | if R[rs]==R[rt]: PC ← PC+1+imm |
| 0101 | BNE  | I | if R[rs]!=R[rt]: PC ← PC+1+imm |
| 0110 | J    | J | PC ← addr |
| 0111 | LUI  | I | R[rt] ← imm << 2 |
| 1111 | HALT | - | Stop execution |

### Demo Program
The hardcoded ROM contains a Fibonacci + ALU test program that:
1. Computes Fibonacci numbers (1, 1, 2, 3, 5)
2. Tests AND, OR, SUB, SLT operations
3. Tests BEQ (not taken) and BNE (taken) branches
4. Tests Jump instruction
5. Halts

## How to test

1. Apply reset (rst_n = 0) for at least one clock cycle, then release (rst_n = 1)
2. The CPU will execute the hardcoded program automatically
3. Use `ui_in[2:0]` to select which register (R0-R7) to observe on `uo_out[7:0]`
4. Monitor `uio_out[4:0]` for the current Program Counter value
5. Check `uio_out[5]` for the halt flag (goes high when HALT is reached)

### Expected results after execution:
| Register | Value | Description |
|----------|-------|-------------|
| R0 | 0x00 | Hardwired zero |
| R1 | 0x03 | Fibonacci intermediate |
| R2 | 0x05 | Fibonacci result |
| R3 | 0x05 | Fibonacci result |
| R4 | 0x15 | ADDI result (21) |
| R5 | 0x0F | ORI result (15) |
| R6 | 0xFE | SUB result (-2 signed) |
| R7 | 0x01 | SLT result (3 < 5 = true) |

## External hardware

No external hardware required. Connect LEDs to outputs for visual observation:
- 8 LEDs on `uo_out` to display the selected register value
- 5 LEDs on `uio_out[4:0]` to show PC
- 1 LED on `uio_out[5]` for halt indicator
- 3 switches on `ui_in[2:0]` for register selection
