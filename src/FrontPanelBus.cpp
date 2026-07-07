#include "Adret/FrontPanelBus.h"

#include <avr/io.h>

#include "Adret/HardwareConfig.h"

namespace adret {

FrontPanelBus frontPanelBus;

void FrontPanelBus::begin()
{
    setDataOutput();
    ADRET_FP_DATA_PORT = 0x00;

    ADRET_FP_SELECT_DDR |= hw::kFrontPanelSelectMask;
    setSelectNibble(uint8_t(front_panel::Select::IdleY0));

    ADRET_FP_CA2_DDR |= _BV(hw::kFrontPanelCa2Bit);
    releaseAddressEnable();
}

void FrontPanelBus::writeRaw(front_panel::Select select, uint8_t value)
{
    setDataOutput();
    ADRET_FP_DATA_PORT = value;
    setSelectNibble(uint8_t(select));
    hw::waitTtlSettle();
    pulseAddressEnable();
}

void FrontPanelBus::writeDisplay(front_panel::DisplayDevice device,
                                 front_panel::DisplayMode mode,
                                 uint8_t value)
{
    setDataOutput();
    ADRET_FP_DATA_PORT = value;
    setSelectNibble(makeIcmSelect(device, mode));
    hw::waitTtlSettle();
    pulseAddressEnable();
}

void FrontPanelBus::writeDecimalPoints(uint8_t flags)
{
    writeRaw(front_panel::Select::DecimalPointsSn17, flags);
}

void FrontPanelBus::writeFirstCharFlags(uint8_t flags)
{
    writeRaw(front_panel::Select::FirstCharsSn4, flags);
}

void FrontPanelBus::writeSn2(front_panel::FunctionLed function,
                             front_panel::AmplitudeUnitLed amplitudeUnit,
                             front_panel::ModulationSourceLed modulationSource)
{
    writeRaw(front_panel::Select::LedBankSn2,
             front_panel::makeSn2Byte(function, amplitudeUnit, modulationSource));
}

void FrontPanelBus::writeSn3(front_panel::StatusLed status,
                             front_panel::ModulationUnitLed modulationUnit,
                             front_panel::MemoryLedMode memoryMode,
                             bool memory,
                             bool sequence)
{
    writeRaw(front_panel::Select::LedBankSn3,
             front_panel::makeSn3Byte(status, modulationUnit, memoryMode, memory, sequence));
}

front_panel::KeyboardSample FrontPanelBus::readKeyboard()
{
    setDataInput();
    setSelectNibble(uint8_t(front_panel::Select::KeyboardSn5));
    assertAddressEnable();
    hw::waitTtlSettle();

    const uint8_t raw = ADRET_FP_DATA_PIN;

    releaseAddressEnable();
    setSelectNibble(uint8_t(front_panel::Select::IdleY0));
    setDataOutput();
    ADRET_FP_DATA_PORT = 0x00;

    front_panel::KeyboardSample sample = {};
    sample.raw = raw;
    sample.xCode = uint8_t(raw & 0x07u);
    sample.yCode = uint8_t((raw >> 3) & 0x07u);
    sample.encoderCountLine = (raw & (1u << 6)) != 0u;
    sample.encoderDirectionLine = (raw & (1u << 7)) != 0u;
    return sample;
}

void FrontPanelBus::setDataOutput()
{
    ADRET_FP_DATA_DDR = 0xFF;
}

void FrontPanelBus::setDataInput()
{
    ADRET_FP_DATA_PORT = 0x00;
    ADRET_FP_DATA_DDR = 0x00;
}

void FrontPanelBus::setSelectNibble(uint8_t nibble)
{
    const uint8_t shifted = uint8_t((nibble << hw::kFrontPanelSelectShift) &
                                    hw::kFrontPanelSelectMask);
    ADRET_FP_SELECT_PORT = uint8_t((ADRET_FP_SELECT_PORT &
                                    uint8_t(~hw::kFrontPanelSelectMask)) |
                                   shifted);
}

void FrontPanelBus::assertAddressEnable()
{
    if (hw::kFrontPanelCa2ActiveLow) {
        ADRET_FP_CA2_PORT &= uint8_t(~_BV(hw::kFrontPanelCa2Bit));
    } else {
        ADRET_FP_CA2_PORT |= _BV(hw::kFrontPanelCa2Bit);
    }
}

void FrontPanelBus::releaseAddressEnable()
{
    if (hw::kFrontPanelCa2ActiveLow) {
        ADRET_FP_CA2_PORT |= _BV(hw::kFrontPanelCa2Bit);
    } else {
        ADRET_FP_CA2_PORT &= uint8_t(~_BV(hw::kFrontPanelCa2Bit));
    }
}

void FrontPanelBus::pulseAddressEnable()
{
    assertAddressEnable();
    hw::waitTtlSettle();
    releaseAddressEnable();
    hw::waitTtlSettle();
}

uint8_t FrontPanelBus::makeIcmSelect(front_panel::DisplayDevice device,
                                     front_panel::DisplayMode mode)
{
    const uint8_t base =
        (device == front_panel::DisplayDevice::FrequencySn10)
            ? uint8_t(front_panel::Select::DisplaySn10)
            : uint8_t(front_panel::Select::DisplaySn11);
    return uint8_t(base | (uint8_t(mode) << 3));
}

}  // namespace adret
