#pragma once

#include <stdint.h>

#include "Adret/FrontPanelMap.h"

class __FlashStringHelper;

namespace adret {
namespace front_panel {

enum class PanelIndicator : uint8_t {
    Rf,
    Fm,
    Pm,
    Am,
    Amplitude,
    DBm,
    DB,
    DBuV,
    Volt,
    MilliVolt,
    MicroVolt,
    Hz400,
    KHz1,
    External,
    Cw,
    Error,
    Dept,
    Normal,
    ModRd,
    ModKHz,
    ModPercent,
    Memory,
    Sequence,
    Remote,
    RfInhibit,
    ManualValidation,
};

enum class DisplayField : uint8_t {
    Frequency,
    Modulation,
    Amplitude,
};

enum class Key : uint8_t {
    None,
    Amplitude,
    Rf,
    Fm,
    Pm,
    Am,
    Spl,
    Digit0,
    Digit1,
    Digit2,
    Digit3,
    Digit4,
    Digit5,
    Digit6,
    Digit7,
    Digit8,
    Digit9,
    Mhz,
    KHz,
    Hz,
    Cw,
    External,
    KHz1,
    Hz400,
    Divide10,
    Multiply10,
    ValidManual,
    Exec,
    Sequence,
    Memory,
    Recall,
    Increment,
    RfOff,
    Address17,
    XToY,
    Left,
    Clear,
    DecimalPoint,
    DBm,
    OneDBm,
    Up,
    Down,
};

struct KeyEvent {
    Key key;
    KeyboardSample sample;
};

struct EncoderEvent {
    KeyboardSample sample;
    int8_t step;
};

const __FlashStringHelper* keyShortLabel(Key key);

struct DisplayBuffers {
    char frequencyHz[11];
    char frequencySn10[9];
    char frequencySn11[3];
    char modulation[7];
    char amplitude[7];
};

}  // namespace front_panel

class FrontPanel final {
public:
    static constexpr uint8_t kKeyQueueCapacity = 8;
    static constexpr uint8_t kEncoderQueueCapacity = 8;

    FrontPanel() = default;
    FrontPanel(const FrontPanel&) = delete;
    FrontPanel& operator=(const FrontPanel&) = delete;

    void begin();
    void reset();
    void flushOutputs();

    void setIndicator(front_panel::PanelIndicator indicator, bool enabled);
    void turnOn(front_panel::PanelIndicator indicator);
    void turnOff(front_panel::PanelIndicator indicator);
    bool isOn(front_panel::PanelIndicator indicator) const;
    void clearIndicators();
    void setMemoryMode(front_panel::MemoryLedMode mode);

    void setFrequencyHz(uint32_t frequencyHz);
    void setModulationValue(uint32_t value,
                            front_panel::ModulationUnitLed unit,
                            bool decimalPoint);
    void setModulationDisplay(uint16_t digits,
                              front_panel::ModulationUnitLed unit,
                              uint8_t icmDecimalMask,
                              bool leadingOne);
    void setAmplitudeValue(int32_t value,
                           front_panel::AmplitudeUnitLed unit,
                           bool decimalPoint);
    void setAmplitudeDisplay(int16_t tenthsDbm,
                             uint8_t icmDecimalMask,
                             bool leadingOne);
    void setDisplayDecimalMask(front_panel::DisplayField field, uint16_t mask);
    void setDisplayBlankMask(front_panel::DisplayField field, uint16_t mask);
    void refreshDisplays();

    void pollInputs();
    bool popKey(front_panel::KeyEvent* event);
    bool popEncoder(front_panel::EncoderEvent* event);
    int16_t consumeEncoderDelta();
    uint8_t keyOverflowCount() const;
    uint8_t encoderOverflowCount() const;
    const front_panel::DisplayBuffers& displayBuffers() const;

private:
    static front_panel::Key keyForSample(const front_panel::KeyboardSample& sample);
    static void formatUnsigned(uint32_t value, char* out, uint8_t width);
    static void formatSignedMagnitude(int32_t value, char* out, uint8_t width);

    void flushSn2();
    void flushSn3();
    void flushFlags();
    void makeDisplayFrames(uint8_t* sn10, uint8_t* sn11) const;
    void pushKey(const front_panel::KeyboardSample& sample);
    void pushEncoder(const front_panel::KeyboardSample& sample, int8_t step);

    front_panel::FunctionLed functionLed_ = front_panel::FunctionLed::None0;
    front_panel::AmplitudeUnitLed amplitudeUnit_ = front_panel::AmplitudeUnitLed::None6;
    front_panel::ModulationSourceLed modulationSource_ = front_panel::ModulationSourceLed::Cw;
    front_panel::StatusLed statusLed_ = front_panel::StatusLed::Normal;
    front_panel::ModulationUnitLed modulationUnit_ = front_panel::ModulationUnitLed::None;
    front_panel::MemoryLedMode memoryMode_ = front_panel::MemoryLedMode::None;
    bool memory_ = false;
    bool sequence_ = false;
    uint8_t firstCharFlags_ = front_panel::kPowerOneBlank;
    uint8_t decimalPointFlags_ = 0;
    uint16_t frequencyBlankMask_ = 0;
    uint8_t modulationBlankMask_ = 0;
    uint8_t amplitudeBlankMask_ = 0;
    uint16_t frequencyIcmDecimalMask_ = 0;
    uint8_t modulationIcmDecimalMask_ = 0;
    uint8_t amplitudeIcmDecimalMask_ = 0;

    front_panel::DisplayBuffers displayBuffers_ = {};
    front_panel::KeyEvent keyQueue_[kKeyQueueCapacity] = {};
    uint8_t keyHead_ = 0;
    uint8_t keyCount_ = 0;
    uint8_t keyOverflowCount_ = 0;
    front_panel::EncoderEvent encoderQueue_[kEncoderQueueCapacity] = {};
    uint8_t encoderHead_ = 0;
    uint8_t encoderCount_ = 0;
    uint8_t encoderOverflowCount_ = 0;
    int16_t encoderDelta_ = 0;
    front_panel::Key lastQueuedKey_ = front_panel::Key::None;
    uint32_t lastQueuedKeyMs_ = 0;
};

extern FrontPanel frontPanel;

}  // namespace adret
