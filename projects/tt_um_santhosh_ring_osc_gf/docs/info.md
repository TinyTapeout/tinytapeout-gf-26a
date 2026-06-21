<!---

This file is used to generate your project datasheet. Please fill in the information below and delete any unused
sections.

You can also include images in this folder and reference them in the markdown. Each image must be less than
512 kb in size, and the combined size of all images must be less than 1 MB.
-->

## How it works

This design is the **GF180mcuD port** of our SKY130 ring-oscillator PVT sensor (`tt_um_santhosh_ring_osc`). It implements **five gatable ring oscillators** (7, 11, 15, 21, and 31 `gf180mcu_fd_sc_mcu7t5v0__inv_1` inverter-chain stages, each with a `gf180mcu_fd_sc_mcu7t5v0__nand2_1` enable gate) together with a 16-bit frequency counter, a three-stage CDC synchronizer, an auto gate timer, a configurable prescaler, an XOR-jitter true random number generator (TRNG), a frequency-bounds health monitor, and a differential (beat-frequency) measurement mode. It is intended for **cross-foundry PVT characterization**: pairing this tile with the SKY130 sibling on the same chip family lets us compare ring-oscillator frequency, TRNG statistics, and aging drift between the two nodes from identical RTL.

All oscillator stages are tagged with `(* keep, dont_touch *)` so that the synthesis and placement flows preserve them as physical inverter/NAND chains rather than optimizing them into constant nets.

The block supports two control modes, selected by `ui_in[6]` (`spi_mode`):

- **Parallel mode (`spi_mode=0`)** — `ro_sel[2:0]` (`ui_in[2:0]`) chooses one of the five ROs, `cnt_enable` (`ui_in[3]`) starts/stops counting, a rising edge on `cnt_clear_latch` (`ui_in[4]`) latches the 16-bit count and clears the accumulator, and `byte_sel` (`ui_in[5]`) multiplexes `uo_out` between the low (0) and high (1) bytes of the latched count. `uio_out[4]` is the overflow flag, `uio_out[5]` exposes the raw RO output, `uio_out[6]` the synchronized RO output, and `uio_out[7]` is `meas_done` from the auto gate timer.
- **SPI mode (`spi_mode=1`)** — a 16-bit SPI slave (Mode 0, MSB first; CS on `uio_in[0]`, MOSI on `uio_in[1]`, MISO on `uio_out[2]`, SCK on `uio_in[3]`) exposes a register file:

| Addr | Name | Access | Description |
|------|------|--------|-------------|
| 0x00 | `reg_ctrl` | R/W | [0]=`auto_gate_start` (self-clear); [1]=`clear_meas_done`; **[2]=`clear_health_history` (self-clear, new on GF)** |
| 0x01 | `reg_ro_sel` | R/W | [2:0] RO select |
| 0x02 | `reg_ro_en` | R/W | [4:0] per-RO enable — reset default `0x1F` |
| 0x03 | `reg_gate_l` | R/W | gate-time low byte |
| 0x04 | `reg_gate_h` | R/W | gate-time high byte |
| 0x05 | `reg_prescale` | R/W | [1:0] prescaler (÷8/÷16/÷32/÷64; reset default ÷16) |
| 0x06 | `reg_status` | R | [0]=`gate_active`, [1]=`overflow`, [2]=`meas_done` |
| 0x07 | `reg_count_l` | R | latched count [7:0] |
| 0x08 | `reg_count_h` | R | latched count [15:8] |
| 0x09 | `reg_trng_ctrl` | R/W | [0]=`trng_en`, [1]=`health_en`, [2]=`diff_mode` |
| 0x0A | `reg_diff_sel` | R/W | [2:0] RO_B selector for beat/XOR modes |
| 0x0B | `reg_health_lo` | R/W | expected frequency lower bound |
| 0x0C | `reg_health_hi` | R/W | expected frequency upper bound |
| 0x0D | `reg_trng_data` | R | 8-bit XOR-jitter byte |
| 0x0E | `reg_health_status` | R | [0]=below, [1]=above, [2]=stuck, [3]=ok, [4]=trng_valid |
| **0x0F** | **`reg_hh_stuck`** | **R** | **per-RO stuck history (sticky; new on GF)** |
| **0x10** | **`reg_hh_below`** | **R** | **per-RO below-lo history (sticky; new on GF)** |

