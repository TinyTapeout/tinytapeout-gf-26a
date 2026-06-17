<!---

This file is used to generate your project datasheet. Please fill in the information below and delete any unused
sections.

You can also include images in this folder and reference them in the markdown. Each image must be less than
512 kb in size, and the combined size of all images must be less than 1 MB.
-->

## How it works

This project implements a 16-bit "one-hot" ring counter. It consists of a circular shift register where a single high bit (`1`) advances sequentially across the 16 outputs.

The internal operation is as follows:
* **Initialization:** Upon activating the reset signal (the `rst_n` pin in Tiny Tapeout, which is internally inverted to an active-high `rst` in the counter's logic), the register is loaded with the initial value `16'b0000_0000_0000_0001`. This turns on only the first output.
* **Shifting:** On every rising edge of the clock signal (`clk`), the bits shift one position to the left. The most significant bit (MSB, bit 15) is fed back to the least significant position (LSB, bit 0), creating an infinite loop.
* **Output mapping:** To accommodate the 16 outputs within the Tiny Tapeout architecture, the first 8 bits (0 to 7) are assigned to the dedicated output pins (`uo_out`), and the next 8 bits (8 to 15) are assigned to the bidirectional pins (`uio_out`), which are permanently configured as outputs via `uio_oe`.
## How to test

To test the design on the physical evaluation board (or in the Wokwi/Verilator simulator):

1.  **Clock Configuration:** Select a very low clock frequency (e.g., 1 Hz to 10 Hz) using the baseboard configuration or an external pulse generator. This will allow you to see the bit shifting visually.
2.  **Reset:** Press the button associated with the reset signal (`rst_n` on the board is usually active-low). While the reset is held, only the first LED corresponding to `uo_out[0]` should be lit.
3.  **Execution:** Release the reset button. You should observe the lit LED "traveling" sequentially from `uo_out[0]` to `uo_out[7]`, and then continuing its path through `uio_out[0]` to `uio_out[7]`. Once it reaches the last pin, the cycle starts again at `uo_out[0]`.


 ## External hardware

No special external hardware is required if using the standard Tiny Tapeout demonstration board, as it includes a clock generator, pushbuttons for inputs, and LEDs to visualize the outputs. 

If mounted on a custom breadboard, the following will be needed:
* A clock source (e.g., a 555 timer-based oscillator or a microcontroller).
* 16 LEDs connected to the `uo_out` and `uio_out` pins, along with their respective current-limiting resistors (e.g., 330 Ω to 1 kΩ).
* A pushbutton with a pull-up resistor for the reset signal.
