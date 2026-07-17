#include "Adret/FrontPanel.h"

#include <Arduino.h>

#include "Adret/Debug.h"
#include "Adret/FrontPanelBus.h"
#include "Adret/FrontPanelIrq.h"
#include "Adret/HardwareConfig.h"

namespace adret {

namespace {

using namespace front_panel;

constexpr uint8_t kModulationTextWidth = 3;
constexpr uint8_t kAmplitudeTextWidth = 3;

constexpr uint8_t reversedCodeBDigit(const char* digits,
                                     uint8_t width,
                                     uint8_t memoryIndex,
                                     uint16_t decimalMask = 0,
                                     uint16_t blankMask = 0)
{
    return decoratedCodeBDigit(digits[uint8_t(width - 1u - memoryIndex)],
                               (decimalMask & (uint16_t(1u) << memoryIndex)) != 0u,
                               (blankMask & (uint16_t(1u) << memoryIndex)) != 0u);
}

constexpr uint8_t mixedSn11CodeBDigit(const char* frequency,
                                      const char* modulation,
                                      const char* amplitude,
                                      uint8_t memoryIndex)
{
    return (memoryIndex < 3u)
        ? reversedCodeBDigit(amplitude, 3u, memoryIndex)
        : ((memoryIndex < 6u)
            ? reversedCodeBDigit(modulation, 3u, uint8_t(memoryIndex - 3u))
            : reversedCodeBDigit(frequency, 2u, uint8_t(memoryIndex - 6u)));
}

static_assert(kIcm7218CodeBFrameCommand == 0x90u,
              "Unexpected ICM7218A Code B frame command");
static_assert(codeBDigit('0') == 0x80u && codeBDigit('9') == 0x89u,
              "Unexpected ICM7218A Code B digit encoding");
static_assert(codeBDigit('P') == 0x8Eu && codeBDigit('E') == 0x8Bu &&
              codeBDigit('-') == 0x8Au,
              "Unexpected ICM7218A Code B status character encoding");
static_assert(decoratedCodeBDigit('5', true, false) == 0x05u &&
              decoratedCodeBDigit('5', false, true) == 0x8Fu,
              "Unexpected ICM7218A decimal point or blank encoding");
static_assert(makeSn17Byte(0u) == 0xFFu &&
              makeSn17Byte(kModulationDecimalPoint) == 0xFEu,
              "Unexpected active-low SN17 decimal-point encoding");
static_assert(kModulationOne == 0x01u && kModulationP == 0x02u &&
              kPowerOneBlank == 0x04u &&
              kPowerPlus == 0x08u && kPowerMinus == 0x10u,
              "Unexpected bench-validated SN4 bus mapping");
static_assert(withRemoteIndicator(kPowerOneBlank, false) == 0x24u &&
              withRemoteIndicator(kPowerOneBlank, true) == 0x04u,
              "Unexpected active-low REM encoding");
static_assert(reversedCodeBDigit("12345678", 8u, 0u) == 0x88u &&
              reversedCodeBDigit("12345678", 8u, 7u) == 0x81u,
              "Unexpected SN10 frame order");
static_assert(mixedSn11CodeBDigit("12", "345", "678", 0u) == 0x88u &&
              mixedSn11CodeBDigit("12", "345", "678", 3u) == 0x85u &&
              mixedSn11CodeBDigit("12", "345", "678", 6u) == 0x82u &&
              mixedSn11CodeBDigit("12", "345", "678", 7u) == 0x81u,
              "Unexpected SN11 frame order");

static_assert(makeSn2Byte(FunctionLed::Rf,
                          AmplitudeUnitLed::DBm,
                          ModulationSourceLed::Hz400) == 0x60u,
              "Unexpected SN2 RF/dBm/400Hz byte");
static_assert(makeSn2Byte(FunctionLed::Amplitude,
                          AmplitudeUnitLed::UV,
                          ModulationSourceLed::Cw) == 0xF7u,
              "Unexpected SN2 AMP/uV/CW byte");
static_assert(makeSn3Byte(StatusLed::Normal,
                          ModulationUnitLed::Percent,
                          MemoryLedMode::Blink,
                          true,
                          true) == 0xF0u,
              "Unexpected SN3 all-selected byte");
static_assert(makeSn3Byte(StatusLed::None,
                          ModulationUnitLed::None,
                          MemoryLedMode::Off,
                          false,
                          false) == 0x07u,
              "Unexpected SN3 cleared byte");
static_assert(makeSn3Byte(StatusLed::None,
                          ModulationUnitLed::None,
                          MemoryLedMode::Off,
                          true,
                          false) == 0x05u &&
              makeSn3Byte(StatusLed::None,
                          ModulationUnitLed::None,
                          MemoryLedMode::Off,
                          false,
                          true) == 0x06u,
              "Unexpected SN3 MEM/SEQ mapping");
static_assert(keyboardX(0x28u) == 0u && keyboardY(0x28u) == 5u,
              "Unexpected AMPL keyboard coordinates");
static_assert(keyboardX(0x05u) == 5u && keyboardY(0x05u) == 0u,
              "Unexpected RF OFF keyboard coordinates");
static_assert(keyboardX(0x0Eu) == 6u && keyboardY(0x0Eu) == 1u,
              "Unexpected EXEC keyboard coordinates");

uint8_t queueIndex(uint8_t head, uint8_t offset)
{
    uint8_t index = uint8_t(head + offset);
    if (index >= FrontPanel::kKeyQueueCapacity) {
        index = uint8_t(index - FrontPanel::kKeyQueueCapacity);
    }
    return index;
}

}  // namespace

FrontPanel frontPanel;

const __FlashStringHelper* front_panel::keyShortLabel(Key key)
{
    switch (key) {
    case Key::Amplitude: return F("AMPL");
    case Key::Rf: return F("RF");
    case Key::Fm: return F("FM");
    case Key::Pm: return F("PM");
    case Key::Am: return F("AM");
    case Key::Spl: return F("SPL");
    case Key::Digit0: return F("0");
    case Key::Digit1: return F("1");
    case Key::Digit2: return F("2");
    case Key::Digit3: return F("3");
    case Key::Digit4: return F("4");
    case Key::Digit5: return F("5");
    case Key::Digit6: return F("6");
    case Key::Digit7: return F("7");
    case Key::Digit8: return F("8");
    case Key::Digit9: return F("9");
    case Key::Mhz: return F("MHZ");
    case Key::KHz: return F("KHZ");
    case Key::Hz: return F("HZ");
    case Key::Cw: return F("CW");
    case Key::External: return F("EXT");
    case Key::KHz1: return F("1KHZ");
    case Key::Hz400: return F("400HZ");
    case Key::Divide10: return F("DIV10");
    case Key::Multiply10: return F("MUL10");
    case Key::ValidManual: return F("VALID");
    case Key::Exec: return F("EXEC");
    case Key::Sequence: return F("SEQ");
    case Key::Memory: return F("MEM");
    case Key::Recall: return F("RECALL");
    case Key::Increment: return F("INC");
    case Key::RfOff: return F("RF_OFF");
    case Key::AddressRtl: return F("ADR_RTL");
    case Key::XToY: return F("X_TO_Y");
    case Key::Left: return F("LEFT");
    case Key::Clear: return F("CLEAR");
    case Key::DecimalPoint: return F("POINT");
    case Key::DBm: return F("DBM");
    case Key::OneDBm: return F("1DBM");
    case Key::Up: return F("UP");
    case Key::Down: return F("DOWN");
    case Key::None: return F("UNKNOWN");
    }
    return F("UNKNOWN");
}

void FrontPanel::begin()
{
    reset();
    flushOutputs();
}

void FrontPanel::reset()
{
    functionLed_ = FunctionLed::None0;
    amplitudeUnit_ = AmplitudeUnitLed::None6;
    modulationSource_ = ModulationSourceLed::Cw;
    statusLed_ = StatusLed::Normal;
    modulationUnit_ = ModulationUnitLed::None;
    memoryMode_ = MemoryLedMode::Off;
    memory_ = false;
    sequence_ = false;
    firstCharFlags_ = withRemoteIndicator(kPowerOneBlank, false);
    decimalPointFlags_ = 0;
    frequencyBlankMask_ = 0;
    modulationBlankMask_ = 0;
    amplitudeBlankMask_ = 0;
    frequencyIcmDecimalMask_ = 0;
    modulationIcmDecimalMask_ = 0;
    amplitudeIcmDecimalMask_ = 0;
    keyHead_ = 0;
    keyCount_ = 0;
    keyOverflowCount_ = 0;
    encoderHead_ = 0;
    encoderCount_ = 0;
    encoderOverflowCount_ = 0;
    encoderDelta_ = 0;
    ca1FailureLatched_ = false;
    ca1RecoveryCount_ = 0u;
    ca1FailureCount_ = 0u;
    lastQueuedKey_ = Key::None;
    lastQueuedKeyMs_ = 0;

    setFrequencyHz(0);
    formatUnsigned(0, displayBuffers_.modulation, kModulationTextWidth);
    formatSignedMagnitude(0, displayBuffers_.amplitude, kAmplitudeTextWidth);
}

void FrontPanel::flushOutputs()
{
    flushFlags();
    flushSn2();
    flushSn3();
}

void FrontPanel::setIndicator(PanelIndicator indicator, bool enabled)
{
    switch (indicator) {
    case PanelIndicator::Rf:
        if (enabled || functionLed_ == FunctionLed::Rf) {
            functionLed_ = enabled ? FunctionLed::Rf : FunctionLed::None0;
        }
        break;
    case PanelIndicator::Fm:
        if (enabled || functionLed_ == FunctionLed::Fm) {
            functionLed_ = enabled ? FunctionLed::Fm : FunctionLed::None0;
        }
        break;
    case PanelIndicator::Pm:
        if (enabled || functionLed_ == FunctionLed::Pm) {
            functionLed_ = enabled ? FunctionLed::Pm : FunctionLed::None0;
        }
        break;
    case PanelIndicator::Am:
        if (enabled || functionLed_ == FunctionLed::Am) {
            functionLed_ = enabled ? FunctionLed::Am : FunctionLed::None0;
        }
        break;
    case PanelIndicator::Amplitude:
        if (enabled || functionLed_ == FunctionLed::Amplitude) {
            functionLed_ = enabled ? FunctionLed::Amplitude : FunctionLed::None0;
        }
        break;
    case PanelIndicator::DBm:
        if (enabled || amplitudeUnit_ == AmplitudeUnitLed::DBm) {
            amplitudeUnit_ = enabled ? AmplitudeUnitLed::DBm : AmplitudeUnitLed::None6;
        }
        break;
    case PanelIndicator::DB:
        if (enabled || amplitudeUnit_ == AmplitudeUnitLed::DB) {
            amplitudeUnit_ = enabled ? AmplitudeUnitLed::DB : AmplitudeUnitLed::None6;
        }
        break;
    case PanelIndicator::DBuV:
        if (enabled || amplitudeUnit_ == AmplitudeUnitLed::DBuV) {
            amplitudeUnit_ = enabled ? AmplitudeUnitLed::DBuV : AmplitudeUnitLed::None6;
        }
        break;
    case PanelIndicator::Volt:
        if (enabled || amplitudeUnit_ == AmplitudeUnitLed::V) {
            amplitudeUnit_ = enabled ? AmplitudeUnitLed::V : AmplitudeUnitLed::None6;
        }
        break;
    case PanelIndicator::MilliVolt:
        if (enabled || amplitudeUnit_ == AmplitudeUnitLed::MV) {
            amplitudeUnit_ = enabled ? AmplitudeUnitLed::MV : AmplitudeUnitLed::None6;
        }
        break;
    case PanelIndicator::MicroVolt:
        if (enabled || amplitudeUnit_ == AmplitudeUnitLed::UV) {
            amplitudeUnit_ = enabled ? AmplitudeUnitLed::UV : AmplitudeUnitLed::None6;
        }
        break;
    case PanelIndicator::Hz400:
        if (enabled) {
            modulationSource_ = ModulationSourceLed::Hz400;
        } else if (modulationSource_ == ModulationSourceLed::Hz400) {
            modulationSource_ = ModulationSourceLed::Cw;
        }
        break;
    case PanelIndicator::KHz1:
        if (enabled) {
            modulationSource_ = ModulationSourceLed::KHz1;
        } else if (modulationSource_ == ModulationSourceLed::KHz1) {
            modulationSource_ = ModulationSourceLed::Cw;
        }
        break;
    case PanelIndicator::External:
        if (enabled) {
            modulationSource_ = ModulationSourceLed::External;
        } else if (modulationSource_ == ModulationSourceLed::External) {
            modulationSource_ = ModulationSourceLed::Cw;
        }
        break;
    case PanelIndicator::Cw:
        modulationSource_ = ModulationSourceLed::Cw;
        break;
    case PanelIndicator::Error:
        if (enabled || statusLed_ == StatusLed::Error) {
            statusLed_ = enabled ? StatusLed::Error : StatusLed::None;
        }
        break;
    case PanelIndicator::Dept:
        if (enabled || statusLed_ == StatusLed::Dept) {
            statusLed_ = enabled ? StatusLed::Dept : StatusLed::None;
        }
        break;
    case PanelIndicator::Normal:
        if (enabled || statusLed_ == StatusLed::Normal) {
            statusLed_ = enabled ? StatusLed::Normal : StatusLed::None;
        }
        break;
    case PanelIndicator::ModRd:
        if (enabled || modulationUnit_ == ModulationUnitLed::Rd) {
            modulationUnit_ = enabled ? ModulationUnitLed::Rd : ModulationUnitLed::None;
        }
        break;
    case PanelIndicator::ModKHz:
        if (enabled || modulationUnit_ == ModulationUnitLed::KHz) {
            modulationUnit_ = enabled ? ModulationUnitLed::KHz : ModulationUnitLed::None;
        }
        break;
    case PanelIndicator::ModPercent:
        if (enabled || modulationUnit_ == ModulationUnitLed::Percent) {
            modulationUnit_ = enabled ? ModulationUnitLed::Percent : ModulationUnitLed::None;
        }
        break;
    case PanelIndicator::Memory:
        memory_ = enabled;
        break;
    case PanelIndicator::Sequence:
        sequence_ = enabled;
        break;
    case PanelIndicator::Remote:
        firstCharFlags_ = withRemoteIndicator(firstCharFlags_, enabled);
        break;
    case PanelIndicator::RfInhibit:
        if (enabled) {
            firstCharFlags_ |= kRfInhibit;
        } else {
            firstCharFlags_ &= uint8_t(~kRfInhibit);
        }
        break;
    case PanelIndicator::ManualValidation:
        if (enabled) {
            firstCharFlags_ |= kManualValidation;
        } else {
            firstCharFlags_ &= uint8_t(~kManualValidation);
        }
        break;
    }

    flushOutputs();
}

void FrontPanel::turnOn(PanelIndicator indicator)
{
    setIndicator(indicator, true);
}

void FrontPanel::turnOff(PanelIndicator indicator)
{
    setIndicator(indicator, false);
}

bool FrontPanel::isOn(PanelIndicator indicator) const
{
    switch (indicator) {
    case PanelIndicator::Rf:
        return functionLed_ == FunctionLed::Rf;
    case PanelIndicator::Fm:
        return functionLed_ == FunctionLed::Fm;
    case PanelIndicator::Pm:
        return functionLed_ == FunctionLed::Pm;
    case PanelIndicator::Am:
        return functionLed_ == FunctionLed::Am;
    case PanelIndicator::Amplitude:
        return functionLed_ == FunctionLed::Amplitude;
    case PanelIndicator::DBm:
        return amplitudeUnit_ == AmplitudeUnitLed::DBm;
    case PanelIndicator::DB:
        return amplitudeUnit_ == AmplitudeUnitLed::DB;
    case PanelIndicator::DBuV:
        return amplitudeUnit_ == AmplitudeUnitLed::DBuV;
    case PanelIndicator::Volt:
        return amplitudeUnit_ == AmplitudeUnitLed::V;
    case PanelIndicator::MilliVolt:
        return amplitudeUnit_ == AmplitudeUnitLed::MV;
    case PanelIndicator::MicroVolt:
        return amplitudeUnit_ == AmplitudeUnitLed::UV;
    case PanelIndicator::Hz400:
        return modulationSource_ == ModulationSourceLed::Hz400;
    case PanelIndicator::KHz1:
        return modulationSource_ == ModulationSourceLed::KHz1;
    case PanelIndicator::External:
        return modulationSource_ == ModulationSourceLed::External;
    case PanelIndicator::Cw:
        return modulationSource_ == ModulationSourceLed::Cw;
    case PanelIndicator::Error:
        return statusLed_ == StatusLed::Error;
    case PanelIndicator::Dept:
        return statusLed_ == StatusLed::Dept;
    case PanelIndicator::Normal:
        return statusLed_ == StatusLed::Normal;
    case PanelIndicator::ModRd:
        return modulationUnit_ == ModulationUnitLed::Rd;
    case PanelIndicator::ModKHz:
        return modulationUnit_ == ModulationUnitLed::KHz;
    case PanelIndicator::ModPercent:
        return modulationUnit_ == ModulationUnitLed::Percent;
    case PanelIndicator::Memory:
        return memory_;
    case PanelIndicator::Sequence:
        return sequence_;
    case PanelIndicator::Remote:
        return (firstCharFlags_ & kRemote) == 0u;
    case PanelIndicator::RfInhibit:
        return (firstCharFlags_ & kRfInhibit) != 0u;
    case PanelIndicator::ManualValidation:
        return (firstCharFlags_ & kManualValidation) != 0u;
    }
    return false;
}

void FrontPanel::setMemoryMode(MemoryLedMode mode)
{
    memoryMode_ = mode;
    flushOutputs();
}

void FrontPanel::setExecIndicator(ExecIndicator mode)
{
    switch (mode) {
    case ExecIndicator::Off: memoryMode_ = MemoryLedMode::Off; break;
    case ExecIndicator::Fixed: memoryMode_ = MemoryLedMode::Fixed; break;
    case ExecIndicator::Blink: memoryMode_ = MemoryLedMode::Blink; break;
    }
    flushOutputs();
}

void FrontPanel::setFrequencyHz(uint32_t frequencyHz)
{
    formatUnsigned(frequencyHz, displayBuffers_.frequencyHz, 10);

    for (uint8_t i = 0; i < 8; ++i) {
        displayBuffers_.frequencySn10[i] = displayBuffers_.frequencyHz[i];
    }
    displayBuffers_.frequencySn10[8] = '\0';
    displayBuffers_.frequencySn11[0] = displayBuffers_.frequencyHz[8];
    displayBuffers_.frequencySn11[1] = displayBuffers_.frequencyHz[9];
    displayBuffers_.frequencySn11[2] = '\0';
}

void FrontPanel::setFrequencyText(const char* text)
{
    uint8_t length = 0;
    if (text != nullptr) {
        while (text[length] != '\0' && length < 10u) {
            ++length;
        }
    }
    const uint8_t padding = uint8_t(10u - length);
    for (uint8_t i = 0; i < padding; ++i) {
        displayBuffers_.frequencyHz[i] = ' ';
    }
    for (uint8_t i = 0; i < length; ++i) {
        displayBuffers_.frequencyHz[uint8_t(padding + i)] = text[i];
    }
    displayBuffers_.frequencyHz[10] = '\0';
    for (uint8_t i = 0; i < 8u; ++i) {
        displayBuffers_.frequencySn10[i] = displayBuffers_.frequencyHz[i];
    }
    displayBuffers_.frequencySn10[8] = '\0';
    displayBuffers_.frequencySn11[0] = displayBuffers_.frequencyHz[8];
    displayBuffers_.frequencySn11[1] = displayBuffers_.frequencyHz[9];
    displayBuffers_.frequencySn11[2] = '\0';
    frequencyIcmDecimalMask_ = 0u;
    frequencyBlankMask_ = 0u;
}

void FrontPanel::setModulationValue(uint32_t value,
                                    ModulationUnitLed unit,
                                    bool decimalPoint)
{
    formatUnsigned(value, displayBuffers_.modulation, kModulationTextWidth);
    modulationUnit_ = unit;
    modulationIcmDecimalMask_ = 0;
    if (decimalPoint) {
        decimalPointFlags_ |= kModulationDecimalPoint;
    } else {
        decimalPointFlags_ &= uint8_t(~kModulationDecimalPoint);
    }
    flushOutputs();
}

void FrontPanel::setModulationDisplay(uint16_t digits,
                                      ModulationUnitLed unit,
                                      uint8_t icmDecimalMask,
                                      bool leadingOne)
{
    formatUnsigned(digits, displayBuffers_.modulation, kModulationTextWidth);
    modulationUnit_ = unit;
    modulationIcmDecimalMask_ = uint8_t(icmDecimalMask & 0x07u);
    decimalPointFlags_ &= uint8_t(~kModulationDecimalPoint);
    firstCharFlags_ &= uint8_t(~(kModulationOne | kModulationP));
    if (leadingOne) {
        firstCharFlags_ |= kModulationOne;
    }
    flushOutputs();
}

void FrontPanel::setAmplitudeValue(int32_t value,
                                   AmplitudeUnitLed unit,
                                   bool decimalPoint)
{
    formatSignedMagnitude(value, displayBuffers_.amplitude, kAmplitudeTextWidth);
    amplitudeUnit_ = unit;
    amplitudeIcmDecimalMask_ = 0;
    firstCharFlags_ &= uint8_t(~(kPowerOneBlank | kPowerMinus | kPowerPlus));
    const uint32_t magnitude = value < 0
        ? uint32_t(-(value + 1)) + 1u
        : uint32_t(value);
    if (magnitude < 1000u) {
        firstCharFlags_ |= kPowerOneBlank;
    }
    if (value < 0) {
        firstCharFlags_ |= kPowerMinus;
    } else if (value > 0) {
        firstCharFlags_ |= kPowerPlus;
    }
    if (decimalPoint) {
        decimalPointFlags_ |= kAmplitudeDecimalPoint;
    } else {
        decimalPointFlags_ &= uint8_t(~kAmplitudeDecimalPoint);
    }
    flushOutputs();
}

void FrontPanel::setAmplitudeDisplay(int16_t tenthsDbm,
                                     uint8_t icmDecimalMask,
                                     bool leadingOne)
{
    formatSignedMagnitude(tenthsDbm, displayBuffers_.amplitude,
                          kAmplitudeTextWidth);
    amplitudeUnit_ = AmplitudeUnitLed::DBm;
    amplitudeIcmDecimalMask_ = uint8_t(icmDecimalMask & 0x07u);
    decimalPointFlags_ &= uint8_t(~kAmplitudeDecimalPoint);
    firstCharFlags_ &= uint8_t(~(kPowerOneBlank | kPowerMinus | kPowerPlus));
    if (!leadingOne) {
        firstCharFlags_ |= kPowerOneBlank;
    }
    if (tenthsDbm < 0) {
        firstCharFlags_ |= kPowerMinus;
    } else {
        firstCharFlags_ |= kPowerPlus;
    }
    flushOutputs();
}

void FrontPanel::setAmplitudeIncrementDisplay(uint16_t tenthsDb)
{
    formatUnsigned(tenthsDb, displayBuffers_.amplitude, kAmplitudeTextWidth);
    amplitudeUnit_ = AmplitudeUnitLed::DB;
    amplitudeIcmDecimalMask_ = 0x02u;
    decimalPointFlags_ &= uint8_t(~kAmplitudeDecimalPoint);
    firstCharFlags_ &= uint8_t(~(kPowerOneBlank | kPowerMinus | kPowerPlus));
    if (tenthsDb < 1000u) {
        firstCharFlags_ |= kPowerOneBlank;
    }
    flushOutputs();
}

void FrontPanel::setDisplayBlankMask(DisplayField field, uint16_t mask)
{
    switch (field) {
    case DisplayField::Frequency:
        frequencyBlankMask_ = uint16_t(mask & 0x03FFu);
        break;
    case DisplayField::Modulation:
        modulationBlankMask_ = uint8_t(mask & 0x07u);
        break;
    case DisplayField::Amplitude:
        amplitudeBlankMask_ = uint8_t(mask & 0x07u);
        break;
    }
}

void FrontPanel::setDisplayDecimalMask(DisplayField field, uint16_t mask)
{
    switch (field) {
    case DisplayField::Frequency:
        frequencyIcmDecimalMask_ = uint16_t(mask & 0x03FFu);
        break;
    case DisplayField::Modulation:
        modulationIcmDecimalMask_ = uint8_t(mask & 0x07u);
        break;
    case DisplayField::Amplitude:
        amplitudeIcmDecimalMask_ = uint8_t(mask & 0x07u);
        break;
    }
}

void FrontPanel::refreshDisplays()
{
    uint8_t sn10[kIcm7218DigitCount] = {};
    uint8_t sn11[kIcm7218DigitCount] = {};
    makeDisplayFrames(sn10, sn11);
    frontPanelBus.writeDisplayFrame(DisplayDevice::FrequencySn10, sn10);
    frontPanelBus.writeDisplayFrame(DisplayDevice::MixedSn11, sn11);
}

void FrontPanel::makeDisplayFrames(uint8_t* sn10, uint8_t* sn11) const
{
    for (uint8_t i = 0; i < kIcm7218DigitCount; ++i) {
        const uint8_t frequencyPosition = uint8_t(i + 2u);
        const uint16_t bit = uint16_t(1u) << frequencyPosition;
        sn10[i] = decoratedCodeBDigit(
            displayBuffers_.frequencySn10[uint8_t(7u - i)],
            (frequencyIcmDecimalMask_ & bit) != 0u,
            (frequencyBlankMask_ & bit) != 0u);
    }

    // ICM7218A loads dg0 first. SN11 is wired from right to left as:
    // amplitude dg0..dg2, modulation dg3..dg5, frequency dg6..dg7.
    for (uint8_t i = 0; i < kIcm7218DigitCount; ++i) {
        if (i < 3u) {
            sn11[i] = reversedCodeBDigit(displayBuffers_.amplitude, 3u, i,
                                         amplitudeIcmDecimalMask_,
                                         amplitudeBlankMask_);
        } else if (i < 6u) {
            const uint8_t position = uint8_t(i - 3u);
            sn11[i] = reversedCodeBDigit(displayBuffers_.modulation, 3u,
                                         position,
                                         modulationIcmDecimalMask_,
                                         modulationBlankMask_);
        } else {
            const uint8_t position = uint8_t(i - 6u);
            const uint16_t bit = uint16_t(1u) << position;
            sn11[i] = decoratedCodeBDigit(
                displayBuffers_.frequencySn11[uint8_t(1u - position)],
                (frequencyIcmDecimalMask_ & bit) != 0u,
                (frequencyBlankMask_ & bit) != 0u);
        }
    }
}

void FrontPanel::pollInputs()
{
    const uint8_t pendingPanelEvents = frontPanelIrq.consumePending();
    bool haveLastAcknowledgedSample = false;
    uint8_t lastAcknowledgedRaw = 0u;
    for (uint8_t i = 0; i < pendingPanelEvents; ++i) {
        const KeyboardSample sample = frontPanelBus.readKeyboard();
        haveLastAcknowledgedSample = true;
        lastAcknowledgedRaw = sample.raw;
        if (sample.encoderCountLine) {
            const int8_t step =
                sample.encoderDirectionLine == hw::kFrontPanelEncoderClockwiseLevel
                    ? 1
                    : -1;
            if ((step > 0) && (encoderDelta_ < INT16_MAX)) {
                ++encoderDelta_;
            } else if ((step < 0) && (encoderDelta_ > INT16_MIN)) {
                --encoderDelta_;
            }
            pushEncoder(sample, step);
        } else {
            pushKey(sample);
        }
    }

    if (!frontPanelIrq.ca1Asserted()) {
        ca1FailureLatched_ = false;
        return;
    }
    // A new edge can arrive just after consumePending(). Leave its latched SN5
    // sample untouched so the next poll processes the key instead of treating
    // it as a failed acknowledgement.
    if (pendingPanelEvents == 0u || frontPanelIrq.hasPending()) {
        return;
    }
    if (ca1FailureLatched_) {
        return;
    }

    uint8_t attempts = 0u;
#if ADRET_DEBUG_SERIAL
    uint8_t recoveredKeys = 0u;
#endif
    KeyboardSample lastSample = {};
    delayMicroseconds(hw::kFrontPanelRecoveryAcknowledgeGapUs);
    if (!frontPanelIrq.ca1Asserted() || frontPanelIrq.hasPending()) {
        return;
    }
    while (frontPanelIrq.ca1Asserted() &&
           attempts < hw::kFrontPanelRecoveryAcknowledgeCount) {
        if (frontPanelIrq.hasPending()) {
            return;
        }
        lastSample = frontPanelBus.readKeyboard();
        ++attempts;
        // The extra read usually returns the same key while completing the
        // acknowledgement. If it already contains a different keyboard key,
        // preserve it instead of silently discarding a fast following press.
        // Recovered encoder samples remain ignored to avoid double steps.
        if (!lastSample.encoderCountLine &&
            (!haveLastAcknowledgedSample ||
             lastSample.raw != lastAcknowledgedRaw)) {
            pushKey(lastSample);
#if ADRET_DEBUG_SERIAL
            ++recoveredKeys;
#endif
        }
        haveLastAcknowledgedSample = true;
        lastAcknowledgedRaw = lastSample.raw;
        delayMicroseconds(hw::kFrontPanelRecoveryAcknowledgeGapUs);
    }
    if (frontPanelIrq.ca1Asserted()) {
        ca1FailureLatched_ = true;
        if (ca1FailureCount_ < UINT16_MAX) {
            ++ca1FailureCount_;
        }
#if ADRET_DEBUG_SERIAL
        Serial.print(F("CA1_STUCK_LOW attempts="));
        Serial.print(attempts);
        Serial.print(F(" pending="));
        Serial.print(pendingPanelEvents);
        Serial.print(F(" recovered_keys="));
        Serial.print(recoveredKeys);
        Serial.print(F(" last_raw=0x"));
        if (lastSample.raw < 0x10u) {
            Serial.print('0');
        }
        Serial.print(lastSample.raw, HEX);
        Serial.print(F(" total="));
        Serial.println(ca1FailureCount_);
#endif
        return;
    }
    if (ca1RecoveryCount_ < UINT16_MAX) {
        ++ca1RecoveryCount_;
    }
    if (attempts > 1u || ca1RecoveryCount_ == 1u ||
        (ca1RecoveryCount_ & 0x001Fu) == 0u) {
#if ADRET_DEBUG_SERIAL
        Serial.print(F("CA1_RECOVERED attempts="));
        Serial.print(attempts);
        Serial.print(F(" pending="));
        Serial.print(pendingPanelEvents);
        Serial.print(F(" recovered_keys="));
        Serial.print(recoveredKeys);
        Serial.print(F(" total="));
        Serial.println(ca1RecoveryCount_);
#endif
    }
}

bool FrontPanel::popEncoder(EncoderEvent* event)
{
    if ((event == nullptr) || (encoderCount_ == 0u)) {
        return false;
    }

    *event = encoderQueue_[encoderHead_];
    encoderHead_ = queueIndex(encoderHead_, 1);
    --encoderCount_;
    return true;
}

bool FrontPanel::popKey(KeyEvent* event)
{
    if ((event == nullptr) || (keyCount_ == 0u)) {
        return false;
    }

    *event = keyQueue_[keyHead_];
    keyHead_ = queueIndex(keyHead_, 1);
    --keyCount_;
    return true;
}

int16_t FrontPanel::consumeEncoderDelta()
{
    const int16_t result = encoderDelta_;
    encoderDelta_ = 0;
    return result;
}

uint8_t FrontPanel::keyOverflowCount() const
{
    return keyOverflowCount_;
}

uint8_t FrontPanel::encoderOverflowCount() const
{
    return encoderOverflowCount_;
}

const DisplayBuffers& FrontPanel::displayBuffers() const
{
    return displayBuffers_;
}

Key FrontPanel::keyForSample(const KeyboardSample& sample)
{
    switch (sample.yCode) {
    case 0:
        switch (sample.xCode) {
        case 1:
            return Key::DecimalPoint;
        case 2:
            return Key::Digit4;
        case 3:
            return Key::Digit9;
        case 4:
            return Key::OneDBm;
        case 5:
            return Key::RfOff;
        case 6:
            return Key::Increment;
        case 7:
            return Key::Down;
        default:
            return Key::None;
        }
    case 1:
        switch (sample.xCode) {
        case 0:
            return Key::Am;
        case 1:
            return Key::Clear;
        case 2:
            return Key::Digit3;
        case 3:
            return Key::Digit8;
        case 4:
            return Key::DBm;
        case 5:
            return Key::Hz400;
        case 6:
            return Key::Exec;
        case 7:
            return Key::Up;
        default:
            return Key::None;
        }
    case 2:
        switch (sample.xCode) {
        case 0:
            return Key::Pm;
        case 1:
            return Key::Left;
        case 2:
            return Key::Digit2;
        case 3:
            return Key::Digit7;
        case 4:
            return Key::Hz;
        case 5:
            return Key::KHz1;
        case 6:
            return Key::Multiply10;
        case 7:
            return Key::Recall;
        default:
            return Key::None;
        }
    case 3:
        switch (sample.xCode) {
        case 0:
            return Key::Fm;
        case 1:
            return Key::XToY;
        case 2:
            return Key::Digit1;
        case 3:
            return Key::Digit6;
        case 4:
            return Key::KHz;
        case 5:
            return Key::External;
        case 6:
            return Key::ValidManual;
        case 7:
            return Key::Sequence;
        default:
            return Key::None;
        }
    case 4:
        switch (sample.xCode) {
        case 0:
            return Key::Rf;
        case 1:
            return Key::Spl;
        case 2:
            return Key::Digit0;
        case 3:
            return Key::Digit5;
        case 4:
            return Key::Mhz;
        case 5:
            return Key::Cw;
        case 6:
            return Key::Divide10;
        case 7:
            return Key::Memory;
        default:
            return Key::None;
        }
    case 5:
        switch (sample.xCode) {
        case 0:
            return Key::Amplitude;
        case 7:
            return Key::AddressRtl;
        default:
            return Key::None;
        }
    default:
        return Key::None;
    }
}

void FrontPanel::formatUnsigned(uint32_t value, char* out, uint8_t width)
{
    out[width] = '\0';
    for (uint8_t i = 0; i < width; ++i) {
        const uint8_t digit = uint8_t(value % 10u);
        out[uint8_t(width - 1u - i)] = char('0' + digit);
        value /= 10u;
    }
}

void FrontPanel::formatSignedMagnitude(int32_t value, char* out, uint8_t width)
{
    uint32_t magnitude = 0;
    if (value < 0) {
        magnitude = uint32_t(-(value + 1)) + 1u;
    } else {
        magnitude = uint32_t(value);
    }
    formatUnsigned(magnitude, out, width);
}

void FrontPanel::flushSn2()
{
    frontPanelBus.writeSn2(functionLed_, amplitudeUnit_, modulationSource_);
}

void FrontPanel::flushSn3()
{
    frontPanelBus.writeSn3(statusLed_,
                           modulationUnit_,
                           memoryMode_,
                           memory_,
                           sequence_);
}

void FrontPanel::flushFlags()
{
    frontPanelBus.writeDecimalPoints(decimalPointFlags_);
    frontPanelBus.writeFirstCharFlags(firstCharFlags_);
}

void FrontPanel::pushKey(const KeyboardSample& sample)
{
    const Key key = keyForSample(sample);
    if (key == Key::None) {
        return;
    }

    constexpr uint16_t kKeyDebounceMs = 30;
    const uint32_t now = millis();
    if ((key == lastQueuedKey_) &&
        ((now - lastQueuedKeyMs_) < kKeyDebounceMs)) {
        return;
    }

    if (keyCount_ >= kKeyQueueCapacity) {
        if (keyOverflowCount_ != 0xFFu) {
            ++keyOverflowCount_;
        }
        return;
    }

    const uint8_t writeIndex = queueIndex(keyHead_, keyCount_);
    keyQueue_[writeIndex].sample = sample;
    keyQueue_[writeIndex].key = key;
    ++keyCount_;
    lastQueuedKey_ = key;
    lastQueuedKeyMs_ = now;
}

void FrontPanel::pushEncoder(const KeyboardSample& sample, int8_t step)
{
    if (encoderCount_ >= kEncoderQueueCapacity) {
        if (encoderOverflowCount_ != 0xFFu) {
            ++encoderOverflowCount_;
        }
        return;
    }

    const uint8_t writeIndex = queueIndex(encoderHead_, encoderCount_);
    encoderQueue_[writeIndex].sample = sample;
    encoderQueue_[writeIndex].step = step;
    ++encoderCount_;
}

}  // namespace adret
