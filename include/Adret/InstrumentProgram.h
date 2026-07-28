#pragma once

#include <stdint.h>

#include "Adret/InstrumentBusTypes.h"
#include "Adret/InstrumentModulation.h"

namespace adret {
namespace instrument_bus {

constexpr uint8_t kInstrumentRegisterCount = 16u;
constexpr uint8_t kMaximumConfigurationWrites = 21u;

enum class InstrumentProgramSection : uint8_t {
    Frequency = 1u << 0u,
    Amplitude = 1u << 1u,
    Modulation = 1u << 2u,
    RfInhibit = 1u << 3u,
};

using InstrumentProgramSections = uint8_t;

constexpr InstrumentProgramSections instrumentProgramSection(
    InstrumentProgramSection section)
{
    return uint8_t(section);
}

constexpr InstrumentProgramSections kNoInstrumentProgramSections = 0u;
constexpr InstrumentProgramSections kAllInstrumentProgramSections =
    instrumentProgramSection(InstrumentProgramSection::Frequency) |
    instrumentProgramSection(InstrumentProgramSection::Amplitude) |
    instrumentProgramSection(InstrumentProgramSection::Modulation) |
    instrumentProgramSection(InstrumentProgramSection::RfInhibit);

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

// Selects the functional blocks needed to move from the last successfully
// applied configuration to the requested one. A null previous configuration
// forces a complete transaction. Dependencies between the original routines
// are included: frequency needs all three blocks, while amplitude finalizes
// its own shared address-6 control bits just like the original CPU.
InstrumentProgramSections requiredInstrumentProgramSections(
    const InstrumentConfiguration* previousConfiguration,
    int8_t previousCalibrationTenthsDb,
    const InstrumentConfiguration& configuration,
    int8_t calibrationTenthsDb);

// Builds only the requested functional blocks, in their original order. The
// caller must use requiredInstrumentProgramSections() or otherwise honor the
// documented block dependencies. RfInhibit emits a word only when rfOff is
// true. No hardware is touched by this function.
InstrumentProgramResult makeInstrumentProgramForSections(
    const InstrumentConfiguration& configuration,
    int8_t calibrationTenthsDb,
    const uint8_t currentRegisters[kInstrumentRegisterCount],
    InstrumentProgramSections sections,
    InstrumentProgram* program);

}  // namespace instrument_bus
}  // namespace adret
