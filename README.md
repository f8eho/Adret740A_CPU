# ADRET740A_CPU

[Version française](README_French.md)

![ADRET 740A prototype operating with the Arduino Mega CPU](docs/Photos/Proto%20en%20fonctionnement%201.jpg)

`ADRET740A_CPU` replaces the processor board of an Adret 740A RF signal
generator with an Arduino Mega 1280 or 2560. The project retains the original
front panel and analog RF boards; it replaces their controller, stores the
settings and adds ASCII remote control over a serial link.

The perfboard prototype is installed in a 740A and already controls the
generator. This repository contains the firmware, the complete KiCad wiring
schematic, calibration tools and detailed reverse-engineering results.

## What is the Adret 740A?

The Adret 740A is a synthesized RF signal generator intended for laboratory
and radio servicing work. The base version covers 100 kHz to 560 MHz with
10 Hz command resolution. An optional frequency doubler extends coverage to
1.12 GHz. The instrument also controls RF output level and provides AM, FM,
PM and pulse modulation.

Its RF section remains useful today: it is built around specialized analog
boards and an original frequency-synthesis design. Its control system,
however, relies on a 6802 processor board, two EPROMs and battery-backed
memory. That board communicates separately with the front panel and with an
internal sixteen-register bus controlling the instrument boards.

## Why replace the CPU board?

In my instrument, electrolyte leaked from the backup battery and destroyed the
CPU board. Given the age of these generators, the same failure may already
have affected—or may threaten—other units whose RF sections are still
repairable and useful.

The goal is therefore not to rebuild the entire 740A. It is to give its RF
boards, power supply and front panel a second life using available components,
readable firmware and documented wiring. Reverse engineering the EPROMs and
captured bus traffic makes it possible to reproduce frequency, level and
modulation commands without modifying the instrument boards.

## Why an Arduino Mega?

The Mega 1280/2560 is a practical compromise for this replacement:

- its ATmega uses 5 V logic, compatible with much of the 740A TTL/CMOS
  circuitry without adding level converters to every signal;
- it provides a complete 8-bit AVR port for the front panel, enough GPIO, a
  hardware I2C controller and an independent hardware UART;
- its pins are accessible and the board remains easy to obtain and replace;
- the Arduino framework simplifies non-critical functions, while
  timing-sensitive buses use the AVR registers directly;
- PlatformIO makes both targets, compiler options and diagnostic builds
  reproducible.

The Mega was not selected to turn the 740A into a basic Arduino project. It
primarily provides an accessible 5 V AVR platform with enough resources to
emulate the original board cleanly.

Porting the firmware to another platform remains possible—for example an
ESP32, STM32 or Raspberry Pi Pico. Because these microcontrollers generally
use 3.3 V logic, their GPIO cannot be connected directly to the front panel's
5 V bus. That side would require an additional isolated interface and a 5 V
I/O expander, as well as the existing instrument-bus interface, followed by an
adaptation of the low-level hardware backend and its timing. Most of the
high-level functional logic could remain unchanged.

## Architecture

```text
                       5 V CPU domain

 front panel <------ PORTA/PORTB ------ Arduino Mega 1280/2560
                                             |
                                             | 400 kHz I2C
                                             v
                                        ISO1540 side 1
                                 - - galvanic isolation - -
                                        ISO1540 side 2
                                             |
                                             v
                                         MCP23017
                                  8 data + 4 address bits
                                       + Chargt strobe
                                             |
                                             v
                                  5 V instrument-card bus
                                   isolated instrument domain

 Serial0 D0/D1 <------------- 115200-baud ASCII remote control
```

### Front panel

The front-panel data bus is connected directly to `PORTA` (Mega pins 22 to
29). `PORTB` selects the latches, displays, indicators, keyboard and optical
wheel. Direct AVR register access avoids the overhead and jitter of
`digitalWrite()`.

### ISO1540 and MCP23017 adapter

The instrument bus is not merely an extension of the front-panel bus. It
belongs to a separate power and ground domain. Connecting it directly to the
Mega would defeat this separation and could create ground currents or damage
the instrument, development board or test equipment.

