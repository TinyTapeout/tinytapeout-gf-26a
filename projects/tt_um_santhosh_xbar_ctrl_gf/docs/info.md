<!---

This file is used to generate the TTGF26a datasheet for
tt_um_santhosh_xbar_ctrl_gf. Cross-foundry sibling of the TTSKY26a
tt_um_santhosh_xbar_ctrl.

-->

## How it works

Device-agnostic peripheral controller for 8-row x 8-column memristive /
spintronic / phase-change / ferroelectric crossbar arrays. Drives four
operation modes — READ, SET, RESET, FORMING — with a configurable 1-to-511-
cycle pulse width, repeatable pulse trains with programmable inter-pulse
gap, a swept-DAC I-V characterization mode, a compliance-current auto-abort,
a **16-bit** hardware pulse counter, a read-only V/2 half-select DAC value
for sneak-path mitigation, a **sticky compliance-history register**, and a
**last-ADC-in-sweep** snapshot. All parameters are programmed through a
Mode-0 SPI slave.

The FSM is verbatim from the TTSKY26a sibling
(IDLE -> SETUP -> PULSE -> SENSE -> GAP -> REPORT with an additional SWEEP
outer loop). The design instantiates no foundry-specific standard cells, so
the GF180mcuD port required no cell-library substitution; instead the
extra gate budget that the GF 1x1 tile provides versus SKY (~1.6x) is
spent on features that were deferred on SKY:

| Feature | SKY port | GF port |
|---|---|---|
| Pulse counter width | 8-bit (wraps at 256) | **16-bit** (0x0E lo / 0x11 hi) |
| Compliance history | Only current trip in status | **Sticky 8-bit** (0x10), clear via `reg_ctrl[4]` |
| Last-sweep-ADC snapshot | not captured | **Register 0x12** |
| Register count (NUM_REGS) | 16 | **20** |

## Register map

| Addr | Name | Access | Description |
|------|------|--------|-------------|
| 0x00 | `reg_ctrl`          | RW | `[0]=start`, `[1]=abort`, `[2]=auto_sweep`, `[3]=compliance_en`, `[4]=clear_hist` (self-clearing) |
| 0x01 | `reg_mode`          | RW | `[1:0]` in {READ=00, SET=01, RESET=10, FORM=11} |
| 0x02 | `reg_row`           | RW | 3-bit row address |
| 0x03 | `reg_col`           | RW | 3-bit column address |
| 0x04 | `reg_pulse_l`       | RW | Pulse width `[7:0]` |
| 0x05 | `reg_pulse_h`       | RW | Pulse width `[8]` (9-bit total, default 10) |
| 0x06 | `reg_dac`           | RW | 8-bit DAC code (default 0x80) |
| 0x07 | `reg_status`        | R  | `[7]=compliance_hit`, `[3]=sense_in`, `[2]=op_error`, `[1]=op_done`, `[0]=busy` |
| 0x08 | `reg_adc_data`      | R  | Last ADC reading, `{4'b0, ui_in[7:4]}` |
| 0x09 | `reg_sweep_start`   | RW | Sweep start DAC (default 0x00) |
| 0x0A | `reg_sweep_end`     | RW | Sweep end DAC (default 0xFF) |
| 0x0B | `reg_sweep_step`    | RW | Sweep increment (default 0x10) |
| 0x0C | `reg_repeat`        | RW | `[3:0]=repeat_count` (0 -> single), `[7:4]=gap x 16 cycles` |
| 0x0D | `reg_compliance`    | RW | Compliance ADC threshold (default 0xFF = off) |
| 0x0E | `pulse_count[7:0]`  | R  | Pulse counter low byte |
| 0x0F | `V/2`               | R  | `{1'b0, active_dac[7:1]}` half-select bias |
| 0x10 | `reg_compliance_hist` | R  | **GF-new** sticky compliance history (cleared by `reg_ctrl[4]`) |
| 0x11 | `pulse_count[15:8]` | R  | **GF-new** pulse counter high byte |
| 0x12 | `reg_sweep_last_adc`| R  | **GF-new** ADC sample from last sweep step |

SPI: Mode 0 (CPOL=0, CPHA=0), MSB first. CS=`uio[0]`, MOSI=`uio[1]`,
MISO=`uio[2]` (tri-stated when CS high), SCK=`uio[3]`. First byte is
`{rw, addr[6:0]}`; second byte is write data, or 8 clocks of MISO for reads.

## Pinout

- `ui[0]` sense_in, `ui[1]` adc_ready, `ui[2]` ext_irq, `ui[3]` unused
- `ui[7:4]` 4-bit ADC data (captured into `reg_adc_data[3:0]`)
- `uo[0]` pulse_out, `uo[1]` row_enable, `uo[2]` col_enable, `uo[3]` op_done
- `uo[7:4]` = `active_dac[3:0]` (low nibble of DAC code)
- `uio[0..3]` SPI CS/MOSI/MISO/SCK
- `uio[4..6]` = `row_addr[2:0]`
- `uio[7]` = `col_addr[0]`

Full 3-bit column address is SPI-readable at `reg_col[2:0]`.

## How to test

1. Apply reset. Configure over SPI. For a single SET pulse on row 2 / col 5
   with DAC 0xA0: write `reg_mode=0x01`, `reg_row=0x02`, `reg_col=0x05`,
   `reg_pulse_l=0x32` (50 cycles), `reg_dac=0xA0`, then pulse `reg_ctrl[0]=1`.
2. Observe `pulse_out` high for 50 clock cycles; `row_enable`/`col_enable`
   stay high; `op_done` asserts on completion. Read `reg_adc_data` (0x08).
3. **READ:** `reg_mode=0x00`, start — skips PULSE, waits for `adc_ready`.
4. **Pulse train:** `reg_repeat=0x34` -> 4 pulses with 3x16=48-cycle gap.
   Counter (0x11:0x0E) reports actual pulses delivered.
5. **Compliance limit:** `reg_compliance=0x40`, `reg_ctrl[3]=1`. If ADC
   crosses the threshold during SENSE, the FSM aborts; compliance_hit
   latches in status AND in `reg_compliance_hist` (0x10, GF-new).
6. **Clear history:** write `reg_ctrl=0x10` to clear `reg_compliance_hist`;
   the bit self-clears next cycle.
7. **Sweep mode:** set `reg_ctrl[2]=1` + `reg_ctrl[0]=1`. After completion,
   the ADC sample at the last DAC step is retained in `reg_sweep_last_adc`
   (0x12, GF-new), separate from `reg_adc_data` (0x08).

A cocotb suite of 36 tests in `test/test.py` covers every mode, SPI round-
trip, pulse-width boundaries (1 and 511 cycles), pulse trains, compliance
abort, sweep (incl. step=0 edge case), V/2 readback, `uio_oe` direction,
and all three GF-new features. All tests pass locally on icarus.

## External hardware

- **SPI master** (MCU/FPGA) on `uio[0:3]`.
- **External DAC**: connect `uo_out[7:4]` to a 4-bit DAC for basic use, or
  read the full 8-bit `reg_dac` over SPI for higher resolution. Register
  0x0F gives the V/2 half-select bias line.
- **External ADC**: 4-bit nibble on `ui_in[7:4]`, ready pulse on `ui_in[1]`.
- **Crossbar array**: row select on `uio_out[6:4]` (3 bits), column-low on
  `uio_out[7]`; decode full 3-bit column via SPI.
- Optional: external interrupt on `ui_in[2]`, single-bit sense-comparator
  on `ui_in[0]`.
