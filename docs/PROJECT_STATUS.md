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
- Bench-corrected independent SN3 indicators: active-low D1 drives `MEM` and
  active-low D0 drives `SEQ`.
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
- Bounded runtime CA1 recovery: after a missed acknowledgement, at most four
  extra SN5 reads are attempted and reported as `CA1_RECOVERED` or
  `CA1_STUCK_LOW` on Serial0.
- Late CA1 edges are left pending for the next poll instead of being consumed
  by recovery. A distinct keyboard sample found during acknowledgement
  recovery is queued rather than discarded, and routine one-read recovery
  reports are rate-limited on Serial0.
- Allocation-free operating controller for frequency, amplitude, FM, PM and
  AM adjustment with independent decade steps.
- Functional RF OFF, VALID MAN, CW/400 Hz/1 kHz/EXT and parameter-selection
  keys, with simulated instrument commands on Serial0.
- Per-digit ICM7218A decimal-point and blank masks for non-blocking step-digit
  blinking.
- Two-slot, versioned EEPROM settings storage with CRC and forced RF OFF at
  startup.
- Allocation-free deferred numeric entry with unit validation, correction,
  EXEC transactions and active/prepared configuration views. RF keyboard
  entry and display expose the hertz digit; that digit is forced to zero when
  the value is prepared because the generator applies 10 Hz steps.
- Forty independently CRC-protected EEPROM memories, v2 settings migration,
  recall and keyboard-driven memory sequences.
- Allocation-free per-parameter keyboard increments, with deferred RF
  lower-limit validation and immediate UP/DOWN instrument transactions.
- Sequence entry requires its first limit digit within two seconds of `SEQ`,
  then leaves the remaining three digits untimed.
- Sequence UP/DOWN navigation saturates silently at its end/start positions
  without re-executing the boundary memory or raising `E-89`.
- PlatformIO normal build succeeds: RAM 471 bytes / 8192 bytes, Flash 19664
  bytes / 253952 bytes. Serial debug build succeeds with 750 bytes RAM and
  24468 bytes Flash.

## Remaining Hardware Validation

- Long-term CA1 electrical stability and cold-start behavior.
- Exact left/right sign of the optical wheel delta.
- Individual decimal-point placement and SN4 special leading characters.
- High-level API behavior beyond the current diagnostic scan.

## Current Functional Diagnostic

- Serial0 diagnostics are compile-time controlled by `ADRET_DEBUG_SERIAL` in
  `platformio.ini`. The normal build sets it to `0`; changing it to `1`
  restores all current `KEY`, `ENTRY`, `PENDING`, `INSTR`, EEPROM and CA1
  traces at 115200 baud.
- The temporary EXEC indicator sweep has been removed after bench validation.
  Raw SN3 D3..D2 codes are 0=blinking, 1=off, 2=fixed and 3=off; the normal
  firmware uses codes 0, 1 and 2.
- Each SN5 wheel event is retained in a fixed-size FIFO. Per-step raw traces
  and ignored-step diagnostics have been removed from Serial0 after bench
  validation.
- The provisional polarity is D6 high = clockwise = +1. This remains to be
  confirmed at the bench and is centralized as
  `kFrontPanelEncoderClockwiseLevel` in `HardwareConfig.h`.
- The displayed selection and wheel target are independent. VALID MAN assigns
  the displayed selection to the wheel without toggling an already active
  target; all values saturate at their documented limits.
- Indicator-only refreshes preserve amplitude signs, special leading digits,
  decimal points and the current EXEC mode. Bench validation is still required
  for VALID MAN and RF OFF while an entry is pending.
- The active-low SN4/D5 REM indicator is forced off by default and reserved for
  a possible future Serial0 remote mode; no GPIB hardware is planned.
- MUL10 and DIV10 select the decade and blink the affected digit three times.
- Instrument-bus writes are currently represented by `INSTR` lines on
  Serial0.
- PA is reserved on Mega D3 / PE5 / INT5 but monitoring remains disabled until
  its voltage and polarity are validated at the bench.
- Numeric entry, EXEC fixed/blinking modes, Code B status messages and memory
  sequence behavior compile successfully but still require panel bench tests.
- Keyboard increments are stored separately for RF, amplitude, FM, PM and AM;
  active sequences retain priority over UP/DOWN. End-to-end bench validation
  remains pending.

## Next Steps

1. Validate optical-wheel direction and all display boundary formats.
2. Measure PA voltage, polarity and power-fail hold-up time before enabling it.
3. Exercise cold-start CA1 recovery repeatedly.
   The application adds only about 120 us of startup acknowledgement; the
   cold-power delay observed at the bench does not occur on a warm reset and
   must be localized between the 5 V rail, RESET and the first CA2 activity.
4. Implement the instrument-bus output layer behind the current serial events.
5. Validate keypad entry, EXEC/MEM/SEQ indicators and Code B `P`, `E` and `-`
   messages on the real panel.
6. Add keyboard increments, AUX sequence stepping and replace the placeholder
   calibration EPROM.
