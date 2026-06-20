<!---
This file is used to generate your project datasheet. Please fill in the information below and delete any unused
sections.

You can also include images in this folder and reference them in the markdown. Each image must be less than
512 kb in size, and the combined size of all images must be less than 1 MB.
-->

## How it works

BIST-8 implements a complete Built-In Self-Test architecture for an 8-bit Carry-Lookahead Adder (CLA).

The design has two modes of operation:

**Normal mode** (bist_en=0): The CLA adder operates as a standard 8-bit adder. Operand A is provided via ui_in[7:2] and uio_in[7:6], operand B via uio_in[5:0]. The result appears on uo_out[7:3].

**BIST mode** (bist_en=1): The circuit self-tests in 4095 clock cycles automatically:

1. A 12-bit LFSR (polynomial x^12+x^11+x^10+x^4+1, seed 0xACE) generates 4095 unique test vector pairs.
2. Each pair is applied to the CLA adder (Circuit Under Test).
3. Each response is compacted into a 16-bit MISR (polynomial x^16+x^15+x^2+1).
4. After 4095 cycles, the MISR signature is compared against the golden reference 0xCF77.
5. If they match, bist_pass=1. Otherwise bist_fail=1.

A fault injection input (fault_inject) forces bit 3 of the adder output to stuck-at-0, allowing demonstration of fault detection. The faulty signature is 0x927F, which differs from the golden value, proving the BIST detects the fault.

The FSM has 4 states: IDLE -> BIST_RUN -> COMPARE -> DONE.

## How to test

**Normal mode:**
1. Set ui_in[0]=0 (bist_en=0)
2. Apply operand A on ui_in[7:2] and uio_in[7:6]
3. Apply operand B on uio_in[5:0]
4. Read result on uo_out[7:3]

**BIST mode (no fault):**
1. Assert reset (rst_n=0 then rst_n=1)
2. Set ui_in[0]=1, ui_in[1]=0
3. Wait 4095 clock cycles for uo_out[2]=1 (bist_done)
4. Expected: uo_out[0]=1 (bist_pass), uo_out[1]=0 (bist_fail)

**BIST mode with fault injection:**
1. Assert reset
2. Set ui_in[0]=1, ui_in[1]=1
3. Wait for uo_out[2]=1 (bist_done)
4. Expected: uo_out[1]=1 (bist_fail) - fault detected