The raw RO is synchronized into the system clock domain through a 3-stage flip-flop synchronizer (with an optional ÷8/÷16/÷32/÷64 prescaler ahead of it) before being rising-edge detected and counted. When `diff_mode` is set, two user-selected ROs are XORed prior to counting, producing the beat frequency |f_A − f_B|, which is very sensitive to local PVT mismatch. The TRNG collects XOR jitter bits into an 8-bit register readable at `reg_trng_data`; the health monitor flags the selected RO against `reg_health_lo`/`reg_health_hi` bounds into `reg_health_status`.

### New on GF: per-RO health history

GF180 1×1 tile area (~55 712 µm²) holds more gates than SKY130 1×1 (~17 954 µm²) after process-scaling, so on this port we re-enable a feature that was deferred on the SKY submission: **two sticky 5-bit history registers** (`reg_hh_stuck`, `reg_hh_below`) that latch a bit per RO whenever that RO is the currently-selected one and is flagged stuck or below-lo by the health monitor. The registers survive until explicitly cleared by writing `reg_ctrl[2]=1` (self-clearing pulse). This makes aging and fault detection possible without continuously polling from the host.

## How to test

1. Apply reset (`rst_n` low for ≥10 clock cycles, then release).
2. **Simple parallel measurement:** set `spi_mode=0`, write `ro_sel[2:0]` to select RO (0=7, 1=11, 2=15, 3=21, 4=31), pulse `cnt_enable` high for the desired gate time, pulse `cnt_clear_latch` high for ≥1 cycle to latch the count, then toggle `byte_sel` and read `uo_out` to retrieve the low and high bytes of the 16-bit count. Check `uio_out[4]` for overflow.
3. **SPI-timed measurement:** set `spi_mode=1`, write `reg_gate_l/h` with the desired gate cycle count, set `reg_ctrl[0]=1` to start the auto gate timer, poll `reg_status` (or watch `uio_out[7]` = `meas_done`) for completion, and read `reg_count_l` / `reg_count_h`. Write `reg_ctrl[1]=1` to clear `meas_done` before the next run.
4. **TRNG:** in SPI mode, set `reg_trng_ctrl[0]=1` and enable at least two ROs; read `reg_trng_data` (0x0D) to consume 8 jitter-XOR bits.
5. **Health monitor:** set `reg_trng_ctrl[1]=1`, write `reg_health_lo`/`reg_health_hi` to the expected frequency window, and read `reg_health_status` (0x0E) after each gate. For long-term audits, sweep all 5 ROs and read `reg_hh_stuck` (0x0F) / `reg_hh_below` (0x10); write `reg_ctrl[2]=1` to clear.
6. **Differential mode:** set `reg_trng_ctrl[2]=1`, set `reg_ro_sel` to RO_A and `reg_diff_sel` to RO_B, then gate as usual — the count represents |f_A − f_B|.

A cocotb test suite (23 tests in `test/test.py`) exercises parallel counting, SPI register roundtrip, auto gate timing, prescaler selection, TRNG/health/differential modes, `uio_oe` direction control, and the new GF-only health-history registers and self-clearing `reg_ctrl[2]`. All tests pass on the RTL. Gate-level simulation is intentionally skipped in CI because the real gf180mcu inverter-chain ring oscillators produce ≈10⁹ events/s of simulated time and are not tractable in icarus.

## External hardware

No external hardware is required for core operation. For SPI control, an SPI master (microcontroller or FPGA) is connected to `uio[0]` (CS), `uio[1]` (MOSI), `uio[2]` (MISO), `uio[3]` (SCK) at any clock rate up to half the system clock. Optional: an oscilloscope on `uio_out[5]` (raw RO) and `uio_out[6]` (synced RO) for direct frequency observation, and any 8-bit digital sink (logic analyzer or microcontroller GPIO) on `uo_out[7:0]` for reading the latched count byte in parallel mode.
