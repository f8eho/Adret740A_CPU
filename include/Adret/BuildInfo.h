#pragma once

#include <stdint.h>

namespace adret {
namespace build_info {

// Format: YYYYMMDDRR, where RR is the firmware revision for that day.
// Increment this value for every source revision intended to be flashed.
constexpr uint32_t kBuildNumber = 2026072802UL;

}  // namespace build_info
}  // namespace adret