The ISO1540 isolates the I2C SDA and SCL lines. The instrument-side MCP23017
then converts I2C into the parallel bus expected by the 740A:

- `GPA0..7` carry the eight data bits;
- `GPB0..3` carry the four address bits;
- `GPB4` generates the active-low `Chargt` signal, whose falling edge stores
  the command in the selected board.

The ISO1540 does **not** isolate power. Its side 2 and the MCP23017 use the
instrument domain's `+5V_INST` and `GND_INST`, which remain separate from the
Mega's `+5V_CPU` and `GND_CPU`. Each side of the isolator requires its own I2C
pull-up resistors and decoupling.

The complete pinout and safe startup sequence are documented in
[`BUS_INSTRUMENTS_MAPPING_HARDWARE.md`](docs/BUS_INSTRUMENTS_MAPPING_HARDWARE.md)
and
[`BUS_INSTRUMENTS_MCP23017.md`](docs/BUS_INSTRUMENTS_MCP23017.md).

## Performance compared with the original board

The I2C interface is slower than the original 6802 CPU's parallel writes. This
tradeoff has been measured rather than assumed:

| Operation | Original board | ISO1540 + MCP23017 at 400 kHz |
| --- | ---: | ---: |
| typical low `Chargt` pulse | 3 to 5 µs | 22.5 µs |
| measured mean `Chargt` pulse | 4.151 µs | 22.5 µs |
| one word, bus unchanged | — | 90 µs theoretical |
| one word, data only changed | — | 157.5 µs theoretical |
| one word, data and address changed | — | 225 µs theoretical |
| 13-word RF sequence, worst case | — | 2.925 ms theoretical |

The pulse is therefore about five times longer than the original mean pulse.
It was verified with a logic analyzer and then accepted by the original boards
in the assembled generator. The firmware also reduces latency by transmitting
only changed functional blocks: an identical request produces no writes, and
`RF OFF` by itself produces a single word.

These figures describe the time required to program the internal bus latches.
They are not measurements of the original analog circuitry's accuracy, phase
noise, spectral purity or RF level. Those characteristics still depend on the
condition and calibration of each 740A.

## Project status

The prototype has completed a cold start with the complete instrument bus
connected and has produced an RF signal. Validation so far includes:

- the front-panel bus, indicators, displays and keyboard, plus optical-wheel
  event acquisition (the final direction still requires validation);
- functional frequency, level, AM, FM and PM commands;
- RF inhibition and differential programming of the instrument boards;
- startup without a spurious load pulse and bounded recovery after an I2C
  error;
- versioned, CRC-protected EEPROM settings and memories; power-loss detection
  is implemented, but validation during a real power-down remains pending;
- historical GPIB commands mapped to a 115200-baud ASCII protocol on Serial0;
- tools for importing the original 2816 and calibrating RF output level.

Base coverage is 100 kHz to 560 MHz. The same firmware can declare the optional
doubler through a jumper and computes commands up to 1,119,999,990 Hz, but this
part has only been validated off-hardware until it can be tested in a chassis
fitted with the doubler.

Wiring is identical for the Mega 1280 and 2560, and both firmware targets
build successfully. The recorded hardware tests were nevertheless performed
with the prototype's Mega 2560.

Some front-panel validation, accurate measurement of the 10 Hz steps, saving
during a real mains power-down and full RF calibration also remain to be
completed. Detailed status, including successful tests and open items, is
maintained in [`PROJECT_STATUS.md`](docs/PROJECT_STATUS.md).

## Building a replacement board

The build requires the ability to read a schematic, wire perfboard carefully
and check 5 V power rails. It does not require redesigning the RF synthesis or
modifying the analog boards.

The prototype mainly uses:

- an Arduino Mega 2560 or 1280;
- an ISO1540 isolation module;
- an MCP23017 module configured at I2C address `0x20`;
- perfboard, suitable 740A connectors, and the pull-up, safety and decoupling
  components shown in the schematic;
- a USB programming connection, a multimeter and preferably a logic analyzer
  or isolated oscilloscope for bring-up.

