#pragma once

#include <stdint.h>

namespace adret {

class FrontPanelIrq final {
public:
    FrontPanelIrq() = default;
    FrontPanelIrq(const FrontPanelIrq&) = delete;
    FrontPanelIrq& operator=(const FrontPanelIrq&) = delete;

    void begin();
    uint8_t consumePending();
    bool hasPending() const;
    void onCa1FromIsr();
    bool ca1Asserted() const;

private:
    volatile uint8_t pending_ = 0;
};

extern FrontPanelIrq frontPanelIrq;

}  // namespace adret
