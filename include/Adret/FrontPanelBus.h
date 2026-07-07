#pragma once

#include <stdint.h>

#include "Adret/FrontPanelMap.h"

namespace adret {

class FrontPanelBus final {
public:
    FrontPanelBus() = default;
    FrontPanelBus(const FrontPanelBus&) = delete;
    FrontPanelBus& operator=(const FrontPanelBus&) = delete;

    void begin();

    void writeRaw(front_panel::Select select, uint8_t value);
    void writeDisplay(front_panel::DisplayDevice device,
                      front_panel::DisplayMode mode,
                      uint8_t value);

    void writeDecimalPoints(uint8_t flags);
    void writeFirstCharFlags(uint8_t flags);
    void writeSn2(front_panel::FunctionLed function,
                  front_panel::AmplitudeUnitLed amplitudeUnit,
                  front_panel::ModulationSourceLed modulationSource);
    void writeSn3(front_panel::StatusLed status,
                  front_panel::ModulationUnitLed modulationUnit,
                  front_panel::MemoryLedMode memoryMode,
                  bool memory,
                  bool sequence);

    front_panel::KeyboardSample readKeyboard();

private:
    static void setDataOutput();
    static void setDataInput();
    static void setSelectNibble(uint8_t nibble);
    static void assertAddressEnable();
    static void releaseAddressEnable();
    static void pulseAddressEnable();
    static uint8_t makeIcmSelect(front_panel::DisplayDevice device,
                                 front_panel::DisplayMode mode);
};

extern FrontPanelBus frontPanelBus;

}  // namespace adret
