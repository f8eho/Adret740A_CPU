#include "Adret/FrontPanel.h"

#include "Adret/FrontPanelBus.h"
#include "Adret/FrontPanelIrq.h"

namespace adret {

namespace {

using namespace front_panel;

constexpr uint8_t kModulationTextWidth = 6;
constexpr uint8_t kAmplitudeTextWidth = 6;

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
                          MemoryLedMode::D25Blink,
                          true,
                          true) == 0xFFu,
              "Unexpected SN3 all-selected byte");
static_assert(makeSn3Byte(StatusLed::None,
                          ModulationUnitLed::None,
                          MemoryLedMode::None,
                          false,
                          false) == 0x08u,
              "Unexpected SN3 cleared byte");

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
    memoryMode_ = MemoryLedMode::None;
    memory_ = false;
    sequence_ = false;
    firstCharFlags_ = 0;
    decimalPointFlags_ = 0;
    keyHead_ = 0;
    keyCount_ = 0;
    keyOverflowCount_ = 0;
    encoderDelta_ = 0;

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
        if (enabled) {
            firstCharFlags_ |= kRemote;
        } else {
            firstCharFlags_ &= uint8_t(~kRemote);
        }
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
        return (firstCharFlags_ & kRemote) != 0u;
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

void FrontPanel::setModulationValue(uint32_t value,
                                    ModulationUnitLed unit,
                                    bool decimalPoint)
{
    formatUnsigned(value, displayBuffers_.modulation, kModulationTextWidth);
    modulationUnit_ = unit;
    if (decimalPoint) {
        decimalPointFlags_ |= kModulationDecimalPoint;
    } else {
        decimalPointFlags_ &= uint8_t(~kModulationDecimalPoint);
    }
    flushOutputs();
}

void FrontPanel::setAmplitudeValue(int32_t value,
                                   AmplitudeUnitLed unit,
                                   bool decimalPoint)
{
    formatSignedMagnitude(value, displayBuffers_.amplitude, kAmplitudeTextWidth);
    amplitudeUnit_ = unit;
    firstCharFlags_ &= uint8_t(~(kPowerMinus | kPowerPlus));
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

void FrontPanel::pollInputs()
{
    const uint8_t pendingPanelEvents = frontPanelIrq.consumePending();
    for (uint8_t i = 0; i < pendingPanelEvents; ++i) {
        const KeyboardSample sample = frontPanelBus.readKeyboard();
        if (sample.encoderCountLine) {
            if (sample.encoderDirectionLine) {
                ++encoderDelta_;
            } else {
                --encoderDelta_;
            }
        } else {
            pushKey(sample);
        }
    }
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
            return Key::Address17;
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
    if (keyCount_ >= kKeyQueueCapacity) {
        if (keyOverflowCount_ != 0xFFu) {
            ++keyOverflowCount_;
        }
        return;
    }

    const uint8_t writeIndex = queueIndex(keyHead_, keyCount_);
    keyQueue_[writeIndex].sample = sample;
    keyQueue_[writeIndex].key = keyForSample(sample);
    ++keyCount_;
}

}  // namespace adret