The KiCad 10 project and its printable PDF are in
[`hardware/Adret740A_replacement_cpu`](hardware/Adret740A_replacement_cpu/).
It documents the prototype wire by wire, and its latest ERC report contains no
errors or warnings. It currently contains **no production-ready PCB layout**
or footprints: the documented build is the perfboard prototype.

A cautious bring-up sequence is:

1. inspect and repair the 740A power supplies and RF boards as necessary;
2. wire and test the front panel without the instrument bus;
3. validate the ISO1540 and MCP23017 with the `i2c_probe` build while the
   outputs remain high impedance;
4. observe `Chargt` using `instrument_bus_bench`, with the instrument
   backplane disconnected without exception;
5. reload the normal firmware, verify isolation, then connect the instrument
   bus;
6. perform the functional checks and calibration described in the repository.

Prototype and wiring photographs are available in
[`docs/Photos`](docs/Photos/).

## Important precautions

The 740A is a mains-powered instrument containing RF circuitry. The
replacement board does not remove the normal hazards and precautions involved
in servicing laboratory equipment.

- Never connect `GND_CPU` directly to `GND_INST` when galvanic isolation is to
  be preserved.
- A USB cable, grounded logic analyzer or grounded oscilloscope can bridge the
  two domains unintentionally. Check ground references before attaching a
  probe.
- Check the SDA/SCL pull-ups already fitted to each module. The validated
  prototype uses an MCP23017 module with 4.7 kΩ pull-ups; a 10 kΩ module
  produced invalid intermediate levels behind the ISO1540.
- Hold MCP23017 `RESET` high and place decoupling close to each device.
- An external resistor must hold `Chargt` inactive high during reset and
  before the firmware configures the outputs.
- Never load `instrument_bus_bench` while the instrument backplane is
  connected. Reload the normal firmware afterwards.

## Firmware technologies and rules

- C++17, the Arduino framework and the AVR toolchain through PlatformIO;
- Arduino Mega / ATmega1280 or ATmega2560 at 16 MHz with 5 V logic;
- direct PORTA, PORTB and PORTE access for buses and interrupts;
- 400 kHz hardware I2C with bounded timeouts and no infinite recovery loop;
- large data and the calibration image kept in Flash using `PROGMEM`;
- transactional, CRC-protected EEPROM configuration, memories and calibration;
- Python scripts for calibration and data generation;
- KiCad 10 schematic and netlist validation;
- ASCII remote control on Serial0, with D0/D1 reserved.

Project code remains allocation-free: it does not use `String`, `malloc`,
`free`, `new` or `delete`. Modules are static, and queues, buffers and tables
have fixed sizes.

## Building with PlatformIO

The default target is `megaatmega2560`. A Mega 1280 uses the same connections
but must be selected explicitly.

### VS Code on Windows, Linux or macOS

Install the PlatformIO IDE extension, open the repository root, then use:

- `Project Tasks > megaatmega2560 > Build` for the default target;
- `Project Tasks > megaatmega1280 > Build` for a Mega 1280;
- the corresponding `Upload` task to flash the board.

### Linux terminal

