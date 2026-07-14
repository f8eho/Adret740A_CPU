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
- Allocation-free operating controller for frequency, amplitude, FM, PM and
  AM adjustment with independent decade steps.
- Functional RF OFF, VALID MAN, CW/400 Hz/1 kHz/EXT and parameter-selection
  keys, with simulated instrument commands on Serial0.
- Per-digit ICM7218A decimal-point and blank masks for non-blocking step-digit
  blinking.
- Two-slot, versioned EEPROM settings storage with CRC and forced RF OFF at
  startup.
- PlatformIO build succeeds: RAM 606 bytes / 8192 bytes, Flash 11832 bytes /
  253952 bytes.

## Remaining Hardware Validation

- Long-term CA1 electrical stability and cold-start behavior.
- Exact left/right sign of the optical wheel delta.
- Individual decimal-point placement and SN4 special leading characters.
- High-level API behavior beyond the current diagnostic scan.

## Current Functional Diagnostic

- The former automatic display and LED sweep has been removed.
- Each SN5 wheel event is retained in a fixed-size FIFO and reported on
  Serial0 as raw hexadecimal, D7..D0 binary, count, direction, interpreted
  step and signed diagnostic total.
- The provisional polarity is D6 high = clockwise = +1. This remains to be
  confirmed at the bench and is centralized as
  `kFrontPanelEncoderClockwiseLevel` in `HardwareConfig.h`.
- The displayed selection and wheel target are independent. VALID MAN assigns
  the displayed selection to the wheel without toggling an already active
  target; all values saturate at their documented limits.
- MUL10 and DIV10 select the decade and blink the affected digit three times.
- Instrument-bus writes are currently represented by `INSTR` lines on
  Serial0.
- PA is reserved on Mega D3 / PE5 / INT5 but monitoring remains disabled until
  its voltage and polarity are validated at the bench.

## Next Steps

1. Validate optical-wheel direction and all display boundary formats.
2. Measure PA voltage, polarity and power-fail hold-up time before enabling it.
3. Exercise cold-start CA1 recovery repeatedly.
4. Implement the instrument-bus output layer behind the current serial events.
5. Add numeric keypad entry and replace the placeholder calibration EPROM.
