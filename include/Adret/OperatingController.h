#pragma once

#include <stdint.h>

#include "Adret/FrontPanel.h"

namespace adret {
namespace control {

enum class Target : uint8_t {
    Frequency,
    Amplitude,
    Fm,
    Pm,
    Am,
};

enum class ModulationMode : uint8_t {
    Fm,
    Pm,
    Am,
};

enum class ModulationSource : uint8_t {
    Cw,
    Hz400,
    KHz1,
    External,
};

struct Settings {
    uint32_t frequencyHz;
    uint32_t fmHz;
    int16_t amplitudeTenthsDbm;
    uint16_t pmHundredthsRd;
    uint16_t amTenthsPercent;
    Target target;
    Target wheelTarget;
    ModulationMode modulationMode;
    ModulationSource modulationSource;
    uint8_t frequencyStepIndex;
    uint8_t amplitudeStepIndex;
    uint8_t fmStepIndex;
    uint8_t pmStepIndex;
    uint8_t amStepIndex;
    bool wheelInhibited;
    bool rfOff;
};

Settings defaultSettings();
bool settingsAreValid(const Settings& settings);

class OperatingController final {
public:
    OperatingController() = default;
    OperatingController(const OperatingController&) = delete;
    OperatingController& operator=(const OperatingController&) = delete;

    void begin(const Settings& settings);
    void handleKey(front_panel::Key key);
    void handleEncoder(const front_panel::EncoderEvent& event);
    void tick(uint32_t nowMs);

    const Settings& settings() const;

private:
    void selectTarget(Target target);
    void selectSource(ModulationSource source);
    void changeStep(bool multiply);
    void startStepBlink();
    void applyBlinkMask(bool blank);
    void renderAll();
    void renderIndicators();
    void renderDisplays();
    void renderModulationDisplay();
    void reportTarget() const;
    void reportStep() const;
    void reportValue(Target target, bool instrumentEvent) const;

    uint32_t currentStep() const;
    uint8_t currentStepIndex() const;
    uint8_t currentStepMaximumIndex() const;
    uint8_t displayStepPosition() const;
    front_panel::DisplayField targetDisplayField() const;

    Settings settings_ = {};
    bool blinkActive_ = false;
    bool blinkBlank_ = false;
    uint8_t blinkPhasesRemaining_ = 0;
    uint32_t previousBlinkMs_ = 0;
};

extern OperatingController operatingController;

}  // namespace control
}  // namespace adret
