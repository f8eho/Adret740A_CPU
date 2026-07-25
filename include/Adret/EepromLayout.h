#pragma once

namespace adret {
namespace eeprom_layout {

// Settings and the forty user memories currently end at address 1215.
// Keeping the calibration area aligned leaves room for future settings
// migrations and makes overlap a compile-time error in SettingsStore.cpp.
constexpr int kCalibrationBaseAddress = 1280;
constexpr int kEepromSize = 4096;

}  // namespace eeprom_layout
}  // namespace adret
