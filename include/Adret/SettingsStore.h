#pragma once

#include <stdint.h>

#include "Adret/OperatingController.h"

namespace adret {

class SettingsStore final {
public:
    static constexpr uint8_t kMemoryCount = 40u;

    SettingsStore() = default;
    SettingsStore(const SettingsStore&) = delete;
    SettingsStore& operator=(const SettingsStore&) = delete;

    bool load(control::Settings* settings);
    bool saveNow(const control::Settings& settings);
    bool loadMemory(uint8_t index, control::OutputConfiguration* configuration);
    bool saveMemory(uint8_t index, const control::OutputConfiguration& configuration);

private:
    uint16_t generation_ = 0;
    uint8_t activeSlot_ = 0;
    bool hasValidSlot_ = false;
};

extern SettingsStore settingsStore;

}  // namespace adret
