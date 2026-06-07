## How it works

This project implements a **2×2 systolic Processing Element (PE) grid** for CNN inference, controlled entirely over UART from a host PC.

### Architecture

The core is `peg_1x` — a 2×2 array of multiply-accumulate PEs arranged in a systolic fashion. Each PE has a 2-bit signed weight register and a 13-bit accumulator. The array supports three dataflow patterns:

| Direction | Encoding | Description |
|---|---|---|
| H-zigzag | `2'b10` | Activations enter via `h_in0`, snake left→up→left→down |
| V-zigzag | `2'b01` | Activations enter via `v_in0`, snake down→right→up→left |
| Circular | `2'b11` | Internal ring; boundary inputs ignored |

The `uart_peg_top` wrapper sits on top and bridges a host PC to the PE grid over **8N1 UART at 115200 baud**.

### UART Protocol

**PC → FPGA: 3 bytes per DUT clock cycle**

| Byte | Bits | Signal |
|---|---|---|
| B0 | [7] | `en` |
| B0 | [6] | `move_en` |
| B0 | [5] | `psum_shift_en` |
| B0 | [4] | `psum_clr` |
| B0 | [3] | `w_ld_en` |
| B0 | [2:1] | `direction[1:0]` |
| B1 | [7:2] | `h_in0[5:0]` |
| B1 | [1:0] | `v_in0[5:4]` |
| B2 | [7:4] | `v_in0[3:0]` |
| B2 | [3:2] | `w_in[1][1:0]` |
| B2 | [1:0] | `w_in[0][1:0]` |

**FPGA → PC: 2 bytes after each applied cycle**

| Byte | Bits | Signal |
|---|---|---|
| B0 | [4:0] | `psum_out0[12:8]` |
| B1 | [7:0] | `psum_out0[7:0]` |

Each 3-byte packet applies the encoded inputs for exactly **one DUT clock cycle**. Transient control signals (`en`, `move_en`, `w_ld_en`, etc.) are auto-cleared after each cycle. Sticky signals (`direction`, `h_in0`, `v_in0`, `w_in`) retain their last value.

### Pins

- `ui[0]` = UART RX (input from PC)
- `uo[0]` = UART TX (output to PC)

## How to test

Connect a USB-to-UART adapter: adapter TX → `ui[0]`, adapter RX → `uo[0]`, GND → GND.

Install the Python host script dependencies:
```
pip install pyserial
```

Run the full verification suite against the chip:
```
python uart_peg_host.py /dev/ttyUSB0
```

This runs 9 test cases matching the simulation testbench (h-zigzag, v-zigzag, circular shift, negative weights, psum_clr, multi-stream accumulation).

### Example: load weights and compute one dot product

```python
from uart_peg_host import PegController

ctrl = PegController("/dev/ttyUSB0", baud=115200)
ctrl.clear_psums()
ctrl.load_weights(w0=1, w1=1)          # +1 both columns
ctrl.stream_h([5, 7], extra_drain=6)   # stream activations
result = ctrl.drain_psum()             # read accumulated psum
print(result)                          # → 12
ctrl.close()
```

## External hardware

- USB-to-UART adapter (3.3V logic level, e.g. FTDI FT232 or CP2102)
- Host PC running `uart_peg_host.py` (Python 3, pyserial)
