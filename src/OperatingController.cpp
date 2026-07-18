#include "Adret/OperatingController.h"

#include <Arduino.h>
#include <math.h>

#include "Adret/CalibrationEprom.h"
#include "Adret/Debug.h"
#include "Adret/InstrumentBus.h"
#include "Adret/InstrumentProgram.h"
#include "Adret/SettingsStore.h"

namespace adret {
namespace control {

namespace {

using front_panel::AmplitudeUnitLed;
using front_panel::DisplayField;
using front_panel::ExecIndicator;
using front_panel::Key;
using front_panel::ModulationUnitLed;
using front_panel::PanelIndicator;

constexpr uint16_t kBlinkPhaseMs = 150u;
constexpr uint8_t kBlinkPhaseCount = 6u;
constexpr uint32_t kOverlayDurationMs = 2000u;
constexpr uint32_t kSequenceEntryTimeoutMs = 2000u;

constexpr uint32_t kFrequencySteps[] = {
    10u, 100u, 1000u, 10000u, 100000u, 1000000u, 10000000u, 100000000u,
};
constexpr uint16_t kAmplitudeSteps[] = {1u, 10u, 100u};
constexpr uint32_t kFmSteps[] = {10u, 100u, 1000u, 10000u, 100000u};
constexpr uint16_t kPmSteps[] = {1u, 10u, 100u, 1000u};
constexpr uint16_t kAmSteps[] = {1u, 10u, 100u};

struct DisplaySpec {
    uint16_t digits;
    uint8_t decimalMask;
    bool leadingOne;
};

template <typename T, uint8_t N>
constexpr uint8_t itemCount(const T (&)[N])
{
    return N;
}

#if !ADRET_INSTRUMENT_BUS_BENCH
instrument_bus::ModulationKind instrumentModulationKind(ModulationMode mode)
{
    switch (mode) {
        case ModulationMode::Fm:
            return instrument_bus::ModulationKind::Fm;
        case ModulationMode::Pm:
            return instrument_bus::ModulationKind::Pm;
        case ModulationMode::Am:
            return instrument_bus::ModulationKind::Am;
    }
    return instrument_bus::ModulationKind::Am;
}

instrument_bus::ModulationSource instrumentModulationSource(
    ModulationSource source)
{
    switch (source) {
        case ModulationSource::Cw:
            return instrument_bus::ModulationSource::Cw;
        case ModulationSource::Hz400:
            return instrument_bus::ModulationSource::Internal400Hz;
        case ModulationSource::KHz1:
            return instrument_bus::ModulationSource::Internal1kHz;
        case ModulationSource::External:
            return instrument_bus::ModulationSource::External;
    }
    return instrument_bus::ModulationSource::Cw;
}

instrument_bus::InstrumentConfiguration instrumentConfiguration(
    const OutputConfiguration& configuration)
{
    return {
        configuration.frequencyHz,
        configuration.amplitudeTenthsDbm,
        configuration.fmHz,
        configuration.pmHundredthsRd,
        configuration.amTenthsPercent,
        instrumentModulationKind(configuration.modulationMode),
        instrumentModulationSource(configuration.modulationSource),
        configuration.rfOff,
        false,
        false,
        false,
    };
}
#endif

constexpr uint32_t powerOfTen(uint8_t exponent)
{
    return exponent == 0u ? 1u
        : exponent == 1u ? 10u
        : exponent == 2u ? 100u
        : exponent == 3u ? 1000u
        : exponent == 4u ? 10000u
        : exponent == 5u ? 100000u
        : exponent == 6u ? 1000000u
        : exponent == 7u ? 10000000u
        : exponent == 8u ? 100000000u
        : 1000000000u;
}

constexpr uint32_t exactScaledValue(uint32_t digits,
                                    uint8_t fractionalDigits,
                                    uint32_t multiplier)
{
    return fractionalDigits > 9u
        ? UINT32_MAX
        : ((uint64_t(digits) * multiplier) % powerOfTen(fractionalDigits)) != 0u
            ? UINT32_MAX
            : (uint64_t(digits) * multiplier) /
                    powerOfTen(fractionalDigits) > UINT32_MAX
                ? UINT32_MAX
                : uint32_t((uint64_t(digits) * multiplier) /
                           powerOfTen(fractionalDigits));
}

constexpr uint8_t decimalDigitCount(uint32_t value)
{
    return value >= 1000000000u ? 10u
        : value >= 100000000u ? 9u
        : value >= 10000000u ? 8u
        : value >= 1000000u ? 7u
        : value >= 100000u ? 6u
        : value >= 10000u ? 5u
        : value >= 1000u ? 4u
        : value >= 100u ? 3u
        : value >= 10u ? 2u : 1u;
}

constexpr uint16_t frequencyLeadingBlankMask(uint32_t frequencyHz)
{
    return uint16_t(0x03FFu &
        ~uint16_t((uint16_t(1u) << decimalDigitCount(frequencyHz)) - 1u));
}

constexpr uint16_t frequencySeparatorMask(uint32_t frequencyHz)
{
    return uint16_t((uint16_t(1u) << 3u) |
        (frequencyHz >= 1000000u ? uint16_t(1u) << 6u : 0u));
}

constexpr uint32_t quantizedFrequencyHz(uint32_t frequencyHz)
{
    return frequencyHz - (frequencyHz % 10u);
}

bool scaledInteger(uint32_t digits,
                   uint8_t fractionalDigits,
                   uint32_t multiplier,
                   uint32_t* result)
{
    if (fractionalDigits > 9u) {
        return false;
    }
    const uint64_t numerator = uint64_t(digits) * multiplier;
    const uint32_t denominator = powerOfTen(fractionalDigits);
    if (denominator == 0u || (numerator % denominator) != 0u ||
        (numerator / denominator) > UINT32_MAX) {
        return false;
    }
    *result = uint32_t(numerator / denominator);
    return true;
}

bool parseDigits(const char* text, uint8_t count, uint32_t* result)
{
    uint64_t value = 0u;
    for (uint8_t i = 0; i < count; ++i) {
        value = value * 10u + uint8_t(text[i] - '0');
        if (value > UINT32_MAX) {
            return false;
        }
    }
    *result = uint32_t(value);
    return true;
}

constexpr uint32_t effectiveFmStep(uint32_t valueHz, uint8_t index)
{
    return (valueHz >= kFmFineRangeMaximumHz && kFmSteps[index] < 100u)
        ? 100u
        : kFmSteps[index];
}

constexpr DisplaySpec fmDisplaySpec(uint32_t valueHz)
{
    return valueHz < 20000u
        ? DisplaySpec{uint16_t((valueHz / 10u) % 1000u),
                      0x04u, (valueHz / 10u) >= 1000u}
        : (valueHz < 200000u
            ? DisplaySpec{uint16_t((valueHz / 100u) % 1000u),
                          0x02u, (valueHz / 100u) >= 1000u}
            : DisplaySpec{200u, 0u, false});
}

constexpr DisplaySpec pmDisplaySpec(uint16_t hundredthsRd)
{
    return DisplaySpec{uint16_t(hundredthsRd % 1000u), 0x04u,
                       hundredthsRd >= 1000u};
}

constexpr uint32_t keyboardIncrementMaximum(Target target)
{
    return target == Target::Frequency ? kFrequencyMaximumHz
        : target == Target::Amplitude
            ? uint32_t(kAmplitudeMaximumTenthsDbm -
                       kAmplitudeMinimumTenthsDbm)
        : target == Target::Fm ? kFmMaximumHz
        : target == Target::Pm ? kPmMaximumHundredthsRd
        : kAmMaximumTenthsPercent;
}

#if ADRET_DEBUG_SERIAL
const __FlashStringHelper* targetName(Target target)
{
    switch (target) {
    case Target::Frequency: return F("FREQ");
    case Target::Amplitude: return F("AMPL");
    case Target::Fm: return F("FM");
    case Target::Pm: return F("PM");
    case Target::Am: return F("AM");
    }
    return F("UNKNOWN");
}

const __FlashStringHelper* sourceName(ModulationSource source)
{
    switch (source) {
    case ModulationSource::Cw: return F("CW");
    case ModulationSource::Hz400: return F("400HZ");
    case ModulationSource::KHz1: return F("1KHZ");
    case ModulationSource::External: return F("EXT");
    }
    return F("UNKNOWN");
}
#endif

uint32_t clampUnsignedStep(uint32_t value,
                           int8_t direction,
                           uint32_t step,
                           uint32_t minimum,
                           uint32_t maximum)
{
    if (direction > 0) {
        return (value >= maximum - step) ? maximum : value + step;
    }
    return (value <= minimum + step) ? minimum : value - step;
}

int16_t clampSignedStep(int16_t value,
                        int8_t direction,
                        uint16_t step,
                        int16_t minimum,
                        int16_t maximum)
{
    const int32_t candidate = int32_t(value) +
                              (direction > 0 ? int32_t(step) : -int32_t(step));
    if (candidate < minimum) {
        return minimum;
    }
    if (candidate > maximum) {
        return maximum;
    }
    return int16_t(candidate);
}

uint8_t decimalPosition(uint32_t step, uint32_t displayResolution)
{
    uint8_t position = 0;
    uint32_t scaled = step / displayResolution;
    while (scaled > 1u) {
        scaled /= 10u;
        ++position;
    }
    return position;
}

int8_t digitForKey(Key key)
{
    if (key >= Key::Digit0 && key <= Key::Digit9) {
        return int8_t(uint8_t(key) - uint8_t(Key::Digit0));
    }
    return -1;
}

bool timeReached(uint32_t now, uint32_t deadline)
{
    return int32_t(now - deadline) >= 0;
}

static_assert(itemCount(kFrequencySteps) == 8u &&
              itemCount(kAmplitudeSteps) == 3u &&
              itemCount(kFmSteps) == 5u &&
              itemCount(kPmSteps) == 4u &&
              itemCount(kAmSteps) == 3u,
              "Unexpected control step tables");
static_assert(powerOfTen(0u) == 1u && powerOfTen(4u) == 10000u,
              "Unexpected decimal scaling");
static_assert(exactScaledValue(54321u, 2u, 1000000u) == 543210000u &&
              exactScaledValue(125u, 1u, 1000u) == 12500u &&
              exactScaledValue(123456u, 0u, 1u) == 123456u &&
              exactScaledValue(1u, 1u, 1u) == UINT32_MAX,
              "Unexpected exact unit conversion");
static_assert(frequencySeparatorMask(999999u) == 0x0008u &&
              frequencySeparatorMask(1000000u) == 0x0048u,
              "Unexpected frequency separator threshold");
static_assert(quantizedFrequencyHz(123456u) == 123450u &&
              quantizedFrequencyHz(123450u) == 123450u,
              "Unexpected 10 Hz frequency quantization");
static_assert(frequencyLeadingBlankMask(100000u) == 0x03C0u &&
              frequencyLeadingBlankMask(1000000u) == 0x0380u &&
              frequencyLeadingBlankMask(10000000u) == 0x0300u &&
              frequencyLeadingBlankMask(560000000u) == 0x0200u,
              "Unexpected frequency leading-zero mask");
static_assert(effectiveFmStep(19999u, 0u) == 10u &&
              effectiveFmStep(20000u, 0u) == 100u,
              "Unexpected FM fine-range threshold");
static_assert(keyboardIncrementMaximum(Target::Frequency) == 560000000u &&
              keyboardIncrementMaximum(Target::Amplitude) == 1429u,
              "Unexpected keyboard increment limits");

}  // namespace

OperatingController operatingController;

Settings defaultSettings()
{
    Settings result = {};
    result.output.frequencyHz = kFrequencyMinimumHz;
    result.output.fmHz = 0u;
    result.output.amplitudeTenthsDbm = kAmplitudeMinimumTenthsDbm;
    result.output.pmHundredthsRd = 0u;
    result.output.amTenthsPercent = 0u;
    result.output.modulationMode = ModulationMode::Am;
    result.output.modulationSource = ModulationSource::Cw;
    result.output.amplitudeDisplayUnit = AmplitudeDisplayUnit::DBm;
    result.output.rfOff = true;
    result.target = Target::Frequency;
    result.wheelTarget = Target::Frequency;
    result.wheelInhibited = true;
    return result;
}

bool outputConfigurationIsValid(const OutputConfiguration& value)
{
    return value.frequencyHz >= kFrequencyMinimumHz &&
           value.frequencyHz <= kFrequencyMaximumHz &&
           value.fmHz <= kFmMaximumHz &&
           value.amplitudeTenthsDbm >= kAmplitudeMinimumTenthsDbm &&
           value.amplitudeTenthsDbm <= kAmplitudeMaximumTenthsDbm &&
           value.pmHundredthsRd <= kPmMaximumHundredthsRd &&
           value.amTenthsPercent <= kAmMaximumTenthsPercent &&
           uint8_t(value.modulationMode) <= uint8_t(ModulationMode::Am) &&
           uint8_t(value.modulationSource) <= uint8_t(ModulationSource::External) &&
           uint8_t(value.amplitudeDisplayUnit) <= uint8_t(AmplitudeDisplayUnit::UV);
}

bool settingsAreValid(const Settings& value)
{
    return outputConfigurationIsValid(value.output) &&
           uint8_t(value.target) <= uint8_t(Target::Am) &&
           uint8_t(value.wheelTarget) <= uint8_t(Target::Am) &&
           value.frequencyStepIndex < itemCount(kFrequencySteps) &&
           value.amplitudeStepIndex < itemCount(kAmplitudeSteps) &&
           value.fmStepIndex < itemCount(kFmSteps) &&
           value.pmStepIndex < itemCount(kPmSteps) &&
           value.amStepIndex < itemCount(kAmSteps);
}

void OperatingController::begin(const Settings& settings)
{
    settings_ = settingsAreValid(settings) ? settings : defaultSettings();
    settings_.output.rfOff = true;
    pending_ = settings_.output;
    renderAll();
#if ADRET_DEBUG_SERIAL
    Serial.print(F("STATE restored target="));
    Serial.print(targetName(settings_.target));
    Serial.print(F(" wheel_target="));
    Serial.print(targetName(settings_.wheelTarget));
    Serial.print(F(" wheel_inhibited="));
    Serial.print(settings_.wheelInhibited ? 1 : 0);
    Serial.println(F(" rf_off=1"));
#endif
    reportInstrumentTransaction(settings_.output);
}

void OperatingController::enterRemoteControl()
{
    pendingActive_ = false;
    recalledPending_ = false;
    entryHadPending_ = false;
    entryLocked_ = false;
    entryMode_ = EntryMode::None;
    entryDigitCount_ = 0u;
    entryDecimalIndex_ = -1;
    entryDigits_[0] = '\0';
    completedEntryAvailable_ = false;
    completedEntryDeferredError_ = false;
    completedEntryIncrementCompatible_ = false;
    completedEntryErrorCode_ = nullptr;
    incrementViewActive_ = false;
    overlay_ = Overlay::None;
    blinkActive_ = false;
    blinkBlank_ = false;
    correctionBlink_ = false;
    sequenceActive_ = false;
    sequenceCursorValid_ = false;
    frontPanel.turnOff(PanelIndicator::Memory);
    renderAll();
}

void OperatingController::applyRemoteConfiguration(
    const OutputConfiguration& configuration)
{
    if (!outputConfigurationIsValid(configuration)) {
        return;
    }
    settings_.output = configuration;
    pending_ = configuration;
    pendingActive_ = false;
    recalledPending_ = false;
    entryLocked_ = false;
    overlay_ = Overlay::None;
    renderAll();
    reportInstrumentTransaction(settings_.output);
}

void OperatingController::defineRemoteSequence(uint8_t start, uint8_t end)
{
    if (start >= SettingsStore::kMemoryCount ||
        end >= SettingsStore::kMemoryCount || start > end) {
        return;
    }
    sequenceDefined_ = true;
    sequenceActive_ = true;
    sequenceCursorValid_ = false;
    sequenceStart_ = start;
    sequenceEnd_ = end;
    renderIndicators();
}

void OperatingController::clearRemoteSequence()
{
    sequenceDefined_ = false;
    sequenceActive_ = false;
    sequenceCursorValid_ = false;
    renderIndicators();
}

void OperatingController::showRemoteError(const char* code, int8_t memoryIndex)
{
    frontPanel.turnOn(PanelIndicator::Error);
    if (memoryIndex >= 0 && memoryIndex < int8_t(SettingsStore::kMemoryCount)) {
        const char text[4] = {
            'E', char('0' + uint8_t(memoryIndex) / 10u),
            char('0' + uint8_t(memoryIndex) % 10u), '\0'};
        renderMessage(text, kOverlayDurationMs);
        return;
    }
    renderMessage(code == nullptr ? "E-00" : code, kOverlayDurationMs);
}

void OperatingController::clearRemoteError()
{
    overlay_ = Overlay::None;
    renderAll();
}

void OperatingController::handleKey(Key key)
{
    if (overlay_ != Overlay::None) {
        overlay_ = Overlay::None;
        renderAll();
    }

    if (completedEntryDeferredError_ && key != Key::Increment &&
        key != Key::Clear) {
        const char* code = completedEntryErrorCode_;
        restoreCompletedEntryBase();
        failEntry(code);
        return;
    }
    if (completedEntryAvailable_ && !completedEntryDeferredError_ &&
        key != Key::Increment) {
        completedEntryAvailable_ = false;
    }
    if (incrementViewActive_ && key != Key::Increment && key != Key::Up &&
        key != Key::Down) {
        incrementViewActive_ = false;
    }

    const int8_t digit = digitForKey(key);
    if (digit >= 0) {
        handleDigit(uint8_t(digit));
        return;
    }

    if ((entryMode_ == EntryMode::Memory || entryMode_ == EntryMode::Recall ||
         entryMode_ == EntryMode::Sequence) && key != Key::Clear &&
        key != Key::Sequence) {
        entryMode_ = EntryMode::None;
        frontPanel.turnOff(PanelIndicator::Memory);
        frontPanel.setIndicator(PanelIndicator::Sequence, sequenceActive_);
        failEntry(nullptr);
        return;
    }

    switch (key) {
    case Key::Rf: selectTarget(Target::Frequency); break;
    case Key::Amplitude: selectTarget(Target::Amplitude); break;
    case Key::Fm: selectTarget(Target::Fm); break;
    case Key::Pm: selectTarget(Target::Pm); break;
    case Key::Am: selectTarget(Target::Am); break;
    case Key::DecimalPoint: handleDecimalPoint(); break;
    case Key::Left: handleLeft(); break;
    case Key::Mhz:
    case Key::KHz:
    case Key::Hz:
    case Key::DBm:
    case Key::OneDBm:
        handleUnit(key);
        break;
    case Key::Increment: handleIncrement(); break;
    case Key::Exec: handleExec(); break;
    case Key::Clear: handleClear(); break;
    case Key::XToY: handleXToY(); break;
    case Key::Memory: beginCommand(EntryMode::Memory); break;
    case Key::Recall: beginCommand(EntryMode::Recall); break;
    case Key::Sequence:
        beginCommand(EntryMode::Sequence);
        if (sequenceDefined_) {
            sequenceActive_ = true;
            renderIndicators();
            char text[6] = {
                char('0' + sequenceStart_ / 10u),
                char('0' + sequenceStart_ % 10u), '-',
                char('0' + sequenceEnd_ / 10u),
                char('0' + sequenceEnd_ % 10u), '\0'};
            renderMessage(text, kSequenceEntryTimeoutMs);
        }
        break;
    case Key::Up: handleIncrementStep(true); break;
    case Key::Down: handleIncrementStep(false); break;
    case Key::Multiply10: changeStep(true); break;
    case Key::Divide10: changeStep(false); break;
    case Key::ValidManual:
        settings_.wheelTarget = settings_.target;
        settings_.wheelInhibited = false;
        renderIndicators();
#if ADRET_DEBUG_SERIAL
        Serial.print(F("VALID target="));
        Serial.print(targetName(settings_.wheelTarget));
        Serial.println(F(" active=1"));
#endif
        break;
    case Key::RfOff:
        settings_.output.rfOff = !settings_.output.rfOff;
        if (pendingActive_) {
            pending_.rfOff = settings_.output.rfOff;
        }
        renderIndicators();
        reportInstrumentTransaction(settings_.output);
#if ADRET_DEBUG_SERIAL
        Serial.print(F("RF_OFF value="));
        Serial.println(settings_.output.rfOff ? 1 : 0);
        Serial.print(F("INSTR rf_off="));
        Serial.println(settings_.output.rfOff ? 1 : 0);
#endif
        break;
    case Key::Cw: selectSource(ModulationSource::Cw); break;
    case Key::Hz400: selectSource(ModulationSource::Hz400); break;
    case Key::KHz1: selectSource(ModulationSource::KHz1); break;
    case Key::External: selectSource(ModulationSource::External); break;
    default: break;
    }
}

void OperatingController::handleDigit(uint8_t digit)
{
    if (entryMode_ == EntryMode::Memory || entryMode_ == EntryMode::Recall ||
        entryMode_ == EntryMode::Sequence) {
        const uint8_t required = entryMode_ == EntryMode::Sequence ? 4u : 2u;
        if (entryDigitCount_ >= required) {
            failEntry(nullptr);
            return;
        }
        entryDigits_[entryDigitCount_++] = char('0' + digit);
        entryDigits_[entryDigitCount_] = '\0';
        frontPanel.setFrequencyText(entryDigits_);
        frontPanel.refreshDisplays();
        if (entryDigitCount_ == required) {
            if (entryMode_ == EntryMode::Memory) {
                finishMemoryCommand();
            } else if (entryMode_ == EntryMode::Recall) {
                finishRecallCommand();
            } else {
                finishSequenceCommand();
            }
        }
        return;
    }

    if (entryLocked_) {
#if ADRET_DEBUG_SERIAL
        Serial.println(F("ENTRY ignored=1 reason=SELECT_OR_EXEC"));
#endif
        return;
    }
    if (entryMode_ == EntryMode::None) {
        entryHadPending_ = pendingActive_;
        ensurePending();
        entryBase_ = pending_;
        entryMode_ = EntryMode::Numeric;
        entryDigitCount_ = 0u;
        entryDecimalIndex_ = -1;
        entryDigits_[0] = '\0';
    }
    const uint8_t maximumDigits = settings_.target == Target::Frequency ? 10u : 4u;
    if (entryDigitCount_ >= maximumDigits) {
        failEntry(nullptr);
        return;
    }
    entryDigits_[entryDigitCount_++] = char('0' + digit);
    entryDigits_[entryDigitCount_] = '\0';
    uint32_t parsed = 0u;
    if (!parseDigits(entryDigits_, entryDigitCount_, &parsed)) {
        failEntry(nullptr);
        return;
    }
    renderEntry();
    updateExecIndicator();
#if ADRET_DEBUG_SERIAL
    Serial.print(F("ENTRY target="));
    Serial.print(targetName(settings_.target));
    Serial.print(F(" digits="));
    Serial.println(entryDigits_);
#endif
}

void OperatingController::handleDecimalPoint()
{
    if (entryLocked_) {
        return;
    }
    if (entryMode_ == EntryMode::None) {
        entryHadPending_ = pendingActive_;
        ensurePending();
        entryBase_ = pending_;
        entryMode_ = EntryMode::Numeric;
        entryDigitCount_ = 0u;
        entryDigits_[0] = '\0';
    }
    if (entryMode_ != EntryMode::Numeric || entryDecimalIndex_ >= 0) {
        failEntry(nullptr);
        return;
    }
    entryDecimalIndex_ = int8_t(entryDigitCount_);
    renderEntry();
    updateExecIndicator();
}

void OperatingController::handleLeft()
{
    if (entryMode_ != EntryMode::Numeric) {
        return;
    }
    if (entryDigitCount_ > 0u) {
        --entryDigitCount_;
        entryDigits_[entryDigitCount_] = '\0';
        if (entryDecimalIndex_ > int8_t(entryDigitCount_)) {
            entryDecimalIndex_ = -1;
        }
    } else if (entryDecimalIndex_ >= 0) {
        entryDecimalIndex_ = -1;
    }
    renderEntry();
    if (entryDigitCount_ > 0u) {
        correctionBlink_ = true;
        correctionBlinkField_ = targetDisplayField();
        correctionBlinkPosition_ = 0u;
        blinkActive_ = true;
        blinkBlank_ = true;
        blinkPhasesRemaining_ = kBlinkPhaseCount;
        previousBlinkMs_ = millis();
        applyBlinkMask(true);
    }
}

void OperatingController::handleUnit(Key key)
{
    if (entryMode_ != EntryMode::Numeric || entryDigitCount_ == 0u) {
        failEntry(nullptr);
        return;
    }
    completedEntryAvailable_ = false;
    completedEntryDeferredError_ = false;
    completedEntryIncrementCompatible_ = false;
    completedEntryValue_ = 0u;
    completedEntryErrorCode_ = nullptr;
    const char* errorCode = nullptr;
    if (!commitNumericEntry(key, &errorCode)) {
        if (errorCode != nullptr && completedEntryCanBeIncrement()) {
            completedEntryAvailable_ = true;
            completedEntryDeferredError_ = true;
            completedEntryErrorCode_ = errorCode;
            entryMode_ = EntryMode::None;
            entryLocked_ = true;
            updateExecIndicator();
#if ADRET_DEBUG_SERIAL
            Serial.print(F("PENDING target="));
            Serial.print(targetName(settings_.target));
            Serial.println(F(" increment_candidate=1 absolute_valid=0"));
#endif
            return;
        }
#if ADRET_DEBUG_SERIAL
        Serial.print(F("ERROR entry_target="));
        Serial.print(targetName(settings_.target));
        Serial.print(F(" unit="));
        Serial.print(keyShortLabel(key));
        Serial.print(F(" digits="));
        Serial.print(entryDigits_);
        Serial.print(F(" decimal_index="));
        Serial.println(entryDecimalIndex_);
#endif
        failEntry(errorCode);
        return;
    }
    completedEntryAvailable_ = true;
    entryMode_ = EntryMode::None;
    entryLocked_ = true;
    recalledPending_ = false;
    renderAll();
#if ADRET_DEBUG_SERIAL
    Serial.print(F("PENDING target="));
    Serial.println(targetName(settings_.target));
#endif
}

bool OperatingController::completedEntryCanBeIncrement() const
{
    return completedEntryIncrementCompatible_ && completedEntryValue_ > 0u &&
           completedEntryValue_ <= keyboardIncrementMaximum(settings_.target);
}

void OperatingController::restoreCompletedEntryBase()
{
    pending_ = entryBase_;
    pendingActive_ = entryHadPending_;
    entryMode_ = EntryMode::None;
    entryLocked_ = false;
    completedEntryAvailable_ = false;
    completedEntryDeferredError_ = false;
    completedEntryIncrementCompatible_ = false;
    completedEntryErrorCode_ = nullptr;
}

void OperatingController::handleIncrement()
{
    const uint8_t index = uint8_t(settings_.target);
    const uint8_t bit = uint8_t(1u << index);
    if (completedEntryAvailable_) {
        if (!completedEntryCanBeIncrement()) {
            restoreCompletedEntryBase();
            failEntry(nullptr);
            return;
        }
        const uint32_t value = completedEntryValue_;
        restoreCompletedEntryBase();
        keyboardIncrements_[index] = value;
        keyboardIncrementDefinedMask_ |= bit;
        incrementViewActive_ = false;
        renderAll();
#if ADRET_DEBUG_SERIAL
        Serial.print(F("INCREMENT target="));
        Serial.print(targetName(settings_.target));
        Serial.print(F(" value="));
        Serial.println(value);
#endif
        return;
    }
    if ((keyboardIncrementDefinedMask_ & bit) == 0u) {
        failEntry(nullptr);
        return;
    }
    incrementViewActive_ = true;
    renderIncrementView();
    updateExecIndicator();
#if ADRET_DEBUG_SERIAL
    Serial.print(F("INCREMENT view="));
    Serial.println(targetName(settings_.target));
#endif
}

void OperatingController::handleIncrementStep(bool increase)
{
    if (sequenceDefined_ && sequenceActive_) {
        stepSequence(!increase);
        return;
    }
    const uint8_t index = uint8_t(settings_.target);
    const uint8_t bit = uint8_t(1u << index);
    if ((keyboardIncrementDefinedMask_ & bit) == 0u) {
        return;
    }
    const int8_t direction = increase ? 1 : -1;
    const uint32_t step = keyboardIncrements_[index];
    OutputConfiguration& output = settings_.output;
    bool changed = false;
    switch (settings_.target) {
    case Target::Frequency: {
        const uint32_t previous = output.frequencyHz;
        output.frequencyHz = clampUnsignedStep(previous, direction, step,
                                                kFrequencyMinimumHz,
                                                kFrequencyMaximumHz);
        changed = previous != output.frequencyHz;
        if (pendingActive_) {
            pending_.frequencyHz = output.frequencyHz;
        }
        break;
    }
    case Target::Amplitude: {
        const int16_t previous = output.amplitudeTenthsDbm;
        output.amplitudeTenthsDbm = clampSignedStep(
            previous, direction, uint16_t(step),
            kAmplitudeMinimumTenthsDbm, kAmplitudeMaximumTenthsDbm);
        changed = previous != output.amplitudeTenthsDbm;
        if (pendingActive_) {
            pending_.amplitudeTenthsDbm = output.amplitudeTenthsDbm;
        }
        break;
    }
    case Target::Fm: {
        const uint32_t previous = output.fmHz;
        output.fmHz = clampUnsignedStep(previous, direction, step,
                                        0u, kFmMaximumHz);
        output.modulationMode = ModulationMode::Fm;
        changed = previous != output.fmHz;
        if (pendingActive_) {
            pending_.fmHz = output.fmHz;
            pending_.modulationMode = ModulationMode::Fm;
        }
        break;
    }
    case Target::Pm: {
        const uint16_t previous = output.pmHundredthsRd;
        output.pmHundredthsRd = uint16_t(clampUnsignedStep(
            previous, direction, step, 0u, kPmMaximumHundredthsRd));
        output.modulationMode = ModulationMode::Pm;
        changed = previous != output.pmHundredthsRd;
        if (pendingActive_) {
            pending_.pmHundredthsRd = output.pmHundredthsRd;
            pending_.modulationMode = ModulationMode::Pm;
        }
        break;
    }
    case Target::Am: {
        const uint16_t previous = output.amTenthsPercent;
        output.amTenthsPercent = uint16_t(clampUnsignedStep(
            previous, direction, step, 0u, kAmMaximumTenthsPercent));
        output.modulationMode = ModulationMode::Am;
        changed = previous != output.amTenthsPercent;
        if (pendingActive_) {
            pending_.amTenthsPercent = output.amTenthsPercent;
            pending_.modulationMode = ModulationMode::Am;
        }
        break;
    }
    }
    if (!changed) {
#if ADRET_DEBUG_SERIAL
        Serial.println(F("INCREMENT applied=0 reason=LIMIT"));
#endif
        return;
    }
    if (incrementViewActive_) {
        renderIndicators();
        renderIncrementView();
        updateExecIndicator();
    } else {
        renderAll();
    }
    reportInstrumentTransaction(settings_.output);
#if ADRET_DEBUG_SERIAL
    Serial.print(F("INCREMENT applied=1 direction="));
    Serial.println(increase ? 1 : -1);
#endif
}

void OperatingController::handleExec()
{
    if (entryMode_ == EntryMode::Numeric) {
        failEntry(nullptr);
        return;
    }
    if (!pendingActive_) {
        return;
    }
    settings_.output = pending_;
    pendingActive_ = false;
    recalledPending_ = false;
    completedEntryAvailable_ = false;
    completedEntryDeferredError_ = false;
    entryLocked_ = false;
    renderAll();
#if ADRET_DEBUG_SERIAL
    Serial.println(F("EXEC applied=1"));
#endif
    reportInstrumentTransaction(settings_.output);
}

void OperatingController::handleClear()
{
    pendingActive_ = false;
    recalledPending_ = false;
    entryLocked_ = false;
    entryMode_ = EntryMode::None;
    entryDigitCount_ = 0u;
    entryDecimalIndex_ = -1;
    sequenceDefined_ = false;
    sequenceActive_ = false;
    sequenceCursorValid_ = false;
    overlay_ = Overlay::None;
    blinkActive_ = false;
    correctionBlink_ = false;
    completedEntryAvailable_ = false;
    completedEntryDeferredError_ = false;
    completedEntryIncrementCompatible_ = false;
    keyboardIncrementDefinedMask_ = 0u;
    incrementViewActive_ = false;
    frontPanel.turnOff(PanelIndicator::Memory);
    renderAll();
#if ADRET_DEBUG_SERIAL
    Serial.println(F("ENTRY cleared=1 sequence_cleared=1 increments_cleared=1"));
#endif
}

void OperatingController::handleXToY()
{
    if (recalledPending_) {
        pendingActive_ = false;
        recalledPending_ = false;
        entryLocked_ = false;
        renderAll();
#if ADRET_DEBUG_SERIAL
        Serial.println(F("PENDING recalled_cancelled=1"));
#endif
        return;
    }
    if (!pendingActive_) {
        return;
    }
    overlay_ = Overlay::Active;
    overlayDeadlineMs_ = millis() + kOverlayDurationMs;
    const bool savedPending = pendingActive_;
    pendingActive_ = false;
    renderAll();
    pendingActive_ = savedPending;
#if ADRET_DEBUG_SERIAL
    Serial.println(F("PENDING active_view=1"));
#endif
}

void OperatingController::beginCommand(EntryMode mode)
{
    if (entryMode_ == EntryMode::Numeric) {
        failEntry(nullptr);
        return;
    }
    entryMode_ = mode;
    entryDigitCount_ = 0u;
    entryDecimalIndex_ = -1;
    entryDigits_[0] = '\0';
    if (mode == EntryMode::Memory || mode == EntryMode::Recall) {
        frontPanel.turnOn(PanelIndicator::Memory);
    }
    if (mode == EntryMode::Sequence) {
        frontPanel.turnOn(PanelIndicator::Sequence);
        commandDeadlineMs_ = millis() + kSequenceEntryTimeoutMs;
    }
}

void OperatingController::finishMemoryCommand()
{
    const uint8_t index = uint8_t((entryDigits_[0] - '0') * 10 +
                                  (entryDigits_[1] - '0'));
    entryMode_ = EntryMode::None;
    frontPanel.turnOff(PanelIndicator::Memory);
    if (index >= SettingsStore::kMemoryCount ||
        !settingsStore.saveMemory(index, displayedOutput())) {
        failEntry(nullptr);
        return;
    }
    entryLocked_ = false;
    char text[4] = {'P', entryDigits_[0], entryDigits_[1], '\0'};
    renderMessage(text, kOverlayDurationMs);
#if ADRET_DEBUG_SERIAL
    Serial.print(F("MEMORY saved="));
    Serial.println(index);
#endif
}

void OperatingController::finishRecallCommand()
{
    const uint8_t index = uint8_t((entryDigits_[0] - '0') * 10 +
                                  (entryDigits_[1] - '0'));
    entryMode_ = EntryMode::None;
    frontPanel.turnOff(PanelIndicator::Memory);
    if (index >= SettingsStore::kMemoryCount ||
        !settingsStore.loadMemory(index, &pending_)) {
        char text[4] = {'E', entryDigits_[0], entryDigits_[1], '\0'};
        frontPanel.turnOn(PanelIndicator::Error);
        renderMessage(text, kOverlayDurationMs);
#if ADRET_DEBUG_SERIAL
        Serial.print(F("ERROR memory_empty="));
        Serial.println(index);
#endif
        return;
    }
    pendingActive_ = true;
    recalledPending_ = true;
    entryLocked_ = true;
    char text[4] = {'P', entryDigits_[0], entryDigits_[1], '\0'};
    renderMessage(text, kOverlayDurationMs);
    updateExecIndicator();
#if ADRET_DEBUG_SERIAL
    Serial.print(F("MEMORY recalled="));
    Serial.println(index);
#endif
}

void OperatingController::finishSequenceCommand()
{
    const uint8_t start = uint8_t((entryDigits_[0] - '0') * 10 +
                                  (entryDigits_[1] - '0'));
    const uint8_t end = uint8_t((entryDigits_[2] - '0') * 10 +
                                (entryDigits_[3] - '0'));
    entryMode_ = EntryMode::None;
    if (start >= SettingsStore::kMemoryCount ||
        end >= SettingsStore::kMemoryCount || start > end) {
        frontPanel.setIndicator(PanelIndicator::Sequence, sequenceActive_);
        failEntry("E-89");
        return;
    }
    sequenceDefined_ = true;
    sequenceActive_ = true;
    sequenceCursorValid_ = false;
    sequenceStart_ = start;
    sequenceEnd_ = end;
    renderAll();
    char text[6] = {entryDigits_[0], entryDigits_[1], '-',
                    entryDigits_[2], entryDigits_[3], '\0'};
    renderMessage(text, kOverlayDurationMs);
#if ADRET_DEBUG_SERIAL
    Serial.print(F("SEQUENCE start="));
    Serial.print(start);
    Serial.print(F(" end="));
    Serial.println(end);
#endif
}

void OperatingController::stepSequence(bool restart)
{
    if (!sequenceDefined_ || !sequenceActive_) {
        return;
    }
    uint8_t next = sequenceStart_;
    if (sequenceCursorValid_) {
        if (restart) {
            if (sequenceCursor_ <= sequenceStart_) {
                return;
            }
            next = sequenceStart_;
        } else {
            if (sequenceCursor_ >= sequenceEnd_) {
                return;
            }
            next = uint8_t(sequenceCursor_ + 1u);
        }
    }
    OutputConfiguration configuration = {};
    if (!settingsStore.loadMemory(next, &configuration)) {
        char text[4] = {'E', char('0' + next / 10u),
                        char('0' + next % 10u), '\0'};
        frontPanel.turnOn(PanelIndicator::Error);
        renderMessage(text, kOverlayDurationMs);
#if ADRET_DEBUG_SERIAL
        Serial.print(F("ERROR memory_empty="));
        Serial.println(next);
#endif
        return;
    }
    settings_.output = configuration;
    pendingActive_ = false;
    recalledPending_ = false;
    entryLocked_ = false;
    sequenceCursor_ = next;
    sequenceCursorValid_ = true;
    renderAll();
    reportInstrumentTransaction(settings_.output);
#if ADRET_DEBUG_SERIAL
    Serial.print(F("SEQUENCE position="));
    Serial.println(next);
#endif
}

void OperatingController::ensurePending()
{
    if (!pendingActive_) {
        pending_ = settings_.output;
        pendingActive_ = true;
    }
}

void OperatingController::cancelNumericEntry()
{
    if (entryMode_ == EntryMode::Numeric) {
        pending_ = entryBase_;
        if (!entryHadPending_) {
            pendingActive_ = false;
        }
    }
    entryMode_ = EntryMode::None;
    entryDigitCount_ = 0u;
    entryDecimalIndex_ = -1;
    entryDigits_[0] = '\0';
}

void OperatingController::failEntry(const char* code)
{
    cancelNumericEntry();
    entryLocked_ = false;
    frontPanel.turnOn(PanelIndicator::Error);
#if ADRET_DEBUG_SERIAL
    Serial.print(F("ERROR code="));
    if (code == nullptr) {
        Serial.println(F("UNSPECIFIED"));
    } else {
        Serial.println(code);
    }
#endif
    if (code != nullptr) {
        renderMessage(code, kOverlayDurationMs);
    } else {
        overlay_ = Overlay::Message;
        overlayDeadlineMs_ = millis() + kOverlayDurationMs;
        updateExecIndicator();
    }
}

bool OperatingController::commitNumericEntry(Key unitKey, const char** errorCode)
{
    uint32_t digits = 0u;
    if (!parseDigits(entryDigits_, entryDigitCount_, &digits)) {
        *errorCode = nullptr;
        return false;
    }
    const uint8_t fractionalDigits = entryDecimalIndex_ < 0
        ? 0u
        : uint8_t(entryDigitCount_ - uint8_t(entryDecimalIndex_));
    uint32_t value = 0u;

    switch (settings_.target) {
    case Target::Frequency: {
        const uint32_t multiplier = unitKey == Key::Mhz ? 1000000u
            : unitKey == Key::KHz ? 1000u
            : unitKey == Key::Hz ? 1u : 0u;
        if (multiplier == 0u ||
            !scaledInteger(digits, fractionalDigits, multiplier, &value)) {
            *errorCode = nullptr;
            return false;
        }
        value = quantizedFrequencyHz(value);
        completedEntryValue_ = value;
        completedEntryIncrementCompatible_ = true;
        if (value > kFrequencyMaximumHz) {
            *errorCode = "E-21";
            return false;
        }
        if (value < kFrequencyMinimumHz) {
            *errorCode = "E-22";
            return false;
        }
        pending_.frequencyHz = value;
        break;
    }
    case Target::Amplitude:
        if (unitKey == Key::DBm || unitKey == Key::OneDBm) {
            if (!scaledInteger(digits, fractionalDigits, 10u, &value) ||
                value > uint32_t(INT16_MAX)) {
                *errorCode = nullptr;
                return false;
            }
            const int32_t signedValue = unitKey == Key::DBm
                ? -int32_t(value) : int32_t(value);
            completedEntryValue_ = value;
            completedEntryIncrementCompatible_ = true;
            if (signedValue > kAmplitudeMaximumTenthsDbm) {
                *errorCode = "E-41";
                return false;
            }
            if (signedValue < kAmplitudeMinimumTenthsDbm) {
                *errorCode = "E-42";
                return false;
            }
            pending_.amplitudeTenthsDbm = int16_t(signedValue);
            pending_.amplitudeDisplayUnit = AmplitudeDisplayUnit::DBm;
        } else {
            const float denominator = float(powerOfTen(fractionalDigits));
            const float unitScale = unitKey == Key::Mhz ? 1.0f
                : unitKey == Key::KHz ? 0.001f
                : unitKey == Key::Hz ? 0.000001f : 0.0f;
            if (unitScale == 0.0f || digits == 0u ||
                (float(digits) / denominator) > 1999.0f) {
                *errorCode = nullptr;
                return false;
            }
            const float volts = (float(digits) / denominator) * unitScale;
            const int32_t tenthsDbm = int32_t(lroundf(
                200.0f * log10f(volts) + 130.103f));
            completedEntryValue_ = uint32_t(tenthsDbm < 0
                ? -tenthsDbm : tenthsDbm);
            completedEntryIncrementCompatible_ = false;
            if (tenthsDbm > kAmplitudeMaximumTenthsDbm) {
                *errorCode = "E-41";
                return false;
            }
            if (tenthsDbm < kAmplitudeMinimumTenthsDbm) {
                *errorCode = "E-42";
                return false;
            }
            pending_.amplitudeTenthsDbm = int16_t(tenthsDbm);
            pending_.amplitudeDisplayUnit = unitKey == Key::Mhz
                ? AmplitudeDisplayUnit::V
                : unitKey == Key::KHz
                    ? AmplitudeDisplayUnit::MV
                    : AmplitudeDisplayUnit::UV;
        }
        break;
    case Target::Fm: {
        const uint32_t multiplier = unitKey == Key::KHz ? 1000u
            : unitKey == Key::Hz ? 1u : 0u;
        if (multiplier == 0u ||
            !scaledInteger(digits, fractionalDigits, multiplier, &value) ||
            (value % 10u) != 0u) {
            *errorCode = "E-77";
            return false;
        }
        completedEntryValue_ = value;
        completedEntryIncrementCompatible_ = true;
        if (value > kFmMaximumHz) {
            *errorCode = "E-71";
            return false;
        }
        pending_.fmHz = value;
        pending_.modulationMode = ModulationMode::Fm;
        break;
    }
    case Target::Pm:
        if (unitKey != Key::Hz ||
            !scaledInteger(digits, fractionalDigits, 100u, &value)) {
            *errorCode = "E-77";
            return false;
        }
        completedEntryValue_ = value;
        completedEntryIncrementCompatible_ = true;
        if (value > kPmMaximumHundredthsRd) {
            *errorCode = "E-71";
            return false;
        }
        pending_.pmHundredthsRd = uint16_t(value);
        pending_.modulationMode = ModulationMode::Pm;
        break;
    case Target::Am:
        if (unitKey != Key::Mhz ||
            !scaledInteger(digits, fractionalDigits, 10u, &value)) {
            *errorCode = nullptr;
            return false;
        }
        completedEntryValue_ = value;
        completedEntryIncrementCompatible_ = true;
        if (value > kAmMaximumTenthsPercent) {
            *errorCode = "E-61";
            return false;
        }
        pending_.amTenthsPercent = uint16_t(value);
        pending_.modulationMode = ModulationMode::Am;
        break;
    }
    return true;
}

void OperatingController::renderEntry()
{
    renderDisplays();
    uint32_t digits = 0u;
    (void)parseDigits(entryDigits_, entryDigitCount_, &digits);
    const uint8_t fractionalDigits = entryDecimalIndex_ < 0
        ? 0u
        : uint8_t(entryDigitCount_ - uint8_t(entryDecimalIndex_));
    const uint16_t decimalMask = entryDecimalIndex_ < 0
        ? 0u : uint16_t(1u) << fractionalDigits;

    switch (settings_.target) {
    case Target::Frequency: {
        frontPanel.setFrequencyHz(digits);
        const uint16_t visible = entryDigitCount_ >= 10u
            ? 0x03FFu : uint16_t((uint16_t(1u) << entryDigitCount_) - 1u);
        frontPanel.setDisplayBlankMask(DisplayField::Frequency,
                                       uint16_t(0x03FFu & ~visible));
        frontPanel.setDisplayDecimalMask(DisplayField::Frequency, decimalMask);
        break;
    }
    case Target::Amplitude: {
        const OutputConfiguration& configuration = displayedOutput();
        AmplitudeUnitLed unit = AmplitudeUnitLed::DBm;
        if (configuration.amplitudeDisplayUnit == AmplitudeDisplayUnit::V) {
            unit = AmplitudeUnitLed::V;
        } else if (configuration.amplitudeDisplayUnit == AmplitudeDisplayUnit::MV) {
            unit = AmplitudeUnitLed::MV;
        } else if (configuration.amplitudeDisplayUnit == AmplitudeDisplayUnit::UV) {
            unit = AmplitudeUnitLed::UV;
        }
        frontPanel.setAmplitudeValue(int32_t(digits), unit, false);
        frontPanel.setDisplayDecimalMask(DisplayField::Amplitude,
                                         uint8_t(decimalMask & 0x07u));
        const uint8_t visible = entryDigitCount_ >= 3u
            ? 0x07u : uint8_t((uint8_t(1u) << entryDigitCount_) - 1u);
        frontPanel.setDisplayBlankMask(DisplayField::Amplitude,
                                       uint8_t(0x07u & ~visible));
        break;
    }
    case Target::Fm:
    case Target::Pm:
    case Target::Am: {
        const ModulationUnitLed unit = settings_.target == Target::Fm
            ? ModulationUnitLed::KHz
            : settings_.target == Target::Pm
                ? ModulationUnitLed::Rd : ModulationUnitLed::Percent;
        frontPanel.setModulationDisplay(uint16_t(digits % 1000u), unit,
                                        uint8_t(decimalMask & 0x07u),
                                        digits >= 1000u);
        const uint8_t visible = entryDigitCount_ >= 3u
            ? 0x07u : uint8_t((uint8_t(1u) << entryDigitCount_) - 1u);
        frontPanel.setDisplayBlankMask(DisplayField::Modulation,
                                       uint8_t(0x07u & ~visible));
        break;
    }
    }
    frontPanel.refreshDisplays();
}

void OperatingController::renderIncrementView()
{
    renderDisplays();
    const uint32_t value = keyboardIncrements_[uint8_t(settings_.target)];
    switch (settings_.target) {
    case Target::Frequency:
        frontPanel.setFrequencyHz(value);
        frontPanel.setDisplayBlankMask(DisplayField::Frequency,
                                       frequencyLeadingBlankMask(value));
        frontPanel.setDisplayDecimalMask(DisplayField::Frequency,
                                         frequencySeparatorMask(value));
        break;
    case Target::Amplitude:
        frontPanel.setDisplayBlankMask(DisplayField::Amplitude, 0u);
        frontPanel.setAmplitudeIncrementDisplay(uint16_t(value));
        break;
    case Target::Fm: {
        const DisplaySpec spec = fmDisplaySpec(value);
        frontPanel.setDisplayBlankMask(DisplayField::Modulation, 0u);
        frontPanel.setModulationDisplay(spec.digits, ModulationUnitLed::KHz,
                                        spec.decimalMask, spec.leadingOne);
        break;
    }
    case Target::Pm: {
        const DisplaySpec spec = pmDisplaySpec(uint16_t(value));
        frontPanel.setDisplayBlankMask(DisplayField::Modulation, 0u);
        frontPanel.setModulationDisplay(spec.digits, ModulationUnitLed::Rd,
                                        spec.decimalMask, spec.leadingOne);
        break;
    }
    case Target::Am:
        frontPanel.setDisplayBlankMask(DisplayField::Modulation, 0u);
        frontPanel.setModulationDisplay(uint16_t(value),
                                        ModulationUnitLed::Percent,
                                        0x02u, false);
        break;
    }
    frontPanel.refreshDisplays();
}

void OperatingController::renderMessage(const char* text, uint32_t durationMs)
{
    frontPanel.setFrequencyText(text);
    frontPanel.refreshDisplays();
    overlay_ = Overlay::Message;
    overlayDeadlineMs_ = millis() + durationMs;
}

void OperatingController::updateExecIndicator()
{
    const ExecIndicator mode = entryMode_ == EntryMode::Numeric
        ? ExecIndicator::Fixed
        : pendingActive_ ? ExecIndicator::Blink : ExecIndicator::Off;
    frontPanel.setExecIndicator(mode);
}

void OperatingController::reportInstrumentTransaction(
    const OutputConfiguration& configuration)
{
#if ADRET_DEBUG_SERIAL
    Serial.println(F("INSTR BEGIN"));
    Serial.print(F("INSTR frequency_hz="));
    Serial.println(configuration.frequencyHz);
    Serial.print(F("INSTR amplitude_tenths_dbm="));
    Serial.println(configuration.amplitudeTenthsDbm);
    Serial.print(F("INSTR modulation_mode="));
    switch (configuration.modulationMode) {
    case ModulationMode::Fm: Serial.println(F("FM")); break;
    case ModulationMode::Pm: Serial.println(F("PM")); break;
    case ModulationMode::Am: Serial.println(F("AM")); break;
    }
    Serial.print(F("INSTR fm_hz="));
    Serial.println(configuration.fmHz);
    Serial.print(F("INSTR pm_hundredths_rd="));
    Serial.println(configuration.pmHundredthsRd);
    Serial.print(F("INSTR am_tenths_percent="));
    Serial.println(configuration.amTenthsPercent);
    Serial.print(F("INSTR modulation_source="));
    Serial.println(sourceName(configuration.modulationSource));
    Serial.print(F("INSTR rf_off="));
    Serial.println(configuration.rfOff ? 1 : 0);
    Serial.println(F("INSTR END"));
#else
    (void)configuration;
#endif

#if !ADRET_INSTRUMENT_BUS_BENCH
    if (!instrumentRegistersInitialized_) {
        instrument_bus::makeInitialInstrumentRegisters(instrumentRegisters_);
        instrumentRegistersInitialized_ = true;
    }

    instrument_bus::InstrumentProgram program = {};
    // The correction table is deliberately zero-filled. Index selection will
    // be supplied by the calibration phase; index zero is therefore neutral.
    const int8_t correctionTenthsDb = calibration::readCorrection(0u);
    const instrument_bus::InstrumentProgramResult result =
        instrument_bus::makeInstrumentProgram(
            instrumentConfiguration(configuration),
            correctionTenthsDb,
            instrumentRegisters_,
            &program);
    if (result != instrument_bus::InstrumentProgramResult::Ok ||
        !instrument_bus::instrumentBus.ready()) {
#if ADRET_DEBUG_SERIAL
        Serial.print(F("INSTR BUS skipped program_result="));
        Serial.print(uint8_t(result));
        Serial.print(F(" ready="));
        Serial.println(instrument_bus::instrumentBus.ready() ? 1 : 0);
#endif
        return;
    }

    for (uint8_t i = 0u; i < program.writeCount; ++i) {
        const instrument_bus::InstrumentWrite& write = program.writes[i];
        if (!instrument_bus::instrumentBus.write(write.address, write.value)) {
#if ADRET_DEBUG_SERIAL
            Serial.print(F("INSTR BUS failed index="));
            Serial.print(i);
            Serial.print(F(" error="));
            Serial.println(uint8_t(instrument_bus::instrumentBus.lastError()));
#endif
            return;
        }
        instrumentRegisters_[write.address] = write.value;
    }
#endif
}

void OperatingController::handleEncoder(const front_panel::EncoderEvent& event)
{
    if (settings_.wheelInhibited) {
        return;
    }
    if (entryMode_ == EntryMode::Numeric) {
        return;
    }

    OutputConfiguration& output = editableOutput();
    bool changed = false;
    switch (settings_.wheelTarget) {
    case Target::Frequency: {
        const uint32_t previous = output.frequencyHz;
        output.frequencyHz = clampUnsignedStep(previous, event.step, currentStep(),
                                                kFrequencyMinimumHz,
                                                kFrequencyMaximumHz);
        changed = previous != output.frequencyHz;
        break;
    }
    case Target::Amplitude: {
        const int16_t previous = output.amplitudeTenthsDbm;
        output.amplitudeTenthsDbm = clampSignedStep(
            previous, event.step, uint16_t(currentStep()),
            kAmplitudeMinimumTenthsDbm, kAmplitudeMaximumTenthsDbm);
        changed = previous != output.amplitudeTenthsDbm;
        break;
    }
    case Target::Fm: {
        const uint32_t previous = output.fmHz;
        output.fmHz = clampUnsignedStep(previous, event.step, currentStep(),
                                        0u, kFmMaximumHz);
        output.modulationMode = ModulationMode::Fm;
        changed = previous != output.fmHz;
        break;
    }
    case Target::Pm: {
        const uint16_t previous = output.pmHundredthsRd;
        output.pmHundredthsRd = uint16_t(clampUnsignedStep(
            previous, event.step, currentStep(), 0u, kPmMaximumHundredthsRd));
        output.modulationMode = ModulationMode::Pm;
        changed = previous != output.pmHundredthsRd;
        break;
    }
    case Target::Am: {
        const uint16_t previous = output.amTenthsPercent;
        output.amTenthsPercent = uint16_t(clampUnsignedStep(
            previous, event.step, currentStep(), 0u, kAmMaximumTenthsPercent));
        output.modulationMode = ModulationMode::Am;
        changed = previous != output.amTenthsPercent;
        break;
    }
    }
    if (!changed) {
        return;
    }
    renderAll();
    reportValue(settings_.wheelTarget, false);
    if (!pendingActive_) {
        reportInstrumentTransaction(settings_.output);
    }
}

void OperatingController::tick(uint32_t nowMs)
{
    if (entryMode_ == EntryMode::Sequence && entryDigitCount_ == 0u &&
        timeReached(nowMs, commandDeadlineMs_)) {
        entryMode_ = EntryMode::None;
        entryDigitCount_ = 0u;
        if (sequenceDefined_) {
            sequenceActive_ = true;
        }
        renderAll();
    }
    if (overlay_ != Overlay::None && timeReached(nowMs, overlayDeadlineMs_)) {
        overlay_ = Overlay::None;
        renderAll();
    }
    if (!blinkActive_ || (nowMs - previousBlinkMs_) < kBlinkPhaseMs) {
        return;
    }
    previousBlinkMs_ = nowMs;
    blinkBlank_ = !blinkBlank_;
    if (blinkPhasesRemaining_ > 0u) {
        --blinkPhasesRemaining_;
    }
    if (blinkPhasesRemaining_ == 0u) {
        blinkActive_ = false;
        blinkBlank_ = false;
        correctionBlink_ = false;
    }
    applyBlinkMask(blinkBlank_);
}

const Settings& OperatingController::settings() const
{
    return settings_;
}

void OperatingController::selectTarget(Target target)
{
    if (entryMode_ == EntryMode::Numeric) {
        failEntry(nullptr);
        return;
    }
    settings_.target = target;
    entryLocked_ = false;
    sequenceActive_ = false;
    sequenceCursorValid_ = false;
    blinkActive_ = false;
    correctionBlink_ = false;
    renderAll();
    reportTarget();
}

void OperatingController::selectSource(ModulationSource source)
{
    if (entryMode_ == EntryMode::Numeric) {
        failEntry(nullptr);
        return;
    }
    ensurePending();
    pending_.modulationSource = source;
    recalledPending_ = false;
    renderAll();
#if ADRET_DEBUG_SERIAL
    Serial.print(F("PENDING source="));
    Serial.println(sourceName(source));
#endif
}

void OperatingController::changeStep(bool multiply)
{
    uint8_t* index = nullptr;
    switch (settings_.wheelTarget) {
    case Target::Frequency: index = &settings_.frequencyStepIndex; break;
    case Target::Amplitude: index = &settings_.amplitudeStepIndex; break;
    case Target::Fm: index = &settings_.fmStepIndex; break;
    case Target::Pm: index = &settings_.pmStepIndex; break;
    case Target::Am: index = &settings_.amStepIndex; break;
    }
    const uint8_t maximum = currentStepMaximumIndex();
    if (multiply && *index < maximum) {
        ++(*index);
    } else if (!multiply && *index > 0u) {
        --(*index);
    }
    reportStep();
    startStepBlink();
}

void OperatingController::startStepBlink()
{
    correctionBlink_ = false;
    blinkActive_ = true;
    blinkBlank_ = true;
    blinkPhasesRemaining_ = kBlinkPhaseCount;
    previousBlinkMs_ = millis();
    applyBlinkMask(true);
}

void OperatingController::applyBlinkMask(bool blank)
{
    if (overlay_ != Overlay::None) {
        frontPanel.refreshDisplays();
        return;
    }

    uint16_t frequencyMask =
        frequencyLeadingBlankMask(displayedOutput().frequencyHz);
    uint8_t modulationMask = 0u;
    uint8_t amplitudeMask = 0u;
    if (entryMode_ == EntryMode::Numeric) {
        const uint8_t visibleDigits = entryDigitCount_;
        if (settings_.target == Target::Frequency) {
            const uint16_t visible = visibleDigits >= 10u
                ? 0x03FFu
                : uint16_t((uint16_t(1u) << visibleDigits) - 1u);
            frequencyMask = uint16_t(0x03FFu & ~visible);
        } else if (settings_.target == Target::Amplitude) {
            const uint8_t visible = visibleDigits >= 3u
                ? 0x07u
                : uint8_t((uint8_t(1u) << visibleDigits) - 1u);
            amplitudeMask = uint8_t(0x07u & ~visible);
        } else {
            const uint8_t visible = visibleDigits >= 3u
                ? 0x07u
                : uint8_t((uint8_t(1u) << visibleDigits) - 1u);
            modulationMask = uint8_t(0x07u & ~visible);
        }
    }
    if (blank) {
        const uint8_t position = correctionBlink_
            ? correctionBlinkPosition_ : displayStepPosition();
        const DisplayField field = correctionBlink_
            ? correctionBlinkField_ : targetDisplayField();
        const uint16_t mask = (position >= 3u && field == DisplayField::Modulation)
            ? 0x07u : uint16_t(1u) << position;
        if (field == DisplayField::Frequency) {
            frequencyMask = uint16_t(frequencyMask | mask);
        } else if (field == DisplayField::Modulation) {
            modulationMask = uint8_t(modulationMask | uint8_t(mask));
        } else {
            amplitudeMask = uint8_t(amplitudeMask | uint8_t(mask));
        }
    }
    frontPanel.setDisplayBlankMask(DisplayField::Frequency, frequencyMask);
    frontPanel.setDisplayBlankMask(DisplayField::Modulation, modulationMask);
    frontPanel.setDisplayBlankMask(DisplayField::Amplitude, amplitudeMask);
    frontPanel.refreshDisplays();
}

void OperatingController::renderAll()
{
    renderIndicators();
    renderDisplays();
    updateExecIndicator();
}

void OperatingController::renderIndicators()
{
    switch (settings_.target) {
    case Target::Frequency: frontPanel.turnOn(PanelIndicator::Rf); break;
    case Target::Amplitude: frontPanel.turnOn(PanelIndicator::Amplitude); break;
    case Target::Fm: frontPanel.turnOn(PanelIndicator::Fm); break;
    case Target::Pm: frontPanel.turnOn(PanelIndicator::Pm); break;
    case Target::Am: frontPanel.turnOn(PanelIndicator::Am); break;
    }
    const OutputConfiguration& configuration = displayedOutput();
    switch (configuration.amplitudeDisplayUnit) {
    case AmplitudeDisplayUnit::DBm: frontPanel.turnOn(PanelIndicator::DBm); break;
    case AmplitudeDisplayUnit::V: frontPanel.turnOn(PanelIndicator::Volt); break;
    case AmplitudeDisplayUnit::MV: frontPanel.turnOn(PanelIndicator::MilliVolt); break;
    case AmplitudeDisplayUnit::UV: frontPanel.turnOn(PanelIndicator::MicroVolt); break;
    }
    const Target modulationTarget = settings_.target == Target::Fm ||
                                    settings_.target == Target::Pm ||
                                    settings_.target == Target::Am
        ? settings_.target
        : configuration.modulationMode == ModulationMode::Fm ? Target::Fm
            : configuration.modulationMode == ModulationMode::Pm ? Target::Pm
            : Target::Am;
    if (modulationTarget == Target::Fm) {
        frontPanel.turnOn(PanelIndicator::ModKHz);
    } else if (modulationTarget == Target::Pm) {
        frontPanel.turnOn(PanelIndicator::ModRd);
    } else {
        frontPanel.turnOn(PanelIndicator::ModPercent);
    }
    switch (configuration.modulationSource) {
    case ModulationSource::Cw: frontPanel.turnOn(PanelIndicator::Cw); break;
    case ModulationSource::Hz400: frontPanel.turnOn(PanelIndicator::Hz400); break;
    case ModulationSource::KHz1: frontPanel.turnOn(PanelIndicator::KHz1); break;
    case ModulationSource::External: frontPanel.turnOn(PanelIndicator::External); break;
    }
    frontPanel.turnOn(PanelIndicator::Normal);
    frontPanel.setIndicator(PanelIndicator::ManualValidation,
                            !settings_.wheelInhibited &&
                            settings_.target == settings_.wheelTarget);
    frontPanel.setIndicator(PanelIndicator::RfInhibit, settings_.output.rfOff);
    frontPanel.setIndicator(PanelIndicator::Sequence, sequenceActive_);
}

void OperatingController::renderDisplays()
{
    const OutputConfiguration& configuration = displayedOutput();
    frontPanel.setDisplayBlankMask(
        DisplayField::Frequency,
        frequencyLeadingBlankMask(configuration.frequencyHz));
    frontPanel.setDisplayBlankMask(DisplayField::Modulation, 0u);
    frontPanel.setDisplayBlankMask(DisplayField::Amplitude, 0u);
    frontPanel.setDisplayDecimalMask(
        DisplayField::Frequency,
        frequencySeparatorMask(configuration.frequencyHz));
    frontPanel.setFrequencyHz(configuration.frequencyHz);

    if (configuration.amplitudeDisplayUnit == AmplitudeDisplayUnit::DBm) {
        const uint16_t magnitude = configuration.amplitudeTenthsDbm < 0
            ? uint16_t(-int32_t(configuration.amplitudeTenthsDbm))
            : uint16_t(configuration.amplitudeTenthsDbm);
        frontPanel.setAmplitudeDisplay(configuration.amplitudeTenthsDbm, 0x02u,
                                       magnitude >= 1000u);
    } else {
        const float volts = powf(10.0f,
            (float(configuration.amplitudeTenthsDbm) / 10.0f - 13.0103f) / 20.0f);
        AmplitudeUnitLed unit = AmplitudeUnitLed::V;
        int32_t displayed = int32_t(lroundf(volts * 1000.0f));
        bool decimalPoint = true;
        if (configuration.amplitudeDisplayUnit == AmplitudeDisplayUnit::MV) {
            unit = AmplitudeUnitLed::MV;
            displayed = int32_t(lroundf(volts * 1000.0f));
            decimalPoint = false;
        } else if (configuration.amplitudeDisplayUnit == AmplitudeDisplayUnit::UV) {
            unit = AmplitudeUnitLed::UV;
            displayed = int32_t(lroundf(volts * 1000000.0f));
            decimalPoint = false;
        }
        if (displayed > 1999) {
            unit = unit == AmplitudeUnitLed::UV ? AmplitudeUnitLed::MV
                                                : AmplitudeUnitLed::V;
            displayed = int32_t(lroundf(volts * (unit == AmplitudeUnitLed::V
                ? 1000.0f : 1000.0f)));
            decimalPoint = unit == AmplitudeUnitLed::V;
        }
        frontPanel.setAmplitudeValue(displayed, unit, decimalPoint);
    }
    renderModulationDisplay(configuration);
    frontPanel.refreshDisplays();
}

void OperatingController::renderModulationDisplay(
    const OutputConfiguration& configuration)
{
    const Target target = settings_.target == Target::Fm ||
                          settings_.target == Target::Pm ||
                          settings_.target == Target::Am
        ? settings_.target
        : configuration.modulationMode == ModulationMode::Fm ? Target::Fm
            : configuration.modulationMode == ModulationMode::Pm ? Target::Pm
            : Target::Am;
    if (target == Target::Am) {
        frontPanel.setModulationDisplay(configuration.amTenthsPercent,
                                        ModulationUnitLed::Percent,
                                        0x02u, false);
    } else if (target == Target::Pm) {
        const DisplaySpec spec = pmDisplaySpec(configuration.pmHundredthsRd);
        frontPanel.setModulationDisplay(spec.digits, ModulationUnitLed::Rd,
                                        spec.decimalMask, spec.leadingOne);
    } else {
        const DisplaySpec spec = fmDisplaySpec(configuration.fmHz);
        frontPanel.setModulationDisplay(spec.digits, ModulationUnitLed::KHz,
                                        spec.decimalMask, spec.leadingOne);
    }
}

void OperatingController::reportTarget() const
{
#if ADRET_DEBUG_SERIAL
    Serial.print(F("TARGET value="));
    Serial.println(targetName(settings_.target));
#endif
}

void OperatingController::reportStep() const
{
#if ADRET_DEBUG_SERIAL
    Serial.print(F("STEP target="));
    Serial.print(targetName(settings_.wheelTarget));
    Serial.print(F(" value="));
    Serial.println(currentStep());
#endif
}

void OperatingController::reportValue(Target target, bool instrumentEvent) const
{
#if ADRET_DEBUG_SERIAL
    const OutputConfiguration& output = displayedOutput();
    Serial.print(F("VALUE target="));
    Serial.print(targetName(target));
    Serial.print(F(" value="));
    switch (target) {
    case Target::Frequency: Serial.println(output.frequencyHz); break;
    case Target::Amplitude: Serial.println(output.amplitudeTenthsDbm); break;
    case Target::Fm: Serial.println(output.fmHz); break;
    case Target::Pm: Serial.println(output.pmHundredthsRd); break;
    case Target::Am: Serial.println(output.amTenthsPercent); break;
    }
    if (instrumentEvent) {
        Serial.print(F("INSTR parameter="));
        Serial.print(targetName(target));
        Serial.print(F(" value="));
        switch (target) {
        case Target::Frequency: Serial.println(output.frequencyHz); break;
        case Target::Amplitude: Serial.println(output.amplitudeTenthsDbm); break;
        case Target::Fm: Serial.println(output.fmHz); break;
        case Target::Pm: Serial.println(output.pmHundredthsRd); break;
        case Target::Am: Serial.println(output.amTenthsPercent); break;
        }
    }
#else
    (void)target;
    (void)instrumentEvent;
#endif
}

uint32_t OperatingController::currentStep() const
{
    const OutputConfiguration& output = displayedOutput();
    switch (settings_.wheelTarget) {
    case Target::Frequency: return kFrequencySteps[settings_.frequencyStepIndex];
    case Target::Amplitude: return kAmplitudeSteps[settings_.amplitudeStepIndex];
    case Target::Fm: return effectiveFmStep(output.fmHz, settings_.fmStepIndex);
    case Target::Pm: return kPmSteps[settings_.pmStepIndex];
    case Target::Am: return kAmSteps[settings_.amStepIndex];
    }
    return 1u;
}

uint8_t OperatingController::currentStepIndex() const
{
    switch (settings_.wheelTarget) {
    case Target::Frequency: return settings_.frequencyStepIndex;
    case Target::Amplitude: return settings_.amplitudeStepIndex;
    case Target::Fm: return settings_.fmStepIndex;
    case Target::Pm: return settings_.pmStepIndex;
    case Target::Am: return settings_.amStepIndex;
    }
    return 0u;
}

uint8_t OperatingController::currentStepMaximumIndex() const
{
    switch (settings_.wheelTarget) {
    case Target::Frequency: return uint8_t(itemCount(kFrequencySteps) - 1u);
    case Target::Amplitude: return uint8_t(itemCount(kAmplitudeSteps) - 1u);
    case Target::Fm: return uint8_t(itemCount(kFmSteps) - 1u);
    case Target::Pm: return uint8_t(itemCount(kPmSteps) - 1u);
    case Target::Am: return uint8_t(itemCount(kAmSteps) - 1u);
    }
    return 0u;
}

uint8_t OperatingController::displayStepPosition() const
{
    const OutputConfiguration& output = displayedOutput();
    switch (settings_.wheelTarget) {
    case Target::Frequency: return uint8_t(currentStepIndex() + 1u);
    case Target::Amplitude:
    case Target::Am:
    case Target::Pm: return currentStepIndex();
    case Target::Fm:
        return decimalPosition(currentStep(), output.fmHz < 20000u ? 10u : 100u);
    }
    return 0u;
}

DisplayField OperatingController::targetDisplayField() const
{
    switch (settings_.wheelTarget) {
    case Target::Frequency: return DisplayField::Frequency;
    case Target::Amplitude: return DisplayField::Amplitude;
    case Target::Fm:
    case Target::Pm:
    case Target::Am: return DisplayField::Modulation;
    }
    return DisplayField::Frequency;
}

OutputConfiguration& OperatingController::editableOutput()
{
    return pendingActive_ ? pending_ : settings_.output;
}

const OutputConfiguration& OperatingController::displayedOutput() const
{
    return pendingActive_ ? pending_ : settings_.output;
}

}  // namespace control
}  // namespace adret
