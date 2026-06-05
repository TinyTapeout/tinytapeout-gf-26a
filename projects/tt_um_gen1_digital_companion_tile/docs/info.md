## How it works

This project is a small digital companion tile for a future local memristive AI chip. It does not implement real memristors. Instead, it implements the digital control contract around a symbolic memristive update:

1. Load a symbolic target value with `LOAD_TARGET`.
2. Load a symbolic current value with `LOAD_CURRENT`.
3. Start a bounded write-verify loop with `START`.
4. Emit one-cycle `pulse_up` or `pulse_down` events while moving the symbolic current toward the target.
5. Finish with `verify_ok` when the target is reached, or `fault` when the attempt budget is exhausted.

The public output contract exposes status, pulse events, verification status, a fault bit, an attempt counter and an FSM state code. It does not expose the loaded target/current values directly on the public outputs in the tested scenarios.

## How to test

Reset the design, then drive the command/data input bus:

- `01vvvvvv`: load target.
- `10vvvvvv`: load current.
- `11mmmm01`: start with max attempt count `m`.
- `11xxxx10`: clear public state.

Expected smoke tests:

- Target 5, current 2, max attempts 4: emits `pulse_up` events and finishes with `verify_ok`.
- Target 1, current 5, max attempts 4: emits `pulse_down` events and finishes with `verify_ok`.
- Target 8, current 0, max attempts 3: emits `fault` after timeout.

The cocotb tests in `test/test.py` cover these scenarios and the `CLEAR` command.

The Yosys-only contract checks in `formal/companion_contract.sv` prove the same terminal expectations for the packaged RTL and can be run with:

```sh
yosys formal/run_yosys_contract.ys
```

## External hardware

No external hardware is required for the logic test. On a Tiny Tapeout demo board, switches or a microcontroller can drive the 8 input bits, and LEDs or a logic analyzer can observe the public outputs.
