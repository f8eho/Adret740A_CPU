# Project Status

Project name: `ADRET740A_CPU`

The hardware test environment is not ready yet. The current firmware is a
compile-tested low-level and front-panel state base for the Arduino Mega /
ATmega2560 replacement CPU.

## Done

- PlatformIO project for `megaatmega2560`.
- Front-panel data bus on full 8-bit PORTA.
- Front-panel control nibble on consecutive PORTB bits by default.
- CA2 active-low address-enable handling for the 74LS138.
- CA1 interrupt source shared by keyboard and optical wheel events.
- Static `PROGMEM` placeholder for the 2716 calibration EPROM dump.
- First LED debug phase for SN2/SN3 output validation.
- High-level front-panel state layer for LEDs, display buffers, keyboard FIFO,
  and optical wheel accumulation.
- Named front-panel indicators with exclusive hardware groups reflected in the
  API behavior.
- Keyboard matrix mapping from the provisional front-panel table/image, while
  preserving raw SN5 samples.
- PlatformIO build succeeds: RAM 137 bytes / 8192 bytes, Flash 2308 bytes /
  253952 bytes.

## Not Yet Tested On Hardware

- Electrical polarity and timing of CA2 on the original front-panel decoder.
- LED decode mapping and active states.
- ICM7218A command/data sequencing.
- CA1 event timing and SN5 data validity window.
- Keyboard and optical wheel decoding.
- High-level front-panel API behavior against the real panel latches.
- Exact left/right sign of the optical wheel delta.
- SN10/SN11 ICM7218A display command/data sequence.

## Next Steps

1. Validate pin wiring on the test harness.
2. Run the LED debug phase and compare SN2/SN3 outputs with the front panel.
3. Validate the high-level LED API against SN2/SN3 active states.
4. Add a minimal ICM7218A display test pattern.
5. Capture CA1/SN5 timing for keyboard and optical wheel events.
6. Replace placeholder EPROM data with the real 2716 calibration dump.
