#pragma once

#include <stdint.h>

namespace adret {

constexpr uint32_t kBaseMaximumFrequencyHz = 560000000u;
constexpr uint32_t kDoublerEndFrequencyHz = 1120000000u;
constexpr uint32_t kDoublerMaximumFrequencyHz = 1119999990u;
constexpr uint32_t kFrequencyResolutionHz = 10u;

class InstrumentCapabilities final {
public:
    constexpr InstrumentCapabilities()
        : doublerInstalled_(false)
    {
    }

    constexpr explicit InstrumentCapabilities(bool doublerInstalled)
        : doublerInstalled_(doublerInstalled)
    {
    }

    constexpr bool doublerInstalled() const
    {
        return doublerInstalled_;
    }

    constexpr uint32_t maximumFrequencyHz() const
    {
        return doublerInstalled_ ? kDoublerMaximumFrequencyHz
                                 : kBaseMaximumFrequencyHz;
    }

private:
    bool doublerInstalled_;
};

constexpr bool frequencyIsAvailable(
    uint32_t frequencyHz,
    const InstrumentCapabilities& capabilities)
{
    return frequencyHz >= 100000u &&
           frequencyHz <= capabilities.maximumFrequencyHz() &&
           (frequencyHz % kFrequencyResolutionHz) == 0u;
}

constexpr InstrumentCapabilities capabilitiesFromDoublerJumperLevel(
    bool inputIsHigh)
{
    return InstrumentCapabilities(!inputIsHigh);
}

static_assert(!capabilitiesFromDoublerJumperLevel(true).doublerInstalled() &&
                  capabilitiesFromDoublerJumperLevel(true).maximumFrequencyHz() ==
                      kBaseMaximumFrequencyHz &&
                  capabilitiesFromDoublerJumperLevel(false).doublerInstalled() &&
                  capabilitiesFromDoublerJumperLevel(false).maximumFrequencyHz() ==
                      kDoublerMaximumFrequencyHz,
              "Unexpected active-low doubler jumper mapping");

// Reads the passive CPU-domain configuration jumper once. Call this during
// setup and pass the returned value to every subsystem; runtime changes are
// deliberately ignored until the next restart.
InstrumentCapabilities detectInstrumentCapabilities();

}  // namespace adret
