#include <Arduino.h>

#include "Adret/Debug.h"
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

#if ADRET_DEBUG_SERIAL
void printHexByte(uint8_t value)
{
    if (value < 0x10u) {
        Serial.print('0');
    }
    Serial.print(value, HEX);
}
#endif

void processPanelEvents()
{
    adret::frontPanel.pollInputs();

    KeyEvent event = {};
    while (adret::frontPanel.popKey(&event)) {
#if ADRET_DEBUG_SERIAL
        Serial.print(F("KEY raw=0x"));
        printHexByte(event.sample.raw);
        Serial.print(F(" X="));
        Serial.print(event.sample.xCode);
        Serial.print(F(" Y="));
        Serial.print(event.sample.yCode);
        Serial.print(F(" label="));
        Serial.println(adret::front_panel::keyShortLabel(event.key));
#endif
        adret::control::operatingController.handleKey(event.key);
    }

    EncoderEvent encoderEvent = {};
    while (adret::frontPanel.popEncoder(&encoderEvent)) {
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
#if ADRET_DEBUG_SERIAL
    Serial.begin(115200);
#endif
    adret::frontPanelBus.begin();
    adret::frontPanel.begin();

    adret::control::Settings settings = adret::control::defaultSettings();
    const bool restored = adret::settingsStore.load(&settings);
#if ADRET_DEBUG_SERIAL
    Serial.print(F("EEPROM restored="));
    Serial.println(restored ? 1 : 0);
#else
    (void)restored;
#endif
    adret::control::operatingController.begin(settings);

    releasePendingPanelInputAtStartup();
    adret::frontPanelIrq.begin();
    adret::powerFailMonitor.begin();
#if ADRET_DEBUG_SERIAL
    Serial.print(F("PA monitoring="));
    Serial.println(adret::hw::kPowerSenseEnabled ? F("enabled") : F("disabled"));
    Serial.println(F("ADRET front panel control ready"));
#endif
}

void loop()
{
    processPanelEvents();
    adret::control::operatingController.tick(millis());
    if (adret::powerFailMonitor.consumePending()) {
        const bool saved = adret::settingsStore.saveNow(
            adret::control::operatingController.settings());
#if ADRET_DEBUG_SERIAL
        Serial.print(F("EEPROM power_fail_save="));
        Serial.println(saved ? F("OK") : F("ERROR"));
#else
        (void)saved;
#endif
    }
}
