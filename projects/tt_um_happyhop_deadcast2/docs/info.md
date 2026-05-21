<!-- TT submissions page datasheet. Keep total images < 1 MB. -->

## How it works

A 16x16 smiley sprite bounces around a 640x480 VGA screen. No framebuffer
— each pixel is computed live from the beam position and the ball's `(x, y)`.
The smiley blinks every ~2 seconds and its eyes shift toward the direction
of motion.

## How to test

Plug the TT VGA PMOD into the chip's output PMOD, connect a 640x480 @ 60 Hz
monitor, power on. No input controls.

## External hardware

- TT VGA PMOD (Matt Venn)
- VGA monitor at 640x480 @ 60 Hz
