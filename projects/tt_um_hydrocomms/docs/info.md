<!---

This file is used to generate your project datasheet. Please fill in the information below and delete any unused
sections.

You can also include images in this folder and reference them in the markdown. Each image must be less than
512 kb in size, and the combined size of all images must be less than 1 MB.
-->

## How it works

This is a digital binary FSK modem designed for underwater acoustic communication in the 46-56 kHz band.

Data bytes are framed as the following:

 [preamble sync word payload CRC] 
 
Then each bit selects between two frequencies — 48 kHz (mark/1) and 54 kHz (space/0). 

Similar to the DDS algorithm, a numerically controlled oscillator (NCO) uses a 16-bit phase accumulator with a 32-entry sine lookup table to generate 8-bit samples at 200 kHz. 

There is also a CRC-8 for error detection on the 8-bit payload. 

On the receiving side, 8-bit ADC samples feed two parallel Goertzel filters at the chosen mark and space frequencies (48 and 54 kHz). A frame synchronizer detects the preamble/sync pattern, extracts the payload byte, and verifies the CRC.

SPI is the protocol used to interface with the design. 

There is a loopback mode to test the chip on its own, which is standard. 


## How to test

All 8 output pins expose these signals for hardware bring-up: 
- uo_out[1] RX_BYTE_VALID - Pulses once per decoded byte 
- uo_out[2] CRC_OK - High = good frame, low = corrupt 
- uo_out[3] PACKET_DETECTED - Goes high when sync word found 
- uo_out[4] TX_ACTIVE - High while transmitting 
- uo_out[5] SYMBOL_CLK - 100 Hz baud tick during TX 
- uo_out[6] MARK_GT_SPACE - Real-time Goertzel comparison 
- uo_out[7] SAMPLE_CLK - 200 kHz ADC/DAC sample clock 

These can be monitored with a logic analyzer or oscilloscope during bench testing.

To write a register, set bit 7 of the address byte. To read, send the plain address followed by a dummy byte, the register value comes back on MISO during the dummy byte.

Note: the link is half-duplex — a board cannot receive while it is transmitting, since TX output and RX input share the same 8 pins. Note also that the receiver has no symbol-timing recovery: the Goertzel blocks free-run, so board-to-board reception requires the block phase to land close to the symbol boundaries. 

Expect to need multiple frames (or a hardware retry loop) for the first sync in two-board tests.




## External hardware

List external hardware used in your project (e.g. PMOD, LED display, etc), if any
