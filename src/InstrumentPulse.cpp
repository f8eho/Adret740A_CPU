#include "Adret/InstrumentPulse.h"

namespace adret {
namespace instrument_bus {

PulseRequestResult makePulseRegisterState(
    bool enabled,
    bool optionInstalled,
    ModulationKind currentModulation,
    const FrequencyPlan& frequency,
    uint8_t currentAddress6,
    PulseRegisterState* state)
{
    if (state == nullptr) {
        return PulseRequestResult::InvalidArgument;
    }
    if (enabled && !optionInstalled) {
        return PulseRequestResult::OptionUnavailable;
    }
    if (enabled && currentModulation != ModulationKind::Am) {
        return PulseRequestResult::IncompatibleModulation;
    }

    state->address5 = makeAddress5WithPulse(frequency, enabled);
    state->address6 = mergeAddress6Pulse(currentAddress6, enabled);
    return PulseRequestResult::Ok;
}

}  // namespace instrument_bus
}  // namespace adret
