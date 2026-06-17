
## How it works

Implements a basic GNSS receiver including functionality to synchronise in time and frequency with different GNSS constellations.

Works in conjunction with a GPS front end capable of providing single bit (and potentially multi bit I/Q streams along with an ADC sampling clock.

Design is targeting MAX2769 and MAX2771 from Analog Devices, though testing may not occur with hw due to time limitations.

A table of features and maturity is below:

| Requirement ID |  State | Description |
| :---: | :---: | :--- |
| 1.0 | ☑️ | Support search for acquisition |
| 1.1 | ☑️ | Generate Gold Codes for GPS L1 | 
| 1.2 | ☑️ | Generate NCO for frequency correction |
| 1.3 | ☑️ | Generate timing signal for frame |
| 2.0 | ☑️ | Provide SPI slave interface for command and control |
| 2.1 | ☑️ | support clock domain crossing between SPI clock and sample clock |
| 2.2 | ☑️ | Provide readback for acquisition registers |
| 2.3 | ☑️ | provide readback for tracking registers |
| 3.0 | ☑️ | Enable tracking channel for time, freq, sv settings |
| 3.1 | ☑️ | provide update mechanism for tracking channels |
| 3.2 | ☑️ | provide early/mid/late tracking for tracking channels to improve acquition performance |
| 3.3 | ❌ | support selectable correlation duration


## How to test

Will need a custom load on the RP2050 on the TT development kit to manage software interactions.

Needs a source of GNSS data, either recorded or simulated, look in /data for example data

## External hardware

Custom MAX2769 or MAX2771 board required, SPI interface to RP2050 for configuration and control.
