#pragma once

#include <stdint.h>

#include "Adret/InstrumentBusTypes.h"
#include "Adret/InstrumentFrequencyPlan.h"

namespace adret {
namespace instrument_bus {

enum class ModulationKind : uint8_t {
    Am,
    Fm,
    Pm,
};

enum class ModulationSource : uint8_t {
    Cw,
    External,
    Internal1kHz,
    Internal400Hz,
};

constexpr uint8_t kMaximumModulationWrites = 7u;

struct ModulationProgram {
    ModulationKind kind;
    ModulationSource source;
    uint16_t scaledValue;
    bool highFmRange;
    uint8_t writeCount;
    InstrumentWrite writes[kMaximumModulationWrites];
};

constexpr uint16_t kAmMaximumTenthsPercent = 999u;
constexpr uint32_t kFmLowRangeEndHz = 20000u;
// The four BCD digits encode at most 19.99 in either FM range. The documented
// 200 kHz endpoint still needs a bench vector from the original CPU.
constexpr uint32_t kFmMaximumExactlyEncodedHz = 199900u;
constexpr uint16_t kPmMaximumHundredthsRadian = 1999u;

bool makeAmModulationProgram(uint16_t tenthsPercent,
                             ModulationSource source,
                             const FrequencyPlan& frequency,
                             uint8_t currentAddress6,
                             bool highLevelRange,
                             ModulationProgram* program);

bool makeFmModulationProgram(uint32_t deviationHz,
                             ModulationSource source,
                             const FrequencyPlan& frequency,
                             uint8_t currentAddress6,
                             bool highLevelRange,
                             ModulationProgram* program);

bool makePmModulationProgram(uint16_t hundredthsRadian,
                             ModulationSource source,
                             const FrequencyPlan& frequency,
                             uint8_t currentAddress6,
                             bool highLevelRange,
                             ModulationProgram* program);

}  // namespace instrument_bus
}  // namespace adret
