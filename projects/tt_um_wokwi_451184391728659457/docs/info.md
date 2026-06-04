<!---

This file is used to generate your project datasheet. Please fill in the information below and delete any unused
sections.

You can also include images in this folder and reference them in the markdown. Each image must be less than
512 kb in size, and the combined size of all images must be less than 1 MB.
-->

## How it works

The Simple Sprinkler depends on 2 conditions to properly function: the sprinkler system must 
be enabled and it must have a sufficient supply of water. Of those 2 conditions, they are 
dependent on a further 4 conditions.
 - A (Rain)
   - A = 1 (Currently raining)
   - A = 0 (Not raining)
 - B (Water Supply)
   - B = 1 (Sufficient water available)
   - B = 0 (Water supply insufficient)
 - C (Soil Moisture)
   - C = 1 (Soil is already moist)
   - C = 0 (Soil is dry)
 - D (Time)
   - D = 1 (Current time is within watering period)
   - D = 0 ((Current time is not within watering period)
       
## How to test

Adjust inputs A through D (IN1 - IN4) to see which combinations toggle the LEDs. For the sprinkler to fully function
both LEDs must be lit. The truth table is included in README.md.


## External hardware

None
