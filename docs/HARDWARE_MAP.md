# Hardware Map

This map is provisional until the test harness is wired and checked.

## Reserved Interfaces

- Arduino Serial0 pins D0/D1 are left free for external communication.

## Front Panel Bus

- Data bus: ATmega2560 PORTA, Arduino Mega pins 22..29.
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
- `110`: SN10 ICM7218A frequency display.
- `111`: SN11 ICM7218A mixed display.

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
- SN10/SN11 display buffers are prepared by the high-level layer, but the final
  ICM7218A command/data sequence remains to be validated on hardware.

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
3. Assert CA2 active low.
4. Read PINA.
5. Release CA2.
6. Return PORTA to output idle.
