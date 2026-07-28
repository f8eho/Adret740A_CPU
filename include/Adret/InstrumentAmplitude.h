#pragma once

#include <stdint.h>

namespace adret {
namespace instrument_bus {

// Frequency-specific calibration is supplied by the caller. It is expressed
// directly in tenths of a dB so that the nominal encoder remains independent
// from the future PROGMEM table layout.
struct AmplitudeProgram {
    int16_t requestedTenthsDbm;
    int16_t nominalFineTenthsDb;
    int16_t correctedFineTenthsDb;
    int8_t calibrationTenthsDb;
    uint8_t attenuatorStep;
    uint8_t address6BeforeAddress8;
    uint8_t address8;
    uint8_t address6AfterAddress8;
    bool highLevelRange;
};

constexpr int16_t kAmplitudeMinimumTenthsDbm = -1299;
constexpr int16_t kAmplitudeMaximumTenthsDbm = 130;
constexpr uint8_t kAmplitudePulseMask = 0x40u;
constexpr uint8_t kAmplitudePlus5dBMask = 0x80u;

// Reproduces the final address-6 decision shared by amplitude and modulation.
// On the heterodyne path, D7 is set either by the high-level range or by an
// active AM source. D6 and the six relay bits are preserved.
uint8_t makeAmplitudeControlAddress6(uint8_t currentAddress6,
                                     uint8_t address5,
                                     bool highLevelRange,
                                     bool amplitudeModulationActive);

// Reproduces the original 6,8,6 write sequence. currentAddress6 supplies the
// Pulse state and the previous +5 dB state for the first write. The final D7
// state depends on the level, active AM state and address-5 D1 (heterodyne
// path), as in the original $CC7E finalizer.
bool makeAmplitudeProgram(int16_t requestedTenthsDbm,
                          int8_t calibrationTenthsDb,
                          uint8_t currentAddress6,
                          uint8_t address5,
                          bool amplitudeModulationActive,
                          AmplitudeProgram* program);

// Converts the non-standard high nibble used by address 8 back to the
// physical 0.1/1 dB network value. Returns -1 for an invalid bus code.
int16_t decodeAddress8TenthsDb(uint8_t address8);

}  // namespace instrument_bus
}  // namespace adret
