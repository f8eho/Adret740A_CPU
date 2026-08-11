#include "Adret/InstrumentSmallSteps.h"

namespace adret {
namespace instrument_bus {
namespace {

constexpr uint32_t kPointAMinimumHz = 90000000u;
constexpr uint32_t kPointAMaximumHz = 129999975u;
constexpr uint32_t kCoarseStepHz = 500000u;
constexpr uint32_t kFineMinimumHz = 1000000u;
constexpr uint8_t kDivisor80Minimum = 178u;
constexpr uint16_t kDivisor20000Minimum = 40000u;
constexpr uint16_t kDivisor20000Maximum = 59999u;

struct BusWords {
    uint8_t address0;
    uint8_t address1;
    uint8_t address2;
    uint8_t address3;
};

constexpr uint8_t packedBcd(uint8_t value)
{
    return uint8_t(uint8_t(value / 10u) << 4u) | uint8_t(value % 10u);
}

constexpr uint16_t fineCode(uint16_t divisor20000)
{
    return uint16_t(divisor20000 / 2u - kDivisor20000Minimum / 2u);
}

constexpr uint8_t coarseCode(uint16_t divisor80)
{
    return uint8_t(divisor80 - kDivisor80Minimum);
}

constexpr BusWords encodeDivisors(uint16_t divisor20000,
                                  uint16_t divisor80)
{
    return {
        uint8_t(uint8_t(uint8_t(fineCode(divisor20000) % 10u) << 4u) |
                ((divisor20000 & 1u) != 0u ? 0x08u : 0x00u)),
        uint8_t(
            uint8_t(uint8_t((fineCode(divisor20000) / 100u) % 10u) << 4u) |
            uint8_t((fineCode(divisor20000) / 10u) % 10u)),
        uint8_t((fineCode(divisor20000) / 1000u) % 10u),
        uint8_t(packedBcd(coarseCode(divisor80)) ^ 0xFEu),
    };
}

constexpr BusWords kAt240MHzPlus10Hz = encodeDivisors(40004u, 238u);
constexpr BusWords kAt240MHzPlus100Hz = encodeDivisors(40040u, 238u);
constexpr BusWords kAt240MHzPlus1kHz = encodeDivisors(40400u, 238u);
constexpr BusWords kAt241MHzPlus100Hz = encodeDivisors(40040u, 178u);
constexpr BusWords kOddMinimum = encodeDivisors(40001u, 238u);
constexpr BusWords kOddMaximum = encodeDivisors(59999u, 238u);

static_assert(kAt240MHzPlus10Hz.address0 == 0x20u &&
                  kAt240MHzPlus10Hz.address1 == 0x00u &&
                  kAt240MHzPlus10Hz.address2 == 0x00u &&
                  kAt240MHzPlus10Hz.address3 == 0x9Eu,
              "Unexpected 20000/80 encoding at 240 MHz + 10 Hz");
static_assert(kAt240MHzPlus100Hz.address0 == 0x00u &&
                  kAt240MHzPlus100Hz.address1 == 0x02u &&
                  kAt240MHzPlus100Hz.address2 == 0x00u &&
                  kAt240MHzPlus100Hz.address3 == 0x9Eu,
              "Unexpected 20000/80 encoding at 240 MHz + 100 Hz");
static_assert(kAt240MHzPlus1kHz.address0 == 0x00u &&
                  kAt240MHzPlus1kHz.address1 == 0x20u &&
                  kAt240MHzPlus1kHz.address2 == 0x00u &&
                  kAt240MHzPlus1kHz.address3 == 0x9Eu,
              "Unexpected 20000/80 encoding at 240 MHz + 1 kHz");
static_assert(kAt241MHzPlus100Hz.address0 == 0x00u &&
                  kAt241MHzPlus100Hz.address1 == 0x02u &&
                  kAt241MHzPlus100Hz.address2 == 0x00u &&
                  kAt241MHzPlus100Hz.address3 == 0xFEu,
              "Unexpected 20000/80 encoding after the 8 MHz carry");
static_assert(kOddMinimum.address0 == 0x08u &&
                  kOddMinimum.address1 == 0x00u &&
                  kOddMinimum.address2 == 0x00u,
              "Unexpected odd 20000 divisor encoding at the lower bound");
static_assert(kOddMaximum.address0 == 0x98u &&
                  kOddMaximum.address1 == 0x99u &&
                  kOddMaximum.address2 == 0x09u,
              "Unexpected odd 20000 divisor encoding at the upper bound");

}  // namespace

bool makeSmallStepProgram(uint32_t pointAFrequencyHz, SmallStepProgram* program)
{
    if (program == nullptr || pointAFrequencyHz < kPointAMinimumHz ||
        pointAFrequencyHz > kPointAMaximumHz || pointAFrequencyHz % 25u != 0u) {
        return false;
    }

    const uint16_t divisor80 = uint16_t(
        (pointAFrequencyHz - kFineMinimumHz) / kCoarseStepHz);
    const uint32_t fineFrequencyHz =
        pointAFrequencyHz - uint32_t(divisor80) * kCoarseStepHz;
    const uint16_t divisor20000 = uint16_t(fineFrequencyHz / 25u);

    if (divisor80 < kDivisor80Minimum || divisor80 > 257u ||
        divisor20000 < kDivisor20000Minimum ||
        divisor20000 > kDivisor20000Maximum) {
        return false;
    }

    const BusWords words = encodeDivisors(divisor20000, divisor80);
    program->divisor20000 = divisor20000;
    program->divisor80 = divisor80;
    program->dataByAddress[0] = words.address0;
    program->dataByAddress[1] = words.address1;
    program->dataByAddress[2] = words.address2;
    program->dataByAddress[3] = words.address3;
    return true;
}

}  // namespace instrument_bus
}  // namespace adret