Install Python 3 and then PlatformIO Core according to the
[official PlatformIO documentation](https://docs.platformio.org/en/latest/core/installation/methods/pypi.html):

```bash
python3 -m pip install -U platformio
```

From the repository root:

```bash
# Build the default Mega 2560 target
pio run

# Explicitly build the Mega 1280 target
pio run -e megaatmega1280

# Upload the default target
pio run -t upload

# Upload the Mega 1280 target
pio run -e megaatmega1280 -t upload

# Open the Serial0 terminal
pio device monitor --baud 115200
```

Depending on the distribution, the executable may be named `platformio`
instead of `pio`; both names invoke PlatformIO Core.

### Windows PowerShell terminal

If `pio` is in `PATH`, the Linux commands above work unchanged in PowerShell.
To use the Python environment created by the PlatformIO extension:

```powershell
& "$env:USERPROFILE\.platformio\penv\Scripts\pio.exe" run
& "$env:USERPROFILE\.platformio\penv\Scripts\pio.exe" run -e megaatmega1280
& "$env:USERPROFILE\.platformio\penv\Scripts\pio.exe" run -t upload
& "$env:USERPROFILE\.platformio\penv\Scripts\pio.exe" device monitor --baud 115200
```

### Can the Arduino IDE be used?

The firmware uses the Arduino framework and the standard `Wire` and `EEPROM`
libraries, but this repository is not directly an Arduino IDE sketch. It has
no `.ino` file and relies on the PlatformIO `src`/`include` layout, C++17,
environment-specific macros and a linker option that retains the calibration
table in Flash.

Manual conversion to an Arduino sketch or library structure is possible, but
is neither provided nor validated. PlatformIO is the supported, reproducible
build method.

## Diagnostic builds

Two environments are reserved for hardware bring-up:

```bash
# Safe I2C probe: MCP23017 GPIO remains configured as input
pio run -e i2c_probe
pio run -e i2c_probe -t upload

# Output pattern for a logic analyzer
# DANGER: instrument backplane must be disconnected
pio run -e instrument_bus_bench
pio run -e instrument_bus_bench -t upload
```

After diagnostics, reload the normal firmware:

```bash
pio run -e megaatmega2560 -t upload
```

The complete procedure and measured results are in
[`BUS_INSTRUMENTS_MCP23017.md`](docs/BUS_INSTRUMENTS_MCP23017.md).

## Calibration and host tests

The menu-driven application combines manual calibration, import of an
original 2816 and final merging of the table into Flash.

On Windows, double-click `scripts\lancer_calibration.cmd` or run:

```powershell
python .\scripts\adret_calibration.py
```

On Linux:

```bash
python3 scripts/adret_calibration.py
```

The detailed procedure is in
[`CALIBRATION_AMPLITUDE.md`](docs/CALIBRATION_AMPLITUDE.md). Preliminary analog
realignment is described in
[`CALIBRATION_GROSSIERE_NIVEAU_RF.md`](docs/CALIBRATION_GROSSIERE_NIVEAU_RF.md).

Host tests for the parser, serial framing, instrument-bus composition,
calibration and persistence run on Windows with:

```powershell
& ".\test\run_host_tests.ps1"
```

They require PowerShell and a host `g++` compiler.

## Repository map

- [`src`](src/): C++ implementation and firmware entry point;
- [`include/Adret`](include/Adret/): interfaces, hardware configuration and
  fixed tables;
- [`hardware/Adret740A_replacement_cpu`](hardware/Adret740A_replacement_cpu/):
  KiCad schematic, PDF, netlist and ERC report;
- [`docs/PROJECT_STATUS.md`](docs/PROJECT_STATUS.md): detailed status and bench
  results;
- [`docs/retroanalyse_panneau_avant.md`](docs/retroanalyse_panneau_avant.md):
  front-panel electrical protocol;
- [`docs/BUS_INSTRUMENTS_CARTOGRAPHIE.md`](docs/BUS_INSTRUMENTS_CARTOGRAPHIE.md):
  consolidated map of the sixteen registers;
- [`docs/ADRET7401_Principe.md`](docs/ADRET7401_Principe.md): explanation of the
  original frequency synthesis;
- [`scripts`](scripts/): calibration, import and host-test tools;
- [`platformio.ini`](platformio.ini): build targets and compiler options.

AVR wiring is centralized in
[`HardwareConfig.h`](include/Adret/HardwareConfig.h). Serial0 pins D0/D1 remain
reserved for external remote control.

## License and credits

Original work in this project—firmware, scripts, tests, documentation and
KiCad hardware—is released under the [MIT License](LICENSE), Copyright (c)
2026 Pascal AMESLAND (F8EHO).

Scans, excerpts, dumps, disassemblies and other third-party material are not
covered by that license. See
[`THIRD_PARTY_NOTICES.md`](THIRD_PARTY_NOTICES.md) for details.

Assisted-by: OpenAI:ChatGPT-5.6-Sol codex
