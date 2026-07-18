#pragma once

#include <stdint.h>

namespace adret {
namespace instrument_bus {

enum class RfFrequencyPath : uint8_t {
    HeterodyneLow,
    Heterodyne,
    DivideBy2O2,
    DivideBy2O1,
    DirectO2,
    DirectO1,
    DoublerO2,
    DoublerO1,
};

// Frequency-dependent part of the instrument-bus program. Fields shared with
// modulation are deliberately exposed as masks instead of complete bytes.
struct FrequencyPlan {
    RfFrequencyPath path;
    uint32_t outputFrequencyHz;
    uint32_t oscillatorFrequencyHz;
    uint32_t pointAFrequencyHz;
    uint32_t pointBNumeratorHz;
    uint32_t deltaHz;
    uint8_t incrementDivisor;
    uint8_t incrementQuotient;
    uint8_t incrementRemainder;
    uint8_t address4;
    uint8_t address5;
    uint8_t address12RangeBits;
    uint8_t address13LowBits;
};

constexpr uint8_t kAddress12RangeMask = 0x86u;
constexpr uint8_t kAddress13FrequencyMask = 0x7Fu;
constexpr uint8_t kAddress5PulseMask = 0x20u;
constexpr uint8_t kAddress6PulseMask = 0x40u;
constexpr uint8_t kAddress6Plus5dBMask = 0x80u;

// Standard 740A, without the optional frequency doubler. Exactly 560 MHz is
// retained on the direct O1 path when the optional doubler is unavailable.
bool makeBaseFrequencyPlan(uint32_t outputFrequencyHz, FrequencyPlan* plan);

// Optional doubler path. Its oscillator is programmed at half the displayed
// frequency. The original firmware changes to another extension at exactly
// 1120 MHz, hence the exclusive upper bound.
bool makeDoublerFrequencyPlan(uint32_t outputFrequencyHz,
                              FrequencyPlan* plan);

// Preserve the modulation bits of address 12 while changing its RF range.
uint8_t mergeAddress12Range(uint8_t currentAddress12,
                            const FrequencyPlan& plan);

// Address 13 carries the same 7-bit divisor code as address 4. Its D7 is the
// inverse of address-12 D0 in the original firmware.
uint8_t makeAddress13(const FrequencyPlan& plan, uint8_t address12);

// The original CPU derives D7..D5 of address 15 from D3..D1 of the complete
// address-12 word and preserves D4..D0 of the previous address-15 word.
uint8_t makeAddress15(uint8_t currentAddress15, uint8_t address12);

// Enabling pulse modulation sets address-5 D5 in addition to its RF path
// value. Disabling must restore the frequency-plan word: D5 is also required
// by the normal sub-1.5 MHz heterodyne path.
uint8_t makeAddress5WithPulse(const FrequencyPlan& plan, bool enabled);

// Pulse is active high on the approach-board register. Other address-6 bits
// belong to the RF level and attenuator programming and are preserved.
uint8_t mergeAddress6Pulse(uint8_t currentAddress6, bool enabled);

}  // namespace instrument_bus
}  // namespace adret
