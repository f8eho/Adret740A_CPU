#pragma once

#include <avr/pgmspace.h>
#include <stdint.h>

namespace adret {
namespace calibration {

constexpr uint16_t kEprom2716Size = 2048;

extern const uint8_t eprom2716[kEprom2716Size] PROGMEM;

uint8_t readByte(uint16_t address);

}  // namespace calibration
}  // namespace adret
