<!---

This file is used to generate your project datasheet. Please fill in the information below and delete any unused
sections.

You can also include images in this folder and reference them in the markdown. Each image must be less than
512 kb in size, and the combined size of all images must be less than 1 MB.
-->

## How it works

This design implements a custom SPI module to interface with `RHD2164` neural amplifier chips and selects specific channels to transfer the data to a MCU via SPI. The design also implements a register bank accessible either by SPI or scanchain/shift register.

## How to test

To be added.

## External hardware

You can test this chip in two different ways.

1\. Connect the chip to an FPGA and use the RHD2164 emulator and MCU-SPI emulator available here. The register bank is tested using any MCU.

2\. Connect the chip to a `RHD2164` neural amplifier chip in CMOS mode or in LVDS mode using `LVDS-to-CMOS` adapters. The selected data is connected to any MCU which is also connected to the register bank.
