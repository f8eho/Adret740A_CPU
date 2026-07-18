#pragma once

#include <stdint.h>

#include "Adret/FrontPanel.h"

namespace adret {
namespace control {

constexpr uint32_t kFrequencyMinimumHz = 100000u;
constexpr uint32_t kFrequencyMaximumHz = 560000000u;
constexpr int16_t kAmplitudeMinimumTenthsDbm = -1299;
constexpr int16_t kAmplitudeMaximumTenthsDbm = 130;
constexpr uint32_t kFmMaximumHz = 200000u;
constexpr uint16_t kPmMaximumHundredthsRd = 1999u;
constexpr uint16_t kAmMaximumTenthsPercent = 999u;
constexpr uint32_t kFmFineRangeMaximumHz = 20000u;

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

enum class AmplitudeDisplayUnit : uint8_t {
    DBm,
    V,
    MV,
    UV,
};

struct OutputConfiguration {
    uint32_t frequencyHz;
    uint32_t fmHz;
    int16_t amplitudeTenthsDbm;
    uint16_t pmHundredthsRd;
    uint16_t amTenthsPercent;
    ModulationMode modulationMode;
    ModulationSource modulationSource;
    AmplitudeDisplayUnit amplitudeDisplayUnit;
    bool rfOff;
};

struct Settings {
    OutputConfiguration output;
    Target target;
    Target wheelTarget;
    uint8_t frequencyStepIndex;
    uint8_t amplitudeStepIndex;
    uint8_t fmStepIndex;
    uint8_t pmStepIndex;
    uint8_t amStepIndex;
    bool wheelInhibited;
};

Settings defaultSettings();
bool outputConfigurationIsValid(const OutputConfiguration& configuration);
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

    void enterRemoteControl();
    void applyRemoteConfiguration(const OutputConfiguration& configuration);
    void defineRemoteSequence(uint8_t start, uint8_t end);
    void clearRemoteSequence();
    void showRemoteError(const char* code, int8_t memoryIndex = -1);
    void clearRemoteError();

    const Settings& settings() const;

private:
    enum class EntryMode : uint8_t {
        None,
        Numeric,
        Memory,
        Recall,
        Sequence,
    };

    enum class Overlay : uint8_t {
        None,
        Active,
        Message,
    };

    void selectTarget(Target target);
    void selectSource(ModulationSource source);
    void handleDigit(uint8_t digit);
    void handleDecimalPoint();
    void handleLeft();
    void handleUnit(front_panel::Key key);
    void handleIncrement();
    void handleIncrementStep(bool increase);
    void handleExec();
    void handleClear();
    void handleXToY();
    void beginCommand(EntryMode mode);
    void finishMemoryCommand();
    void finishRecallCommand();
    void finishSequenceCommand();
    void stepSequence(bool restart);
    void ensurePending();
    void cancelNumericEntry();
    void failEntry(const char* code);
    bool commitNumericEntry(front_panel::Key unitKey, const char** errorCode);
    bool completedEntryCanBeIncrement() const;
    void restoreCompletedEntryBase();
    void renderEntry();
    void renderIncrementView();
    void renderMessage(const char* text, uint32_t durationMs);
    void updateExecIndicator();
    void reportInstrumentTransaction(const OutputConfiguration& configuration);
    void changeStep(bool multiply);
    void startStepBlink();
    void applyBlinkMask(bool blank);
    void renderAll();
    void renderIndicators();
    void renderDisplays();
    void renderModulationDisplay(const OutputConfiguration& configuration);
    void reportTarget() const;
    void reportStep() const;
    void reportValue(Target target, bool instrumentEvent) const;

    uint32_t currentStep() const;
    uint8_t currentStepIndex() const;
    uint8_t currentStepMaximumIndex() const;
    uint8_t displayStepPosition() const;
    front_panel::DisplayField targetDisplayField() const;

    OutputConfiguration& editableOutput();
    const OutputConfiguration& displayedOutput() const;

    Settings settings_ = {};
    OutputConfiguration pending_ = {};
    OutputConfiguration entryBase_ = {};
    bool pendingActive_ = false;
    bool recalledPending_ = false;
    bool entryHadPending_ = false;
    bool entryLocked_ = false;
    EntryMode entryMode_ = EntryMode::None;
    char entryDigits_[11] = {};
    uint8_t entryDigitCount_ = 0;
    int8_t entryDecimalIndex_ = -1;
    bool completedEntryAvailable_ = false;
    bool completedEntryDeferredError_ = false;
    bool completedEntryIncrementCompatible_ = false;
    uint32_t completedEntryValue_ = 0;
    const char* completedEntryErrorCode_ = nullptr;
    uint32_t keyboardIncrements_[5] = {};
    uint8_t keyboardIncrementDefinedMask_ = 0;
    bool incrementViewActive_ = false;
    uint32_t commandDeadlineMs_ = 0;
    Overlay overlay_ = Overlay::None;
    uint32_t overlayDeadlineMs_ = 0;
    bool sequenceDefined_ = false;
    bool sequenceActive_ = false;
    bool sequenceCursorValid_ = false;
    uint8_t sequenceStart_ = 0;
    uint8_t sequenceEnd_ = 0;
    uint8_t sequenceCursor_ = 0;
    bool blinkActive_ = false;
    bool blinkBlank_ = false;
    bool correctionBlink_ = false;
    front_panel::DisplayField correctionBlinkField_ =
        front_panel::DisplayField::Frequency;
    uint8_t correctionBlinkPosition_ = 0;
    uint8_t blinkPhasesRemaining_ = 0;
    uint32_t previousBlinkMs_ = 0;
    uint8_t instrumentRegisters_[16] = {};
    bool instrumentRegistersInitialized_ = false;
};

extern OperatingController operatingController;

}  // namespace control
}  // namespace adret
