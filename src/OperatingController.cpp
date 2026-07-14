#include "Adret/OperatingController.h"

#include <Arduino.h>

namespace adret {
namespace control {

namespace {

using front_panel::AmplitudeUnitLed;
using front_panel::DisplayField;
using front_panel::Key;
using front_panel::ModulationUnitLed;
using front_panel::PanelIndicator;

constexpr uint32_t kFrequencyMinimumHz = 100000u;
constexpr uint32_t kFrequencyMaximumHz = 560000000u;
constexpr int16_t kAmplitudeMinimumTenthsDbm = -1299;
constexpr int16_t kAmplitudeMaximumTenthsDbm = 130;
constexpr uint32_t kFmMaximumHz = 200000u;
constexpr uint16_t kPmMaximumHundredthsRd = 1999u;
constexpr uint16_t kAmMaximumTenthsPercent = 999u;
constexpr uint32_t kFmFineRangeMaximumHz = 20000u;
constexpr uint16_t kBlinkPhaseMs = 150u;
constexpr uint8_t kBlinkPhaseCount = 6u;

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

static_assert(itemCount(kFrequencySteps) == 8u &&
              kFrequencySteps[0] == 10u &&
              kFrequencySteps[7] == 100000000u,
              "Unexpected frequency step table");
static_assert(itemCount(kAmplitudeSteps) == 3u &&
              itemCount(kFmSteps) == 5u &&
              itemCount(kPmSteps) == 4u &&
              itemCount(kAmSteps) == 3u,
              "Unexpected control step table");
static_assert(effectiveFmStep(19999u, 0u) == 10u &&
              effectiveFmStep(20000u, 0u) == 100u,
              "Unexpected FM fine-range threshold");
static_assert(fmDisplaySpec(19990u).digits == 999u &&
              fmDisplaySpec(19990u).decimalMask == 0x04u &&
              fmDisplaySpec(19990u).leadingOne,
              "Unexpected 19.99 kHz display format");
static_assert(fmDisplaySpec(20000u).digits == 200u &&
              fmDisplaySpec(20000u).decimalMask == 0x02u &&
              !fmDisplaySpec(20000u).leadingOne,
              "Unexpected 20.0 kHz display format");
static_assert(fmDisplaySpec(199900u).digits == 999u &&
              fmDisplaySpec(199900u).leadingOne &&
              fmDisplaySpec(200000u).digits == 200u &&
              fmDisplaySpec(200000u).decimalMask == 0u,
              "Unexpected upper FM display format");
static_assert(pmDisplaySpec(1999u).digits == 999u &&
              pmDisplaySpec(1999u).leadingOne,
              "Unexpected 19.99 rd display format");

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

}  // namespace

OperatingController operatingController;

Settings defaultSettings()
{
    Settings result = {};
    result.frequencyHz = kFrequencyMinimumHz;
    result.fmHz = 0;
    result.amplitudeTenthsDbm = kAmplitudeMinimumTenthsDbm;
    result.pmHundredthsRd = 0;
    result.amTenthsPercent = 0;
    result.target = Target::Frequency;
    result.wheelTarget = Target::Frequency;
    result.modulationMode = ModulationMode::Am;
    result.modulationSource = ModulationSource::Cw;
    result.wheelInhibited = true;
    result.rfOff = true;
    return result;
}

bool settingsAreValid(const Settings& value)
{
    return value.frequencyHz >= kFrequencyMinimumHz &&
           value.frequencyHz <= kFrequencyMaximumHz &&
           value.fmHz <= kFmMaximumHz &&
           value.amplitudeTenthsDbm >= kAmplitudeMinimumTenthsDbm &&
           value.amplitudeTenthsDbm <= kAmplitudeMaximumTenthsDbm &&
           value.pmHundredthsRd <= kPmMaximumHundredthsRd &&
           value.amTenthsPercent <= kAmMaximumTenthsPercent &&
           uint8_t(value.target) <= uint8_t(Target::Am) &&
           uint8_t(value.wheelTarget) <= uint8_t(Target::Am) &&
           uint8_t(value.modulationMode) <= uint8_t(ModulationMode::Am) &&
           uint8_t(value.modulationSource) <= uint8_t(ModulationSource::External) &&
           value.frequencyStepIndex < itemCount(kFrequencySteps) &&
           value.amplitudeStepIndex < itemCount(kAmplitudeSteps) &&
           value.fmStepIndex < itemCount(kFmSteps) &&
           value.pmStepIndex < itemCount(kPmSteps) &&
           value.amStepIndex < itemCount(kAmSteps);
}

void OperatingController::begin(const Settings& settings)
{
    settings_ = settingsAreValid(settings) ? settings : defaultSettings();
    settings_.rfOff = true;
    renderAll();
    Serial.print(F("STATE restored target="));
    Serial.print(targetName(settings_.target));
    Serial.print(F(" wheel_target="));
    Serial.print(targetName(settings_.wheelTarget));
    Serial.print(F(" wheel_inhibited="));
    Serial.print(settings_.wheelInhibited ? 1 : 0);
    Serial.println(F(" rf_off=1"));
    Serial.print(F("INSTR frequency_hz="));
    Serial.println(settings_.frequencyHz);
    Serial.print(F("INSTR amplitude_tenths_dbm="));
    Serial.println(settings_.amplitudeTenthsDbm);
    Serial.print(F("INSTR modulation_mode="));
    switch (settings_.modulationMode) {
    case ModulationMode::Fm: Serial.println(F("FM")); break;
    case ModulationMode::Pm: Serial.println(F("PM")); break;
    case ModulationMode::Am: Serial.println(F("AM")); break;
    }
    Serial.print(F("INSTR modulation_value="));
    switch (settings_.modulationMode) {
    case ModulationMode::Fm: Serial.println(settings_.fmHz); break;
    case ModulationMode::Pm: Serial.println(settings_.pmHundredthsRd); break;
    case ModulationMode::Am: Serial.println(settings_.amTenthsPercent); break;
    }
    Serial.print(F("INSTR modulation_source="));
    Serial.println(sourceName(settings_.modulationSource));
    Serial.println(F("INSTR rf_off=1"));
}

void OperatingController::handleKey(Key key)
{
    switch (key) {
    case Key::Rf: selectTarget(Target::Frequency); break;
    case Key::Amplitude: selectTarget(Target::Amplitude); break;
    case Key::Fm: selectTarget(Target::Fm); break;
    case Key::Pm: selectTarget(Target::Pm); break;
    case Key::Am: selectTarget(Target::Am); break;
    case Key::Multiply10: changeStep(true); break;
    case Key::Divide10: changeStep(false); break;
    case Key::ValidManual:
        settings_.wheelTarget = settings_.target;
        settings_.wheelInhibited = false;
        frontPanel.setIndicator(PanelIndicator::ManualValidation, true);
        Serial.print(F("VALID target="));
        Serial.print(targetName(settings_.wheelTarget));
        Serial.println(F(" active=1"));
        break;
    case Key::RfOff:
        settings_.rfOff = !settings_.rfOff;
        frontPanel.setIndicator(PanelIndicator::RfInhibit, settings_.rfOff);
        Serial.print(F("RF_OFF value="));
        Serial.println(settings_.rfOff ? 1 : 0);
        Serial.print(F("INSTR rf_off="));
        Serial.println(settings_.rfOff ? 1 : 0);
        break;
    case Key::Cw: selectSource(ModulationSource::Cw); break;
    case Key::Hz400: selectSource(ModulationSource::Hz400); break;
    case Key::KHz1: selectSource(ModulationSource::KHz1); break;
    case Key::External: selectSource(ModulationSource::External); break;
    default: break;
    }
}

void OperatingController::handleEncoder(const front_panel::EncoderEvent& event)
{
    if (settings_.wheelInhibited) {
        Serial.println(F("VALUE applied=0 reason=VALID"));
        return;
    }

    bool changed = false;
    switch (settings_.wheelTarget) {
    case Target::Frequency: {
        const uint32_t previous = settings_.frequencyHz;
        settings_.frequencyHz = clampUnsignedStep(
            previous, event.step, currentStep(),
            kFrequencyMinimumHz, kFrequencyMaximumHz);
        changed = previous != settings_.frequencyHz;
        break;
    }
    case Target::Amplitude: {
        const int16_t previous = settings_.amplitudeTenthsDbm;
        settings_.amplitudeTenthsDbm = clampSignedStep(
            previous, event.step, uint16_t(currentStep()),
            kAmplitudeMinimumTenthsDbm, kAmplitudeMaximumTenthsDbm);
        changed = previous != settings_.amplitudeTenthsDbm;
        break;
    }
    case Target::Fm: {
        const uint32_t previous = settings_.fmHz;
        settings_.fmHz = clampUnsignedStep(previous, event.step, currentStep(),
                                            0u, kFmMaximumHz);
        changed = previous != settings_.fmHz;
        break;
    }
    case Target::Pm: {
        const uint16_t previous = settings_.pmHundredthsRd;
        settings_.pmHundredthsRd = uint16_t(clampUnsignedStep(
            previous, event.step, currentStep(), 0u, kPmMaximumHundredthsRd));
        changed = previous != settings_.pmHundredthsRd;
        break;
    }
    case Target::Am: {
        const uint16_t previous = settings_.amTenthsPercent;
        settings_.amTenthsPercent = uint16_t(clampUnsignedStep(
            previous, event.step, currentStep(), 0u, kAmMaximumTenthsPercent));
        changed = previous != settings_.amTenthsPercent;
        break;
    }
    }

    if (!changed) {
        Serial.println(F("VALUE applied=0 reason=LIMIT"));
        return;
    }

    renderDisplays();
    reportValue(settings_.wheelTarget, true);
}

void OperatingController::tick(uint32_t nowMs)
{
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
    }
    applyBlinkMask(blinkBlank_);
}

const Settings& OperatingController::settings() const
{
    return settings_;
}

void OperatingController::selectTarget(Target target)
{
    settings_.target = target;
    if (target == Target::Fm) {
        settings_.modulationMode = ModulationMode::Fm;
    } else if (target == Target::Pm) {
        settings_.modulationMode = ModulationMode::Pm;
    } else if (target == Target::Am) {
        settings_.modulationMode = ModulationMode::Am;
    }
    blinkActive_ = false;
    renderAll();
    reportTarget();
    if (target == Target::Fm || target == Target::Pm || target == Target::Am) {
        Serial.print(F("INSTR modulation_mode="));
        Serial.println(targetName(target));
        reportValue(target, true);
    }
}

void OperatingController::selectSource(ModulationSource source)
{
    settings_.modulationSource = source;
    switch (source) {
    case ModulationSource::Cw: frontPanel.turnOn(PanelIndicator::Cw); break;
    case ModulationSource::Hz400: frontPanel.turnOn(PanelIndicator::Hz400); break;
    case ModulationSource::KHz1: frontPanel.turnOn(PanelIndicator::KHz1); break;
    case ModulationSource::External: frontPanel.turnOn(PanelIndicator::External); break;
    }
    Serial.print(F("SOURCE value="));
    Serial.println(sourceName(source));
    Serial.print(F("INSTR modulation_source="));
    Serial.println(sourceName(source));
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
    blinkActive_ = true;
    blinkBlank_ = true;
    blinkPhasesRemaining_ = kBlinkPhaseCount;
    previousBlinkMs_ = millis();
    applyBlinkMask(true);
}

void OperatingController::applyBlinkMask(bool blank)
{
    frontPanel.setDisplayBlankMask(DisplayField::Frequency, 0u);
    frontPanel.setDisplayBlankMask(DisplayField::Modulation, 0u);
    frontPanel.setDisplayBlankMask(DisplayField::Amplitude, 0u);
    if (blank) {
        const uint8_t position = displayStepPosition();
        const DisplayField field = targetDisplayField();
        const uint16_t mask = (position >= 3u && field == DisplayField::Modulation)
            ? 0x07u
            : uint16_t(1u) << position;
        frontPanel.setDisplayBlankMask(field, mask);
    }
    frontPanel.refreshDisplays();
}

void OperatingController::renderAll()
{
    renderIndicators();
    renderDisplays();
}

void OperatingController::renderIndicators()
{
    frontPanel.clearIndicators();
    switch (settings_.target) {
    case Target::Frequency: frontPanel.turnOn(PanelIndicator::Rf); break;
    case Target::Amplitude: frontPanel.turnOn(PanelIndicator::Amplitude); break;
    case Target::Fm: frontPanel.turnOn(PanelIndicator::Fm); break;
    case Target::Pm: frontPanel.turnOn(PanelIndicator::Pm); break;
    case Target::Am: frontPanel.turnOn(PanelIndicator::Am); break;
    }
    frontPanel.turnOn(PanelIndicator::DBm);
    switch (settings_.modulationMode) {
    case ModulationMode::Fm: frontPanel.turnOn(PanelIndicator::ModKHz); break;
    case ModulationMode::Pm: frontPanel.turnOn(PanelIndicator::ModRd); break;
    case ModulationMode::Am: frontPanel.turnOn(PanelIndicator::ModPercent); break;
    }
    switch (settings_.modulationSource) {
    case ModulationSource::Cw: frontPanel.turnOn(PanelIndicator::Cw); break;
    case ModulationSource::Hz400: frontPanel.turnOn(PanelIndicator::Hz400); break;
    case ModulationSource::KHz1: frontPanel.turnOn(PanelIndicator::KHz1); break;
    case ModulationSource::External: frontPanel.turnOn(PanelIndicator::External); break;
    }
    frontPanel.setIndicator(PanelIndicator::ManualValidation,
                            !settings_.wheelInhibited &&
                            settings_.target == settings_.wheelTarget);
    frontPanel.setIndicator(PanelIndicator::RfInhibit, settings_.rfOff);
}

void OperatingController::renderDisplays()
{
    frontPanel.setDisplayBlankMask(DisplayField::Frequency, 0u);
    frontPanel.setDisplayBlankMask(DisplayField::Modulation, 0u);
    frontPanel.setDisplayBlankMask(DisplayField::Amplitude, 0u);
    frontPanel.setFrequencyHz(settings_.frequencyHz);
    const uint16_t amplitudeMagnitude = settings_.amplitudeTenthsDbm < 0
        ? uint16_t(-int32_t(settings_.amplitudeTenthsDbm))
        : uint16_t(settings_.amplitudeTenthsDbm);
    frontPanel.setAmplitudeDisplay(settings_.amplitudeTenthsDbm, 0x02u,
                                   amplitudeMagnitude >= 1000u);
    renderModulationDisplay();
    frontPanel.refreshDisplays();
}

void OperatingController::renderModulationDisplay()
{
    switch (settings_.modulationMode) {
    case ModulationMode::Am:
        frontPanel.setModulationDisplay(settings_.amTenthsPercent,
                                        ModulationUnitLed::Percent,
                                        0x02u, false);
        break;
    case ModulationMode::Pm:
        {
            const DisplaySpec spec = pmDisplaySpec(settings_.pmHundredthsRd);
            frontPanel.setModulationDisplay(spec.digits, ModulationUnitLed::Rd,
                                            spec.decimalMask, spec.leadingOne);
        }
        break;
    case ModulationMode::Fm:
        {
            const DisplaySpec spec = fmDisplaySpec(settings_.fmHz);
            frontPanel.setModulationDisplay(spec.digits, ModulationUnitLed::KHz,
                                            spec.decimalMask, spec.leadingOne);
        }
        break;
    }
}

void OperatingController::reportTarget() const
{
    Serial.print(F("TARGET value="));
    Serial.println(targetName(settings_.target));
}

void OperatingController::reportStep() const
{
    Serial.print(F("STEP target="));
    Serial.print(targetName(settings_.wheelTarget));
    Serial.print(F(" value="));
    Serial.println(currentStep());
}

void OperatingController::reportValue(Target target, bool instrumentEvent) const
{
    Serial.print(F("VALUE target="));
    Serial.print(targetName(target));
    Serial.print(F(" value="));
    switch (target) {
    case Target::Frequency: Serial.println(settings_.frequencyHz); break;
    case Target::Amplitude: Serial.println(settings_.amplitudeTenthsDbm); break;
    case Target::Fm: Serial.println(settings_.fmHz); break;
    case Target::Pm: Serial.println(settings_.pmHundredthsRd); break;
    case Target::Am: Serial.println(settings_.amTenthsPercent); break;
    }
    if (instrumentEvent) {
        Serial.print(F("INSTR parameter="));
        Serial.print(targetName(target));
        Serial.print(F(" value="));
        switch (target) {
        case Target::Frequency: Serial.println(settings_.frequencyHz); break;
        case Target::Amplitude: Serial.println(settings_.amplitudeTenthsDbm); break;
        case Target::Fm: Serial.println(settings_.fmHz); break;
        case Target::Pm: Serial.println(settings_.pmHundredthsRd); break;
        case Target::Am: Serial.println(settings_.amTenthsPercent); break;
        }
    }
}

uint32_t OperatingController::currentStep() const
{
    switch (settings_.wheelTarget) {
    case Target::Frequency: return kFrequencySteps[settings_.frequencyStepIndex];
    case Target::Amplitude: return kAmplitudeSteps[settings_.amplitudeStepIndex];
    case Target::Fm: return effectiveFmStep(settings_.fmHz, settings_.fmStepIndex);
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
    switch (settings_.wheelTarget) {
    case Target::Frequency:
        return uint8_t(currentStepIndex() + 1u);
    case Target::Amplitude:
    case Target::Am:
    case Target::Pm:
        return currentStepIndex();
    case Target::Fm:
        return decimalPosition(currentStep(), settings_.fmHz < 20000u ? 10u : 100u);
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
    case Target::Am:
        return DisplayField::Modulation;
    }
    return DisplayField::Frequency;
}

}  // namespace control
}  // namespace adret
