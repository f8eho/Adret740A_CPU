#include "Adret/CalibrationEprom.h"

namespace adret {
namespace calibration {

// CalibrationTable.inc is either the neutral one-value initializer or the
// complete output of the 2816 importer/session merger. Keeping the fixed-size
// symbol here reserves the final 2 KiB Flash budget in both cases.
extern "C" {
const int8_t
    adretCalibrationCorrectionTable[kCorrectionTableSize] PROGMEM = {
#include "CalibrationTable.inc"
};
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

bool frequencyRow(uint32_t frequencyHz, uint8_t* row)
{
    if (row == nullptr || frequencyHz < 100000u ||
        frequencyHz > 560000000u) {
        return false;
    }

    uint32_t selected = 0u;
    if (frequencyHz < 1000000u) {
        selected = frequencyHz / 100000u - 1u;
    } else if (frequencyHz < 10000000u) {
        selected = 8u + frequencyHz / 1000000u;
    } else {
        const uint32_t tensMHz = frequencyHz / 10000000u;
        selected = 18u + (tensMHz - 1u) / 5u;
    }
    if (selected >= kStandardFrequencyRowCount) {
        return false;
    }
    *row = uint8_t(selected);
    return true;
}

bool attenuatorStep(int16_t amplitudeTenthsDbm, uint8_t* step)
{
    if (step == nullptr || amplitudeTenthsDbm < -1299 ||
        amplitudeTenthsDbm > 130) {
        return false;
    }
    if (amplitudeTenthsDbm >= 70) {
        *step = 0u;
        return true;
    }
    const int16_t numerator = int16_t(20 - amplitudeTenthsDbm);
    const uint8_t selected = numerator <= 0
        ? 0u
        : uint8_t((numerator + 49) / 50);
    if (selected >= kAttenuatorStepCount) {
        return false;
    }
    *step = selected;
    return true;
}

bool correctionIndex(uint32_t frequencyHz,
                     int16_t amplitudeTenthsDbm,
                     uint16_t* tableIndex,
                     uint16_t* compactOverlayIndex,
                     uint8_t* row,
                     uint8_t* step)
{
    if (tableIndex == nullptr) {
        return false;
    }
    uint8_t selectedRow = 0u;
    uint8_t selectedStep = 0u;
    if (!frequencyRow(frequencyHz, &selectedRow) ||
        !attenuatorStep(amplitudeTenthsDbm, &selectedStep)) {
        return false;
    }
    *tableIndex = uint16_t(selectedRow) * kCorrectionColumnsPerRow +
                  selectedStep;
    if (compactOverlayIndex != nullptr) {
        *compactOverlayIndex = uint16_t(selectedRow) * kAttenuatorStepCount +
                               selectedStep;
    }
    if (row != nullptr) {
        *row = selectedRow;
    }
    if (step != nullptr) {
        *step = selectedStep;
    }
    return true;
}

uint16_t baseTableCrc16()
{
    uint16_t crc = 0xFFFFu;
    for (uint16_t i = 0u; i < kCorrectionTableSize; ++i) {
        crc ^= uint16_t(uint8_t(readCorrection(i))) << 8u;
        for (uint8_t bit = 0u; bit < 8u; ++bit) {
            crc = (crc & 0x8000u) != 0u
                ? uint16_t((crc << 1u) ^ 0x1021u)
                : uint16_t(crc << 1u);
        }
    }
    return crc;
}

}  // namespace calibration
}  // namespace adret
