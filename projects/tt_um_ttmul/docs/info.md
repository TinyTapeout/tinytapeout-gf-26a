<!---
This file is used to generate your project datasheet. Please fill in the information below and delete any unused sections.
-->

## How it works

`tt_um_ttmul` is a **balanced-ternary integer multiplier**. Internally it does
not multiply in binary at all — it converts the binary operands to *balanced
ternary* (digits −1, 0, +1), multiplies them with a serial ternary
shift-and-add core, then converts the product back to binary. The binary
interface makes it a drop-in multiplier for a conventional host, while the
arithmetic is done the way the historic Soviet **Setun-1958** computer did it.

The datapath reuses building blocks from **Serge Rabyking's Amaranth HDL
implementation of the Setun-1958 computer** (the Setun-HDL project):

```
 binary serial in                                                  binary serial out
 ui_in[0] sdi_a ─► StreamingBinaryToTernary A ─┐
                                                ├─► TernarySerialMultiplier ─► SerialTernaryToBinary ─► uo_out[0] sdo
 ui_in[1] sdi_b ─► StreamingBinaryToTernary B ─┘     (full 2·w-trit product)
```

- **Binary → ternary** uses Horner's method, one bit per clock — the same
  on-the-fly converter that fed the Tang Nano SPI-flash boot loader.
- **Ternary multiply** is a schoolbook shift-and-add over balanced trits
  (single full-adder + sign gate), producing the full `2·width`-trit product.
- **Ternary → binary** uses Horner's method, one trit per clock.

A trit is encoded in 2 bits internally (`p`,`n`): 0=`00`, +1=`01`, −1=`10`.

Operands are **8-bit two's complement** (−128..+127), converted to **6 trits** each:

| Quantity            | Value |
|---------------------|-------|
| Operand load bits   | 8 (two's complement) |
| Product trits       | 12 |
| Result bits         | 16 (signed; 8×8 products span −16256..+16384) |

## How to test

The host steps `clk` and drives the control pins one bit at a time. All
control inputs are active-high and sampled on the rising edge of `clk`.

1. **Reset:** hold `rst_n` low for a few clocks, then release.
2. **Load both operands together:** for 8 clocks, present each bit of A on
   `ui_in[0]` (sdi_a) and the matching bit of B on `ui_in[1]` (sdi_b), MSB
   first, two's complement, with `ui_in[2]` (wr) high.
3. **Start:** pulse `ui_in[3]` (go) high for one clock. `uo_out[1]` (busy)
   stays high while it computes.
4. **Wait** until `uo_out[2]` (ready) goes high.
5. **Read the result:** for 16 clocks, read `uo_out[0]` (sdo) MSB first
   (two's complement), pulsing `ui_in[4]` (rd) high to advance to the next bit.
   `uo_out[3]` (done) pulses high on the final bit.

The cocotb test in `test/test.py` exercises this protocol with fixed and
random operands, including the corners `127 × 127 = 16129` and
`−128 × −128 = 16384`.

## External hardware

None required. Drive the pins directly from the RP2040 on the Tiny Tapeout
demo board (or any microcontroller / logic). No external components needed.

## Pinout

| Pin       | Direction | Function |
|-----------|-----------|----------|
| ui_in[0]  | in  | `sdi_a` — operand A serial data in (MSB first, two's complement) |
| ui_in[1]  | in  | `sdi_b` — operand B serial data in (MSB first, two's complement) |
| ui_in[2]  | in  | `wr`    — shift-in strobe (shifts one bit of A and B per asserted clk) |
| ui_in[3]  | in  | `go`    — start multiply (pulse after both operands loaded) |
| ui_in[4]  | in  | `rd`    — shift-out strobe (advance to next result bit) |
| uo_out[0] | out | `sdo`   — serial data out (result bit, MSB first, two's complement) |
| uo_out[1] | out | `busy`  — convert/multiply/convert in progress |
| uo_out[2] | out | `ready` — result available, drive `rd` to read it out |
| uo_out[3] | out | `done`  — high in the cycle the last result bit is shifted out |

The bidirectional `uio` pins are unused (driven as inputs, `uio_oe = 0`).
