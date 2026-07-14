#pragma once

#include <stdint.h>

#include "Adret/OperatingController.h"

namespace adret {

class SettingsStore final {
public:
    SettingsStore() = default;
    SettingsStore(const SettingsStore&) = delete;
    SettingsStore& operator=(const SettingsStore&) = delete;

    bool load(control::Settings* settings);
    bool saveNow(const control::Settings& settings);

private:
    uint16_t generation_ = 0;
    uint8_t activeSlot_ = 0;
    bool hasValidSlot_ = false;
};

extern SettingsStore settingsStore;

}  // namespace adret
