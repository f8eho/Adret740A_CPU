# Hardware Map

This map records the harness and front-panel selections validated on the bench.
Items explicitly listed under remaining validation are still provisional.

## Reserved Interfaces

- Arduino Serial0 pins D0/D1 are left free for external communication.

## Frequency-Doubler Declaration

- Arduino Mega D4, ATmega2560 PG5, is reserved for a passive configuration
  jumper sampled once during startup.
- The AVR input uses its internal pull-up: open means the doubler is absent;
  shorting D4 to `GND_CPU` means it is installed.
- Never connect this jumper to `GND_INST`: that ground belongs to the isolated,
  write-only instrument-bus domain.
- This is a hardware declaration, not electrical detection of the RF module.
  Changing the jumper while powered has no effect until the next restart.

## Power-Fail Input

- The original supply exposes `PRESENCE ALIM (1)` on output 35. The chassis
  routes it to `PA`, which drove the original 6802 `NMI` input directly.
- `PA` is connected to Arduino Mega D3, ATmega2560 PE5 / INT5.
- D3 is a high-impedance input without an internal pull-up. `PA` is normally
  high; its falling edge requests the EEPROM settings save.
- The supply schematic takes `PA` from its presence detector/divider, not from
  a raw supply rail. Since the same node drove a 5 V CPU input directly, no
  additional series resistor is required for the nominal connection. A series
  resistor would provide only optional fault-current limiting.
- Sources: [power-supply schematic](Adret740a_schemas/Page%2021a%20_%20alimentation_schema.pdf),
  [chassis schematic](Adret740a_schemas/Page%2023a%20_%20chassis_schema.pdf),
  and [original CPU schematic](Adret740a_schemas/Page%2030a%20_%20CPU_schema.pdf).

## Instrument Bus

- Arduino Mega D20/SDA and D21/SCL drive an ISO1540 and a MCP23017 at I2C
  address `0x20`.
- MCP23017 GPA0..7 drive instrument data D0..D7, GPB0..3 drive address A0..A3,
  and GPB4 drives active-low `Chargt`.
- The complete component and B1 connector pinout is documented in
  [`BUS_INSTRUMENTS_MAPPING_HARDWARE.md`](BUS_INSTRUMENTS_MAPPING_HARDWARE.md).

## Front Panel Bus

- Data bus: ATmega2560 PORTA, Arduino Mega pins 22..29.
- Validated harness pairs: panel D0/D1 to Mega 23/22, D2/D3 to 25/24,
  D4/D5 to 27/26, and D6/D7 to 29/28.
- Direction: bidirectional.
- Access: direct register writes and reads through `PORTA`, `PINA`, `DDRA`.

## Front Panel Control

Default mapping in `include/Adret/HardwareConfig.h`:

- `PB0`: PORTB bit 0, Arduino Mega pin 53.
- `PB1`: PORTB bit 1, Arduino Mega pin 52.
- `PB2`: PORTB bit 2, Arduino Mega pin 51.
- `PB3`: PORTB bit 3, Arduino Mega pin 50, ICM7218A mode line.
- `CA2`: PORTB bit 4, Arduino Mega pin 10, active low.
- `CA1`: PORTE bit 4, Arduino Mega pin 2 / INT4.

## Front Panel Selects

Values come from `Adret_740A_table_memoire_panneau_avant.ods`.

- `000`: idle / Y0.
- `001`: SN17 decimal points.
- `010`: SN4 first-character flags and status bits.
- `011`: SN2 LED bank.
- `100`: SN3 LED bank.
- `101`: SN5 keyboard / optical wheel read path.
- `110`: SN11 ICM7218A mixed display.
- `111`: SN10 ICM7218A frequency display.

## Logical Front Panel Layer

`adret::frontPanel` keeps RAM mirrors of the front-panel latch state before
writing through `FrontPanelBus`.

- SN2 is split into exclusive logical groups for function, amplitude unit, and
  modulation source LEDs.
- SN3 is split into exclusive logical groups for status, modulation unit, and
  memory LED mode, plus independent `MEM` and `SEQ` bits.
- SN4/SN17 hold first-character/status flags and decimal-point flags.
- SN5 samples are decoded into raw `xCode`/`yCode`, a named keyboard event when
  known, and an accumulated signed optical-wheel delta.
- SN10/SN11 use full eight-byte Code B frames. SN10/Y7 drives the first eight
  frequency digits; SN11/Y6 drives the final two frequency digits and the
  modulation/amplitude groups. ICM decimal-point data is active low.

## Timing Model

For output writes:

1. Drive PORTA with data.
2. Drive `PB3..PB0`.
3. Wait a short TTL settle delay.
4. Assert CA2 active low.
5. Release CA2.

For SN5 reads:

1. Put PORTA in input mode.
2. Select `101`.
3. Assert CA2 active low for 10 microseconds.
4. Read PINA.
5. Release CA2.
6. Return PORTA to output idle.

Four SN5 acknowledgement reads are issued at startup before INT4 is enabled so
that a CA1 line already low during reset can be released.
