#include "Adret/InstrumentFrequencyPlan.h"

namespace adret {
namespace instrument_bus {
namespace {

constexpr uint32_t kBaseMinimumHz = 100000u;
constexpr uint32_t kLowHeterodyneEndHz = 1500000u;
constexpr uint32_t kHeterodyneEndHz = 122000000u;
constexpr uint32_t kDivideBy2O2EndHz = 184000000u;
constexpr uint32_t kDivideBy2O1EndHz = 280000000u;
constexpr uint32_t kDirectO2EndHz = 368000000u;
constexpr uint32_t kDoublerStartHz = 560000000u;
constexpr uint32_t kDoublerO2EndHz = 736000000u;
constexpr uint32_t kDoublerEndHz = 1120000000u;

constexpr uint32_t kFrequencyOffsetHz = 18000000u;
constexpr uint32_t kLargeStepHz = 8000000u;
constexpr uint32_t kHeterodyneOffsetHz = 400000000u;

constexpr uint8_t kRangeHeterodyne = 0x84u;
constexpr uint8_t kRangeDivideBy2 = 0x00u;
constexpr uint8_t kRangeDirect = 0x04u;
constexpr uint8_t kRangeDoubler = 0x02u;

constexpr uint8_t encodeIncrementDivisor(uint8_t divisor)
{
    return uint8_t(uint8_t(16u - divisor / 5u) << 3u) |
           uint8_t(divisor % 5u);
}

constexpr uint8_t packedBcd(uint8_t value)
{
    return uint8_t(uint8_t(value / 10u) << 4u) | uint8_t(value % 10u);
}

// Exact transcription of the D7 tracking decision at EPROM addresses
// EA4E..EAA7. It is only used while address-5 D4 (X2) is active.
bool doublerTrackingHigh(uint32_t outputFrequencyHz)
{
    uint8_t hundreds = packedBcd(
        uint8_t(outputFrequencyHz / 100000000u));
    const uint8_t lowerMHz = packedBcd(
        uint8_t((outputFrequencyHz / 1000000u) % 100u));

    if (hundreds >= 0x10u) {
        hundreds = uint8_t(hundreds - 0x0Au);
    }
    if (hundreds == 0x05u) {
        return true;
    }
    if (hundreds >= 0x09u) {
        return lowerMHz >= 0x64u || lowerMHz < 0x24u;
    }
    if (hundreds >= 0x08u) {
        return (lowerMHz >= 0x84u) ||
               (lowerMHz >= 0x04u && lowerMHz < 0x44u);
    }
    if (hundreds >= 0x07u) {
        return lowerMHz >= 0x24u && lowerMHz < 0x64u;
    }
    return (lowerMHz >= 0x44u && lowerMHz < 0x84u) ||
           lowerMHz < 0x04u;
}

bool fillPlan(uint32_t outputFrequencyHz,
              uint32_t oscillatorFrequencyHz,
              RfFrequencyPath path,
              uint8_t address5,
              uint8_t address12RangeBits,
              bool trackingHigh,
              FrequencyPlan* plan)
{
    if (plan == nullptr || oscillatorFrequencyHz < kFrequencyOffsetHz) {
        return false;
    }

    const uint32_t shiftedFrequencyHz =
        oscillatorFrequencyHz - kFrequencyOffsetHz;
    const uint8_t divisor = uint8_t(shiftedFrequencyHz / kLargeStepHz);
    const uint32_t deltaHz = shiftedFrequencyHz % kLargeStepHz;
    const uint32_t pointAFrequencyHz =
        5u * (kFrequencyOffsetHz + deltaHz);

    if (divisor < 28u || divisor > 67u || pointAFrequencyHz < 90000000u ||
        pointAFrequencyHz > 129999975u) {
        return false;
    }

    const uint8_t divisorCode = encodeIncrementDivisor(divisor);
    plan->path = path;
    plan->outputFrequencyHz = outputFrequencyHz;
    plan->oscillatorFrequencyHz = oscillatorFrequencyHz;
    plan->pointAFrequencyHz = pointAFrequencyHz;
    plan->pointBNumeratorHz =
        pointAFrequencyHz + uint32_t(divisor) * 40000000u;
    plan->deltaHz = deltaHz;
    plan->incrementDivisor = divisor;
    plan->incrementQuotient = uint8_t(divisor / 5u);
    plan->incrementRemainder = uint8_t(divisor % 5u);
    plan->address4 = uint8_t(divisorCode | (trackingHigh ? 0x80u : 0x00u));
    plan->address5 = address5;
    plan->address12RangeBits = address12RangeBits;
    plan->address13LowBits = divisorCode;
    return true;
}

static_assert(encodeIncrementDivisor(28u) == 0x5Bu,
              "Unexpected code at the minimum increment divisor");
static_assert(encodeIncrementDivisor(57u) == 0x2Au,
              "Unexpected increment code for the captured 240 MHz range");
static_assert(encodeIncrementDivisor(67u) == 0x1Au,
              "Unexpected code at the maximum increment divisor");
}  // namespace

bool makeBaseFrequencyPlan(uint32_t outputFrequencyHz, FrequencyPlan* plan)
{
    if (outputFrequencyHz < kBaseMinimumHz ||
        outputFrequencyHz > kDoublerStartHz ||
        outputFrequencyHz % 5u != 0u) {
        return false;
    }

    uint32_t oscillatorFrequencyHz = outputFrequencyHz;
    RfFrequencyPath path = RfFrequencyPath::DirectO1;
    uint8_t address5 = 0x09u;
    uint8_t address12RangeBits = kRangeDirect;

    if (outputFrequencyHz < kHeterodyneEndHz) {
        oscillatorFrequencyHz = kHeterodyneOffsetHz + outputFrequencyHz;
        const bool useLowPath = outputFrequencyHz < kLowHeterodyneEndHz;
        path = useLowPath ? RfFrequencyPath::HeterodyneLow
                          : RfFrequencyPath::Heterodyne;
        address5 = useLowPath ? 0x23u : 0x03u;
        address12RangeBits = kRangeHeterodyne;
    } else if (outputFrequencyHz < kDivideBy2O2EndHz) {
        oscillatorFrequencyHz = 2u * outputFrequencyHz;
        path = RfFrequencyPath::DivideBy2O2;
        address5 = 0x04u;
        address12RangeBits = kRangeDivideBy2;
    } else if (outputFrequencyHz < kDivideBy2O1EndHz) {
        oscillatorFrequencyHz = 2u * outputFrequencyHz;
        path = RfFrequencyPath::DivideBy2O1;
        address5 = 0x05u;
        address12RangeBits = kRangeDivideBy2;
    } else if (outputFrequencyHz < kDirectO2EndHz) {
        path = RfFrequencyPath::DirectO2;
        address5 = 0x08u;
    }

    return fillPlan(outputFrequencyHz,
                    oscillatorFrequencyHz,
                    path,
                    address5,
                    address12RangeBits,
                    true,
                    plan);
}

bool makeDoublerFrequencyPlan(uint32_t outputFrequencyHz,
                              FrequencyPlan* plan)
{
    if (outputFrequencyHz < kDoublerStartHz ||
        outputFrequencyHz >= kDoublerEndHz ||
        outputFrequencyHz % 10u != 0u) {
        return false;
    }

    const bool useO2 = outputFrequencyHz < kDoublerO2EndHz;
    return fillPlan(outputFrequencyHz,
                    outputFrequencyHz / 2u,
                    useO2 ? RfFrequencyPath::DoublerO2
                          : RfFrequencyPath::DoublerO1,
                    useO2 ? 0x10u : 0x11u,
                    kRangeDoubler,
                    doublerTrackingHigh(outputFrequencyHz),
                    plan);
}

uint8_t mergeAddress12Range(uint8_t currentAddress12,
                            const FrequencyPlan& plan)
{
    return uint8_t(uint8_t(currentAddress12 & uint8_t(~kAddress12RangeMask)) |
                   plan.address12RangeBits);
}

uint8_t makeAddress13(const FrequencyPlan& plan, uint8_t address12)
{
    return uint8_t(plan.address13LowBits |
                   ((address12 & 0x01u) == 0u ? 0x80u : 0x00u));
}

uint8_t makeAddress15(uint8_t currentAddress15, uint8_t address12)
{
    return uint8_t(uint8_t(currentAddress15 & 0x1Fu) |
                   uint8_t(uint8_t(address12 & 0x0Eu) << 4u));
}

uint8_t makeAddress5WithPulse(const FrequencyPlan& plan, bool enabled)
{
    return enabled ? uint8_t(plan.address5 | kAddress5PulseMask)
                   : plan.address5;
}

uint8_t mergeAddress6Pulse(uint8_t currentAddress6, bool enabled)
{
    if (enabled) {
        return uint8_t(currentAddress6 | kAddress6PulseMask);
    }
    return uint8_t(currentAddress6 & uint8_t(~kAddress6PulseMask));
}

}  // namespace instrument_bus
}  // namespace adret
