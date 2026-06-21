<!---

This file is used to generate your project datasheet. Please fill in the information below and delete any unused
sections.

You can also include images in this folder and reference them in the markdown. Each image must be less than
512 kb in size, and the combined size of all images must be less than 1 MB.
-->

## How it works

This design simulates a universal one-qubit quantum computer.

It can execute 8 operations:
- Reset the state to |0>
- Apply a X/Y/Z/H/S/T gate to the qubit (see https://en.wikipedia.org/wiki/Quantum_logic_gate for gate definitions)
- Measure and returned the result, upon which the state will collapse to the measured value

Amplitudes are stored in 8 bit fixed point numbers, where the value v is indicated by the binary value round(127 * v).
A LFSR is used to generate pseudorandom numbers for measurement.

## How to test

ui_in[2:0] indicate which operation should be executed.
ui_in[3] contains the start signal, inverting its value will make the chip run the operation.

If the operation was the measure operation, the result can be read from uo[0].
After the operation was executed, the chip inverts the value of the done signal on uo[1] to match that of ready signal and waits for another command. 
