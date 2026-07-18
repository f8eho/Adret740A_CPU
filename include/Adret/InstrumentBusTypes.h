#pragma once

#include <stdint.h>

namespace adret {
namespace instrument_bus {

struct InstrumentWrite {
    uint8_t address;
    uint8_t value;
};

}  // namespace instrument_bus
}  // namespace adret
