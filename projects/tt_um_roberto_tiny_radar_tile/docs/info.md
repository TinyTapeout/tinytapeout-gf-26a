<!---
This file is used to generate your project datasheet. Please fill in the
information below and delete any unused sections.
-->

## How it works

**BioPulse Tile** turns a single 8-bit radar/biosignal sample stream into
vital-sign events and metrics, using only digital logic — no CPU, no software.
The datapath processes one sample per clock.

Processing chain:

1. **Input select** — the 8-bit `ui_in` sample, or, in demo mode
   (`uio[0]=1`), an internal generator producing a synthetic breathing
   triangle plus a small heartbeat ripple.
2. **Baseline tracker** — a slow exponential moving average (alpha = 1/256)
   estimates the DC level; a faster EMA (alpha = 1/2) high-passes the signal
   to isolate the heartbeat band.
3. **Breathing detector** — a hysteresis comparator against `baseline ± thr`
   marks one breath per low→high crossing. `uio[1]` selects sensitivity.
4. **Classification FSM** — labels the breathing period normal / fast / slow /
   irregular, or raises apnea after 255 clocks with no breath.
5. **Heartbeat detector** — a second hysteresis path on the high-passed signal
   detects the faster heartbeat component.
6. **Rate estimators** — two sequential long-division units compute
   breaths-per-minute and heart-rate as `BPM = 1000 / period`.
7. **Signal-quality** — peak-to-peak amplitude over each frame gives a quality
   flag.
8. **UART transmitter** — every frame it streams a 5-byte packet (8N1, LSB
   first) out of `uio[5]`: `0xAA, breaths-per-min, heart-rate, peak-to-peak,
   flags`.

### Reading the outputs

`uo_out` is dual-purpose, selected by `uio[2]` (BPM readout select):

- `uio[2]=0` → `uo_out` shows the status flags:

  | Bit | Meaning                    |
  |-----|----------------------------|
  | 0   | breathing detected         |
  | 1   | apnea warning              |
  | 2   | fast breathing             |
  | 3   | slow breathing             |
  | 4   | irregular signal / motion  |
  | 5   | heartbeat detected         |
  | 6   | signal quality good        |
  | 7   | valid / status             |

- `uio[2]=1` → `uo_out` shows the 8-bit breaths-per-minute value.

`uio[5]` is the UART transmit line; `uio[7:6]` show the top two bits of
breaths-per-minute as a coarse indicator.

### Controls (`uio[4:0]`, inputs)

`uio[0]` demo mode, `uio[1]` sensitivity, `uio[2]` BPM readout select,
`uio[4:3]` demo pattern (`00`=normal, `01`=fast, `10`=slow, `11`=apnea).

### A note on timing

Periods and thresholds are in clocks. Run the chip at a low clock for
realistic vital-sign timescales, or feed external samples at your sample rate.

## How to test

Run the cocotb testbench:

```
cd test
make
```

It checks reset, the four demo patterns (normal / fast / slow / apnea), the
heartbeat detector, the breaths-per-minute readout, UART activity, and
external-input mode.

On hardware: set `uio[0]=1`, pick a pattern on `uio[4:3]`, and watch `uo_out`
on LEDs (flags). Set `uio[2]=1` to read breaths-per-minute on the same LEDs,
and capture `uio[5]` with a 3.3 V UART receiver to read all the streamed
metrics.

## External hardware

None required for the demo. For real measurements, connect the digitised
output of a continuous-wave radar or biosignal analog front-end to
`ui_in[7:0]`, LEDs to `uo_out`, and optionally a UART receiver to `uio[5]`.
