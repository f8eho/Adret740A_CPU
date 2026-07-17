#include "Adret/FrontPanelIrq.h"

#include <avr/interrupt.h>
#include <util/atomic.h>

#include "Adret/HardwareConfig.h"

namespace adret {

FrontPanelIrq frontPanelIrq;

void FrontPanelIrq::begin()
{
    ADRET_FP_CA1_DDR &= uint8_t(~_BV(hw::kFrontPanelCa1Bit));
    ADRET_FP_CA1_PORT |= _BV(hw::kFrontPanelCa1Bit);  // Enable D2/PE4 pull-up.

    EIMSK &= uint8_t(~hw::kFrontPanelCa1InterruptMask);
    EICRB = uint8_t((EICRB & uint8_t(~(_BV(hw::kFrontPanelCa1SenseBit0) |
                                      _BV(hw::kFrontPanelCa1SenseBit1)))) |
                    _BV(hw::kFrontPanelCa1SenseBit1));  // Falling edge on CA1.
    EIFR = hw::kFrontPanelCa1InterruptFlag;
    EIMSK |= hw::kFrontPanelCa1InterruptMask;
}

uint8_t FrontPanelIrq::consumePending()
{
    uint8_t result = 0;
    ATOMIC_BLOCK(ATOMIC_RESTORESTATE) {
        result = pending_;
        pending_ = 0;
    }
    return result;
}

bool FrontPanelIrq::hasPending() const
{
    return pending_ != 0u;
}

void FrontPanelIrq::onCa1FromIsr()
{
    if (pending_ != 0xFFu) {
        ++pending_;
    }
}

bool FrontPanelIrq::ca1Asserted() const
{
    return (ADRET_FP_CA1_PIN & _BV(hw::kFrontPanelCa1Bit)) == 0u;
}

}  // namespace adret

ISR(INT4_vect)
{
    adret::frontPanelIrq.onCa1FromIsr();
}
