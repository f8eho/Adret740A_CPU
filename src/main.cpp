#include <Arduino.h>

#include "Adret/Debug.h"
#include "Adret/CalibrationStore.h"
#include "Adret/FrontPanel.h"
#include "Adret/FrontPanelBus.h"
#include "Adret/FrontPanelIrq.h"
#include "Adret/HardwareConfig.h"
#include "Adret/InstrumentBus.h"
#include "Adret/InstrumentCapabilities.h"
#include "Adret/OperatingController.h"
#include "Adret/PowerFailMonitor.h"
#include "Adret/SettingsStore.h"
#include "Adret/SerialRemoteController.h"

#if !ADRET_I2C_PROBE

#if ADRET_INSTRUMENT_BUS_BENCH
#warning "Instrument-bus bench pattern enabled: disconnect the instrument backplane"
#endif

namespace {

using adret::front_panel::EncoderEvent;
using adret::front_panel::KeyEvent;

constexpr uint8_t kStartupDisplayWidth = 10u;
constexpr uint16_t kStartupScrollStepMs = 320u;
constexpr uint16_t kStartupHoldMs = 2000u;
constexpr uint8_t kStartupBanner[] PROGMEM = {
    adret::front_panel::segmentGlyph('1', true),
    adret::front_panel::segmentGlyph('0'),
    adret::front_panel::segmentGlyph(' '),
    adret::front_panel::segmentGlyph('b'),
    adret::front_panel::segmentGlyph('y'),
    adret::front_panel::segmentGlyph(' '),
    adret::front_panel::segmentGlyph('F'),
    adret::front_panel::segmentGlyph('8'),
    adret::front_panel::segmentGlyph('E'),
    adret::front_panel::segmentGlyph('H'),
    adret::front_panel::segmentGlyph('O'),
    adret::front_panel::segmentGlyph(' '),
    adret::front_panel::segmentGlyph('2'),
    adret::front_panel::segmentGlyph('0'),
    adret::front_panel::segmentGlyph('2'),
    adret::front_panel::segmentGlyph('6'),
};

void showStartupBanner()
{
    uint8_t frame[kStartupDisplayWidth] = {};
    const uint8_t bannerLength = uint8_t(sizeof(kStartupBanner));
    for (uint8_t revealed = 1u; revealed <= bannerLength; ++revealed) {
        for (uint8_t i = 0u; i < kStartupDisplayWidth; ++i) {
            frame[i] = adret::front_panel::kIcm7218NoDecodeBlank;
        }

        const uint8_t source = revealed > kStartupDisplayWidth
            ? uint8_t(revealed - kStartupDisplayWidth) : 0u;
        const uint8_t count = revealed < kStartupDisplayWidth
            ? revealed : kStartupDisplayWidth;
        for (uint8_t i = 0u; i < count; ++i) {
            frame[i] = pgm_read_byte(&kStartupBanner[uint8_t(source + i)]);
        }
        adret::frontPanel.showFrequencySegmentFrame(frame);
        if (revealed < bannerLength) {
            delay(kStartupScrollStepMs);
        }
    }
    delay(kStartupHoldMs);
    adret::frontPanel.flushOutputs();
    adret::frontPanel.refreshDisplays();
}

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
        if (!adret::serialRemoteController.handlePanelKey(event.key)) {
            adret::control::operatingController.handleKey(event.key);
        }
    }

    EncoderEvent encoderEvent = {};
    while (adret::frontPanel.popEncoder(&encoderEvent)) {
        if (adret::serialRemoteController.localControlsEnabled()) {
            adret::control::operatingController.handleEncoder(encoderEvent);
        }
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

#if ADRET_INSTRUMENT_BUS_BENCH
void runInstrumentBusBenchPattern()
{
    using adret::instrument_bus::instrumentBus;
    if (!instrumentBus.ready()) {
        return;
    }

    // Finite startup pattern for a disconnected logic load. Consecutive words
    // exercise: unchanged bus, data only, address only, then both changed.
    (void)instrumentBus.write(0u, 0x00u);
    (void)instrumentBus.write(0u, 0x00u);
    (void)instrumentBus.write(0u, 0xA5u);
    (void)instrumentBus.write(5u, 0xA5u);
    (void)instrumentBus.write(10u, 0x5Au);
    (void)instrumentBus.write(15u, 0xFFu);
}
#endif

}  // namespace

void setup()
{
#if ADRET_DEBUG_SERIAL
    Serial.begin(115200);
#endif
    adret::frontPanelBus.begin();
    adret::frontPanel.begin();
    const bool instrumentBusReady = adret::instrument_bus::instrumentBus.begin();
#if ADRET_INSTRUMENT_BUS_BENCH
    runInstrumentBusBenchPattern();
#endif

    const adret::InstrumentCapabilities capabilities =
        adret::detectInstrumentCapabilities();
    adret::control::Settings settings = adret::control::defaultSettings();
    const bool restored = adret::settingsStore.load(&settings);
    adret::calibration::calibrationStore.begin(capabilities);
#if ADRET_DEBUG_SERIAL
    Serial.print(F("EEPROM restored="));
    Serial.println(restored ? 1 : 0);
#else
    (void)restored;
    (void)instrumentBusReady;
#endif
    adret::control::operatingController.begin(settings, capabilities);
    showStartupBanner();
    adret::serialRemoteController.begin(capabilities);

    releasePendingPanelInputAtStartup();
    adret::frontPanelIrq.begin();
    adret::powerFailMonitor.begin();
#if ADRET_DEBUG_SERIAL
    Serial.print(F("Instrument bus MCP23017="));
    Serial.println(instrumentBusReady ? F("ready") : F("unavailable"));
    Serial.print(F("Frequency doubler="));
    Serial.println(capabilities.doublerInstalled() ? F("installed")
                                                   : F("absent"));
    Serial.print(F("PA monitoring="));
    Serial.println(adret::hw::kPowerSenseEnabled ? F("enabled") : F("disabled"));
    Serial.println(F("ADRET front panel control ready"));
#endif
}

void loop()
{
    adret::serialRemoteController.poll();
    processPanelEvents();
    adret::control::operatingController.tick(millis());
    if (adret::powerFailMonitor.consumePending() &&
        !adret::serialRemoteController.calibrationActive()) {
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

#endif  // !ADRET_I2C_PROBE
