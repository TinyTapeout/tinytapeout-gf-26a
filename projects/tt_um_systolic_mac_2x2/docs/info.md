
## How it works

This project implements a 2×2 output-stationary systolic array that computes signed 4-bit matrix multiplication, producing 8-bit results.

The design has 5 modules:

- **PE (Processing Element)** — bit-serial multiplier with accumulator. Each PE computes `acc += a_in × weight_in` every cycle when `en=1`.
- **array_module** — 2×2 grid of 4 PEs with input skew registers. `a_row1` and `weight_col1` are delayed by 1 cycle to align data correctly across the array.
- **FSM** — controls the computation sequence: IDLE → COMPUTE (2 cycles) → DRAIN (2 cycles) → READ (4 cycles) → IDLE. Generates `en`, `clear`, and `valid` signals automatically after `start` is pulsed.
- **output_serializer** — serializes the 4 accumulator results (`acc_00`, `acc_01`, `acc_10`, `acc_11`) onto `data_out` one per cycle when `valid=1`.
- **tt_um_systolic_mac_2x2** — TT wrapper with streaming counter. Loads two sets of input registers (cycle 1 and cycle 2 values) via `ui_in` and `uio_in`, then auto-streams them to the array after `start`.

### Input loading protocol

Load all 4 register pairs in 4 cycles using `load=1` and `sel`:

| sel | ui_in[7:4] (data_c1) | uio_in[7:4] (data_c2) |
|-----|----------------------|------------------------|
| 00 | A[0][0] | A[0][1] |
| 01 | A[1][0] | A[1][1] |
| 10 | B[0][0] | B[1][0] |
| 11 | B[0][1] | B[1][1] |

After loading, pulse `start=1` for 1 cycle. The wrapper streams cycle 1 values, then cycle 2 values, then zeros automatically. Results appear on `uo_out` one per cycle when `uio_out[0]` (valid) goes high.

### Matrix multiply

Computes C = A × B where:
- A and B are 2×2 matrices of signed 4-bit integers (-8 to 7)
- C elements are signed 8-bit integers (-128 to 127)
- Output order: C[0][0], C[0][1], C[1][0], C[1][1]

## How to test

1. Reset the design (`rst_n=0` for 5 cycles, then `rst_n=1`)
2. Load matrix A and B values using `load=1`, `sel`, `ui_in[7:4]`, `uio_in[7:4]`
3. Pulse `start=1` for 1 cycle
4. Wait for `uio_out[0]` (valid) to go high
5. Read 4 consecutive values from `uo_out`

### Example — identity matrix test

