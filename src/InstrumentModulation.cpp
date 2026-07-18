#include "Adret/InstrumentModulation.h"

#include "Adret/InstrumentAmplitude.h"

namespace adret {
namespace instrument_bus {
namespace {

constexpr uint8_t kAddress9 = 9u;
constexpr uint8_t kAddress10 = 10u;
constexpr uint8_t kAddress11 = 11u;
constexpr uint8_t kAddress12 = 12u;
constexpr uint8_t kAddress13 = 13u;
constexpr uint8_t kAddress6 = 6u;

constexpr uint8_t packedBcd(uint8_t value)
{
    return uint8_t(uint8_t(value / 10u) << 4u) |
           uint8_t(value % 10u);
}

uint8_t sourceBitsAddress10(ModulationKind kind,
                            ModulationSource source)
{
    if (source == ModulationSource::Cw) {
        return 0u;
    }

    uint8_t bits = 0x80u;
    if (source == ModulationSource::Internal1kHz ||
        source == ModulationSource::Internal400Hz) {
        bits = uint8_t(bits | 0x20u);
    }
    if (kind == ModulationKind::Am) {
        bits = uint8_t(bits | 0x40u);
    }
    return bits;
}

uint8_t sourceBitsAddress12(ModulationSource source)
{
    switch (source) {
        case ModulationSource::Internal1kHz:
            return 0x60u;
        case ModulationSource::Internal400Hz:
            return 0x40u;
        case ModulationSource::Cw:
        case ModulationSource::External:
            return 0u;
    }
    return 0u;
}

bool fillProgram(ModulationKind kind,
                 ModulationSource source,
                 uint16_t scaledValue,
                 bool highFmRange,
                 const FrequencyPlan& frequency,
                 uint8_t currentAddress6,
                 bool highLevelRange,
                 ModulationProgram* program)
{
    if (program == nullptr || scaledValue > 1999u) {
        return false;
    }

    const uint8_t address9 = packedBcd(uint8_t(scaledValue % 100u));
    const uint8_t major = uint8_t(scaledValue / 100u);
    uint8_t address10 = uint8_t(major % 10u);
    if (major < 10u) {
        // D4 is the complemented tens bit on the analog board.
        address10 = uint8_t(address10 | 0x10u);
    }
    address10 = uint8_t(address10 |
                        sourceBitsAddress10(kind, source));

    uint8_t address12 = frequency.address12RangeBits;
    if (source == ModulationSource::Cw) {
        address12 = uint8_t(address12 | 0x01u);
    } else {
        uint8_t modeBits = 0u;
        if (kind == ModulationKind::Fm) {
            modeBits = highFmRange ? 0x08u : 0x10u;
        } else if (kind == ModulationKind::Pm) {
            modeBits = 0x18u;
        }
        address12 = uint8_t(address12 | modeBits |
                            sourceBitsAddress12(source));
        // The original tail routine sets D0 whenever FM/PM range bits D4/D3
        // are both clear. That includes active AM as well as CW.
        if (kind == ModulationKind::Am) {
            address12 = uint8_t(address12 | 0x01u);
        }
    }

    const uint8_t address13 = makeAddress13(frequency, address12);
    const uint8_t address11 = frequency.incrementDivisor;
    const bool amActive = kind == ModulationKind::Am &&
                          source != ModulationSource::Cw;
    const uint8_t address6After = makeAmplitudeControlAddress6(
        currentAddress6, frequency.address5, highLevelRange, amActive);

    program->kind = kind;
    program->source = source;
    program->scaledValue = scaledValue;
    program->highFmRange = highFmRange;

    uint8_t index = 0u;
    if (kind == ModulationKind::Am) {
        program->writes[index++] = {kAddress6, currentAddress6};
    }
    program->writes[index++] = {kAddress9, address9};
    program->writes[index++] = {kAddress10, address10};
    program->writes[index++] = {kAddress12, address12};
    program->writes[index++] = {kAddress13, address13};
    program->writes[index++] = {kAddress11, address11};
    program->writes[index++] = {kAddress6, address6After};
    program->writeCount = index;
    return true;
}

static_assert(packedBcd(0u) == 0x00u, "Unexpected zero BCD code");
static_assert(packedBcd(99u) == 0x99u, "Unexpected maximum BCD code");

}  // namespace

bool makeAmModulationProgram(uint16_t tenthsPercent,
                             ModulationSource source,
                             const FrequencyPlan& frequency,
                             uint8_t currentAddress6,
                             bool highLevelRange,
                             ModulationProgram* program)
{
    if (tenthsPercent > kAmMaximumTenthsPercent) {
        return false;
    }
    return fillProgram(ModulationKind::Am,
                       source,
                       tenthsPercent,
                       false,
                       frequency,
                       currentAddress6,
                       highLevelRange,
                       program);
}

bool makeFmModulationProgram(uint32_t deviationHz,
                             ModulationSource source,
                             const FrequencyPlan& frequency,
                             uint8_t currentAddress6,
                             bool highLevelRange,
                             ModulationProgram* program)
{
    const bool highFmRange = deviationHz >= kFmLowRangeEndHz;
    const uint32_t resolutionHz = highFmRange ? 100u : 10u;
    if (deviationHz > kFmMaximumExactlyEncodedHz ||
        deviationHz % resolutionHz != 0u) {
        return false;
    }
    return fillProgram(ModulationKind::Fm,
                       source,
                       uint16_t(deviationHz / resolutionHz),
                       highFmRange,
                       frequency,
                       currentAddress6,
                       highLevelRange,
                       program);
}

bool makePmModulationProgram(uint16_t hundredthsRadian,
                             ModulationSource source,
                             const FrequencyPlan& frequency,
                             uint8_t currentAddress6,
                             bool highLevelRange,
                             ModulationProgram* program)
{
    if (hundredthsRadian > kPmMaximumHundredthsRadian) {
        return false;
    }
    return fillProgram(ModulationKind::Pm,
                       source,
                       hundredthsRadian,
                       false,
                       frequency,
                       currentAddress6,
                       highLevelRange,
                       program);
}

}  // namespace instrument_bus
}  // namespace adret
