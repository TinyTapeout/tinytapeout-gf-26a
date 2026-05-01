## How it works

This project draws a small ball on a 640x480 VGA-style display. The top-level clock drives the VGA timing generator, SPI receiver, command decoder, and physics engine.

Commands are sent over SPI using one byte per command. The upper two bits select the command and the lower six bits hold the data:

- `00`: set X position
- `01`: set Y position
- `10`: set X velocity
- `11`: set Y velocity

Position values are shifted left by three before being stored. Velocity values are interpreted as signed 6-bit numbers and clamped to the range `-10` to `10`. The ball position updates every six video frames and rebounds by inverting the X or Y velocity when it reaches the screen edges.

## How to test

Run the cocotb testbench from the `test` directory:

```sh
cd test
make clean
make
```

The tests send SPI commands to set position and velocity, then check movement, velocity clamping, reset behavior, and edge rebound behavior. The gate-level test uses a smaller top-level pin smoke test because internal RTL signal names are not preserved after synthesis.

## External hardware

The design is intended for a TinyVGA-style PMOD connection on the output pins and SPI command input on the bidirectional pins.
