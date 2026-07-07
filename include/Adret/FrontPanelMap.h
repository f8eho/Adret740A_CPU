#pragma once

#include <stdint.h>

namespace adret {
namespace front_panel {

// Values driven on the original CPU PB2..PB0 select lines.
// Names come from Adret_740A_table_memoire_panneau_avant.ods.
enum class Select : uint8_t {
    IdleY0 = 0b000,
    DecimalPointsSn17 = 0b001,
    FirstCharsSn4 = 0b010,
    LedBankSn2 = 0b011,
    LedBankSn3 = 0b100,
    KeyboardSn5 = 0b101,
    DisplaySn10 = 0b110,
    DisplaySn11 = 0b111,
};

enum class DisplayDevice : uint8_t {
    FrequencySn10,
    MixedSn11,
};

// PB3 mode line for the ICM7218A display drivers.
enum class DisplayMode : uint8_t {
    Data = 0,
    Command = 1,
};

enum FirstCharFlags : uint8_t {
    kModAm1 = 1u << 0,
    kModAm2 = 1u << 1,
    kPowerOne = 1u << 2,
    kPowerMinus = 1u << 3,
    kPowerPlus = 1u << 4,
    kRemote = 1u << 5,
    kRfInhibit = 1u << 6,
    kManualValidation = 1u << 7,
};

enum DecimalPointFlags : uint8_t {
    kModulationDecimalPoint = 1u << 0,
    kAmplitudeDecimalPoint = 1u << 1,
};

enum class FunctionLed : uint8_t {
    None0 = 0,
    None1 = 1,
    None2 = 2,
    Rf = 3,
    Fm = 4,
    Pm = 5,
    Am = 6,
    Amplitude = 7,
};

enum class AmplitudeUnitLed : uint8_t {
    DBm = 0,
    DB = 1,
    DBuV = 2,
    V = 3,
    MV = 4,
    UV = 5,
    None6 = 6,
    None7 = 7,
};

enum class ModulationSourceLed : uint8_t {
    Hz400 = 0,
    KHz1 = 1,
    External = 2,
    Cw = 3,
};

enum class StatusLed : uint8_t {
    None = 0,
    Error = 1,
    Dept = 2,
    Normal = 3,
};

enum class ModulationUnitLed : uint8_t {
    None = 0,
    Rd = 1,
    KHz = 2,
    Percent = 3,
};

enum class MemoryLedMode : uint8_t {
    Q2Base = 0,
    D25Fixed = 1,
    None = 2,
    D25Blink = 3,
};

struct KeyboardSample {
    uint8_t raw;
    uint8_t xCode;
    uint8_t yCode;
    bool encoderCountLine;
    bool encoderDirectionLine;
};

constexpr uint8_t makeSn2Byte(FunctionLed function,
                              AmplitudeUnitLed amplitudeUnit,
                              ModulationSourceLed modulationSource)
{
    return uint8_t((uint8_t(function) << 5) |
                   (uint8_t(amplitudeUnit) << 2) |
                   uint8_t(modulationSource));
}

constexpr uint8_t makeSn3Byte(StatusLed status,
                              ModulationUnitLed modulationUnit,
                              MemoryLedMode memoryMode,
                              bool memory,
                              bool sequence)
{
    return uint8_t((uint8_t(status) << 6) |
                   (uint8_t(modulationUnit) << 4) |
                   (uint8_t(memoryMode) << 2) |
                   (memory ? (1u << 1) : 0u) |
                   (sequence ? (1u << 0) : 0u));
}

}  // namespace front_panel
}  // namespace adret
