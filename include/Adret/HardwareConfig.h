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

// Hold SN5 enabled long enough for the CMOS keyboard logic and the C10/SN16
// acknowledgement path. This is deliberately longer than a simple TTL
// settling delay while the original CPU bus timing is being characterized.
constexpr uint8_t kFrontPanelKeyboardEnableUs = 10;
constexpr uint8_t kFrontPanelStartupAcknowledgeCount = 4;
constexpr uint8_t kFrontPanelStartupAcknowledgeGapUs = 20;
constexpr uint8_t kFrontPanelRecoveryAcknowledgeCount = 4;
constexpr uint8_t kFrontPanelRecoveryAcknowledgeGapUs = 20;

// Provisional wheel polarity. Bench validation must confirm that a high SN5
// direction line corresponds to clockwise rotation on the assembled panel.
constexpr bool kFrontPanelEncoderClockwiseLevel = true;

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

// Instrument-bus power-present input PA. Mega D3 is PE5 / INT5. The original
// supply drives the 6802 NMI input directly from its power-presence detector,
// so keep this input high-impedance without the AVR internal pull-up. PA is
// normally high and falls when the supply disappears.
#define ADRET_PA_DDR DDRE
#define ADRET_PA_PORT PORTE
#define ADRET_PA_PIN PINE
constexpr uint8_t kPowerSenseBit = PE5;
constexpr bool kPowerSenseEnabled = true;
constexpr bool kPowerSenseActiveLow = true;
constexpr uint8_t kPowerSenseInterruptMask = _BV(INT5);
constexpr uint8_t kPowerSenseInterruptFlag = _BV(INTF5);
constexpr uint8_t kPowerSenseSenseBit0 = ISC50;
constexpr uint8_t kPowerSenseSenseBit1 = ISC51;

// Instrument bus through ISO1540 + MCP23017. The ATmega2560 hardware I2C pins
// are Mega D20/SDA (PD1) and D21/SCL (PD0); neither is shared with Serial0.
// MCP23017 A2..A0 are expected low. GPIOA carries D7..D0, GPIOB3..B0 the
// address, and GPIOB4 the active-low Chargt strobe. GPIOB7..B5 stay inputs.
constexpr uint8_t kInstrumentMcp23017Address = 0x20u;
constexpr uint32_t kInstrumentI2cClockHz = 400000UL;
constexpr uint32_t kInstrumentI2cTimeoutUs = 2500UL;
constexpr uint8_t kInstrumentLoadBit = 4u;
constexpr bool kInstrumentLoadActiveLow = true;

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
