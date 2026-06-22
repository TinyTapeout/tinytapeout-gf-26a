<!---

This file is used to generate your project datasheet. Please fill in the information below and delete any unused
sections.

You can also include images in this folder and reference them in the markdown. Each image must be less than
512 kb in size, and the combined size of all images must be less than 1 MB.
-->

## How it works

This is a multicycle CPU that runs programs written in the [Brainfuck](https://en.wikipedia.org/wiki/Brainfuck)
(BF) language. BF has eight instructions operating on a tape of byte cells and a data pointer:
`>` `<` move the pointer, `+` `-` change the cell, `.` `,` do output/input, and `[` `]` form loops.

The design has no on-chip RAM. **Both the program and the data tape live off-chip in the RP2040's
emulated SPI RAM** (Michael Bell's `spi-ram-emu`, which behaves like a 23LC512: SPI mode 0, `0x03` read /
`0x02` write, 16-bit address). The chip reaches memory through an on-chip **SPI master**, so almost every
instruction performs an SPI transaction (arithmetic ops are a read-modify-write = two transactions).

Memory map (16-bit address): `0x0000–0x7FFF` is instruction memory, `0x8000–0xFFFF` is the data tape,
and `0xFFFF` is intercepted as memory-mapped I/O instead of going to SPI.

Blocks:
- **FSM (`bf`)** — fetch/decode/execute control, plus a small hardware bracket stack for `[` `]`.
- **`spi_ram`** — adapter that turns each memory request into one SPI transaction.
- **`spi_master`** — generates SCLK/CS, shifts the 32-bit command/address/data frame.
- **I/O unit** — routes the `0xFFFF` accesses to the chip pins with a valid/ack handshake.

I/O handshake: `.` latches the byte to `uo_out` and pulses `out_valid`; `,` waits for `in_valid`, reads
`ui_in`, and pulses `in_ack` (the core stalls until input is ready).

## How to test

1. Connect the SPI pins (`uio[0..3]`) to an RP2040 running `spi-ram-emu` (or any 23LC512-compatible SPI RAM),
   which provides the 64 KB memory.
2. Load a BF program into instruction memory starting at address `0x0000`.
3. Hold `rst_n` low to reset, release it, then pulse **`start`** (`uio[4]`) high.
4. The core runs the program. On `.` it drives the output byte on `uo_out[7:0]` and pulses `out_valid`
   (`uio[5]`) — latch `uo_out` on that strobe. On `,` it waits for `in_valid` (`uio[6]`): present a byte on
   `ui_in[7:0]`, raise `in_valid`, and drop it when the chip pulses `in_ack` (`uio[7]`).

The repo's cocotb tests cover this at three levels: the SPI master (`Makefile.spi`), the BF core
(`Makefile.bf`), and the full chip running real BF programs against a mock SPI RAM (`Makefile.top`).

## External hardware

An RP2040 (e.g. the Tiny Tapeout demo board) running `spi-ram-emu` to provide 64 KB of SPI RAM on
`uio[0..3]`, or any 23LC512-compatible SPI SRAM. Optionally, drive `ui_in` / read `uo_out` (with the
`start` and valid/ack pins) for the BF program's input and output.
