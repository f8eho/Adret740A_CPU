# Repository Guidelines

## Project Structure & Module Organization

This is a PlatformIO firmware project for replacing the Adret 740A CPU with an
Arduino Mega / ATmega2560.

- `src/`: C++ implementation files and `main.cpp`.
- `include/Adret/`: public module headers, hardware mapping, bus maps, and
  fixed-size interfaces.
- `docs/`: project status and provisional hardware mapping.
- `platformio.ini`: target board, framework, and compiler flags.
- `*.pdf`, `*.ods`, `mega2560.sim1`: reference schematics, memory table, and
  simulation support files.
- `.pio/`: generated build output, intentionally ignored.

No formal `test/` directory exists yet; hardware validation is documented in
`docs/PROJECT_STATUS.md`.

## Build, Test, and Development Commands

Build with PlatformIO:

```powershell
& "$env:USERPROFILE\.platformio\penv\Scripts\pio.exe" run
```

If `pio` is in `PATH`, `pio run` is equivalent. This compiles for
`megaatmega2560` and reports RAM/Flash usage. Use VS Code PlatformIO
`Project Tasks > megaatmega2560 > Build` for the same operation.

There are no automated unit tests yet. Treat a successful build plus documented
bench checks as the current validation path.

## Coding Style & Naming Conventions

Use C++17 with AVR/Arduino headers. Keep code allocation-free:

- Do not use Arduino `String`, `malloc`, `free`, `new`, or `delete`.
- Store large static data, including EPROM dumps, in `PROGMEM`.
- Access PORTA/PORTB/PORTE through direct AVR registers for timing-sensitive
  bus operations.
- Prefer `namespace adret`, `enum class`, `constexpr`, and statically allocated
  singleton-style module instances.

Use 4-space indentation. Header names use module names such as
`FrontPanelBus.h`; globals use descriptive lower camel case such as
`frontPanelBus`.

## Testing Guidelines

Before committing, run a PlatformIO build and check memory usage. For hardware
work, update `docs/PROJECT_STATUS.md` with what was tested, observed, and still
untested. Keep debug phases in `src/main.cpp` explicit, for example `Leds`,
`Displays`, then `Inputs`.

## Commit & Pull Request Guidelines

Current history uses short English commit messages, for example:

```text
Initial ADRET740A_CPU firmware scaffold
```

Use concise imperative or descriptive summaries. Pull requests should include:

- purpose and scope of the change;
- build result and RAM/Flash usage;
- hardware bench results, if any;
- affected pins, buses, or timing assumptions;
- links to relevant schematic/table references.

## Agent-Specific Instructions

Keep changes small and hardware-aware. Do not rewrite pin mappings casually;
centralize such edits in `include/Adret/HardwareConfig.h`. Preserve Serial0
D0/D1 for future external communication unless the project explicitly changes
that constraint.
