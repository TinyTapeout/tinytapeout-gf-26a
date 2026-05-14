<!---
This file is used to generate your project datasheet. Please fill in the information below and delete any unused
sections.
You can also include images in this folder and reference them in the markdown. Each image must be less than
512 kb in size, and the combined size of all images must be less than 1 MB.
-->

## How it works

This project is a VGA screensaver that displays a bouncing logo containing the text **UACJ** (top row) and **A.M.G** (bottom row) on a 640×480 @ 60 Hz display. It is based on the original *DVD Screensaver with Tiny Tapeout Logo (Tiny VGA)* by Uri Shaked, adapted and personalized by Angélica Morales Gallegos.

The design is composed of three main modules:

- **`vga_sync_generator`** – Generates the `hsync`, `vsync`, `display_on`, and pixel coordinate (`x`, `y`) signals following standard 640×480 VGA timing.
- **`bitmap_rom`** – Defines which pixels are active based on the current coordinates. The letters U, A, C, J (top) and A, M, G with dots (bottom) are drawn using rectangular coordinate ranges. Coordinates are clamped to the range 0–127 to prevent wrapping artifacts.
- **Top module (`tt_um_...`)** – Integrates both modules into the TinyTapeout standard interface. It handles the bouncing movement of the logo, color changes on each bounce, and drives the 6-bit RGB output (2 bits per channel).

When the logo reaches a screen edge, it reverses direction and cycles through a color palette, replicating the classic DVD screensaver behavior.

## How to test

Connect the design to a VGA-compatible display using the TinyTapeout demo board or a compatible VGA PMOD. Apply a 25.175 MHz pixel clock (standard for 640×480 @ 60 Hz).

**Inputs (via `ui_in`):**

| Bit | Function |
|-----|----------|
| 0 | `cfg_solid_color` – When high, selects a solid palette color; when low, enables gradient color mode |

**Outputs (via `uo_out`):**

| Bits | Function |
|------|----------|
| 7 | `vsync` |
| 6 | `hsync` |
| 5:4 | Red channel (2 bits) |
| 3:2 | Green channel (2 bits) |
| 1:0 | Blue channel (2 bits) |

**Reset:** Assert `rst_n` low to reset the design, then release high to begin operation.

Once running, the display will show the **UACJ / A.M.G** logo bouncing around the screen and changing color on each edge collision.

The design was verified on the TinyTapeout Playground, confirming correct movement, color changes, proper text rendering, and absence of visual artifacts.

## External hardware

- **VGA display** – Any monitor or screen supporting 640×480 @ 60 Hz VGA input.
- **VGA PMOD or breakout board** – Required to connect the TinyTapeout demo board's output signals to a standard VGA connector (HD-15). A resistor DAC may be needed to convert the 2-bit-per-channel digital output to analog VGA levels.
