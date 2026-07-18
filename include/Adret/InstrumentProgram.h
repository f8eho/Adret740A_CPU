#pragma once

#include <stdint.h>

#include "Adret/InstrumentBusTypes.h"
#include "Adret/InstrumentModulation.h"

namespace adret {
namespace instrument_bus {

constexpr uint8_t kInstrumentRegisterCount = 16u;
constexpr uint8_t kMaximumConfigurationWrites = 21u;

enum class InstrumentProgramResult : uint8_t {
    Ok,
    InvalidArgument,
    InvalidFrequency,
    InvalidSmallSteps,
    InvalidAmplitude,
    InvalidModulation,
    InvalidPulseState,
};

struct InstrumentConfiguration {
    uint32_t frequencyHz;
    int16_t amplitudeTenthsDbm;
    uint32_t fmDeviationHz;
    uint16_t pmHundredthsRadian;
    uint16_t amTenthsPercent;
    ModulationKind modulationKind;
    ModulationSource modulationSource;
    bool rfOff;
    bool doublerEnabled;
    bool pulseEnabled;
    bool pulseOptionInstalled;
};

struct InstrumentProgram {
    uint8_t writeCount;
    InstrumentWrite writes[kMaximumConfigurationWrites];
    uint8_t finalRegisters[kInstrumentRegisterCount];
};

// Initial state used before the first complete configuration. Address 15 low
// bits power up logically at one in the original CPU image; other words are
// overwritten by the complete program.
void makeInitialInstrumentRegisters(
    uint8_t registers[kInstrumentRegisterCount]);

// Builds a complete, allocation-free configuration transaction. The caller
// supplies the signed 0.1 dB calibration correction selected for the current
// frequency. No hardware is touched by this function.
InstrumentProgramResult makeInstrumentProgram(
    const InstrumentConfiguration& configuration,
    int8_t calibrationTenthsDb,
    const uint8_t currentRegisters[kInstrumentRegisterCount],
    InstrumentProgram* program);

}  // namespace instrument_bus
}  // namespace adret
