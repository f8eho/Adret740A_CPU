#include <Arduino.h>

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

void initialiseFrontPanel()
{
    using namespace adret::front_panel;

    adret::frontPanelBus.writeDecimalPoints(0x00);
    adret::frontPanelBus.writeFirstCharFlags(0x00);
    adret::frontPanelBus.writeSn2(FunctionLed::None0,
                                  AmplitudeUnitLed::None6,
                                  ModulationSourceLed::Cw);
    adret::frontPanelBus.writeSn3(StatusLed::Normal,
                                  ModulationUnitLed::None,
                                  MemoryLedMode::None,
                                  false,
                                  false);
}

adret::front_panel::FunctionLed functionLedForStep(uint8_t step)
{
    using adret::front_panel::FunctionLed;
    switch (step & 0x07u) {
        case 3:
            return FunctionLed::Rf;
        case 4:
            return FunctionLed::Fm;
        case 5:
            return FunctionLed::Pm;
        case 6:
            return FunctionLed::Am;
        case 7:
            return FunctionLed::Amplitude;
        default:
            return FunctionLed::None0;
    }
}

adret::front_panel::AmplitudeUnitLed amplitudeUnitForStep(uint8_t step)
{
    using adret::front_panel::AmplitudeUnitLed;
    switch (step % 6u) {
        case 0:
            return AmplitudeUnitLed::DBm;
        case 1:
            return AmplitudeUnitLed::DB;
        case 2:
            return AmplitudeUnitLed::DBuV;
        case 3:
            return AmplitudeUnitLed::V;
        case 4:
            return AmplitudeUnitLed::MV;
        default:
            return AmplitudeUnitLed::UV;
    }
}

adret::front_panel::ModulationSourceLed modulationSourceForStep(uint8_t step)
{
    using adret::front_panel::ModulationSourceLed;
    switch (step & 0x03u) {
        case 0:
            return ModulationSourceLed::Hz400;
        case 1:
            return ModulationSourceLed::KHz1;
        case 2:
            return ModulationSourceLed::External;
        default:
            return ModulationSourceLed::Cw;
    }
}

adret::front_panel::StatusLed statusLedForStep(uint8_t step)
{
    using adret::front_panel::StatusLed;
    switch (step & 0x03u) {
        case 1:
            return StatusLed::Error;
        case 2:
            return StatusLed::Dept;
        case 3:
            return StatusLed::Normal;
        default:
            return StatusLed::None;
    }
}

adret::front_panel::ModulationUnitLed modulationUnitForStep(uint8_t step)
{
    using adret::front_panel::ModulationUnitLed;
    switch (step & 0x03u) {
        case 1:
            return ModulationUnitLed::Rd;
        case 2:
            return ModulationUnitLed::KHz;
        case 3:
            return ModulationUnitLed::Percent;
        default:
            return ModulationUnitLed::None;
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

    adret::frontPanelBus.writeSn2(functionLedForStep(step),
                                  amplitudeUnitForStep(step),
                                  modulationSourceForStep(step));
    adret::frontPanelBus.writeSn3(statusLedForStep(step),
                                  modulationUnitForStep(step),
                                  memoryModeForStep(step),
                                  (step & 0x01u) != 0u,
                                  (step & 0x02u) != 0u);
}

void runInputDebug()
{
    const uint8_t pendingPanelEvents = adret::frontPanelIrq.consumePending();
    for (uint8_t i = 0; i < pendingPanelEvents; ++i) {
        const adret::front_panel::KeyboardSample sample =
            adret::frontPanelBus.readKeyboard();
        (void)sample;
    }
}

}  // namespace

void setup()
{
    adret::frontPanelBus.begin();
    adret::frontPanelIrq.begin();
    initialiseFrontPanel();
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
