# tt_um_uacj — VGA Logo Bouncer

A [Tiny Tapeout](https://tinytapeout.com) digital design that displays a **128×40 pixel** bitmap logo bouncing around a 640×480 VGA screen, with real-time visual effects controlled via the input pins.

---

## Overview

The design generates a standard VGA signal (640×480, 60 Hz) and animates a bitmap logo that bounces within the visible area, cycling through colors on each wall collision. Eight visual effects are individually controlled by the bits of `ui_in`.

---

## Pinout

### Inputs (`ui_in`)

| Bit | Name           | Description                                          |
|-----|----------------|------------------------------------------------------|
| 0   | `cfg_tile`     | Tile mode: repeats the logo across the entire screen |
| 1   | `cfg_color`    | Enables dynamic color palette                        |
| 2   | `cfg_invert`   | Swaps foreground and background colors               |
| 3   | `cfg_slow`     | Halves the animation speed                           |
| 4   | `cfg_flip`     | Flips the logo vertically                            |
| 5   | `cfg_checker`  | Enables checkerboard background pattern              |
| 6   | `cfg_scanline` | Simulates CRT scanlines                              |
| 7   | `cfg_glitch`   | Enables the visual corruption (glitch) engine        |

### Outputs (`uo_out`) — TinyVGA PMOD

| Bits  | Signal |
|-------|--------|
| `[7]` | HSYNC  |
| `[6]` | B[0]   |
| `[5]` | G[0]   |
| `[4]` | R[0]   |
| `[3]` | VSYNC  |
| `[2]` | B[1]   |
| `[1]` | G[1]   |
| `[0]` | R[1]   |

Compatible with the standard Tiny Tapeout **TinyVGA PMOD**.

### Bidirectionals (`uio_*`)

Not used. `uio_out` and `uio_oe` are held at `0`.

---

## Timing Parameters

| Parameter     | Value                   |
|---------------|-------------------------|
| Clock (`clk`) | 25 MHz (40 ns period)   |
| Reset         | Active-low (`rst_n`)    |
| Resolution    | 640 × 480 pixels        |
| Refresh rate  | ~60 Hz                  |
| Logo size     | 128 × 40 pixels         |

---

## Modules

### `tt_um_uacj` (top)

Top-level module. Instantiates all submodules and implements:

- **Bounce logic**: the logo starts at (200, 200) and travels diagonally. On each wall hit, the corresponding direction is reversed.
- **Collision flash**: for 6 frames after a bounce, the logo is rendered in full white.
- **Speed divider** (`cfg_slow`): when active, the logo advances one pixel every two frames.
- **Dynamic color**: the color index increments on each bounce and is applied to the logo, background, and checkerboard pattern through the 8-color palette.

### `hvsync_generator`

Generates horizontal and vertical sync signals according to the VGA standard:

| Parameter       | Value |
|-----------------|-------|
| H_DISPLAY       | 640   |
| H_FRONT porch   | 16    |
| H_SYNC          | 96    |
| H_BACK porch    | 48    |
| V_DISPLAY       | 480   |
| V_BOTTOM border | 10    |
| V_SYNC          | 2     |
| V_TOP border    | 33    |

Exposes `hpos` and `vpos` (10-bit each) and the `display_on` signal indicating when the beam is within the visible area.

### `bitmap_rom`

A **640-byte** read-only memory (40 rows × 16 bytes) storing the monochrome logo bitmap at 128×40 pixels (1 bpp).

- Addressing: `addr = y[5:0] * 16 + x[6:3]`
- Pixel extraction: `pixel = mem[addr][x[2:0]]`
- Supports vertical flip via `cfg_flip`.

### `palette`

An 8-entry LUT in 6-bit `RRGGBB` format (2 bits per channel):

| Index | Color  | Value    |
|-------|--------|----------|
| 0     | Cyan   | `001011` |
| 1     | Pink   | `110110` |
| 2     | Green  | `101101` |
| 3     | Orange | `111000` |
| 4     | Purple | `110011` |
| 5     | Yellow | `011111` |
| 6     | Red    | `110001` |
| 7     | White  | `111111` |

Instantiated three times: logo color, background color, and checkerboard color.

---

## Glitch Engine

When `cfg_glitch = 1`, a visual corruption engine is activated based on an **8-bit LFSR** (taps at positions 7, 5, 4, 3). The engine runs a 3-state FSM:

| State | Description                                        |
|-------|----------------------------------------------------|
| 0     | Idle — waiting for a trigger                       |
| 1     | Active corruption (runs for `glitch_timer` frames) |
| 2     | Recovery (1-frame transition back to idle)         |

Effects applied during corruption:

- **Horizontal/vertical XOR scrambling**: pixels are displaced using an LFSR-derived mask.
- **Horizontal tearing**: selected rows are offset laterally by a pseudo-random amount.
- **Chromatic aberration**: each RGB channel receives an independent XOR from the LFSR.
- **Channel swapping**: R↔G and G↔B are permuted based on LFSR bits.
- **Inversion flash**: at maximum intensity, colors are inverted on select frames.

The glitch engine also triggers automatically approximately every 150 frames while `cfg_glitch = 1`.

---

## How to Use

1. Connect the **TinyVGA PMOD** to the `uo_out` pins.
2. Connect a VGA monitor to the PMOD.
3. Supply a **25 MHz** clock on `clk`.
4. Assert `rst_n = 0` briefly at startup, then release (`rst_n = 1`).
5. Control visual effects with the 8 bits of `ui_in` as described in the pinout table above.

---

## Project Files

| File                  | Description                                    |
|-----------------------|------------------------------------------------|
| `tt_um_uacj.v`        | Top module: animation, effects, RGB output     |
| `hvsync_generator.v`  | VGA sync signal generator                      |
| `bitmap_rom.v`        | Logo bitmap ROM (128×40, 1 bpp)                |
| `palette.v`           | 8-color palette LUT                            |
| `config.json`         | Tiny Tapeout build config (25 MHz clock)       |

---

## License

Apache 2.0 — © 2024 Tiny Tapeout LTD / UACJ IIT
