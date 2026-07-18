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
- Zero-filled 2 KiB signed-correction table in `PROGMEM`, reserving the full
  2716 calibration footprint without requiring an external memory component.
- Instrument-amplitude encoder for the original `6, 8, 6` write sequence,
  the 28 relay states and signed 0.1 dB calibration corrections.
- Allocation-free AM/FM/PM instrument-bus encoder. All 7393 captured AM/FM
  writes match; PM follows the original EPROM path but lacks a capture.
- Pulse-modulation register encoder derived from both original EPROMs and the
  Approach/pulse/VHF schematics. Pulse uses address 5 D5 and address 6 D6;
  addresses 7 and 14 have zero writes in all decoded captures and no EPROM
  references.
- Transport-independent `InstrumentBus` API with a safe ISO1540/MCP23017
  backend at 400 kHz. Output latches are preloaded before IODIR changes,
  `Chargt` is pulsed through repeated `OLATB` writes, I2C timeouts are bounded,
  and runtime timing/error counters are retained for bench measurements.
- Allocation-free complete instrument-program composer connected to executed
  panel and remote configurations. It combines frequency, amplitude,
  modulation and RF inhibition in at most 21 writes while retaining the
  sixteen-register image across partial I2C failures.
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
- Allocation-free Serial0 remote protocol with the historical `F`, `A`, `RF`,
  modulation, memory and sequence mnemonics, atomic deferred transactions,
  local/remote lockout states and status/error responses.
- `Adr RTL` on SN12.X7 / SN14.Y5 returns from `REMS` to local, is ignored in
  `RWLS`, and has no address-display action in local mode.
- Serial0 command execution has been bench-validated with PuTTY using both
  the historical `?` terminator and `CR/LF` line endings.
- Host parser/framing and instrument-program vector tests pass. The single
  PlatformIO firmware succeeds with 1121 bytes RAM / 8192 bytes and 35314
  bytes Flash / 253952 bytes, including
  the deliberately retained 2048-byte zero calibration table.

## Remaining Hardware Validation

- Long-term CA1 electrical stability and cold-start behavior.
- Exact left/right sign of the optical wheel delta.
- Individual decimal-point placement and SN4 special leading characters.
- High-level API behavior beyond the current diagnostic scan.
- End-to-end Serial0 command sessions, `REM` indication, panel inhibition and
  `Adr RTL` behavior on the assembled instrument.

## Current Functional Diagnostic

- The firmware uses Serial0 at 115200 baud for remote commands. It sets
  `ADRET_REMOTE_SERIAL=1` and `ADRET_DEBUG_SERIAL=0`; a compile-time guard
  prevents diagnostic traces from sharing the command channel.
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
- The active-low SN4/D5 REM indicator follows the Serial0 remote state; no GPIB
  hardware is planned.
- MUL10 and DIV10 select the decade and blink the affected digit three times.
- The MCP23017 instrument-bus backend is initialized at startup. When present,
  executed state changes now emit the complete functional transaction; when
  absent, the front panel and remote protocol continue without bus writes.
- A 22.5 us low width for `Chargt` is accepted provisionally from the
  falling-edge protocol, trace outliers and the successful 10 us front-panel
  acknowledgement. It remains a bench measurement when components arrive.
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
4. Validate the Serial0 protocol and `Adr RTL` local return on the instrument.
5. Implement the instrument-bus output layer behind the current state changes.
6. Validate keypad entry, EXEC/MEM/SEQ indicators and Code B `P`, `E` and `-`
   messages on the real panel.
7. Add AUX sequence stepping and replace the zero calibration initializer
   with the table generated by the bench-calibration firmware.
