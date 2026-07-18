#pragma once

#include <avr/pgmspace.h>
#include <stdint.h>

namespace adret {
namespace calibration {

// The original CPU used a 2716 (2 KiB) for instrument calibration. The new
// CPU reserves the same amount of Flash for generated signed corrections.
// One unit is 0.1 dB; a zero-filled table therefore gives nominal operation.
constexpr uint16_t kCorrectionTableSize = 2048u;

// C linkage gives the linker anchor in platformio.ini a stable symbol name.
extern "C" {
extern const int8_t
    adretCalibrationCorrectionTable[kCorrectionTableSize] PROGMEM;
}

// Returns zero for an out-of-range index so that missing calibration never
// creates an unintended level correction.
int8_t readCorrection(uint16_t index);

}  // namespace calibration
}  // namespace adret
