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
    DisplaySn11 = 0b110,
    DisplaySn10 = 0b111,
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

constexpr uint8_t kIcm7218CodeBFrameCommand = 0x90u;
constexpr uint8_t kIcm7218DigitCount = 8u;
constexpr uint8_t kIcm7218DecimalPointOff = 0x80u;
constexpr uint8_t kIcm7218CodeBBlank = 0x8Fu;

constexpr uint8_t codeBDigit(char digit)
{
    // ICM7218 decimal-point data is active low: ID7=1 turns it off.
    // Code B also provides '-', E, H, L, P and blank on codes A..F.
    return uint8_t(((digit >= '0' && digit <= '9') ? uint8_t(digit - '0')
                     : digit == '-' ? 0x0Au
                     : digit == 'E' ? 0x0Bu
                     : digit == 'H' ? 0x0Cu
                     : digit == 'L' ? 0x0Du
                     : digit == 'P' ? 0x0Eu
                     : 0x0Fu) |
                   kIcm7218DecimalPointOff);
}

constexpr uint8_t decoratedCodeBDigit(char digit, bool decimalPoint, bool blank)
{
    return blank
        ? kIcm7218CodeBBlank
        : (decimalPoint
            ? uint8_t(codeBDigit(digit) & uint8_t(~kIcm7218DecimalPointOff))
            : codeBDigit(digit));
}

enum FirstCharFlags : uint8_t {
    // These are AVR bus bits after the validated adjacent-pair crossover.
    kModulationOne = 1u << 0,
    kModulationP = 1u << 1,
    kPowerOneBlank = 1u << 2,
    kPowerPlus = 1u << 3,
    kPowerMinus = 1u << 4,
    kRemote = 1u << 5,
    kRfInhibit = 1u << 6,
    kManualValidation = 1u << 7,
};

constexpr uint8_t withRemoteIndicator(uint8_t flags, bool enabled)
{
    // REM is active low on SN4/D5.
    return enabled ? uint8_t(flags & uint8_t(~kRemote))
                   : uint8_t(flags | kRemote);
}

constexpr uint8_t withRfInhibitIndicator(uint8_t flags, bool enabled)
{
    // INHIB RF is active low on SN4/D6.
    return enabled ? uint8_t(flags & uint8_t(~kRfInhibit))
                   : uint8_t(flags | kRfInhibit);
}

enum DecimalPointFlags : uint8_t {
    kModulationDecimalPoint = 1u << 0,
    kAmplitudeDecimalPoint = 1u << 1,
};

constexpr uint8_t makeSn17Byte(uint8_t logicalFlags)
{
    // SN17 drives common-anode decimal points: a low output lights the point.
    return uint8_t(~logicalFlags);
}

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
    Blink = 0,
    Off = 1,
    Fixed = 2,
};

struct KeyboardSample {
    uint8_t raw;
    uint8_t xCode;
    uint8_t yCode;
    bool encoderCountLine;
    bool encoderDirectionLine;
};

constexpr uint8_t keyboardX(uint8_t raw)
{
    return uint8_t(raw & 0x07u);
}

constexpr uint8_t keyboardY(uint8_t raw)
{
    return uint8_t((raw >> 3) & 0x07u);
}

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
    // Bench-validated independent active-low outputs: D1 drives MEM and D0
    // drives SEQ.
    return uint8_t((uint8_t(status) << 6) |
                   (uint8_t(modulationUnit) << 4) |
                   (uint8_t(memoryMode) << 2) |
                   (memory ? 0u : (1u << 1)) |
                   (sequence ? 0u : (1u << 0)));
}

}  // namespace front_panel
}  // namespace adret
