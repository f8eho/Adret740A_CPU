#include "Adret/InstrumentProgram.h"

#include "Adret/InstrumentAmplitude.h"
#include "Adret/InstrumentFrequencyPlan.h"
#include "Adret/InstrumentPulse.h"
#include "Adret/InstrumentSmallSteps.h"

namespace adret {
namespace instrument_bus {
namespace {

bool appendWrite(InstrumentProgram* program, uint8_t address, uint8_t value)
{
    if (program->writeCount >= kMaximumConfigurationWrites ||
        address >= kInstrumentRegisterCount) {
        return false;
    }
    program->writes[program->writeCount++] = {address, value};
    program->finalRegisters[address] = value;
    return true;
}

uint8_t valueForAddress(const ModulationProgram& program,
                        uint8_t address,
                        uint8_t fallback)
{
    uint8_t value = fallback;
    for (uint8_t i = 0u; i < program.writeCount; ++i) {
        if (program.writes[i].address == address) {
            value = program.writes[i].value;
        }
    }
    return value;
}

bool makeSelectedModulation(const InstrumentConfiguration& configuration,
                            const FrequencyPlan& frequency,
                            uint8_t currentAddress6,
                            bool highLevelRange,
                            ModulationProgram* modulation)
{
    switch (configuration.modulationKind) {
        case ModulationKind::Am:
            return makeAmModulationProgram(configuration.amTenthsPercent,
                                           configuration.modulationSource,
                                           frequency,
                                           currentAddress6,
                                           highLevelRange,
                                           modulation);
        case ModulationKind::Fm:
            return makeFmModulationProgram(configuration.fmDeviationHz,
                                           configuration.modulationSource,
                                           frequency,
                                           currentAddress6,
                                           highLevelRange,
                                           modulation);
        case ModulationKind::Pm:
            return makePmModulationProgram(configuration.pmHundredthsRadian,
                                           configuration.modulationSource,
                                           frequency,
                                           currentAddress6,
                                           highLevelRange,
                                           modulation);
    }
    return false;
}

}  // namespace

void makeInitialInstrumentRegisters(
    uint8_t registers[kInstrumentRegisterCount])
{
    if (registers == nullptr) {
        return;
    }
    for (uint8_t i = 0u; i < kInstrumentRegisterCount; ++i) {
        registers[i] = 0u;
    }
    registers[15] = 0x1Fu;
}

InstrumentProgramResult makeInstrumentProgram(
    const InstrumentConfiguration& configuration,
    int8_t calibrationTenthsDb,
    const uint8_t currentRegisters[kInstrumentRegisterCount],
    InstrumentProgram* program)
{
    if (currentRegisters == nullptr || program == nullptr) {
        return InstrumentProgramResult::InvalidArgument;
    }

    program->writeCount = 0u;
    for (uint8_t i = 0u; i < kInstrumentRegisterCount; ++i) {
        program->finalRegisters[i] = currentRegisters[i];
    }

    FrequencyPlan frequency = {};
    const bool frequencyValid = configuration.doublerEnabled
        ? makeDoublerFrequencyPlan(configuration.frequencyHz, &frequency)
        : makeBaseFrequencyPlan(configuration.frequencyHz, &frequency);
    if (!frequencyValid) {
        return InstrumentProgramResult::InvalidFrequency;
    }

    SmallStepProgram smallSteps = {};
    if (!makeSmallStepProgram(frequency.pointAFrequencyHz, &smallSteps)) {
        return InstrumentProgramResult::InvalidSmallSteps;
    }

    PulseRegisterState pulse = {};
    const PulseRequestResult pulseResult = makePulseRegisterState(
        configuration.pulseEnabled,
        configuration.pulseOptionInstalled,
        configuration.modulationKind,
        frequency,
        currentRegisters[6],
        &pulse);
    if (pulseResult != PulseRequestResult::Ok) {
        return InstrumentProgramResult::InvalidPulseState;
    }

    AmplitudeProgram amplitude = {};
    if (!makeAmplitudeProgram(configuration.amplitudeTenthsDbm,
                              calibrationTenthsDb,
                              pulse.address6,
                              pulse.address5,
                              &amplitude)) {
        return InstrumentProgramResult::InvalidAmplitude;
    }

    ModulationProgram modulation = {};
    if (!makeSelectedModulation(configuration,
                                frequency,
                                amplitude.address6AfterAddress8,
                                amplitude.highLevelRange,
                                &modulation)) {
        return InstrumentProgramResult::InvalidModulation;
    }

    const uint8_t address12 = valueForAddress(
        modulation, 12u, frequency.address12RangeBits);
    const uint8_t address13 = makeAddress13(frequency, address12);
    const uint8_t address15 = makeAddress15(currentRegisters[15], address12);

    // Original RF reprogramming order, including transient D7 on address 11.
    if (!appendWrite(program, 12u, address12) ||
        !appendWrite(program, 15u, address15) ||
        !appendWrite(program, 5u, pulse.address5) ||
        !appendWrite(program, 11u,
                     uint8_t(frequency.incrementDivisor | 0x80u)) ||
        !appendWrite(program, 4u, frequency.address4) ||
        !appendWrite(program, 13u, address13)) {
        return InstrumentProgramResult::InvalidArgument;
    }
    for (uint8_t address = 0u; address < 4u; ++address) {
        if (!appendWrite(program, address, smallSteps.dataByAddress[address])) {
            return InstrumentProgramResult::InvalidArgument;
        }
    }

    if (!appendWrite(program, 6u, amplitude.address6BeforeAddress8) ||
        !appendWrite(program, 8u, amplitude.address8) ||
        !appendWrite(program, 6u, amplitude.address6AfterAddress8)) {
        return InstrumentProgramResult::InvalidArgument;
    }

    for (uint8_t i = 0u; i < modulation.writeCount; ++i) {
        if (!appendWrite(program,
                         modulation.writes[i].address,
                         modulation.writes[i].value)) {
            return InstrumentProgramResult::InvalidArgument;
        }
    }

    if (configuration.rfOff) {
        const uint8_t inhibitedAddress6 = uint8_t(
            program->finalRegisters[6] & 0xC0u);
        if (!appendWrite(program, 6u, inhibitedAddress6)) {
            return InstrumentProgramResult::InvalidArgument;
        }
    }
    return InstrumentProgramResult::Ok;
}

static_assert(kMaximumConfigurationWrites == 21u,
              "Update the full-program bound when sequences change");

}  // namespace instrument_bus
}  // namespace adret
