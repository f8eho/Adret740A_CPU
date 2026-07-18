#include "Adret/CalibrationEprom.h"

namespace adret {
namespace calibration {

// Phase-2 calibration output will replace this initializer. Keeping the table
// here, even while it is empty, fixes the final Flash budget at 2 KiB.
extern "C" {
const int8_t
    adretCalibrationCorrectionTable[kCorrectionTableSize] PROGMEM = {0};
}

static_assert(sizeof(adretCalibrationCorrectionTable) == kCorrectionTableSize,
              "Calibration table must reserve exactly one 2716 image");

int8_t readCorrection(uint16_t index)
{
    if (index >= kCorrectionTableSize) {
        return 0;
    }
    return int8_t(pgm_read_byte(&adretCalibrationCorrectionTable[index]));
}

}  // namespace calibration
}  // namespace adret
