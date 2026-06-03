<!---

This file is used to generate your project datasheet. Please fill in the information below and delete any unused
sections.

You can also include images in this folder and reference them in the markdown. Each image must be less than
512 kb in size, and the combined size of all images must be less than 1 MB.
-->

## Status

- Not submitted to [ttsky26a](https://app.tinytapeout.com/prepurchase?shuttle=ttsky26a). (full!)
- Probably NOT going to be submitted to [ttsky26b](https://app.tinytapeout.com/prepurchase?shuttle=ttsky26b) (deadline Mon May 18, 2026)
- Planning submission to [ttgf26a](https://app.tinytapeout.com/prepurchase?shuttle=ttgf26a) (deadline Mon June 22, 2026)

Version 0.1.3

Implemented: 

- Functional UART
- Functional FSM 
- Functional SPI; See [ULX3S ESP32 Demo](../ulx3s/ESP32/README.md)
- TRNG for SKY130 and GF180, as well as a stub for testing.
- Test JTAG

## Testing ULX3S / TT

First run this script in one bash terminal, note test pause "Press Enter to continue..." (see `Testing ESP32`, below)

```bash
cd /mnt/c/workspace/ttsky-UART-FSM-TRNG-Lab/test-hw

./run_tests.sh  --with-build  --ulx3s-board-version v307  --ignore-combinational-warning  --no-warning-pause  --port /dev/ttyS12 --pause-for-test
```

## Testing ESP32

Current testing scripts:

```bash
cd /mnt/c/SysGCC/esp32-master/esp-idf/v5.5

. ./export.sh

cd /mnt/c/workspace/ttsky-UART-FSM-TRNG-Lab/ulx3s/ESP32
idf.py build

idf.py -p /dev/ttyS3 -b 115200 flash

idf.py -p /dev/ttyS3 -b 115200 monitor
```


## How it works

TODO: Add a detailed description of how the FSM and TRNG work, including any relevant diagrams or flowcharts.

This design exposes a UART-controlled interface to a ring-oscillator-based entropy source (TRNG). 
A host (PC, ESP32, etc.) sends simple ASCII commands over UART to configure internal 
registers, control the oscillator network, and read back raw entropy data.

At a high level:
- A bank of ring oscillators generates jitter-based entropy
- A sampling clock (controlled by a divider) captures this behavior
- Control and configuration are managed through memory-mapped registers
- Data and status are read back over the same UART interface

See [spec sheet](./spec_sheet.md)

---

### Register Overview

| Register     | Description |
|--------------|-------------|
| `reg_ctrl`   | Global control bits (enable, feature flags) |
| `reg_src`    | Selects entropy source or oscillator group |
| `reg_div`    | Clock divider controlling sampling rate |
| `reg_mode`   | Operating mode configuration |
| `reg_oscen`  | Bitmask enabling individual oscillators |
| `reg_status` | Status flags (data ready, internal state) |
| `reg_rawlo`  | Low byte of raw sampled entropy |
| `reg_rawhi`  | High byte of raw sampled entropy |

---

### Key Concepts

- **Enable (`E`)**  
  Must typically be cleared (`E0`) before changing configuration, then set (`E1`) to run.

- **Oscillator Control (`O`)**  
  Enables one or more ring oscillators. More oscillators can improve entropy but may affect stability.

- **Sampling (`D`)**  
  The divider controls how frequently entropy is sampled. This impacts randomness quality and bias.

- **Source Selection (`S`)**  
  Allows switching between different entropy paths or test modes (implementation-specific).

- **Raw Data (`R6`, `R7`)**  
  Returns unprocessed entropy bytes. These are not whitened and may require post-processing.

---

### Typical Flow

1. Disable the core (`E0`)
2. Configure source, divider, mode, and oscillators
3. Enable the core (`E1`)
4. Read entropy and status via `R6`, `R7`, `R5`

This simple interface allows interactive exploration of TRNG behavior directly from a terminal.


## UART TRNG Command Interface

All commands are ASCII and terminated with `\r`.  
Responses are ASCII, typically:

`` R<n>=<value> ``

---

### Write Commands

| Cmd      | Description |
|----------|-------------|
| `E<n>`   | Write enable bit (0=disable, 1=enable) |
| `S<n>`   | Write source select |
| `V<n>`   | Write control bit 1 |
| `W<n>`   | Write control bit 2 |
| `D<hex>` | Write divider |
| `M<hex>` | Write mode |
| `O<hex>` | Write oscillator enable mask |

**Special:**
- `V\r` -> returns version string (if enabled in build)

---

### Read Commands

| Cmd | Description |
|-----|-------------|
| R0 | Read reg_ctrl |
| R1 | Read reg_src |
| R2 | Read reg_div |
| R3 | Read reg_mode |
| R4 | Read reg_oscen |
| R5 | Read reg_status |
| R6 | Read reg_rawlo |
| R7 | Read reg_rawhi |

---

### Examples

Enable and configure:

    E0\r
    V0\r
    W0\r
    S0\r
    D10\r
    M00\r
    O01\r
    E1\r

Read back registers:

    R0\r -> R0=01
    R2\r -> R2=10
    R6\r -> R6=7B
    R7\r -> R7=3C

Version query:

    V\r -> Version x.x.x <date>

---

### Notes

- Commands are stateful; configure with `E0` before changes
- `R6/R7` provide raw entropy bytes
- `O` controls active oscillators (entropy source)
- `D` affects sampling rate and bias

### UART

Connect with your favorite terminal program such as putty.

For the ULX3S FPGA, the UART is connected to pins `gp0` and `gp1` The default baud rate is 115200.

See the [default reference ULX3S ulx3s_v20.lpf restraint file](https://github.com/emard/ulx3s/blob/master/doc/constraints/ulx3s_v20.lpf).

Disabled:

```
# FREQUENCY PORT "gn[12]" 50 MHZ;
# FREQUENCY PORT "gn12" 50 MHZ;
```

Previously:

The `B11` and `A10` pins were updated with new names:

```
LOCATE COMP "gp[0]" SITE "B11"; # J1_5+  GP0 PCLK
LOCATE COMP "gp[1]" SITE "A10"; # J1_7+  GP1 PCLK
```

These

```
# UART pins for testing

LOCATE COMP "uart_rx_pin" SITE "B11"; # formerly "gp[0]"; # J1_5+  GP0 PCLK
IOBUF PORT "uart_rx_pin" IO_TYPE=LVCMOS33;

LOCATE COMP "uart_tx_pin" SITE "A10"; # formerly "gp[1]"; # J1_7+  GP1 PCLK
IOBUF PORT "uart_tx_pin" IO_TYPE=LVCMOS33;
```

## How to test

There are TT simulation tests and local ULX3S FPGA tests.

### TT Simulation tests

Commit changes. See results in [actions](./actions/).

In particular, note the output of the [gds workflow](./actions/workflows/gds.yaml):

- Linter output
- Routing Stats
- Cell usage by Category
- Tiny Tapeout Precheck Results
- Viewer summary


### Test on ULX3S FPGA

Build and flash the bitstream to the FPGA, then run the test script. The test script will print the output of the FSM and TRNG.

Test locally with ULX3S FPGA in [/ulx3s/](../ulx3s/README.md) directory.

- [verilator_lint.sh](../ulx3s/verilator_lint.sh)
- [ulx3s_build.sh](../ulx3s/ulx3s_build.sh)
- [ulx3s_flash.sh](../ulx3s/ulx3s_flash.sh)

Example:

```bash
cd ulx3s

./ulx3s_build.sh
./ulx3s_flash.sh
```

Connect to the FPGA using a serial terminal (e.g., `putty` or `minicom`) to view the output of the FSM and TRNG.

### Local Loopback Test

There are two loopback tests: a basic loopback test and a deep loopback test. The basic loopback test verifies that the UART is functioning 
correctly by sending data from the FPGA to the host and back. The deep loopback test verifies that the FSM and TRNG are functioning correctly 
by sending commands to the FPGA and reading the responses.

#### Basic Loopback Test

The basic loopback assigns `Tx` to `Rx` in `top_ulx3s.v`.

```verilog
    assign uart_tx_pin = uart_rx_sync;
```

All characters should be echoed back in the terminal when you type. This verifies that the UART is working correctly.

Sample loopback build defines `FORCE_LOOPBACK=1` macro in `ulx3s_build.sh`:

```bash
./ulx3s_build.sh --loopback --ignore-combinational-warning --no-warning-pause
./ulx3s_flash.sh
```

### Deep Loopback Test

```bash
./ulx3s_build.sh --deep-loopback --ignore-combinational-warning --no-warning-pause
./ulx3s_flash.sh
```

### Extensive loopback tests

Additional loopback tests:

```
    # The safest test to start (default write_with_delay when --bulk not specified)
    python ./loopback_test.py --port $PORT -b 115200                  || exit 1

    echo "Test non-bulk mode, delay = 0.005"
    python ./loopback_test.py --port $PORT -b 115200 --tx-delay 0.005 || exit 1

    echo "Test non-bulk mode, delay = 0.001"
    python ./loopback_test.py --port $PORT -b 115200 --tx-delay 0.001 || exit 1

    echo "Test non-bulk mode, delay = 0.000"
    python ./loopback_test.py --port $PORT -b 115200 --tx-delay 0.000 || exit 1

    echo "Test bulk mode most challenging"
    python ./loopback_test.py --port $PORT -b 115200 --bulk           || exit 1
```

The `run_tests.sh` can be used to run the loopback tests with the appropriate flags:

```bash
cd /mnt/c/workspace/ttgf-UART-FSM-TRNG-Lab/test-hw    
./run_tests.sh --with-build --ignore-combinational-warning --no-warning-pause --loopback
./run_tests.sh --with-build --ignore-combinational-warning --no-warning-pause --deep-loopback
./run_tests.sh --with-build --ignore-combinational-warning --no-warning-pause
```

### Local Automated Hardware Operation Tests

Generic local hardware operation tests in [/test-hw/](../test-hw/README.md).

- [tt_ulx3s_uart_test.py](../test-hw/tt_ulx3s_uart_test.py) - Python script to test the UART functionality of the FSM and TRNG on the ULX3S FPGA. It sends commands to the FPGA and reads the responses to verify correct operation.
- [run_tests.sh](../test-hw/run_tests.sh) - Shell script to run the hardware tests. It can be configured to build the FPGA bitstream, flash it to the FPGA, and run the Python test script.

```bash
cd test-hw

 ./run_tests.sh --with-build --ignore-combinational-warning --no-warning-pause
```



## External hardware

So far, none.
