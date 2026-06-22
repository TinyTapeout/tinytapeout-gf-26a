<!---

This file is used to generate your project datasheet. Please fill in the information below and delete any unused
sections.

You can also include images in this folder and reference them in the markdown. Each image must be less than
512 kb in size, and the combined size of all images must be less than 1 MB.
-->

## How it works

This is a **digital PWM (DPWM) generator** with selectable resolution, dyadic modulation and
dithering. A 12-bit control word sets the duty cycle; the design produces complementary
high-/low-side outputs with dead-time, plus a sync clock.

**Selectable width.** The PWM resolution is configurable to **5, 6, 7, 8 or 9 bits**. All widths
share the same **513-cycle switching period** (~97.5 kHz at a 50 MHz clock); the chosen B-bit duty
is scaled onto that period by `scaled = duty·2^(9−B) + max(1, 2^(8−B))`.

**Modes.** Beyond plain **Normal** PWM, the design adds:
- **Dyadic** — the lower `m` bits of the control word are distributed as a `+1` sequence across a
  2^m-period window (the bit selected each period is `lsb[highest_set_bit(counter)]`), raising the
  *effective* resolution by up to ~7 bits without extra base width.
- **Dithering v1/v2/v3** — a sigma-delta-style `+1` decision (`lsb ≥ counter`); v2 samples the LSB
  once per 2^m window, v3 also samples the base duty once per window.
- A **constant dyadic word** can replace the control LSBs as the modulation source.

**Configuration interface.** Static settings live in a small register file written over the pins.
`uio_in[7]` selects the mode:

| `uio_in[7]` | Meaning | `ui_in[7:0]` | `uio_in[6:4]` | `uio_in[3:0]` |
|-------------|---------|--------------|---------------|---------------|
| `0` (run)   | drive control word | `ctrl[11:4]` | — | `ctrl[3:0]` |
| `1` (config)| write a register   | write data   | reg address   | — |

Config registers (written while `uio_in[7]=1`):

| Addr (`uio_in[6:4]`) | Data (`ui_in`) |
|----------------------|----------------|
| `0` | `[2:0]`=dyadic_len (0–7), `[5:3]`=mode (0=Normal,1=Dyadic,2–4=Dither v1–v3), `[6]`=const_dyadic_flag |
| `1` | `[2:0]`=pwm_bits_sel (0→5-bit … 4→9-bit) |
| `2` | `[6:0]`=dyadic_word (constant modulation word) |

After reset the design defaults to **8-bit Normal** PWM (dyadic_len=0), so it behaves as a plain
8-bit PWM until configured. Outputs: `uo_out[0]`=high-side, `uo_out[1]`=low-side (complementary,
6-cycle / 120 ns dead-time), `uo_out[2]`=sync clock, `uo_out[7:3]`=duty MSBs (debug, normalised to
the 9-bit domain). All `uio` pins are inputs.

## How to test

1. Hold `rst_n` low for several clocks, then release. With no configuration the design is an 8-bit
   PWM: drive `ui_in` with the duty (e.g. `0x80` ≈ 50 %), keep `uio_in = 0x00`, and observe
   `uo_out[0]`/`uo_out[1]` (complementary) and the ~97.5 kHz sync clock on `uo_out[2]`.
2. **Configure** features by pulsing the config interface: set `uio_in[7]=1`, put the register
   address on `uio_in[6:4]` and the data on `ui_in`, clock once, then drop `uio_in[7]` back to 0.
   - *Select 5-bit width:* write addr 1 = `0x00`.
   - *Dyadic, 4-bit:* write addr 0 = `0x0C` (mode=1, dyadic_len=4); then run with `uio_in[3:0]` as
     the LSB word — the average duty shifts by `lsb/16` over 16 periods.
   - *Dithering v1:* write addr 0 = `0x14` (mode=2, dyadic_len=4).
   - *Constant dyadic word:* write addr 0 = `0x4C` (const flag + dyadic mode, len 4) and addr 2 =
     the 7-bit word; the modulation then ignores the control LSBs.
3. The cocotb testbench (`test/test.py`) exercises reset, all five widths, max-duty/dead-time, the
   sync clock, dyadic mode, the three dithering modes and the constant-word path.

## External hardware

None required for bench testing. For power-electronics use, wire `uo_out[0]` (high-side) and
`uo_out[1]` (low-side) to a half-bridge gate driver — the built-in dead-time prevents shoot-through
in, e.g., a synchronous buck converter or class-D stage.
