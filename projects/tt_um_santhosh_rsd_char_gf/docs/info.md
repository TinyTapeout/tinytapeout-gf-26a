# How it works

A **standalone characterization platform** for a single external
resistive-switching device — RRAM / memristor / phase-change cell —
implemented entirely in gf180mcuD digital. The host programs one set of
parameters, asserts `start`, and the on-chip FSM runs the chosen
experiment to completion, writing results into readable registers so the
host never has to micro-manage pulses.

## Four modes

| `mode` | Name      | What it does |
|--------|-----------|--------------|
| `00`   | DC sweep  | DAC ramps `VSTART → VSTOP` by `VSTEP` with a `PW`-cycle settle at each step; every sample updates histogram, min, max, last. |
| `01`   | Endurance | N cycles of `{SET pulse → read-verify vs THR_LO, RESET pulse → read-verify vs THR_HI}`. On the first miss, `FAIL_IDX` and `PASS_FAIL` latch and the FSM stops early. |
| `10`   | Retention | Apply one `SET` pulse, then read every `INTV` clocks for N reads at `VREAD`, updating histogram / min / max / last each time. |
| `11`   | Hist-only | Free-running ADC capture: sample `ui_in` every `PW` clocks for N samples without touching the DAC. |

All four modes write into a shared 16-bin histogram (bins indexed by
`adc[7:4]`, 8-bit saturating counters) and a min / max / last tracker.

## Block diagram

```
       +------+          +---------------+          +-----------+
 ui_in |  ADC |--------> | histogram +   |          |           |
  (in) |      |          | min/max/last  | <--------+ FSM       |<--- SPI regs
       +------+          +---------------+  do_sample|  (4 mode |
                                                     |   dispatch)
       +------+                                      |           |
uo_out |  DAC |<-------------------------------------+           |
 (out) |      |                                      +-----------+
       +------+
                   (uio: cs_n, mosi, miso, sck, busy, done, pass_fail, trig)
```

## Register map

| Addr   | Name       | Description |
|--------|------------|-------------|
| `0x00` | `R_CTRL`   | `{irq_en, —, clear_hist, mode[1:0], reset_sticky, start, global_en}` |
| `0x01` | `R_VSTART` | DC-sweep start DAC code (default `0x00`) |
| `0x02` | `R_VSTOP`  | DC-sweep stop DAC code (default `0xFF`) |
| `0x03` | `R_VSTEP`  | DC-sweep step (default `0x01`) |
| `0x04` | `R_VSET`   | SET-pulse amplitude (default `0xC0`) |
| `0x05` | `R_VRESET` | RESET-pulse amplitude (default `0x40`) |
| `0x06` | `R_VREAD`  | READ amplitude (default `0x80`) |
| `0x07` | `R_THR_LO` | verify threshold after SET (ADC must be `≥ THR_LO`) (default `0xA0`) |
| `0x08` | `R_THR_HI` | verify threshold after RESET (ADC must be `≤ THR_HI`) (default `0x60`) |
| `0x09` | `R_PW`     | pulse / settle width in clocks (default `0x04`) |
| `0x0A` | `R_N_LO`   | low byte of N (endurance cycles / retention reads / hist samples) |
| `0x0B` | `R_N_HI`   | high byte of N (max `0xFFFF` = 65 535) |
| `0x0C` | `R_INTV_LO`| retention interval low byte |
| `0x0D` | `R_INTV_HI`| retention interval high byte |
| `0x10..0x1F` | `R_HIST0..15` | 16-bin 8-bit saturating histogram |
| `0x20` | `R_STATUS` | `{busy, done_sticky, pass_fail, irq_sticky, —, mode[1:0], global_en}` |
| `0x21/22` | `R_FAIL_LO/HI` | cycle index where endurance first failed |
| `0x23` | `R_LAST_ADC` | most-recent sampled ADC value |
| `0x24` | `R_MIN_ADC`  | minimum ADC observed since start |
| `0x25` | `R_MAX_ADC`  | maximum ADC observed since start |
| `0x26` | `R_DAC_DBG`  | current DAC drive value (read-only) |

W1C on `R_STATUS`: write `1 << 6` to clear `done_sticky`; write `1 << 4` to
clear `irq_sticky`. `pass_fail` is cleared by writing `CTRL.reset_sticky=1`.

## Pinout

* `ui_in[7:0]`  — ADC readback from the external cell
* `uo_out[7:0]` — DAC drive to the external cell
* `uio[0]`      — `spi_cs_n`  (in)
* `uio[1]`      — `spi_mosi`  (in)
* `uio[2]`      — `spi_miso`  (out)
* `uio[3]`      — `spi_sck`   (in)
* `uio[4]`      — `busy`
* `uio[5]`      — `done_sticky`
* `uio[6]`      — `pass_fail` (endurance)
* `uio[7]`      — `trigger_out` — high during SET/RESET pulse phases in
  DC / endurance / retention modes, useful as a scope trigger.

## How to test

```
# Endurance: 100 cycles at default SET/RESET/READ/thresholds, PW=4
spi_write(R_PW, 4)
spi_write(R_N_LO, 100); spi_write(R_N_HI, 0)
spi_write(R_CTRL, 0x0B)           # global_en=1, start=1, mode=01
wait(status.done == 1)
if status.pass_fail:
    fail_cycle = R_FAIL_HI << 8 | R_FAIL_LO
else:
    fail_cycle = None
```

## External hardware

An external RRAM/memristor test cell with a byte-granularity DAC drive
and a byte-granularity ADC readback. The on-chip platform does not assume
any particular voltage / current scaling — the 8-bit codes on `uo_out`
map linearly to whatever analog rail the carrier board supplies, and
`ui_in` is whatever the carrier board samples from the cell.
