# Project Status

Project name: `ADRET740A_CPU`

The hardware test environment is not ready yet. The current firmware is a
compile-tested low-level base for the Arduino Mega / ATmega2560 replacement CPU.

## Done

- PlatformIO project for `megaatmega2560`.
- Front-panel data bus on full 8-bit PORTA.
- Front-panel control nibble on consecutive PORTB bits by default.
- CA2 active-low address-enable handling for the 74LS138.
- CA1 interrupt source shared by keyboard and optical wheel events.
- Static `PROGMEM` placeholder for the 2716 calibration EPROM dump.
- First LED debug phase for SN2/SN3 output validation.

## Not Yet Tested On Hardware

- Electrical polarity and timing of CA2 on the original front-panel decoder.
- LED decode mapping and active states.
- ICM7218A command/data sequencing.
- CA1 event timing and SN5 data validity window.
- Keyboard and optical wheel decoding.

## Next Steps

1. Validate pin wiring on the test harness.
2. Run the LED debug phase and compare SN2/SN3 outputs with the front panel.
3. Add a minimal ICM7218A display test pattern.
4. Capture CA1/SN5 timing for keyboard and optical wheel events.
5. Replace placeholder EPROM data with the real 2716 calibration dump.
