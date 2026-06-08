<!---

This file is used to generate your project datasheet. Please fill in the information below and delete any unused
sections.

You can also include images in this folder and reference them in the markdown. Each image must be less than
512 kb in size, and the combined size of all images must be less than 1 MB.
-->

## How it works

There's a [ring oscillator](https://en.wikipedia.org/wiki/Ring_oscillator) implemented at the core of this project for a TRNG (True Random Number Generator.

![ttgf-UART-FSM-TRNG-Lab-block-diagram.png](./ttgf-UART-FSM-TRNG-Lab-block-diagram.jpg)

This design exposes a UART-controlled interface to a ring-oscillator-based entropy source (TRNG). 
A host (PC, ESP32, etc.) sends simple ASCII commands over UART to configure internal 
registers, control the oscillator network, and read back raw entropy data.

At a high level:
- A bank of ring oscillators generates jitter-based entropy
- A sampling clock (controlled by a divider) captures this behavior
- Control and configuration are managed through memory-mapped registers
- Data and status are read back over the same UART interface

---

## How to test

The TT projects usually start in a reset mode = `True`. Connect to TT Breakout (or Demoboard) USB.

Select project, set clock to 25MHZ, and reset:

```
# select project and reset ttsky
# send "tt.shuttle. tt_um_gojimmypi_ttsky_UART_FSM_TRNG_Lab.enable()"

# or

# select project and reset ttgf
send "tt.shuttle. tt_um_gojimmypi_ttgf_UART_FSM_TRNG_Lab.enable()"

send "tt.clock_project_PWM(25000000)"
send "tt.reset_project(True)"
send "tt.reset_project(False)"
```

Connect a UART terminal (e.g. PuTTY) to the TT Breakout (or Demoboard) I/O pins with the following connections:

- UART/TTY USB Tx to `IN3/Rx`
- UART/TTY USB Rx to `OUT4/Tx`
- GND to GND

![PMOD-connector-test1.png](./PMOD-connector-test1.jpg)

Press type `V` and then press `Enter` to query the version string (if enabled in the build). 
Then you can send commands to configure the TRNG and read back entropy samples.

Connect to the UART and send the appropriate commands to configure and read from the TRNG core.

### Quickstart simulation

```bash
cd /mnt/c/workspace/ttgf-UART-FSM-TRNG-Lab/test

./my_test.sh

./jtag_test.sh
```

### Quickstart Testing on TT Demoboard

If all the toolchains are installed:

```bash
cd /mnt/c/workspace/ttgf-UART-FSM-TRNG-Lab/ice40

. ./env_ice40.sh
./build_and_flash.sh
./project_reset.sh
./run_tests.sh
```

### Quickstart Testing on ULX3S

```bash
cd /mnt/c/workspace/ttgf-UART-FSM-TRNG-Lab/test-hw

# may need to remove generated file
rm  ../src/_tt_fpga_top.v

./run_tests.sh  --with-build  --ulx3s-board-version v307  --ignore-combinational-warning  --no-warning-pause  --port /dev/ttyS12 --pause-for-test
```

### Quickstart on ULX3S ESP32

```bash
cd /mnt/c/workspace/ttgf-UART-FSM-TRNG-Lab/ulx3s/ESP32

idf.py -p /dev/ttyS3 -b 115200 flash
idf.py -p /dev/ttyS3 -b 115200 monitor
```

