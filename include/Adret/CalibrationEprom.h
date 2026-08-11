#pragma once

#include <avr/pgmspace.h>
#include <stdint.h>

namespace adret {
namespace calibration {

// The original CPU used a 2716 (2 KiB) for instrument calibration. The new
// CPU reserves the same amount of Flash for generated signed corrections.
// One unit is 0.1 dB; a zero-filled table therefore gives nominal operation.
constexpr uint16_t kCorrectionTableSize = 2048u;
constexpr uint8_t kFrequencyRowCount = 64u;
constexpr uint8_t kCorrectionColumnsPerRow = 32u;
constexpr uint8_t kAttenuatorStepCount = 28u;
constexpr uint8_t kBaseFrequencyRowCount = 30u;
constexpr uint8_t kDoublerFrequencyRowCount = 41u;
constexpr uint8_t kCalibrationFrequencyRowCount =
    kDoublerFrequencyRowCount;
constexpr uint16_t kCalibrationOverlayEntryCount =
    uint16_t(kCalibrationFrequencyRowCount) * kAttenuatorStepCount;

enum class CalibrationProfile : uint8_t {
    Base = 0u,
    Doubler = 1u,
    Neutral = 0xFFu,
};

// C linkage gives the linker anchor in platformio.ini a stable symbol name.
extern "C" {
extern const int8_t
    adretCalibrationCorrectionTable[kCorrectionTableSize] PROGMEM;
}

// Returns zero for an out-of-range index so that missing calibration never
// creates an unintended level correction.
int8_t readCorrection(uint16_t index);
CalibrationProfile permanentTableProfile();

// Reproduces the original 2816 lookup grid through the doubler band. The base
// instrument reaches row 29 only at 560 MHz. With X2, row 29 continues through
// 609.999990 MHz and rows 30..40 cover the rest below 1120 MHz.
bool frequencyRow(uint32_t frequencyHz, uint8_t* row);
bool attenuatorStep(int16_t amplitudeTenthsDbm, uint8_t* step);
bool correctionIndex(uint32_t frequencyHz,
                     int16_t amplitudeTenthsDbm,
                     uint16_t* tableIndex,
                     uint16_t* compactOverlayIndex = nullptr,
                     uint8_t* row = nullptr,
                     uint8_t* step = nullptr);

// Identifies the exact permanent table to which a temporary EEPROM overlay
// belongs. Changing any Flash correction invalidates overlays made from the
// previous base and prevents accidental double application after recompiling.
uint16_t baseTableCrc16();

}  // namespace calibration
}  // namespace adret
