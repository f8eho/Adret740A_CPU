#pragma once

#include <stdint.h>

#include "Adret/InstrumentFrequencyPlan.h"
#include "Adret/InstrumentModulation.h"

namespace adret {
namespace instrument_bus {

enum class PulseRequestResult : uint8_t {
    Ok,
    OptionUnavailable,
    IncompatibleModulation,
    InvalidArgument,
};

// Pulse modulation shares fields with two existing cards. These are target
// register images, not a complete bus transaction: the controller must merge
// them into the normal frequency/modulation programming sequence.
struct PulseRegisterState {
    uint8_t address5;
    uint8_t address6;
};

// Disabling is always accepted, including when the option is absent. Enabling
// requires the optional hardware and AM as the selected modulation family.
PulseRequestResult makePulseRegisterState(
    bool enabled,
    bool optionInstalled,
    ModulationKind currentModulation,
    const FrequencyPlan& frequency,
    uint8_t currentAddress6,
    PulseRegisterState* state);

}  // namespace instrument_bus
}  // namespace adret
