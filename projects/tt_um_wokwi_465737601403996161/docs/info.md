# Tiny Number Simon

Tiny Number Simon is a digital memory game. It displays a growing sequence of
numbers from 1 to 8 on a 7-segment display. The player repeats the sequence with
eight active-high number inputs.

## How it works

The first round displays one number. After the player enters it correctly, the
next round repeats the same number and adds one new number. Every successful
round increases the score and the sequence length by one.

During computer playback, the display shows numbers 1 through 8 with the decimal
point off. During player input, the digit is blank and the decimal point is on.

Each input must be released before it can be detected again. The game also waits
for the final correct input to be released before starting the next round.

A wrong input ends the game. The score is the number of fully completed rounds.
The display advances once per rising clock edge:

```text
H -> blank -> tens digit -> blank -> units digit -> blank
```

For example, a score of 7 is displayed as `H`, blank, `0`, blank, `7`, blank.
The score then returns to zero and a new game begins.

The maximum represented score is 63. No best score is saved between games.

Reset is active low. Keep the clock running while reset is held. Different reset
hold times normally select different pseudo-random sequences. Reset must include
at least one rising clock edge.

## How to test

Use a slow clock or a manually stepped clock.

1. Drive all eight number inputs low.
2. Hold active-low reset low for several rising clock edges.
3. Release reset.
4. Confirm that the display shows one number from 1 to 8 and the decimal point
   is off.
5. Wait for input mode. The digit must be blank and only the decimal point must
   be on.
6. Drive the matching number input high for at least one rising edge, then
   return it low.
7. Confirm that the next round repeats the first number and adds one new number.
8. Continue entering the complete sequence.
9. Hold the final correct input high. The next round must not begin until the
   input returns low.
10. Enter a wrong number during a later round.
11. Verify `H`, blank, decimal tens, blank, decimal units, blank.
12. Verify that only fully completed rounds are counted.
13. Verify that a new one-number game starts after the final blank.
14. Repeat reset with a different hold duration and confirm that the sequence
    normally changes.

If several number inputs are high, the lowest-numbered input has priority.
Normal play should use one input at a time.

### Pinout

| Pin | Function |
| --- | --- |
| `ui[0]` | Number 1 |
| `ui[1]` | Number 2 |
| `ui[2]` | Number 3 |
| `ui[3]` | Number 4 |
| `ui[4]` | Number 5 |
| `ui[5]` | Number 6 |
| `ui[6]` | Number 7 |
| `ui[7]` | Number 8 |
| `uo[0]` | 7-segment `a` |
| `uo[1]` | 7-segment `b` |
| `uo[2]` | 7-segment `c` |
| `uo[3]` | 7-segment `d` |
| `uo[4]` | 7-segment `e` |
| `uo[5]` | 7-segment `f` |
| `uo[6]` | 7-segment `g` |
| `uo[7]` | Decimal point |

All outputs are active high. Bidirectional `uio` pins are unused.

## External hardware

- Eight active-high buttons or switches
- One common-cathode 7-segment display
- One suitable current-limiting resistor per segment
- A slow or manually stepped clock source
- An active-low reset button or signal

No microcontroller or external memory is required.

