#include "Adret/InstrumentCapabilities.h"

#include "Adret/HardwareConfig.h"

namespace adret {

InstrumentCapabilities detectInstrumentCapabilities()
{
    ADRET_DOUBLER_JUMPER_DDR &= uint8_t(~_BV(hw::kDoublerJumperBit));
    ADRET_DOUBLER_JUMPER_PORT |= _BV(hw::kDoublerJumperBit);
    hw::waitTtlSettle();
    const bool inputIsHigh =
        (ADRET_DOUBLER_JUMPER_PIN & _BV(hw::kDoublerJumperBit)) != 0u;
    return capabilitiesFromDoublerJumperLevel(inputIsHigh);
}

}  // namespace adret
