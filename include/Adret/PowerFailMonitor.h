#pragma once

namespace adret {

class PowerFailMonitor final {
public:
    void begin();
    bool consumePending();
    void onInterruptFromIsr();

private:
    volatile bool pending_ = false;
};

extern PowerFailMonitor powerFailMonitor;

}  // namespace adret
