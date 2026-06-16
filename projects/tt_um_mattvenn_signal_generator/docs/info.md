## How it works

Two square wave generators drive `uo[1:0]`.

**Channel 0** (`uo[0]`): independent square wave. High-time (`on_count`) and
low-time (`off_count`) are set independently via SPI, giving full control over
frequency and duty cycle.

**Channel 1** (`uo[1]`): phase-shifted replica of ch0. It uses the same
`on_count` and `off_count` as ch0, but its rising edge is offset by a
programmable delay. This is designed for exploring metastability on an SR latch:
by placing ch1's edge close to ch0's edge, the two inputs can be brought
arbitrarily close together.

### Phase control

The total delay applied to ch1's rising edge is:

```
total_delay = spi_offset + enc_int + sigma_delta_carry
```

**`spi_offset`** (registers 4–5): signed 16-bit static offset in clock cycles,
set via SPI. Positive = ch1 lags ch0; negative = ch1 leads ch0. Range: ±32767
cycles.

**Encoder** (ui[4]=A, ui[5]=B): a quadrature encoder adjusts the phase in
real time. Each click changes the phase by `enc_step / 256` cycles (Q8
fixed-point). The integer part of the encoder accumulator is added directly to
the delay; the fractional part is dithered via first-order sigma-delta
modulation, so sub-cycle offsets are averaged accurately over multiple periods.
Encoder range: ±127 cycles (use `spi_offset` for coarse positioning).

**`enc_step`** (register 10): step size per encoder click in 1/256-cycle units.
Examples:
- `enc_step = 1` → ~0.004 cycles/click (~78 ps at 50 MHz), finest resolution
- `enc_step = 64` → 0.25 cycles/click
- `enc_step = 128` → 0.5 cycles/click
- `enc_step = 255` → ~1 cycle/click

**Encoder button** (`ui[2]`, PmodEnc's `SWT` pin, active-high): while held,
multiplies `enc_step` by 8x for fast scanning across the phase range.
Releasing it reverts the very next click to the normal step size.

ch1's delay (`spi_offset + enc_int + sigma_delta_carry`) covers the full
`[0, period)` range with no clamping — it wraps modulo the period, so ch1's
pulse can land anywhere relative to ch0's, including spanning the period
boundary. (For very small periods combined with large `spi_offset`/encoder
values — larger in magnitude than the period — the wrap is computed mod one
period only, so the resulting delay may not match the mathematical mod for
`|total_delay| >= period`; this is a pre-existing edge case unrelated to
normal use.)

### Frequency formula

At 50 MHz, for a 50% duty-cycle square wave at frequency F:

```
on_count = off_count = 25_000_000 // F
```

Both counts are 16-bit → minimum frequency ≈ 382 Hz (`on_count = off_count = 65535`).

Setting `on_count = 0` silences both channels.

The SPI peripheral is reused from
[calonso88/tt07_alu_74181](https://github.com/calonso88/tt07_alu_74181).

## How to test

The SPI master (e.g. RP2350 running MicroPython) programs the design using
`machine.SoftSPI`. Each SPI frame is 2 bytes:

- Byte 0: `0x80 | reg_addr` (write), or `reg_addr` (read)
- Byte 1: data

SPI mode: CPOL and CPHA are set via `ui[0]` and `ui[1]` respectively (both 0
for mode 0).

### Register map

| Reg | Field | Notes |
|-----|-------|-------|
| 0 | ch0 `on_count[15:8]` | MSB |
| 1 | ch0 `on_count[7:0]` | LSB |
| 2 | ch0 `off_count[15:8]` | MSB |
| 3 | ch0 `off_count[7:0]` | LSB |
| 4 | `spi_offset[15:8]` | Signed 16-bit MSB; +ve=lag, −ve=lead |
| 5 | `spi_offset[7:0]` | Signed 16-bit LSB |
| 6 | `enc_step[7:0]` | Q8 step per encoder click (0–255) |
| 7 | — | reserved |

### MicroPython example — 10 kHz, 500-cycle lag, encoder fine-tune

```python
from machine import Pin, SoftSPI

spi = SoftSPI(baudrate=100_000, polarity=0, phase=0, bits=8,
              firstbit=SoftSPI.MSB,
              sck=Pin(30), mosi=Pin(31), miso=Pin(28))
cs = Pin(29, Pin.OUT, value=1)

def write_reg(addr, val):
    cs(0); spi.write(bytes([0x80 | addr, val])); cs(1)

# ch0: 10 kHz, 50% duty (on=2500, off=2500 @ 50 MHz)
write_reg(0, 0x09); write_reg(1, 0xC4)  # on_count  = 2500
write_reg(2, 0x09); write_reg(3, 0xC4)  # off_count = 2500

# ch1: 500-cycle static lag (10 µs)
offset = 500  # cycles
write_reg(4, (offset >> 8) & 0xFF)
write_reg(5,  offset       & 0xFF)

# Encoder: 0.25 cycles/click for fine phase adjustment
write_reg(10, 64)
```

For RP2350 on the TT demo board, `scripts/demo.py` provides ready-made helpers
(`set_ch0`, `set_ch0_counts`, `set_phase_offset`, `set_enc_step`, `silence`).
Use `scripts/run_freq.py` to program from the command line:

```
python scripts/run_freq.py 1000 --offset 500 --enc-step 64
```

### Encoder hardware

Connect a [Digilent PModEnc](https://digilent.com/reference/pmod/pmodenc/start)
to the **bottom row** of the input Pmod connector on the Tiny Tapeout demo
board. This maps the encoder A/B outputs to `ui[4]` and `ui[5]`, and the
encoder's pushbutton (`SWT`) to `ui[2]` (fast-scan, see "Phase control"
above).

## Testing

### Simulation (cocotb)

```bash
source /home/matt/oss-cad-suite/environment
cd test && make
```

| Test | What it checks |
|------|----------------|
| `test_spi_registers` | Round-trip read/write of all config registers |
| `test_frequency_generation` | ch0 outputs correct frequency (edge count) |
| `test_ch1_inphase` | offset=0 → ch1 fires simultaneously with ch0 |
| `test_spi_phase_offset` | Positive SPI offset → ch1 lags ch0 by correct cycle count |
| `test_channel_silence` | on_count=0 holds both outputs LOW |
| `test_encoder_integer_phase` | Encoder clicks accumulate to integer cycle offset |
| `test_encoder_sigma_delta` | Fractional enc_step dithers delay via sigma-delta |
| `test_encoder_button_fast_scan` | Holding the encoder button multiplies enc_step by 8x |
| `test_encoder_fast_scan_clamp_no_wrap` | Holding the button at ENC_MAX/ENC_MIN clamps correctly instead of wrapping (16->17-bit overflow fix) |

### Hardware-in-the-loop (HIL)

`test/test_hil.py` verifies frequency accuracy on real hardware using a
Keysight oscilloscope and the RP2350. Probes on `uo[0]` (CH1) and `uo[1]` (CH2).

## External hardware

- RP2350 (or any SPI master) connected to `uio[6:4]` (MOSI, CLK, CS_N) and `uio[3]` (MISO)
- [Digilent PModEnc](https://digilent.com/reference/pmod/pmodenc/start) on the bottom row of the input Pmod connector (→ `ui[4]`=A, `ui[5]`=B, `ui[2]`=button/SWT for 8x fast-scan)
- Oscilloscope on `uo[1:0]`
- SR latch with S=`uo[0]` and R=`uo[1]` (or vice versa) for metastability experiments
