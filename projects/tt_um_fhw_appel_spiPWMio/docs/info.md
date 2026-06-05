<!---

This file is used to generate your project datasheet. Please fill in the information below and delete any unused
sections.

You can also include images in this folder and reference them in the markdown. Each image must be less than
512 kb in size, and the combined size of all images must be less than 1 MB.
-->

## How it works

This module provides a PWM generator on output pin 7 and a PWM reader on input pin 7. The PWM generator duty cycle is set by input pins [6:0]. The PWM reader output is reflected on output pins [6:0]. The period is assumed to be 20 ms, and the duty cycle can be adjusted between 1 ms and 2 ms.

When the SPI interface is not used, the module behaves as described above. When SPI is used, its behavior can be configured as described in `docs/specification.md`.

## How to test

Loop back the generated PWM signal to the PWM input pin, then verify that the PWM configuration is reflected on the output pins.

## External hardware

The design can be tested using a development kit. Optionally, use an oscilloscope to monitor the PWM signal and a signal generator to provide a test input on the PWM input pin. 
