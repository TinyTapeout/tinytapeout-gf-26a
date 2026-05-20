<!---

This file is used to generate your project datasheet. Please fill in the information below and delete any unused
sections.

You can also include images in this folder and reference them in the markdown. Each image must be less than
512 kb in size, and the combined size of all images must be less than 1 MB.
-->

## How it works

This chip is an SPI-controlled 8-channel LED driver. An SPI master (such as the RP2040/RP2350 on the Tiny Tapeout dev board) communicates with the chip over a 4-wire SPI interface (CS, SCLK, MOSI, MISO). Each SPI transaction is 16 bits: the first byte selects a register address and direction (read or write), and the second byte carries the data.

Internally, the chip contains a 16-register file (9 read/write, 7 read-only). Eight BRIGHT registers (0x0–0x7) control 8 LED outputs on `uo_out[0..7]`. 

Each LED output is gated by a global ENABLE bit in the CTRL register: `uo_out[n] = ENABLE && BRIGHT_n[7]`. 
Bit 7 of each BRIGHT register controls its LED: 
-- LED ON: Set bit 7 to 1 (e.g. write `0x80`)
-- LED OFF: set bit 7 to 0 (e.g. write `0x00`) 

SPI input signals (CS, SCLK, MOSI) are passed through 2-flop synchronizers before entering the SPI FSM, safely crossing from the asynchronous SPI clock domain into the chip's 50 MHz system clock domain.

## Limitations

- SPI mode: CPOL=0, CPHA=0 only (sample on rising SCLK edge)
- SCLK must be ≤ system clock / 20 (≤ 2.5 MHz at a 50 MHz system clock)
- Single register access per CS assertion — no burst transfers
- Data is MSB first

## Connection

| Pin | Direction | Signal | Description |
|-----|-----------|--------|-------------|
| `uio[0]` | Input | `spi_cs_n` | SPI chip select (active low) |
| `uio[1]` | Input | `spi_mosi` | SPI master-out slave-in |
| `uio[2]` | Output | `spi_miso` | SPI master-in slave-out |
| `uio[3]` | Input | `spi_clk` | SPI clock |
| `uo[0..7]` | Output | `LED0..LED7` | LED drive outputs |

`ui_in` and `uio[4..7]` are unused.

## Protocol

### SPI settings

| Parameter | Value |
|-----------|-------|
| Mode | CPOL=0, CPHA=0 |
| Bit order | MSB first |
| Transaction length | 16 bits |
| CS polarity | Active low |
| Max SCLK | 2.5 MHz (at 50 MHz system clock) |

CS must remain low for the entire 16-bit transaction.

### Transaction format

```
Bit:   [15]    [14:12]      [11:8]    [7:0]
MOSI:  R/W     reserved     addr      data (write) | don't-care (read)
MISO:  0       0            0         0 (write)    | data (read)
```

- `R/W`: 1 = write, 0 = read
- `reserved`: ignored on decode
- `addr`: 4-bit register address (0x0–0xF)
- `data`: value to write, or register contents returned on read

### Register map

| Address | Name | Access | Reset | Description |
|---------|------|--------|-------|-------------|
| 0x0 | `BRIGHT_0` | RW | 0x00 | LED 0 control. Bit[7]=1: on, Bit[7]=0: off |
| 0x1 | `BRIGHT_1` | RW | 0x00 | LED 1 control |
| 0x2 | `BRIGHT_2` | RW | 0x00 | LED 2 control |
| 0x3 | `BRIGHT_3` | RW | 0x00 | LED 3 control |
| 0x4 | `BRIGHT_4` | RW | 0x00 | LED 4 control |
| 0x5 | `BRIGHT_5` | RW | 0x00 | LED 5 control |
| 0x6 | `BRIGHT_6` | RW | 0x00 | LED 6 control |
| 0x7 | `BRIGHT_7` | RW | 0x00 | LED 7 control |
| 0x8 | `CTRL` | RW | 0x00 | Bit[0]: ENABLE — gates all LED outputs globally |
| 0x9 | `ID` | RO | 0xA5 | Fixed magic byte — read to verify SPI is working |
| 0xA | `VERSION` | RO | 0x01 | Design version |
| 0xB | `STATUS` | RO | — | Bit[0]: mirrors CTRL ENABLE. Bit[1]: 1 = "Last Op was Write" |
| 0xC–0xF | `RESERVED` | RO | 0x00 | Reserved, always returns 0x00 |

Writes to addresses 0x9–0xF are silently dropped.

## External hardware

**Pmod 8LD** (e.g., Digilent 410-076 or compatible clone) — 8 discrete LEDs on a standard 12-pin Pmod connector. Plug into the output Pmod header on the TT dev board. `uo_out[0..7]` maps directly to LD0..LD7. No additional components required; the Pmod draws ~1 mA per LED from the signal pins.

## How to test

Recommended bring-up sequence (each step must pass before the next is meaningful):

1. **SPI alive** — Read ID register (0x9). Expect `0xA5`. If this returns 0x00 or 0xFF, check wiring and CS polarity.
2. **Address decode** — Read VERSION (0xA). Expect `0x01`.
3. **RW loopback** — Write `0xA5` to BRIGHT_0 (0x0), read back. Expect `0xA5`. Repeat with `0x5A`.
4. **RO protection** — Write `0xFF` to ID (0x9), read back. Expect `0xA5` (write was dropped).
5. **ENABLE control** — Write `0x01` to CTRL (0x8). Read STATUS (0xB), expect bit[0]=1.
6. **LED output** — With ENABLE=1, write `0x80` to BRIGHT_0 (0x0). `uo_out[0]` should go high (LED lights). Write `0x00` — LED off.
7. **All channels** — Repeat step 6 for BRIGHT_1–BRIGHT_7 to verify all 8 outputs.

Example MicroPython (RP2040, SoftSPI):

```python
from machine import SoftSPI, Pin

spi = SoftSPI(baudrate=100_000, polarity=0, phase=0,
              sck=Pin(18), mosi=Pin(19), miso=Pin(16))
cs = Pin(17, Pin.OUT, value=1)

def spi_write(addr, data):
    cs(0)
    spi.write(bytes([(1 << 7) | addr, data]))
    cs(1)

def spi_read(addr):
    cs(0)
    buf = bytearray(2)
    spi.write_readinto(bytes([addr, 0x00]), buf)
    cs(1)
    return buf[1]

# Enable LEDs and light up channel 0
spi_write(0x8, 0x01)   # CTRL: ENABLE=1
spi_write(0x0, 0x80)   # BRIGHT_0: LED on
```
