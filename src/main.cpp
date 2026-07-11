#include <Arduino.h>

#include "Adret/FrontPanel.h"
#include "Adret/FrontPanelBus.h"
#include "Adret/FrontPanelIrq.h"
#include "Adret/HardwareConfig.h"

namespace {

using adret::front_panel::KeyEvent;
using adret::front_panel::PanelIndicator;

constexpr uint32_t kIndicatorPeriodMs = 200;

constexpr PanelIndicator kIndicatorSequence[] = {
    PanelIndicator::Rf,
    PanelIndicator::Fm,
    PanelIndicator::Pm,
    PanelIndicator::Am,
    PanelIndicator::Amplitude,
    PanelIndicator::DBm,
    PanelIndicator::DB,
    PanelIndicator::DBuV,
    PanelIndicator::Volt,
    PanelIndicator::MilliVolt,
    PanelIndicator::MicroVolt,
    PanelIndicator::Hz400,
    PanelIndicator::KHz1,
    PanelIndicator::External,
    PanelIndicator::Cw,
    PanelIndicator::Error,
    PanelIndicator::Dept,
    PanelIndicator::Normal,
    PanelIndicator::ModRd,
    PanelIndicator::ModKHz,
    PanelIndicator::ModPercent,
    PanelIndicator::Memory,
    PanelIndicator::Sequence,
    PanelIndicator::Remote,
    PanelIndicator::RfInhibit,
    PanelIndicator::ManualValidation,
};

constexpr uint8_t kIndicatorCount =
    sizeof(kIndicatorSequence) / sizeof(kIndicatorSequence[0]);

void advanceIndicatorTest()
{
    static uint32_t previousMs = 0;
    static uint8_t index = 0;
    static uint32_t counter = 0;

    const uint32_t now = millis();
    if ((now - previousMs) < kIndicatorPeriodMs) {
        return;
    }

    previousMs = now;
    ++counter;
    adret::frontPanel.setFrequencyHz(counter);
    adret::frontPanel.setModulationValue(
        counter % 1000u, adret::front_panel::ModulationUnitLed::None, false);
    adret::frontPanel.setAmplitudeValue(
        int32_t(counter % 1000u), adret::front_panel::AmplitudeUnitLed::None6, false);
    adret::frontPanel.clearIndicators();
    adret::frontPanel.turnOn(kIndicatorSequence[index]);
    adret::frontPanel.refreshDisplays();
    index = uint8_t((index + 1u) % kIndicatorCount);
}

void printHexByte(uint8_t value)
{
    if (value < 0x10u) {
        Serial.print('0');
    }
    Serial.print(value, HEX);
}

void reportKeyboardEvents()
{
    adret::frontPanel.pollInputs();

    KeyEvent event = {};
    while (adret::frontPanel.popKey(&event)) {
        Serial.print(F("KEY raw=0x"));
        printHexByte(event.sample.raw);
        Serial.print(F(" X="));
        Serial.print(event.sample.xCode);
        Serial.print(F(" Y="));
        Serial.print(event.sample.yCode);
        Serial.print(F(" label="));
        Serial.println(adret::front_panel::keyShortLabel(event.key));
    }
}

void releasePendingPanelInputAtStartup()
{
    for (uint8_t i = 0; i < adret::hw::kFrontPanelStartupAcknowledgeCount; ++i) {
        (void)adret::frontPanelBus.readKeyboard();
        delayMicroseconds(adret::hw::kFrontPanelStartupAcknowledgeGapUs);
    }
}

}  // namespace

void setup()
{
    Serial.begin(115200);
    adret::frontPanelBus.begin();
    adret::frontPanel.begin();
    adret::frontPanel.clearIndicators();
    adret::frontPanel.refreshDisplays();
    releasePendingPanelInputAtStartup();
    adret::frontPanelIrq.begin();
    Serial.println(F("ADRET panel diagnostic ready"));
}

void loop()
{
    reportKeyboardEvents();
    advanceIndicatorTest();
}
