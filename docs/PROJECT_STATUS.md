# Project Status

Project name: `ADRET740A_CPU`

The current firmware is a compile-tested and bench-tested low-level
front-panel base for the Arduino Mega / ATmega2560 replacement CPU.

## Done

- PlatformIO project for `megaatmega2560`.
- Front-panel data bus on full 8-bit PORTA.
- Front-panel control nibble on consecutive PORTB bits by default.
- CA2 active-low address-enable handling for the 74LS138.
- CA1 interrupt source shared by keyboard and optical wheel events.
- Static `PROGMEM` placeholder for the 2716 calibration EPROM dump.
- Bench-validated LED scan through SN2, SN3, SN4, and SN17.
- High-level front-panel state layer for LEDs, display buffers, keyboard FIFO,
  and optical wheel accumulation.
- Named front-panel indicators with exclusive hardware groups reflected in the
  API behavior.
- Keyboard matrix mapping from the provisional front-panel table/image, while
  preserving raw SN5 samples.
- Bench-validated paired PORTA harness across Mega pins 22..29.
- ICM7218A Code B full-frame output for SN10/Y7 and SN11/Y6.
- Bench-validated ten-digit frequency split and three-digit modulation and
  amplitude groups, with active-low decimal-point handling.
- Bench-validated keyboard labels on Serial0 with unknown-code rejection and
  30 ms duplicate filtering.
- Ten-microsecond SN5 enable and startup acknowledgement sequence for CA1.
- PlatformIO build succeeds: RAM 452 bytes / 8192 bytes, Flash 5072 bytes /
  253952 bytes.

## Remaining Hardware Validation

- Long-term CA1 electrical stability and cold-start behavior.
- Exact left/right sign of the optical wheel delta.
- Individual decimal-point placement and SN4 special leading characters.
- High-level API behavior beyond the current diagnostic scan.

## Current Optical Wheel Diagnostic

- The display counters no longer advance automatically; only the LED sweep
  remains timed at 200 ms.
- Each SN5 wheel event is retained in a fixed-size FIFO and reported on
  Serial0 as raw hexadecimal, D7..D0 binary, count, direction, interpreted
  step, signed total, and displayed frequency.
- The provisional polarity is D6 high = clockwise = +1. This remains to be
  confirmed at the bench and is centralized as
  `kFrontPanelEncoderClockwiseLevel` in `HardwareConfig.h`.
- Frequency decrements saturate at zero. Modulation and amplitude remain at
  zero during this diagnostic.

## Next Steps

1. Validate optical-wheel direction and accumulation.
2. Add decimal-point masks and SN4 leading-character APIs.
3. Exercise cold-start CA1 recovery repeatedly.
4. Replace the diagnostic loop with the first application state machine.
5. Replace placeholder EPROM data with the real 2716 calibration dump.
