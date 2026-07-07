#include <Arduino.h>

#include "Adret/FrontPanel.h"
#include "Adret/FrontPanelBus.h"
#include "Adret/FrontPanelIrq.h"
#include "Adret/FrontPanelMap.h"

namespace {

enum class DebugPhase : uint8_t {
    Leds,
    Displays,
    Inputs,
};

constexpr DebugPhase kDebugPhase = DebugPhase::Leds;
constexpr uint16_t kLedDebugPeriodMs = 500;

adret::front_panel::PanelIndicator functionIndicatorForStep(uint8_t step)
{
    using adret::front_panel::PanelIndicator;
    switch (step & 0x07u) {
        case 3:
            return PanelIndicator::Rf;
        case 4:
            return PanelIndicator::Fm;
        case 5:
            return PanelIndicator::Pm;
        case 6:
            return PanelIndicator::Am;
        case 7:
            return PanelIndicator::Amplitude;
        default:
            return PanelIndicator::Rf;
    }
}

adret::front_panel::PanelIndicator amplitudeIndicatorForStep(uint8_t step)
{
    using adret::front_panel::PanelIndicator;
    switch (step % 6u) {
        case 0:
            return PanelIndicator::DBm;
        case 1:
            return PanelIndicator::DB;
        case 2:
            return PanelIndicator::DBuV;
        case 3:
            return PanelIndicator::Volt;
        case 4:
            return PanelIndicator::MilliVolt;
        default:
            return PanelIndicator::MicroVolt;
    }
}

adret::front_panel::PanelIndicator modulationSourceIndicatorForStep(uint8_t step)
{
    using adret::front_panel::PanelIndicator;
    switch (step & 0x03u) {
        case 0:
            return PanelIndicator::Hz400;
        case 1:
            return PanelIndicator::KHz1;
        case 2:
            return PanelIndicator::External;
        default:
            return PanelIndicator::Cw;
    }
}

adret::front_panel::PanelIndicator statusIndicatorForStep(uint8_t step)
{
    using adret::front_panel::PanelIndicator;
    switch (step & 0x03u) {
        case 1:
            return PanelIndicator::Error;
        case 2:
            return PanelIndicator::Dept;
        case 3:
            return PanelIndicator::Normal;
        default:
            return PanelIndicator::Normal;
    }
}

adret::front_panel::PanelIndicator modulationUnitIndicatorForStep(uint8_t step)
{
    using adret::front_panel::PanelIndicator;
    switch (step & 0x03u) {
        case 1:
            return PanelIndicator::ModRd;
        case 2:
            return PanelIndicator::ModKHz;
        case 3:
            return PanelIndicator::ModPercent;
        default:
            return PanelIndicator::ModPercent;
    }
}

adret::front_panel::MemoryLedMode memoryModeForStep(uint8_t step)
{
    using adret::front_panel::MemoryLedMode;
    switch (step & 0x03u) {
        case 0:
            return MemoryLedMode::Q2Base;
        case 1:
            return MemoryLedMode::D25Fixed;
        case 3:
            return MemoryLedMode::D25Blink;
        default:
            return MemoryLedMode::None;
    }
}

void runLedDebug()
{
    static uint32_t previousMs = 0;
    static uint8_t step = 0;

    const uint32_t now = millis();
    if ((now - previousMs) < kLedDebugPeriodMs) {
        return;
    }
    previousMs = now;
    ++step;

    adret::frontPanel.turnOff(adret::front_panel::PanelIndicator::Rf);
    adret::frontPanel.turnOff(adret::front_panel::PanelIndicator::Fm);
    adret::frontPanel.turnOff(adret::front_panel::PanelIndicator::Pm);
    adret::frontPanel.turnOff(adret::front_panel::PanelIndicator::Am);
    adret::frontPanel.turnOff(adret::front_panel::PanelIndicator::Amplitude);
    if ((step & 0x07u) >= 3u) {
        adret::frontPanel.turnOn(functionIndicatorForStep(step));
    }

    adret::frontPanel.turnOff(adret::front_panel::PanelIndicator::Error);
    adret::frontPanel.turnOff(adret::front_panel::PanelIndicator::Dept);
    adret::frontPanel.turnOff(adret::front_panel::PanelIndicator::Normal);
    if ((step & 0x03u) != 0u) {
        adret::frontPanel.turnOn(statusIndicatorForStep(step));
    }

    adret::frontPanel.turnOff(adret::front_panel::PanelIndicator::ModRd);
    adret::frontPanel.turnOff(adret::front_panel::PanelIndicator::ModKHz);
    adret::frontPanel.turnOff(adret::front_panel::PanelIndicator::ModPercent);
    if ((step & 0x03u) != 0u) {
        adret::frontPanel.turnOn(modulationUnitIndicatorForStep(step));
    }

    adret::frontPanel.turnOn(amplitudeIndicatorForStep(step));
    adret::frontPanel.turnOn(modulationSourceIndicatorForStep(step));
    adret::frontPanel.setIndicator(adret::front_panel::PanelIndicator::Memory,
                                   (step & 0x01u) != 0u);
    adret::frontPanel.setIndicator(adret::front_panel::PanelIndicator::Sequence,
                                   (step & 0x02u) != 0u);
    adret::frontPanel.setMemoryMode(memoryModeForStep(step));
}

void runInputDebug()
{
    adret::frontPanel.pollInputs();

    adret::front_panel::KeyEvent event = {};
    while (adret::frontPanel.popKey(&event)) {
        (void)event;
    }

    const int16_t encoderDelta = adret::frontPanel.consumeEncoderDelta();
    (void)encoderDelta;
}

}  // namespace

void setup()
{
    adret::frontPanelBus.begin();
    adret::frontPanelIrq.begin();
    adret::frontPanel.begin();
}

void loop()
{
    switch (kDebugPhase) {
    case DebugPhase::Leds:
        runLedDebug();
        return;
    case DebugPhase::Displays:
        return;
    case DebugPhase::Inputs:
        runInputDebug();
        return;
    }
}