See also [Comprehensive Testing](./info.md#comprehensive-testing) below and the [TT MicroPython SDK v3](https://github.com/TinyTapeout/tt-micropython-firmware#initialization).

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

## Comprehensive Testing 

There are TT simulation tests and local ULX3S FPGA tests.

Set the `TT_PROJECT_ROOT` environment variable to the root of the project directory before running the tests or other scripts.

```bash
export TT_PROJECT_NAME="ttgf-UART-FSM-TRNG-Lab"
export TT_PROJECT_ROOT="/mnt/c/workspace/$TT_PROJECT_NAME"
```

### Testing on the Tiny Tapeout FPGA Development Kit

See the [overview video](https://www.youtube.com/watch?v=-cbwmJmdnzc) for the [FPGA Development Kit](https://store.tinytapeout.com/products/FPGA-Development-Kit-p813805747).



### Testing ULX3S / TT

First run this script in one bash terminal, note test pause "Press Enter to continue..." (see concurrent `Testing ESP32`, below)

```bash
cd "$TT_PROJECT_ROOT/test-hw"

./run_tests.sh  --with-build  --ulx3s-board-version v307  --ignore-combinational-warning  --no-warning-pause  --port /dev/ttyS12 --pause-for-test
```

### Testing SPI with ESP32

The ULX3S has a built-in ESP32, but a standalone ESP32 can also be used to test the SPI interface.

Current testing scripts:

```bash
# change directory to your ESP-IDF directory:
cd /mnt/c/SysGCC/esp32-master/esp-idf/v5.5

. ./export.sh

cd "$TT_PROJECT_ROOT/ulx3s/ESP32"
idf.py build

idf.py -p /dev/ttyS3 -b 115200 flash

idf.py -p /dev/ttyS3 -b 115200 monitor
```

There should be output from the ESP32 showing the SPI transactions and register values. 
This can be used to verify that the SPI interface is working correctly and that the TRNG lab core is responding to commands. For example:

```text
gojimmypi:/mnt/c/workspace/ttgf-UART-FSM-TRNG-Lab/ulx3s/ESP32
$ idf.py -p /dev/ttyS3 -b 115200 monitor
Executing action: monitor
Running idf_monitor in directory /mnt/c/workspace/ttgf-UART-FSM-TRNG-Lab/ulx3s/ESP32
Executing "/home/gojimmypi/.espressif/python_env/idf5.5_py3.10_env/bin/python /mnt/c/SysGCC/esp32-master/esp-idf/v5.5/tools/idf_monitor.py -p /dev/ttyS3 -b 115200 --toolchain-prefix xtensa-esp32-elf- --target esp32 --revision 0 /mnt/c/workspace/ttgf-UART-FSM-TRNG-Lab/ulx3s/ESP32/build/ulx3s_esp32.elf /mnt/c/workspace/ttgf-UART-FSM-TRNG-Lab/ulx3s/ESP32/build/bootloader/bootloader.elf -m '/home/gojimmypi/.espressif/python_env/idf5.5_py3.10_env/bin/python' '/mnt/c/SysGCC/esp32-master/esp-idf/v5.5/tools/idf.py' '-p' '/dev/ttyS3' '-b' '115200'"...
--- esp-idf-monitor 1.6.2 on /dev/ttyS3 115200
--- Quit: Ctrl+] | Menu: Ctrl+T | Help: Ctrl+T followed by Ctrl+H
I (13) boot: ESP-IDF v5.5 2nd stage bootloader
I (13) boot: compile time Jun  4 2026 08:25:56
I (13) boot: Multicore bootloader
I (13) boot: chip revision: v1.0
I (16) boot.esp32: SPI Speed      : 40MHz
I (20) boot.esp32: SPI Mode       : DIO
I (23) boot.esp32: SPI Flash Size : 2MB
I (27) boot: Enabling RNG early entropy source...
I (31) boot: Partition Table:
I (34) boot: ## Label            Usage          Type ST Offset   Length
I (40) boot:  0 nvs              WiFi data        01 02 00009000 00006000
I (47) boot:  1 phy_init         RF data          01 01 0000f000 00001000
I (53) boot:  2 factory          factory app      00 00 00010000 00100000
I (60) boot: End of partition table
I (63) esp_image: segment 0: paddr=00010020 vaddr=3f400020 size=0a3b0h ( 41904) map
I (85) esp_image: segment 1: paddr=0001a3d8 vaddr=3ff80000 size=00020h (    32) load
I (85) esp_image: segment 2: paddr=0001a400 vaddr=3ffb0000 size=023dch (  9180) load
I (92) esp_image: segment 3: paddr=0001c7e4 vaddr=40080000 size=03834h ( 14388) load
I (102) esp_image: segment 4: paddr=00020020 vaddr=400d0020 size=13374h ( 78708) map
I (131) esp_image: segment 5: paddr=0003339c vaddr=40083834 size=0b144h ( 45380) load
I (156) boot: Loaded app from partition at offset 0x10000
I (156) boot: Disabling RNG early entropy source...
I (166) cpu_start: Multicore app
I (174) cpu_start: Pro cpu start user code
I (175) cpu_start: cpu freq: 160000000 Hz
I (175) app_init: Application information:
I (177) app_init: Project name:     ulx3s_esp32
I (183) app_init: App version:      0.1.5-8-gfc18cf9-dirty
I (189) app_init: Compile time:     Jun  4 2026 08:25:35
I (195) app_init: ELF file SHA256:  ca2f9cedc...
I (200) app_init: ESP-IDF:          v5.5
I (205) efuse_init: Min chip rev:     v0.0
I (209) efuse_init: Max chip rev:     v3.99
I (214) efuse_init: Chip rev:         v1.0
I (220) heap_init: Initializing. RAM available for dynamic allocation:
I (227) heap_init: At 3FFAE6E0 len 00001920 (6 KiB): DRAM
I (233) heap_init: At 3FFB2C90 len 0002D370 (180 KiB): DRAM
I (239) heap_init: At 3FFE0440 len 00003AE0 (14 KiB): D/IRAM
I (245) heap_init: At 3FFE4350 len 0001BCB0 (111 KiB): D/IRAM
I (252) heap_init: At 4008E978 len 00011688 (69 KiB): IRAM
I (259) spi_flash: detected chip: generic
I (262) spi_flash: flash io: dio
W (266) spi_flash: Detected size(4096k) larger than the size in the binary image header(2048k). Using the size in the binary image header.
I (280) main_task: Started on CPU0
I (290) main_task: Calling app_main()
I (290) main: ------------------- ULX3S ESP32 Example ----------------
I (290) main: --------------------------------------------------------
I (300) main: --------------------------------------------------------
I (300) main: ---------------------- BEGIN MAIN ----------------------
I (310) main: --------------------------------------------------------
I (320) main: --------------------------------------------------------
I (330) main: Stack Start: 0x0
I (330) main: Stack HWM: 2400

Hello world 3!
This is esp32 chip with 2 CPU core(s), WiFi/BTBLE, silicon revision v1.0, 2MB external flash
Minimum free heap size: 305496 bytes
I (350) main: SPI write mode: boot config once
I (350) ulx3s_spi: SPI regs: R0=00 R1=00 R2=10 R3=00 R4=01 R5=04 R6=3E R7=84 raw=0x843E status=0x04 src=0 div=0x10 mode=0x00 oscen=0x01
I (460) main: TRNG deterministic LFSR test
I (460) main: lfsr test sample 00: raw=0x7F2E status=0x00
I (460) main: lfsr test sample 01: raw=0x9F33 status=0x00
I (460) main: lfsr test sample 02: raw=0xFC1C status=0x00
I (470) main: lfsr test sample 03: raw=0x6F03 status=0x00
I (480) main: lfsr test sample 04: raw=0x4B7D status=0x00
I (480) main: lfsr test sample 05: raw=0x52C8 status=0x00
I (490) main: lfsr test sample 06: raw=0xD6B7 status=0x00
I (490) main: lfsr test sample 07: raw=0xEF2A status=0x00
I (500) main: TRNG live source test: S1 RO0/fallback
I (510) main: S1 RO0/fallback sample 00: raw=0xAE11 status=0x0C
I (520) main: S1 RO0/fallback sample 01: raw=0x7826 status=0x0C
I (530) main: S1 RO0/fallback sample 02: raw=0x6F7D status=0x0C
I (540) main: S1 RO0/fallback sample 03: raw=0xDA87 status=0x0C
I (550) main: S1 RO0/fallback sample 04: raw=0x616F status=0x0C
I (560) main: S1 RO0/fallback sample 05: raw=0xD14E status=0x0C
I (570) main: S1 RO0/fallback sample 06: raw=0xE2E6 status=0x0C
I (580) main: S1 RO0/fallback sample 07: raw=0xB874 status=0x0C
I (580) main: TRNG live source test: S2 ROX/fallback
I (590) main: S2 ROX/fallback sample 00: raw=0xC060 status=0x14
I (600) main: S2 ROX/fallback sample 01: raw=0x64E4 status=0x14
I (610) main: S2 ROX/fallback sample 02: raw=0xA9DE status=0x14
I (620) main: S2 ROX/fallback sample 03: raw=0x6CB7 status=0x14
I (630) main: S2 ROX/fallback sample 04: raw=0xAF8F status=0x14
I (640) main: S2 ROX/fallback sample 05: raw=0x9E9C status=0x14
I (650) main: S2 ROX/fallback sample 06: raw=0x8E83 status=0x14
I (660) main: S2 ROX/fallback sample 07: raw=0xA7C1 status=0x14
I (660) main: TRNG live source test: S3 MIX/fallback
I (670) main: S3 MIX/fallback sample 00: raw=0x0D45 status=0x1C
I (680) main: S3 MIX/fallback sample 01: raw=0x55D6 status=0x1C
I (690) main: S3 MIX/fallback sample 02: raw=0x138C status=0x1C
I (700) main: S3 MIX/fallback sample 03: raw=0x1815 status=0x1C
I (710) main: S3 MIX/fallback sample 04: raw=0x7104 status=0x1C
I (720) main: S3 MIX/fallback sample 05: raw=0xFD98 status=0x1C
I (730) main: S3 MIX/fallback sample 06: raw=0x1BE8 status=0x1C
I (740) main: S3 MIX/fallback sample 07: raw=0x843E status=0x1C
I (740) ulx3s_spi: SPI regs: R0=00 R1=00 R2=10 R3=00 R4=01 R5=04 R6=3E R7=84 raw=0x843E status=0x04 src=0 div=0x10 mode=0x00 oscen=0x01
I (740) ulx3s_spi: SPI regs: R0=00 R1=00 R2=10 R3=00 R4=01 R5=04 R6=3E R7=84 raw=0x843E status=0x04 src=0 div=0x10 mode=0x00 oscen=0x01
```

If the `./run_tests.sh` was left at the `Press Enter to continue...` prompt, press `Enter` to continue with the next set of tests.
The output should look something like this:

```text
Build PASSED
Flash...
Flashing file:
-rw-r--r-- 1 gojimmypi gojimmypi 294455 Jun  4 08:22 /mnt/c/workspace/ttgf-UART-FSM-TRNG-Lab/ulx3s/ulx3s.bit
ULX2S / ULX3S JTAG programmer v4.8 (git 96ebb45 built Oct  7 2020 22:42:00)
Copyright (C) Marko Zec, EMARD, gojimmypi, kost and contributors
Using USB cable: ULX3S FPGA 12K v3.0.3
Programming: 100%
Completed in 12.78 seconds.
/mnt/c/workspace/ttgf-UART-FSM-TRNG-Lab/test-hw
Press Enter to continue...

Skipping register reset. Use --reset-registers to start from configured defaults.

Running: version_if_present
Version probe response: b'Version 0.1.5d 6/3/2026\r'
PASS: Version command

Running: power_on_defaults
PASS: R0 default reg_ctrl
PASS: R1 default reg_src
PASS: R2 default reg_div
PASS: R3 default reg_mode
PASS: R4 default reg_oscen

Running: single_nibble_writes
PASS: E1 write enable
PASS: R0 after E1
PASS: E0 clear enable
PASS: R0 after E0
PASS: V1 set ctrl bit 1
PASS: R0 after V1
PASS: W1 set ctrl bit 2
PASS: R0 after W1
PASS: S3 set source
PASS: R1 after S3
PASS: S0 clear source
PASS: R1 after S0

Running: two_nibble_writes
PASS: D2A write divider
PASS: R2 after D2A
PASS: M5C write mode
PASS: R3 after M5C
PASS: O0F write oscillator enable
PASS: R4 after O0F

Running: read_only_registers_format
PASS: R5 status format
PASS: R6 rawlo format
PASS: R7 rawhi format

Running: crlf_handling
PASS: CRLF read accepted

Running: error_cases
PASS: Unknown command
PASS: Bad hex digit
PASS: Bad read register
PASS: Missing second digit
PASS: Unexpected extra byte

Running: repeated_reads
PASS: Repeated R2 read 1
PASS: Repeated R2 read 2
PASS: Repeated R2 read 3
PASS: Repeated R2 read 4
PASS: Repeated R2 read 5

Command test coverage:
PASS: all known commands have tests

Tests passed: 8
Tests skipped: 0
Tests failed: 0

PASS

Running: reset_config_registers
PASS: Reset E0
PASS: Reset V0
PASS: Reset W0
PASS: Reset S0
PASS: Reset D10
PASS: Reset M00
PASS: Reset O01

Running: version_if_present
Version probe response: b'Version 0.1.5d 6/3/2026\r'
PASS: Version command

Running: power_on_defaults
PASS: R0 default reg_ctrl
PASS: R1 default reg_src
PASS: R2 default reg_div
PASS: R3 default reg_mode
PASS: R4 default reg_oscen

Running: single_nibble_writes
PASS: E1 write enable
PASS: R0 after E1
PASS: E0 clear enable
PASS: R0 after E0
PASS: V1 set ctrl bit 1
PASS: R0 after V1
PASS: W1 set ctrl bit 2
PASS: R0 after W1
PASS: S3 set source
PASS: R1 after S3
PASS: S0 clear source
PASS: R1 after S0

Running: two_nibble_writes
PASS: D2A write divider
PASS: R2 after D2A
PASS: M5C write mode
PASS: R3 after M5C
PASS: O0F write oscillator enable
PASS: R4 after O0F

Running: read_only_registers_format
PASS: R5 status format
PASS: R6 rawlo format
PASS: R7 rawhi format

Running: crlf_handling
PASS: CRLF read accepted

Running: error_cases
PASS: Unknown command
PASS: Bad hex digit
PASS: Bad read register
PASS: Missing second digit
PASS: Unexpected extra byte

Running: repeated_reads
PASS: Repeated R2 read 1
PASS: Repeated R2 read 2
PASS: Repeated R2 read 3
PASS: Repeated R2 read 4
PASS: Repeated R2 read 5

Command test coverage:
PASS: all known commands have tests

Running: final_reset_config_registers
PASS: Reset E0
PASS: Reset V0
PASS: Reset W0
PASS: Reset S0
PASS: Reset D10
PASS: Reset M00
PASS: Reset O01

Tests passed: 10
Tests skipped: 0
Tests failed: 0

PASS

Running: TRNG S0 LFSR frozen samples
PASS: Configure E0
PASS: Configure source
PASS: Configure oscillator mask
PASS: Configure divider
PASS: Enable sampling
PASS: Freeze sampling
  sample 01: 0x1F34
PASS: Enable sampling
PASS: Freeze sampling
  sample 02: 0x4CE6
PASS: Enable sampling
PASS: Freeze sampling
  sample 03: 0xA63E
PASS: Enable sampling
PASS: Freeze sampling
  sample 04: 0x2381
PASS: Enable sampling
PASS: Freeze sampling
  sample 05: 0xAF56
PASS: Enable sampling
PASS: Freeze sampling
  sample 06: 0x81E9
PASS: Enable sampling
PASS: Freeze sampling
  sample 07: 0x1A72
PASS: Enable sampling
PASS: Freeze sampling
  sample 08: 0xA6FD

Evaluation: TRNG S0 LFSR frozen samples
  Samples:      8
  Unique:       8
  Zero samples: 0
  0xFFFF count: 0
  One bits:     65/128
  One ratio:    0.508
PASS: sample output changes
PASS: bit balance is reasonable for this small sample set

Running: TRNG S1 RO0/fallback path
PASS: Configure E0
PASS: Configure source
PASS: Configure oscillator mask
PASS: Configure divider
PASS: Enable sampling
PASS: Freeze sampling
  sample 01: 0x2B08
PASS: Enable sampling
PASS: Freeze sampling
  sample 02: 0x5E58
PASS: Enable sampling
PASS: Freeze sampling
  sample 03: 0x60B3
PASS: Enable sampling
PASS: Freeze sampling
  sample 04: 0x3295
PASS: Enable sampling
PASS: Freeze sampling
  sample 05: 0xE318
PASS: Enable sampling
PASS: Freeze sampling
  sample 06: 0x6387
PASS: Enable sampling
PASS: Freeze sampling
  sample 07: 0xCB05
PASS: Enable sampling
PASS: Freeze sampling
  sample 08: 0x3867

Evaluation: TRNG S1 RO0/fallback path
  Samples:      8
  Unique:       8
  Zero samples: 0
  0xFFFF count: 0
  One bits:     57/128
  One ratio:    0.445
PASS: sample output changes
PASS: bit balance is reasonable for this small sample set

Running: TRNG S2 ROX/fallback path
PASS: Configure E0
PASS: Configure source
PASS: Configure oscillator mask
PASS: Configure divider
PASS: Enable sampling
PASS: Freeze sampling
  sample 01: 0x4241
PASS: Enable sampling
PASS: Freeze sampling
  sample 02: 0x4634
PASS: Enable sampling
PASS: Freeze sampling
  sample 03: 0x26DA
PASS: Enable sampling
PASS: Freeze sampling
  sample 04: 0xD9AD
PASS: Enable sampling
PASS: Freeze sampling
  sample 05: 0xF7A3
PASS: Enable sampling
PASS: Freeze sampling
  sample 06: 0xC774
PASS: Enable sampling
PASS: Freeze sampling
  sample 07: 0xB924
PASS: Enable sampling
PASS: Freeze sampling
  sample 08: 0x73C0

Evaluation: TRNG S2 ROX/fallback path
  Samples:      8
  Unique:       8
  Zero samples: 0
  0xFFFF count: 0
  One bits:     62/128
  One ratio:    0.484
PASS: sample output changes
PASS: bit balance is reasonable for this small sample set

Running: TRNG S3 MIX/fallback path
PASS: Configure E0
PASS: Configure source
PASS: Configure oscillator mask
PASS: Configure divider
PASS: Enable sampling
PASS: Freeze sampling
  sample 01: 0xBD3F
PASS: Enable sampling
PASS: Freeze sampling
  sample 02: 0xC635
PASS: Enable sampling
PASS: Freeze sampling
  sample 03: 0xD417
PASS: Enable sampling
PASS: Freeze sampling
  sample 04: 0x43E2
PASS: Enable sampling
PASS: Freeze sampling
  sample 05: 0xC7E5
PASS: Enable sampling
PASS: Freeze sampling
  sample 06: 0x565C
PASS: Enable sampling
PASS: Freeze sampling
  sample 07: 0x1669
PASS: Enable sampling
PASS: Freeze sampling
  sample 08: 0xD573

Evaluation: TRNG S3 MIX/fallback path
  Samples:      8
  Unique:       8
  Zero samples: 0
  0xFFFF count: 0
  One bits:     70/128
  One ratio:    0.547
PASS: sample output changes
PASS: bit balance is reasonable for this small sample set

PASS

First LFSR sequence
  sample 01: 0x7F2E
  sample 02: 0x9F33
  sample 03: 0xFC1C
  sample 04: 0x6F03
  sample 05: 0x4B7D
  sample 06: 0x52C8
  sample 07: 0xD6B7
  sample 08: 0xEF2A

Second LFSR sequence
  sample 01: 0x7F2E
  sample 02: 0x9F33
  sample 03: 0xFC1C
  sample 04: 0x6F03
  sample 05: 0x4B7D
  sample 06: 0x52C8
  sample 07: 0xD6B7
  sample 08: 0xEF2A

Reproducibility evaluation:
PASS: LFSR sequence is reproducible

Sequence quality check:
  Samples:      8
  Unique:       8
  Zero samples: 0
  0xFFFF count: 0
  One bits:     75/128
  One ratio:    0.586
PASS: deterministic sequence is not stuck

PASS
```


The continued output from the ESP32 in the separate TTY window should look something like this:

```text
I (186760) ulx3s_spi: SPI regs: R0=06 R1=00 R2=10 R3=00 R4=01 R5=00 R6=00 R7=00 raw=0x0000 status=0x00 src=0 div=0x10 mode=0x00 oscen=0x01
I (187760) ulx3s_spi: SPI regs: R0=06 R1=00 R2=2A R3=5C R4=0F R5=00 R6=00 R7=00 raw=0x0000 status=0x00 src=0 div=0x2A mode=0x5C oscen=0x0F
I (188760) ulx3s_spi: SPI regs: R0=00 R1=00 R2=10 R3=00 R4=01 R5=04 R6=00 R7=00 raw=0x0000 status=0x04 src=0 div=0x10 mode=0x00 oscen=0x01
I (189760) ulx3s_spi: SPI regs: R0=06 R1=00 R2=2A R3=5C R4=01 R5=00 R6=00 R7=00 raw=0x0000 status=0x00 src=0 div=0x2A mode=0x5C oscen=0x01
I (190760) ulx3s_spi: SPI regs: R0=06 R1=00 R2=2A R3=5C R4=0F R5=00 R6=00 R7=00 raw=0x0000 status=0x00 src=0 div=0x2A mode=0x5C oscen=0x0F
I (191760) ulx3s_spi: SPI regs: R0=00 R1=00 R2=01 R3=00 R4=00 R5=00 R6=34 R7=1F raw=0x1F34 status=0x00 src=0 div=0x01 mode=0x00 oscen=0x00
I (192760) ulx3s_spi: SPI regs: R0=00 R1=00 R2=01 R3=00 R4=00 R5=00 R6=E9 R7=81 raw=0x81E9 status=0x00 src=0 div=0x01 mode=0x00 oscen=0x00
I (193760) ulx3s_spi: SPI regs: R0=00 R1=01 R2=01 R3=00 R4=01 R5=0C R6=08 R7=2B raw=0x2B08 status=0x0C src=1 div=0x01 mode=0x00 oscen=0x01
I (194760) ulx3s_spi: SPI regs: R0=00 R1=01 R2=01 R3=00 R4=01 R5=0C R6=87 R7=63 raw=0x6387 status=0x0C src=1 div=0x01 mode=0x00 oscen=0x01
I (195760) ulx3s_spi: SPI regs: R0=00 R1=02 R2=01 R3=00 R4=FF R5=14 R6=41 R7=42 raw=0x4241 status=0x14 src=2 div=0x01 mode=0x00 oscen=0xFF
I (196760) ulx3s_spi: SPI regs: R0=01 R1=02 R2=01 R3=00 R4=FF R5=17 R6=B1 R7=67 raw=0x67B1 status=0x17 src=2 div=0x01 mode=0x00 oscen=0xFF
I (197760) ulx3s_spi: SPI regs: R0=00 R1=03 R2=01 R3=00 R4=FF R5=1C R6=3F R7=BD raw=0xBD3F status=0x1C src=3 div=0x01 mode=0x00 oscen=0xFF
I (198760) ulx3s_spi: SPI regs: R0=01 R1=03 R2=01 R3=00 R4=FF R5=1D R6=E6 R7=19 raw=0x19E6 status=0x1D src=3 div=0x01 mode=0x00 oscen=0xFF
I (199760) ulx3s_spi: SPI regs: R0=04 R1=03 R2=01 R3=00 R4=FF R5=00 R6=00 R7=00 raw=0x0000 status=0x00 src=3 div=0x01 mode=0x00 oscen=0xFF
I (200760) ulx3s_spi: SPI regs: R0=02 R1=00 R2=01 R3=00 R4=00 R5=00 R6=3F R7=00 raw=0x003F status=0x00 src=0 div=0x01 mode=0x00 oscen=0x00
I (201760) ulx3s_spi: SPI regs: R0=02 R1=00 R2=01 R3=00 R4=00 R5=00 R6=2E R7=7F raw=0x7F2E status=0x00 src=0 div=0x01 mode=0x00 oscen=0x00
I (202760) ulx3s_spi: SPI regs: R0=00 R1=00 R2=01 R3=00 R4=00 R5=00 R6=4F R7=97 raw=0x974F status=0x00 src=0 div=0x01 mode=0x00 oscen=0x00
I (203760) ulx3s_spi: SPI regs: R0=00 R1=00 R2=01 R3=00 R4=00 R5=00 R6=33 R7=9F raw=0x9F33 status=0x00 src=0 div=0x01 mode=0x00 oscen=0x00
I (204760) ulx3s_spi: SPI regs: R0=02 R1=00 R2=01 R3=00 R4=00 R5=00 R6=FC R7=33 raw=0x33FC status=0x00 src=0 div=0x01 mode=0x00 oscen=0x00
I (205760) ulx3s_spi: SPI regs: R0=00 R1=00 R2=01 R3=00 R4=00 R5=00 R6=1C R7=FC raw=0xFC1C status=0x00 src=0 div=0x01 mode=0x00 oscen=0x00
I (206760) ulx3s_spi: SPI regs: R0=00 R1=00 R2=01 R3=00 R4=00 R5=00 R6=6F R7=1C raw=0x1C6F status=0x00 src=0 div=0x01 mode=0x00 oscen=0x00
I (207760) ulx3s_spi: SPI regs: R0=00 R1=00 R2=01 R3=00 R4=00 R5=00 R6=03 R7=6F raw=0x6F03 status=0x00 src=0 div=0x01 mode=0x00 oscen=0x00
I (208760) ulx3s_spi: SPI regs: R0=02 R1=00 R2=01 R3=00 R4=00 R5=00 R6=96 R7=06 raw=0x0696 status=0x00 src=0 div=0x01 mode=0x00 oscen=0x00
I (209760) ulx3s_spi: SPI regs: R0=00 R1=00 R2=01 R3=00 R4=00 R5=00 R6=7D R7=4B raw=0x4B7D status=0x00 src=0 div=0x01 mode=0x00 oscen=0x00
I (210760) ulx3s_spi: SPI regs: R0=00 R1=00 R2=01 R3=00 R4=00 R5=00 R6=A5 R7=FA raw=0xFAA5 status=0x00 src=0 div=0x01 mode=0x00 oscen=0x00
I (211760) ulx3s_spi: SPI regs: R0=00 R1=00 R2=01 R3=00 R4=00 R5=00 R6=C8 R7=52 raw=0x52C8 status=0x00 src=0 div=0x01 mode=0x00 oscen=0x00
I (212760) ulx3s_spi: SPI regs: R0=00 R1=00 R2=01 R3=00 R4=00 R5=00 R6=AD R7=91 raw=0x91AD status=0x00 src=0 div=0x01 mode=0x00 oscen=0x00
I (213760) ulx3s_spi: SPI regs: R0=02 R1=00 R2=01 R3=00 R4=00 R5=00 R6=6F R7=AD raw=0xAD6F status=0x00 src=0 div=0x01 mode=0x00 oscen=0x00
I (214760) ulx3s_spi: SPI regs: R0=02 R1=00 R2=01 R3=00 R4=00 R5=00 R6=BC R7=DF raw=0xDFBC status=0x00 src=0 div=0x01 mode=0x00 oscen=0x00
I (215760) ulx3s_spi: SPI regs: R0=04 R1=00 R2=01 R3=00 R4=00 R5=00 R6=00 R7=00 raw=0x0000 status=0x00 src=0 div=0x01 mode=0x00 oscen=0x00
I (216760) ulx3s_spi: SPI regs: R0=02 R1=00 R2=01 R3=00 R4=00 R5=00 R6=3F R7=00 raw=0x003F status=0x00 src=0 div=0x01 mode=0x00 oscen=0x00
I (217760) ulx3s_spi: SPI regs: R0=02 R1=00 R2=01 R3=00 R4=00 R5=00 R6=2E R7=7F raw=0x7F2E status=0x00 src=0 div=0x01 mode=0x00 oscen=0x00
I (218760) ulx3s_spi: SPI regs: R0=00 R1=00 R2=01 R3=00 R4=00 R5=00 R6=4F R7=97 raw=0x974F status=0x00 src=0 div=0x01 mode=0x00 oscen=0x00
I (219760) ulx3s_spi: SPI regs: R0=00 R1=00 R2=01 R3=00 R4=00 R5=00 R6=33 R7=9F raw=0x9F33 status=0x00 src=0 div=0x01 mode=0x00 oscen=0x00
I (220760) ulx3s_spi: SPI regs: R0=02 R1=00 R2=01 R3=00 R4=00 R5=00 R6=FC R7=33 raw=0x33FC status=0x00 src=0 div=0x01 mode=0x00 oscen=0x00
I (221760) ulx3s_spi: SPI regs: R0=00 R1=00 R2=01 R3=00 R4=00 R5=00 R6=1C R7=FC raw=0xFC1C status=0x00 src=0 div=0x01 mode=0x00 oscen=0x00
I (222760) ulx3s_spi: SPI regs: R0=02 R1=00 R2=01 R3=00 R4=00 R5=00 R6=6F R7=1C raw=0x1C6F status=0x00 src=0 div=0x01 mode=0x00 oscen=0x00
I (223760) ulx3s_spi: SPI regs: R0=00 R1=00 R2=01 R3=00 R4=00 R5=00 R6=03 R7=6F raw=0x6F03 status=0x00 src=0 div=0x01 mode=0x00 oscen=0x00
I (224760) ulx3s_spi: SPI regs: R0=00 R1=00 R2=01 R3=00 R4=00 R5=00 R6=4B R7=03 raw=0x034B status=0x00 src=0 div=0x01 mode=0x00 oscen=0x00
I (225760) ulx3s_spi: SPI regs: R0=00 R1=00 R2=01 R3=00 R4=00 R5=00 R6=7D R7=4B raw=0x4B7D status=0x00 src=0 div=0x01 mode=0x00 oscen=0x00
I (226760) ulx3s_spi: SPI regs: R0=02 R1=00 R2=01 R3=00 R4=00 R5=00 R6=A5 R7=FA raw=0xFAA5 status=0x00 src=0 div=0x01 mode=0x00 oscen=0x00
I (227760) ulx3s_spi: SPI regs: R0=00 R1=00 R2=01 R3=00 R4=00 R5=00 R6=C8 R7=52 raw=0x52C8 status=0x00 src=0 div=0x01 mode=0x00 oscen=0x00
I (228760) ulx3s_spi: SPI regs: R0=00 R1=00 R2=01 R3=00 R4=00 R5=00 R6=AD R7=91 raw=0x91AD status=0x00 src=0 div=0x01 mode=0x00 oscen=0x00
I (229760) ulx3s_spi: SPI regs: R0=02 R1=00 R2=01 R3=00 R4=00 R5=00 R6=6F R7=AD raw=0xAD6F status=0x00 src=0 div=0x01 mode=0x00 oscen=0x00
I (230760) ulx3s_spi: SPI regs: R0=02 R1=00 R2=01 R3=00 R4=00 R5=00 R6=BC R7=DF raw=0xDFBC status=0x00 src=0 div=0x01 mode=0x00 oscen=0x00
I (231760) ulx3s_spi: SPI regs: R0=00 R1=00 R2=01 R3=00 R4=00 R5=00 R6=2A R7=EF raw=0xEF2A status=0x00 src=0 div=0x01 mode=0x00 oscen=0x00
```

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
cd "$TT_PROJECT_ROOT/test-hw    

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

It can be helpful to have a TTY-UART adapter on hand to interact with the FSM and TRNG on the FPGA or ASIC. This can be used to send commands and read responses from the FSM and TRNG.

<!-- ************************************************************************************************ -->

## UART FSM TRNG Lab Datasheet

Document revision: 0.1.6
RTL revision string: `Version 0.1.6 6/4/2026`  
Project family: Tiny Tapeout UART/SPI configurable TRNG experiment  
Primary top modules: `tt_um_gojimmypi_ttsky_UART_FSM_TRNG_Lab`, `tt_um_gojimmypi_ttgf_UART_FSM_TRNG_Lab`  
License: Apache-2.0, as declared in the source files

### 1. Overview

The UART FSM TRNG Lab is a Tiny Tapeout compatible experimental random-number and entropy-source project. It exposes a small register bank through an ASCII UART command interface and, when enabled, an SPI mode 0 register-access interface. The design is intended for laboratory bring-up, education, FPGA validation, and ASIC ring-oscillator entropy experiments.

The core supports multiple sample sources:

- Deterministic LFSR source for repeatable tests
- Single ring-oscillator sample source
- XOR of multiple ring-oscillator sources
- Mixed source combining ring-oscillator and LFSR-derived state

The design is not a certified cryptographic random number generator. Raw output should be characterized, health-tested, and conditioned before use in security-sensitive systems.

### 2. Key Features

- Tiny Tapeout standard digital pin interface
- UART RX/TX control path using ASCII commands
- Optional SPI register-access slave
- SPI mode 0, MSB first
- Shared UART and SPI register bank
- 8-byte logical register map
- Configurable sample divider
- Selectable entropy/sample source
- Ring oscillator enable mask
- Deterministic single-step mode for test reproducibility
- Reset control through a configuration bit
- Default 25 MHz project clock
- Default 115200 baud UART
- ASIC real ring-oscillator path for selected PDK builds
- FPGA/simulation-safe LFSR tap substitute when real ring oscillators are disabled

### 3. Design Status and Intended Use

This block is intended as an experimental TRNG lab core. It is suitable for:

- Tiny Tapeout project demonstration
- FPGA bring-up on ULX3S or similar wrappers
- UART command parser testing
- SPI register interface testing
- Ring oscillator experimentation in supported ASIC flows
- Deterministic regression testing using the LFSR source

It is not, by itself, suitable as a drop-in cryptographic RNG. The raw output is unconditioned and no formal entropy claim is made in this datasheet.

### 4. Source Files

The main RTL files are:

| File | Purpose |
| --- | --- |
| `project.v` | Top-level Tiny Tapeout project wrapper and project feature defines |
| `project_config.v` | Project clock and UART baud configuration |
| `target_pdk.v` | PDK target selection |
| `tt_um_main.v` | Tiny Tapeout pin mapping and UART/SPI/TRNG integration |
| `UART/uart_rx_min.v` | Minimal UART receiver |
| `UART/uart_tx_min.v` | Minimal UART transmitter |
| `UART/uart_trng_ascii_core.v` | UART and TRNG integration core |
| `TRNG/trng_cfg_ascii_core.v` | ASCII command parser and register bank |
| `TRNG/trng_lab_core.v` | Experimental TRNG/lab source logic |
| `TRNG/trng_stub.v` | Stub/test TRNG replacement when the lab core is not enabled |
| `SPI/spi_slave.v` | SPI mode 0 register-access slave |
| `JTAG/jtag_core.v` | Optional JTAG-related logic |

### 5. Top-Level Parameters

| Parameter | Default | Description |
| --- | ---: | --- |
| `CLOCK_HZ` | `25000000` | Project clock frequency in Hz |
| `UART_BAUD` | `115200` | UART baud rate |

The source contains parameter checks that intentionally fail elaboration if either parameter is zero or if `CLOCK_HZ / UART_BAUD` would be zero.

The `ULX3S_USE_GN12_50MHZ` configuration path can set `PROJECT_CLOCK_HZ` to 50 MHz for the optional ULX3S `gn12` clock path. Normal builds use the 25 MHz project clock.

### 6. Build-Time Feature Defines

| Define | Purpose |
| --- | --- |
| `UART_ENABLED` | Enables UART-related integration |
| `SPI_ENABLED` | Enables the SPI slave pin path |
| `SPI_REG_ACCESS` | Enables SPI access to the shared register bank |
| `TRNG_ENABLED` | Selects the TRNG lab core instead of the stub core |
| `JTAG_ENABLED` | Enables JTAG-related build integration |
| `USE_LONG_STRINGS` | Enables the long version string reply path |
| `TRNG_USE_RO` | Requests the real ring-oscillator TRNG path |
| `TRNG_ALLOW_REAL_RO` | Explicit guard required with `TRNG_USE_RO` |
| `PDK_TARGET_SKY130` | Selects SKY130 inverter cell instantiation |
| `PDK_TARGET_GF180` | Selects GF180 inverter cell instantiation |
| `ULX3S` | Selects ULX3S FPGA wrapper/build behavior |

For ULX3S builds, the source intentionally rejects `TRNG_USE_RO` and `TRNG_ALLOW_REAL_RO`. FPGA and normal simulation paths use deterministic LFSR-derived substitutes for the ring oscillator signals.

### 7. Functional Block Diagram

```text
              Tiny Tapeout pins
                    |
                    v
              tt_um_main.v
                    |
        +-----------+------------+
        |                        |
        v                        v
  UART RX/TX path          Optional SPI path
  uart_rx_min.v            spi_slave.v
  uart_tx_min.v                  |
        |                        |
        +-----------+------------+
                    |
                    v
          trng_cfg_ascii_core.v
          ASCII parser + registers
                    |
                    v
            trng_lab_core.v
       LFSR / RO / mixed sampling
                    |
                    v
       status, raw low byte, raw high byte
```

### 8. Clock and Reset

| Signal | Active level | Description |
| --- | --- | --- |
| `clk` | Rising edge | Main synchronous project clock |
| `rst_n` | Low | Global reset |

On reset, the register bank is initialized as shown below:

| Register | Reset value |
| --- | ---: |
| `reg_ctrl` | `0x00` |
| `reg_src` | `0x00` |
| `reg_div` | `0x10` |
| `reg_mode` | `0x00` |
| `reg_oscen` | `0x01` |

The TRNG lab core internally resets the LFSR to `0x1ACE`, clears `sample_shift`, clears the sample counter, clears status, and clears raw output registers.

### 9. Tiny Tapeout Pin Map

#### Dedicated inputs: `ui_in[7:0]`

| Pin | Direction | Function |
| --- | --- | --- |
| `ui_in[7:5]` | Input | Reserved / unused |
| `ui_in[4]`   | Input | SPI/JTAG select, 1 = SPI, 0 = JTAG |
| `ui_in[3]`   | Input | UART RX |
| `ui_in[2:0]` | Input | Reserved / unused |

The UART RX input is synchronized through a two-stage synchronizer before it enters the UART receive logic.

#### Dedicated outputs: `uo_out[7:0]`

| Pin | Direction | Function |
| --- | --- | --- |
| `uo_out[0]` | Output | `trng_bit` |
| `uo_out[1]` | Output | `reg_status[0]` |
| `uo_out[2]` | Output | `reg_status[1]` |
| `uo_out[3]` | Output | `reg_status[2]` |
| `uo_out[4]` | Output | UART TX |
| `uo_out[5]` | Output | `reg_rawlo[0]` |
| `uo_out[6]` | Output | `reg_rawlo[1]` |
| `uo_out[7]` | Output | `reg_rawlo[2]` |

#### Bidirectional IO: `uio[7:0]` when SPI is enabled

| Pin | Direction | Function |
| --- | --- | --- |
| `uio[0]` | Input | SPI CS_N |
| `uio[1]` | Input | SPI MOSI |
| `uio[2]` | Output | SPI MISO |
| `uio[3]` | Input | SPI SCK |
| `uio[7:4]` | Output | `reg_rawhi[7:4]` debug visibility |

When SPI is enabled, `uio_oe` is driven as `0xF4`, making `uio[2]` and `uio[7:4]` outputs while leaving `uio[0]`, `uio[1]`, and `uio[3]` as inputs.

#### Bidirectional IO when SPI is disabled

When SPI is not enabled, `uio_out[7:0]` drives the full `reg_rawhi` byte and `uio_oe` is driven as `0xFF`.

### 10. UART Interface

#### UART settings

| Setting | Value |
| --- | --- |
| Baud rate | `UART_BAUD`, default 115200 |
| Data bits | 8 |
| Parity | None |
| Stop bits | 1 |
| Byte order | ASCII command bytes |
| Command terminator | Carriage return, `0x0D` |

Line feed, `0x0A`, is ignored in command wait states, allowing common CRLF terminal behavior.

#### UART command summary

| Command | Arguments | Effect | Reply |
| --- | --- | --- | --- |
| `E0` / `E1` | 1 hex nibble | Write `reg_ctrl[0]`, TRNG enable | `OK<CR>` |
| `Sx` | 1 hex nibble | Write `reg_src[1:0]` | `OK<CR>` |
| `Vx` | 1 hex nibble | Write `reg_ctrl[1]`, deterministic single-step request | `OK<CR>` |
| `Wx` | 1 hex nibble | Write `reg_ctrl[2]`, TRNG reset control | `OK<CR>` |
| `Dxx` | 2 hex nibbles | Write `reg_div[7:0]` | `OK<CR>` |
| `Mxx` | 2 hex nibbles | Write `reg_mode[7:0]` | `OK<CR>` |
| `Oxx` | 2 hex nibbles | Write `reg_oscen[7:0]` | `OK<CR>` |
| `Rn` | `n = 0..7` | Read register `n` | `Rn=HH<CR>` |
| `V` | None | Version query | Version string + `<CR>` |

Invalid syntax returns `?<CR>`.

#### UART command examples

```text
V<CR>       -> Version 0.1.6 6/4/2026<CR>
R2<CR>      -> R2=10<CR>
E1<CR>      -> OK<CR>
D10<CR>     -> OK<CR>
S0<CR>      -> OK<CR>
O01<CR>     -> OK<CR>
R6<CR>      -> R6=HH<CR>
R7<CR>      -> R7=HH<CR>
```

To reconstruct the current 16-bit raw sample from UART register reads:

```text
raw16 = (R7 << 8) | R6
```

### 11. SPI Interface

The SPI interface is available when `SPI_ENABLED` and `SPI_REG_ACCESS` are enabled.

#### SPI electrical/protocol settings

| Setting | Value |
| --- | --- |
| Mode | SPI mode 0 |
| CPOL | 0 |
| CPHA | 0 |
| Bit order | MSB first |
| Chip select | Active low, `CS_N` |
| Register address width | 3 bits |

#### SPI command byte

| Bit field | Description |
| --- | --- |
| `bit[7]` | `1` = read, `0` = write |
| `bit[6:3]` | Ignored |
| `bit[2:0]` | Register address `0..7` |

#### SPI read transaction

```text
byte 0: 0x80 | addr
byte 1: dummy byte; returned MISO byte is the register value
```

For example, reading `reg_rawlo` at address 6:

```text
TX: 86 00
RX: xx HH
```

The useful read value is the second received byte.

#### SPI write transaction

```text
byte 0: addr
byte 1: data byte
```

Only addresses 0 through 4 are writable. Writes to addresses 5 through 7 are ignored by the register bank.

For example, writing divider register `R2 = 0x10`:

```text
TX: 02 10
```

### 12. Register Map

| Addr | UART read | Name | Access | Reset | Description |
| ---: | --- | --- | --- | ---: | --- |
| 0 | `R0` | `reg_ctrl` | R/W | `0x00` | Control bits |
| 1 | `R1` | `reg_src` | R/W | `0x00` | Source selection |
| 2 | `R2` | `reg_div` | R/W | `0x10` | Sample divider |
| 3 | `R3` | `reg_mode` | R/W | `0x00` | Mode/debug field |
| 4 | `R4` | `reg_oscen` | R/W | `0x01` | Ring oscillator enable mask |
| 5 | `R5` | `reg_status` | Read-only | `0x00` | Status mirror |
| 6 | `R6` | `reg_rawlo` | Read-only | `0x00` | Raw sample low byte |
| 7 | `R7` | `reg_rawhi` | Read-only | `0x00` | Raw sample high byte |

### 13. Control Register: `reg_ctrl`, Address 0

| Bit | Name | Description |
| ---: | --- | --- |
| 0 | `enable` | Enables periodic sampling when set |
| 1 | `step` | Deterministic single-step request. A rising edge creates one sample event |
| 2 | `reset` | Resets the TRNG lab core while asserted |
| 7:3 | Reserved | Currently unused |

UART aliases:

| Command | Field |
| --- | --- |
| `E0` / `E1` | `reg_ctrl[0]` |
| `V0` / `V1` | `reg_ctrl[1]` |
| `W0` / `W1` | `reg_ctrl[2]` |

Note: bare `V<CR>` is the version query. `V0<CR>` and `V1<CR>` are control writes.

### 14. Source Register: `reg_src`, Address 1

Only `reg_src[1:0]` is used.

| Value | Source | Description |
| ---: | --- | --- |
| `0` | `SRC_LFSR` | LFSR bit source, deterministic and repeatable |
| `1` | `SRC_RO0` | Sampled ring oscillator 0 source |
| `2` | `SRC_ROX` | XOR of the ring oscillator raw bits |
| `3` | `SRC_MIX` | Mixed source using RO XOR, LFSR taps, and sample history |

UART alias: `Sx<CR>` writes `reg_src[1:0]`.

### 15. Divider Register: `reg_div`, Address 2

`reg_div` controls the periodic sample interval when `reg_ctrl[0]` is enabled. The internal sample counter increments while enabled. A sample event is generated when:

```text
sample_ctr >= reg_div
```

A single-step event through `reg_ctrl[1]` can also generate a sample event without waiting for the periodic divider.

UART alias: `Dxx<CR>` writes the full divider byte.

### 16. Mode Register: `reg_mode`, Address 3

`reg_mode` is a full 8-bit writable register. In the current TRNG lab core, `reg_mode[2:0]` is mirrored into `reg_status[7:5]`. Other bits are reserved for future use.

UART alias: `Mxx<CR>` writes the full mode byte.

### 17. Oscillator Enable Register: `reg_oscen`, Address 4

`reg_oscen` is an 8-bit enable mask for the ring oscillator instances in real RO builds.

| Bit | Real RO instance | Stage count |
| ---: | --- | ---: |
| 0 | `u_ro0` | 3 |
| 1 | `u_ro1` | 5 |
| 2 | `u_ro2` | 7 |
| 3 | `u_ro3` | 9 |
| 4 | `u_ro4` | 11 |
| 5 | `u_ro5` | 13 |
| 6 | `u_ro6` | 15 |
| 7 | `u_ro7` | 17 |

In FPGA and normal simulation builds, the RO raw bits are derived from LFSR taps instead of real ring oscillators.

UART alias: `Oxx<CR>` writes the full oscillator enable mask.

### 18. Status Register: `reg_status`, Address 5

| Bit field | Description |
| --- | --- |
| `bit[0]` | Mirrors TRNG enable |
| `bit[1]` | Mirrors sample tick condition |
| `bit[2]` | Indicates at least one oscillator enable bit is set |
| `bits[4:3]` | Mirrors source selection |
| `bits[7:5]` | Mirrors `reg_mode[2:0]` |

`reg_status` is read-only from the external UART/SPI register interfaces.

### 19. Raw Output Registers: `reg_rawlo` and `reg_rawhi`

The TRNG lab core maintains a 16-bit sample shift register. On each sample event, the selected source bit is shifted into the sample history and the raw output registers are updated.

| Register | Description |
| --- | --- |
| `reg_rawlo` | Low byte of the latest raw sample history |
| `reg_rawhi` | High byte of the latest raw sample history |

The current 16-bit raw sample value is reconstructed as:

```text
raw16 = (reg_rawhi << 8) | reg_rawlo
```

### 20. Sampling Behavior

A sample event occurs when either condition is true:

```text
do_sample = (enable && sample_tick) || step_pulse
```

Where:

```text
sample_tick = sample_ctr >= reg_div
step_pulse  = reg_ctrl[1] && !previous_reg_ctrl_bit_1
```

On each sample event:

- `sample_ctr` is cleared to zero
- The 16-bit LFSR advances
- The selected source bit shifts into `sample_shift`
- `reg_rawlo` and `reg_rawhi` are updated

When enable is deasserted, the sample counter is held at zero. A single-step pulse can still advance one sample.

### 21. LFSR Details

The deterministic LFSR path is used for repeatable tests and for FPGA/simulation-safe substitute RO signals. On TRNG reset, the LFSR seed is:

```text
0x1ACE
```

The next LFSR bit is computed as:

```text
lfsr_next_bit = lfsr[15] ^ lfsr[13] ^ lfsr[12] ^ lfsr[10]
```

The LFSR then shifts as:

```text
lfsr <= {lfsr[14:0], lfsr_next_bit}
```

This path is deterministic and should not be treated as an entropy source.

### 22. Ring Oscillator Path

In real ASIC RO builds, the design instantiates eight odd-length ring oscillators with stage counts from 3 to 17. The oscillator outputs feed the source selection logic through synchronizers.

In FPGA and normal simulation builds, real ring oscillators are not instantiated. Instead, the RO raw signals are mapped to LFSR taps so the rest of the design can be tested safely without combinational oscillator loops.

Supported real RO PDK cell paths in the current source are:

| PDK define | Inverter cell |
| --- | --- |
| `PDK_TARGET_SKY130` | `sky130_fd_sc_hd__inv_2` |
| `PDK_TARGET_GF180` | `gf180mcu_fd_sc_mcu7t5v0__inv_1` |

### 23. Recommended Bring-Up Sequence

A conservative UART bring-up sequence is:

```text
V<CR>       Read version string
R0<CR>      Confirm control reset value
R1<CR>      Confirm source reset value
R2<CR>      Confirm divider reset value, expected 10
R3<CR>      Confirm mode reset value
R4<CR>      Confirm oscillator enable reset value, expected 01
S0<CR>      Select deterministic LFSR source
D10<CR>     Set divider to 0x10
M00<CR>     Clear mode
O01<CR>     Enable oscillator mask bit 0
E1<CR>      Enable sampling
R6<CR>      Read raw low byte
R7<CR>      Read raw high byte
```

For deterministic regression testing, use source `S0`, assert and release reset through `W1` and `W0`, then issue single-step pulses through `V1` and `V0` as required by the test harness.

### 24. Known Deterministic Regression Sequence

With the deterministic LFSR path and the established single-step/reset test flow, the known-good 16-bit sample sequence used in current hardware regression is:

```text
sample 01: 0x7F2E
sample 02: 0x9F33
sample 03: 0xFC1C
sample 04: 0x6F03
sample 05: 0x4B7D
sample 06: 0x52C8
sample 07: 0xD6B7
sample 08: 0xEF2A
```

This sequence is a reproducibility check for the deterministic path. It is not an entropy-quality claim.

### 25. UART and SPI Concurrency Notes

UART and SPI share the same logical register bank. SPI writes are applied when `spi_reg_wr_en` is asserted. UART commands also update the same configuration registers.

When using SPI as a passive monitor while UART is active, individual register reads are separate transactions. Reading `reg_rawlo` and `reg_rawhi` separately is not atomic, so the two bytes may occasionally come from adjacent sample updates. For exact sample capture, add an atomic snapshot/latch mechanism or temporarily stop sampling before reading both bytes.

### 26. Limitations

- No cryptographic certification is claimed.
- No built-in conditioner, extractor, or DRBG is provided by this RTL block.
- Raw RO entropy quality must be measured on the actual ASIC implementation.
- FPGA and normal simulation builds do not use real ring oscillators.
- SPI multi-byte reads of raw low/high registers are not atomic.
- UART command parsing is intentionally small and accepts only the documented command forms.
- Register addresses 5 through 7 are read-only through SPI writes and UART write aliases do not target them.

### 27. Characterization Recommendations

Before using ASIC RO output as a source of entropy, characterize at minimum:

- Raw bit bias for each source selection
- Bit transition rate
- Autocorrelation
- Per-oscillator behavior across voltage and temperature
- Behavior across process corners and multiple chips
- Startup behavior after reset
- Sensitivity to `reg_div` and `reg_oscen`
- Health test behavior under stuck oscillator conditions

For security use, add a conditioning function and a health-test strategy appropriate for the target application.

### 28. Revision History

| Datasheet rev | Date | Notes |
| --- | --- | --- |
| 0.1 | 2026-05-23 | Initial datasheet generated from current TRNG source package |

