#pragma once

#include <stdint.h>

namespace adret {
namespace instrument_bus {

// Programming words for the "20000" board (addresses 0..2) and the "80"
// board (address 3). The point-A frequency is defined in
// docs/ADRET7401_Principe.md.
struct SmallStepProgram {
    uint16_t divisor20000;
    uint16_t divisor80;
    uint8_t dataByAddress[4];
};

// Builds the four bus words from a point-A frequency. The domain is 90 MHz
// through 129.999975 MHz in 25 Hz steps. An odd divisor20000 uses the original
// CPU's half-step marker on address 0; this is required for 10 Hz output steps
// through the optional frequency doubler.
bool makeSmallStepProgram(uint32_t pointAFrequencyHz, SmallStepProgram* program);

}  // namespace instrument_bus
}  // namespace adret
