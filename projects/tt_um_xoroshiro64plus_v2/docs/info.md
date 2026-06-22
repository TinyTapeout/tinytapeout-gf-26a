<!---

This file is used to generate your project datasheet. Please fill in the information below and delete any unused
sections.

You can also include images in this folder and reference them in the markdown. Each image must be less than
512 kb in size, and the combined size of all images must be less than 1 MB.
-->

## How it works

This design implements a lightweight **xoroshiro64+ random number generator** with **ring oscillator (RO) noise injection** to provide entropy.

The generator maintains two 32-bit internal states (`s0` and `s1`). On each enabled clock cycle:

1. A 32-bit random word is generated using a ripple-carry adder:

   ```
   random_word = s0 + s1
   ```
2. The xoroshiro64+ state update equations compute the next values of `s0` and `s1`.
3. The RO noise input is XORed into the least significant bit of `s0` to introduce true randomness.
4. The generated 32-bit word is loaded into a serializer.
5. The serializer shifts out one bit per clock on `serial_out`.

A pulse on `valid_out` indicates the start of a new 32-bit random word.

The internal state can also be seeded through an 8-bit seed-loading interface.

## How to test

1. Apply a clock to `clk`.
2. Release reset by setting `rst_n = 1`.
3. Set `enable = 1`.
4. Provide a changing signal on `ro_noise` (for example, from a ring oscillator).
5. Monitor `serial_out`.
6. Observe `valid_out`; it pulses high when a new 32-bit random word begins shifting out.
7. Optionally load custom seeds using `seed_data`, `seed_wen`, and `seed_sel`.

## External hardware

* 1-bit Ring Oscillator (RO) noise source connected to `ro_noise`.
* No other external hardware is required.
