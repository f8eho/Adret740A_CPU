#pragma once

#include <avr/io.h>
#include <stdint.h>

#if !defined(__AVR_ATmega2560__)
#warning "This project is wired and timed for ATmega2560 / Arduino Mega."
#endif

namespace adret {
namespace hw {

// Front panel 8-bit data bus: Arduino Mega pins 22..29, ATmega2560 PORTA.
#define ADRET_FP_DATA_DDR DDRA
#define ADRET_FP_DATA_PORT PORTA
#define ADRET_FP_DATA_PIN PINA

// Front panel control nibble PB3..PB0 from the original CPU bus.
// PB2..PB0 select the decoded address, PB3 is used as ICM7218A mode.
// Default wiring uses ATmega2560 PORTB bits 0..3 (Mega pins 53, 52, 51, 50).
// Change only this file if the replacement CPU connector is wired elsewhere.
#define ADRET_FP_SELECT_DDR DDRB
#define ADRET_FP_SELECT_PORT PORTB
constexpr uint8_t kFrontPanelSelectShift = 0;
constexpr uint8_t kFrontPanelSelectMask =
    uint8_t(_BV(PB0) | _BV(PB1) | _BV(PB2) | _BV(PB3));

// CA2 enables the 74LS138 address decoder while PB2..PB0 hold a valid address.
// Default: PORTB bit 4 (Mega pin 10), active low on G2.
#define ADRET_FP_CA2_DDR DDRB
#define ADRET_FP_CA2_PORT PORTB
constexpr uint8_t kFrontPanelCa2Bit = PB4;
constexpr bool kFrontPanelCa2ActiveLow = true;

// CA1 is asserted by the original front-panel hardware for keyboard and
// optical-wheel events. Default Arduino Mega pin 2: PE4 / INT4, not INT0.
#define ADRET_FP_CA1_DDR DDRE
#define ADRET_FP_CA1_PORT PORTE
#define ADRET_FP_CA1_PIN PINE
constexpr uint8_t kFrontPanelCa1Bit = PE4;

constexpr uint8_t kFrontPanelCa1InterruptMask = _BV(INT4);
constexpr uint8_t kFrontPanelCa1InterruptFlag = _BV(INTF4);
constexpr uint8_t kFrontPanelCa1SenseBit0 = ISC40;
constexpr uint8_t kFrontPanelCa1SenseBit1 = ISC41;

inline void waitTtlSettle()
{
    asm volatile(
        "nop\n\t"
        "nop\n\t"
        "nop\n\t"
        "nop\n\t");
}

}  // namespace hw
}  // namespace adret
