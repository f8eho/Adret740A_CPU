#include "Adret/InstrumentAmplitude.h"

#include <avr/pgmspace.h>

namespace adret {
namespace instrument_bus {
namespace {

constexpr int16_t kHighLevelStartTenthsDbm = 70;
constexpr int16_t kNormalReferenceTenthsDb = 138;
constexpr int16_t kHighReferenceTenthsDb = 188;
constexpr int16_t kMechanicalStepTenthsDb = 50;
constexpr uint8_t kAttenuatorStepCount = 28u;

// Original CPU table at physical address C1F6. The index is the decimal
// number of 5 dB steps; the byte is the relay pattern for address 6 D5..D0.
const uint8_t kRelayCodeByStep[kAttenuatorStepCount] PROGMEM = {
    0x3Fu, 0x37u, 0x3Bu, 0x33u, 0x3Du, 0x35u, 0x39u,
    0x31u, 0x2Du, 0x25u, 0x29u, 0x21u, 0x38u, 0x30u,
    0x2Cu, 0x24u, 0x28u, 0x20u, 0x19u, 0x11u, 0x0Du,
    0x05u, 0x09u, 0x01u, 0x18u, 0x10u, 0x0Cu, 0x04u,
};

uint8_t attenuatorStepForLevel(int16_t requestedTenthsDbm,
                               bool highLevelRange)
{
    if (highLevelRange) {
        return 0u;
    }

    const int16_t numerator = int16_t(20 - requestedTenthsDbm);
    if (numerator <= 0) {
        return 0u;
    }
    return uint8_t((numerator + kMechanicalStepTenthsDb - 1) /
                   kMechanicalStepTenthsDb);
}

bool encodeFineCorrection(int16_t fineTenthsDb, uint8_t* address8)
{
    if (address8 == nullptr || fineTenthsDb < 0 || fineTenthsDb > 139) {
        return false;
    }

    const uint8_t units = uint8_t(fineTenthsDb % 10);
    uint8_t tens = uint8_t(fineTenthsDb / 10);
    if (tens >= 6u) {
        tens = uint8_t(tens + 2u);
    }
    if (tens > 0x0Fu) {
        return false;
    }

    *address8 = uint8_t(uint8_t(tens << 4u) | units);
    return true;
}

}  // namespace

uint8_t makeAmplitudeControlAddress6(uint8_t currentAddress6,
                                     uint8_t address5,
                                     bool highLevelRange,
                                     bool amplitudeModulationActive)
{
    uint8_t address6 = uint8_t(currentAddress6 & 0x7Fu);
    const bool heterodynePath = (address5 & 0x02u) != 0u;
    if (heterodynePath &&
        (highLevelRange || amplitudeModulationActive)) {
        address6 = uint8_t(address6 | kAmplitudePlus5dBMask);
    }
    return address6;
}

bool makeAmplitudeProgram(int16_t requestedTenthsDbm,
                          int8_t calibrationTenthsDb,
                          uint8_t currentAddress6,
                          uint8_t address5,
                          AmplitudeProgram* program)
{
    if (program == nullptr ||
        requestedTenthsDbm < kAmplitudeMinimumTenthsDbm ||
        requestedTenthsDbm > kAmplitudeMaximumTenthsDbm) {
        return false;
    }

    const bool highLevelRange =
        requestedTenthsDbm >= kHighLevelStartTenthsDbm;
    const uint8_t attenuatorStep =
        attenuatorStepForLevel(requestedTenthsDbm, highLevelRange);
    if (attenuatorStep >= kAttenuatorStepCount) {
        return false;
    }

    const int16_t referenceTenthsDb = highLevelRange
        ? kHighReferenceTenthsDb
        : kNormalReferenceTenthsDb;
    const int16_t nominalFineTenthsDb = int16_t(
        referenceTenthsDb - requestedTenthsDbm -
        int16_t(attenuatorStep) * kMechanicalStepTenthsDb);
    const int16_t correctedFineTenthsDb = int16_t(
        nominalFineTenthsDb + int16_t(calibrationTenthsDb));

    uint8_t address8 = 0u;
    if (!encodeFineCorrection(correctedFineTenthsDb, &address8)) {
        return false;
    }

    const uint8_t relayCode =
        pgm_read_byte(&kRelayCodeByStep[attenuatorStep]);
    const uint8_t preservedControl = uint8_t(currentAddress6 & 0xC0u);
    const uint8_t address6Before = uint8_t(preservedControl | relayCode);

    const uint8_t address6After = makeAmplitudeControlAddress6(
        address6Before, address5, highLevelRange, false);

    program->requestedTenthsDbm = requestedTenthsDbm;
    program->nominalFineTenthsDb = nominalFineTenthsDb;
    program->correctedFineTenthsDb = correctedFineTenthsDb;
    program->calibrationTenthsDb = calibrationTenthsDb;
    program->attenuatorStep = attenuatorStep;
    program->address6BeforeAddress8 = address6Before;
    program->address8 = address8;
    program->address6AfterAddress8 = address6After;
    program->highLevelRange = highLevelRange;
    return true;
}

int16_t decodeAddress8TenthsDb(uint8_t address8)
{
    const uint8_t units = uint8_t(address8 & 0x0Fu);
    uint8_t tens = uint8_t(address8 >> 4u);
    if (units > 9u) {
        return -1;
    }
    if (tens >= 8u) {
        tens = uint8_t(tens - 2u);
    }
    if (tens > 13u) {
        return -1;
    }
    return int16_t(uint16_t(tens) * 10u + units);
}

}  // namespace instrument_bus
}  // namespace adret
