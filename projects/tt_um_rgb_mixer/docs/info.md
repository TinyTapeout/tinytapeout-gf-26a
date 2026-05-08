<!---

This file is used to generate your project datasheet. Please fill in the information below and delete any unused
sections.

You can also include images in this folder and reference them in the markdown. Each image must be less than
512 kb in size, and the combined size of all images must be less than 1 MB.
-->

## How it works

This is a custom implementation of an rgb mixer. The designs uses four inputs, two push buttons (i.e., `inc` and `dec`) and a 2 position dip switch (i.e., `led[1:0]`), and three outputs named `PWM0`, `PWM1`, and `PWM2`. The `inc` and `dec` buttons are used to increase or decrease the Pulse Widht of a selected output specified by the `led[1:0]` switch.

The following indicates the output selection based on the `led[1:0]` input. 

|||
|--|--|
| `led[1:0]` |`Output`|
|00| PWM0|
|01| PWM1|
|10| PWM2|
|11| -|

## How to test

Connect the push buttons and the dip-switches in a pull-up configurations to the following ports.

|||
|-|-|
|tt_inputs| connection|
| ui[0]| inc |
| ui[1]| dec |
| ui[2]| led[0] |
| ui[3]| led[1] |
|||

Connect an RGB LED to the following outputs.

|||
|-|-|
|tt_inputs| connection|
| uo[0]| PWM0 |
| uo[1]| PWM1 |
| uo[2]| PWM2 |
|||

## External hardware

It is only required two push buttons, one dip-switch and an RGB LED and some resistors.
