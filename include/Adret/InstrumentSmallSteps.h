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

// Builds the four bus words from a point-A frequency. The currently validated
// domain is 90 MHz through 129.999975 MHz in 25 Hz steps, with an even
// divisor20000. Odd divisors were not exercised by the available traces and
// are deliberately rejected.
bool makeSmallStepProgram(uint32_t pointAFrequencyHz, SmallStepProgram* program);

}  // namespace instrument_bus
}  // namespace adret
