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
    void onCa1FromIsr();

private:
    volatile uint8_t pending_ = 0;
};

extern FrontPanelIrq frontPanelIrq;

}  // namespace adret
