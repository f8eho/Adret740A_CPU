#include "Adret/CalibrationEprom.h"

namespace adret {
namespace calibration {

const uint8_t eprom2716[kEprom2716Size] PROGMEM = {0};

uint8_t readByte(uint16_t address)
{
    if (address >= kEprom2716Size) {
        return 0xFF;
    }
    return pgm_read_byte(&eprom2716[address]);
}

}  // namespace calibration
}  // namespace adret
