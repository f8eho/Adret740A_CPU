#include <Arduino.h>

#include "Adret/FrontPanel.h"
#include "Adret/FrontPanelBus.h"
#include "Adret/FrontPanelIrq.h"
#include "Adret/HardwareConfig.h"
#include "Adret/OperatingController.h"
#include "Adret/PowerFailMonitor.h"
#include "Adret/SettingsStore.h"

namespace {

using adret::front_panel::EncoderEvent;
using adret::front_panel::KeyEvent;

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

void processPanelEvents()
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
        adret::control::operatingController.handleKey(event.key);
    }

    static int32_t encoderTotal = 0;
    EncoderEvent encoderEvent = {};
    while (adret::frontPanel.popEncoder(&encoderEvent)) {
        if (encoderEvent.step > 0) {
            if (encoderTotal < INT32_MAX) {
                ++encoderTotal;
            }
        } else {
            if (encoderTotal > INT32_MIN) {
                --encoderTotal;
            }
        }

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
        Serial.println(encoderTotal);
        adret::control::operatingController.handleEncoder(encoderEvent);
    }
    (void)adret::frontPanel.consumeEncoderDelta();
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

    adret::control::Settings settings = adret::control::defaultSettings();
    const bool restored = adret::settingsStore.load(&settings);
    Serial.print(F("EEPROM restored="));
    Serial.println(restored ? 1 : 0);
    adret::control::operatingController.begin(settings);

    releasePendingPanelInputAtStartup();
    adret::frontPanelIrq.begin();
    adret::powerFailMonitor.begin();
    Serial.print(F("PA monitoring="));
    Serial.println(adret::hw::kPowerSenseEnabled ? F("enabled") : F("disabled"));
    Serial.println(F("ADRET front panel control ready"));
}

void loop()
{
    processPanelEvents();
    adret::control::operatingController.tick(millis());
    if (adret::powerFailMonitor.consumePending()) {
        const bool saved = adret::settingsStore.saveNow(
            adret::control::operatingController.settings());
        Serial.print(F("EEPROM power_fail_save="));
        Serial.println(saved ? F("OK") : F("ERROR"));
    }
}
