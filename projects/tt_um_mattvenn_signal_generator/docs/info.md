## How it works

Two independent square wave generators drive `uo[1:0]`. Each channel's high-time
(`on_count`) and low-time (`off_count`) are programmed independently via SPI, giving
full control over frequency and duty cycle per channel.

At 50 MHz, the formula for a 50% duty cycle square wave at frequency F is:
`on_count = off_count = 25_000_000 // F`

Both counts are 16-bit, so the minimum programmable frequency is approximately 382 Hz
(`on_count = off_count = 65535`).

Setting `on_count=0` silences the channel (output held LOW regardless of `off_count`).
Setting `off_count=0` with `on_count>0` holds the output continuously HIGH.

The SPI peripheral is reused from [calonso88/tt07_alu_74181](https://github.com/calonso88/tt07_alu_74181)
— all credit to Carlos Alonso for the SPI register bank design.

## How to test

The SPI master (e.g. RP2350 running MicroPython) programs each channel using
`machine.SPI`. Each SPI frame is 2 bytes:

- Byte 0: `0x80 | reg_addr` (write), or `reg_addr` (read)
- Byte 1: data

Register map (4 registers per channel, big-endian):

| Reg | Ch | Field                   |
|-----|----|-------------------------|
| 0–1 | 0  | on_count [15:8], [7:0]  |
| 2–3 | 0  | off_count [15:8], [7:0] |
| 4–5 | 1  | on_count [15:8], [7:0]  |
| 6–7 | 1  | off_count [15:8], [7:0] |

SPI mode: CPOL and CPHA set via `ui[0]` and `ui[1]` respectively.

MicroPython example — 1 kHz square wave on channel 0:

```python
from machine import SPI, Pin

spi = SPI(0, baudrate=1_000_000, polarity=0, phase=1)
cs  = Pin(5, Pin.OUT, value=1)

def write_reg(reg, val):
    cs.value(0)
    spi.write(bytes([0x80 | reg, val]))
    cs.value(1)

# 1 kHz: on = off = 25_000_000 // 1_000 = 25_000
on = off = 25_000
for i, v in enumerate([(on>>8)&0xFF, on&0xFF,
                        (off>>8)&0xFF, off&0xFF]):
    write_reg(i, v)
```

For RP2350 on the TT demo board, `scripts/demo.py` provides ready-made helpers
(`set_channel`, `silence`, `silence_all`) using the correct GPIO pin numbers.

## Testing

### Simulation (cocotb)

Four tests exercising the full design in simulation:

```bash
source /home/matt/oss-cad-suite/environment
cd test && make
```

| Test | What it checks |
|------|----------------|
| `test_spi_registers` | Round-trip read/write of all 24 config registers |
| `test_frequency_generation` | Each channel outputs correct frequency (edge count) |
| `test_channel_independence` | All 4 channels run simultaneously without interference |
| `test_channel_silence` | on_count=0, off_count=0 holds output LOW |

### Hardware-in-the-loop (HIL)

`test/test_hil.py` verifies frequency accuracy on real hardware using a Keysight
oscilloscope (pyvisa) and the RP2350 (mpremote). Channels 0 and 1 are tested across
1 kHz – 1 MHz.

**Prerequisites:**
- `scripts/demo.py` copied to the RP2350: `mpremote cp scripts/demo.py :`
- Scope connected via LAN, probes on `uo[0]` (CH1) and `uo[1]` (CH2)
- `pip install pyvisa pyvisa-py pytest`

```bash
pytest test/test_hil.py -v
# override defaults:
SCOPE_RESOURCE=TCPIP0::192.168.50.11::inst0::INSTR \
MPREMOTE_DEV=/dev/serial/by-id/... \
pytest test/test_hil.py -v
```

Each test case boots the TT SDK, enables the design, starts the 50 MHz clock,
programs the target frequency, sets the scope timebase, and asserts the measured
frequency is within 2% of expected.

## External hardware

- RP2350 (or any SPI master) connected to `uio[6:4]` (MOSI, CLK, CS_N) and `uio[3]` (MISO)
- Oscilloscope or frequency counter on `uo[1:0]`
