#include <Arduino.h>

#include "Adret/FrontPanel.h"
#include "Adret/FrontPanelBus.h"
#include "Adret/FrontPanelIrq.h"
#include "Adret/HardwareConfig.h"

namespace {

using adret::front_panel::EncoderEvent;
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

    const uint32_t now = millis();
    if ((now - previousMs) < kIndicatorPeriodMs) {
        return;
    }

    previousMs = now;
    adret::frontPanel.clearIndicators();
    adret::frontPanel.turnOn(kIndicatorSequence[index]);
    index = uint8_t((index + 1u) % kIndicatorCount);
}

void printHexByte(uint8_t value)
{
    if (value < 0x10u) {
        Serial.print('0');
    }
    Serial.print(value, HEX);
}

void printBinaryByte(uint8_t value)
{
    for (int8_t bit = 7; bit >= 0; --bit) {
        Serial.print((value & (uint8_t(1u) << bit)) != 0u ? '1' : '0');
    }
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

    static uint32_t frequency = 0;
    static int32_t encoderTotal = 0;
    EncoderEvent encoderEvent = {};
    while (adret::frontPanel.popEncoder(&encoderEvent)) {
        if (encoderEvent.step > 0) {
            if (frequency < UINT32_MAX) {
                ++frequency;
            }
            if (encoderTotal < INT32_MAX) {
                ++encoderTotal;
            }
        } else {
            if (frequency > 0u) {
                --frequency;
            }
            if (encoderTotal > INT32_MIN) {
                --encoderTotal;
            }
        }

        adret::frontPanel.setFrequencyHz(frequency);
        adret::frontPanel.refreshDisplays();

        Serial.print(F("ENC raw=0x"));
        printHexByte(encoderEvent.sample.raw);
        Serial.print(F(" bits="));
        printBinaryByte(encoderEvent.sample.raw);
        Serial.print(F(" count="));
        Serial.print(encoderEvent.sample.encoderCountLine ? 1 : 0);
        Serial.print(F(" dir="));
        Serial.print(encoderEvent.sample.encoderDirectionLine ? 1 : 0);
        Serial.print(F(" step="));
        if (encoderEvent.step > 0) {
            Serial.print('+');
        }
        Serial.print(encoderEvent.step);
        Serial.print(F(" total="));
        Serial.print(encoderTotal);
        Serial.print(F(" freq="));
        Serial.println(frequency);
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
    adret::frontPanel.setFrequencyHz(0);
    adret::frontPanel.setModulationValue(
        0, adret::front_panel::ModulationUnitLed::None, false);
    adret::frontPanel.setAmplitudeValue(
        0, adret::front_panel::AmplitudeUnitLed::None6, false);
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
