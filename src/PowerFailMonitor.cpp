#include "Adret/PowerFailMonitor.h"

#include <avr/interrupt.h>
#include <util/atomic.h>

#include "Adret/HardwareConfig.h"

namespace adret {

PowerFailMonitor powerFailMonitor;

void PowerFailMonitor::begin()
{
    if (!hw::kPowerSenseEnabled) {
        return;
    }

    ADRET_PA_DDR &= uint8_t(~_BV(hw::kPowerSenseBit));
    ADRET_PA_PORT &= uint8_t(~_BV(hw::kPowerSenseBit));
    EIMSK &= uint8_t(~hw::kPowerSenseInterruptMask);
    EICRB &= uint8_t(~(_BV(hw::kPowerSenseSenseBit0) |
                       _BV(hw::kPowerSenseSenseBit1)));
    EICRB |= _BV(hw::kPowerSenseSenseBit1);
    if (!hw::kPowerSenseActiveLow) {
        EICRB |= _BV(hw::kPowerSenseSenseBit0);
    }
    EIFR = hw::kPowerSenseInterruptFlag;
    EIMSK |= hw::kPowerSenseInterruptMask;
}

bool PowerFailMonitor::consumePending()
{
    bool result = false;
    ATOMIC_BLOCK(ATOMIC_RESTORESTATE) {
        result = pending_;
        pending_ = false;
    }
    return result;
}

void PowerFailMonitor::onInterruptFromIsr()
{
    pending_ = true;
}

}  // namespace adret

ISR(INT5_vect)
{
    adret::powerFailMonitor.onInterruptFromIsr();
}
