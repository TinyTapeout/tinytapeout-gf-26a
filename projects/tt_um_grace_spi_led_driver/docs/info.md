<!---

This file is used to generate your project datasheet. Please fill in the information below and delete any unused
sections.

You can also include images in this folder and reference them in the markdown. Each image must be less than
512 kb in size, and the combined size of all images must be less than 1 MB.
-->

## How it works

This chip is an SPI-controlled 8-channel LED driver. An SPI master (such as the RP2040/RP2350 on the Tiny Tapeout dev board) communicates with the chip over a 4-wire SPI interface (CS, SCLK, MOSI, MISO). Each SPI transaction is 16 bits: the first byte selects a register address and direction (read or write), and the second byte carries the data.

Internally, the chip contains a 16-register file (9 read/write, 7 read-only). Eight BRIGHT registers (0x0–0x7) set the PWM brightness of 8 LED outputs on `uo_out[0..7]`.

A shared 8-bit counter (`pwm_counter`) cycles 0→255, ticking every `2^PRESCALER` system clock cycles. Each LED output is: `uo_out[n] = ENABLE && (pwm_counter < BRIGHT_n)`, with two special cases: BRIGHT=0xFF → always on, BRIGHT=0x00 → always off. Intermediate values set duty cycle: e.g. 0x80 = 50%, 0x40 = 25%.

With the default PRESCALER=8 and a 50 MHz system clock, PWM refresh rate ≈ 760 Hz (flicker-free).

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
| 0x0 | `BRIGHT_0` | RW | 0x00 | PWM brightness for LED 0. 0x00=off, 0xFF=always on, 0x01–0xFE=duty cycle (value/256) |
| 0x1 | `BRIGHT_1` | RW | 0x00 | PWM brightness for LED 1 |
| 0x2 | `BRIGHT_2` | RW | 0x00 | PWM brightness for LED 2 |
| 0x3 | `BRIGHT_3` | RW | 0x00 | PWM brightness for LED 3 |
| 0x4 | `BRIGHT_4` | RW | 0x00 | PWM brightness for LED 4 |
| 0x5 | `BRIGHT_5` | RW | 0x00 | PWM brightness for LED 5 |
| 0x6 | `BRIGHT_6` | RW | 0x00 | PWM brightness for LED 6 |
| 0x7 | `BRIGHT_7` | RW | 0x00 | PWM brightness for LED 7 |
| 0x8 | `CTRL` | RW | 0x80 | Bits[7:4]: PRESCALER (counter ticks every 2^PRESCALER cycles, default=8). Bits[3:1]: reserved. Bit[0]: ENABLE (1=LEDs active, 0=all off) |
| 0x9 | `ID` | RO | 0xA5 | Fixed magic byte — read to verify SPI is working |
| 0xA | `VERSION` | RO | 0x01 | Design version |
| 0xB | `STATUS` | RO | 0x00 | Bit[0]: mirrors CTRL ENABLE. Bit[1]: 1 after a write, 0 after a read. Bits[7:2]: reserved, read 0 |
| 0xC | `COUNTER` | RO | — | Current value of the free-running PWM counter (0–255). Useful for debug |
| 0xD–0xF | `RESERVED` | RO | 0x00 | Reserved, always returns 0x00 |

Writes to addresses 0x9–0xF are silently dropped.

## External hardware

**Pmod 8LD** (e.g., Digilent 410-076 or compatible clone) — 8 discrete LEDs on a standard 12-pin Pmod connector. Plug into the output Pmod header on the TT dev board. `uo_out[0..7]` maps directly to LD0..LD7. No additional components required; the Pmod draws ~1 mA per LED from the signal pins.

## How to test

Recommended bring-up sequence (each step must pass before the next is meaningful):

1. **SPI alive** — Read ID register (0x9). Expect `0xA5`. If this returns 0x00 or 0xFF, check wiring and CS polarity.
2. **Address decode** — Read VERSION (0xA). Expect `0x01`.
3. **RW loopback** — Write `0xA5` to BRIGHT_0 (0x0), read back. Expect `0xA5`. Repeat with `0x5A`.
4. **RO protection** — Write `0xFF` to ID (0x9), read back. Expect `0xA5` (write was dropped).
5. **ENABLE control** — Write `0x81` to CTRL (0x8) (PRESCALER=8, ENABLE=1). Read STATUS (0xB), expect bit[0]=1.
6. **LED output** — With ENABLE=1, write `0xFF` to BRIGHT_0 (0x0). `uo_out[0]` should go high (always on). Write `0x80` — 50% brightness. Write `0x00` — LED off.
7. **All channels** — Repeat step 6 for BRIGHT_1–BRIGHT_7 to verify all 8 outputs.
8. **COUNTER live** — Read COUNTER (0xC) twice with a short delay between. Values should differ (counter is free-running).

Example MicroPython (RP2040, SoftSPI):

```python
import time
from machine import SoftSPI, Pin
import random

# Set project Clock Speed + Reset Project
tt.clock_project_PWM(10_000_000)
tt.reset_project(True)
import time
time.sleep_ms(10)
tt.reset_project(False)
time.sleep_ms(10)

spi = SoftSPI(baudrate=100_000, polarity=0, phase=0,
              sck=Pin(28), mosi=Pin(26), miso=Pin(27))
cs = Pin(25, Pin.OUT, value=1)

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

# Verify SPI is alive (read ID + Version registers)
assert spi_read(0x9) == 0xA5    # ID = 0xA5
assert spi_read(0xA) == 0x01    # Version = 0x01

# STATUS register checks
spi_write(0x8, 0x81)                    # write to CTRL
assert spi_read(0xB) & 0x02 != 0       # LAST_OP_WAS_WRITE=1
spi_read(0xB)                           # read STATUS
assert spi_read(0xB) & 0x02 == 0       # LAST_OP_WAS_WRITE=0
assert spi_read(0xB) & 0x01 != 0       # ENABLE=1 mirrors CTRL

# COUNTER register — verify it's live
c1 = spi_read(0xC)
time.sleep_ms(50)
c2 = spi_read(0xC)
assert c1 != c2, "counter not incrementing!"
print(f"counter: {c1} → {c2}")


# Enable LEDs (PRESCALER=8, ENABLE=1) and test channel 0
spi_write(0x8, 0x81)   # CTRL: PRESCALER=8, ENABLE=1
spi_write(0x0, 0xFF)   # BRIGHT_0: always on
spi_write(0x0, 0x80)   # BRIGHT_0: 50% brightness
spi_write(0x0, 0x00)   # BRIGHT_0: off

# Light all 8x LEDs one at a time (full brightness)
for i in range(8):
    spi_write(i, 0xFF)
    time.sleep_ms(500)

# Test PWM Control
spi_write(0x8, 0x81)   # CTRL: PRESCALER=8, ENABLE=1
for brightness in [0x20, 0x80, 0xC0, 0xFF, 0x00]:
    for i in range(8):
        spi_write(i, brightness)
    time.sleep_ms(500)

# Party Mode
spi_write(0x8, 0x81)   # CTRL: PRESCALER=8, ENABLE=1
for _ in range(30):
    for i in range(8):
        brightness = random.choice([0x00, 0x20, 0x40, 0x80, 0xC0, 0xFF])
        spi_write(i, brightness)
    time.sleep_ms(150)
```
