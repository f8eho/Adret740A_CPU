#pragma once

#include <stdint.h>

namespace adret {
namespace instrument_bus {

enum class InstrumentBusError : uint8_t {
    None,
    NotReady,
    InvalidAddress,
    I2cBufferOverflow,
    I2cAddressNack,
    I2cDataNack,
    I2cOther,
    I2cTimeout,
};

struct InstrumentBusTiming {
    uint32_t completedWrites;
    uint32_t failedWrites;
    uint32_t lastWriteUs;
    uint32_t maximumWriteUs;
};

// Physical instrument-bus API. Its public contract is deliberately transport
// independent so a parallel TLP281 backend can replace the MCP23017 without
// changing the functional encoders or the operating controller.
class InstrumentBus final {
public:
    InstrumentBus() = default;
    InstrumentBus(const InstrumentBus&) = delete;
    InstrumentBus& operator=(const InstrumentBus&) = delete;

    // Initializes the MCP23017 without generating a falling edge on Chargt.
    // Returns false when the expander is absent or the isolated I2C bus fails.
    bool begin();

    // Applies data and address while Chargt is high, then generates one
    // high-to-low-to-high pulse. Address is restricted to the four bus bits.
    bool write(uint8_t address, uint8_t value);

    // Re-runs the safe initialization after an I2C fault.
    bool recover();

    bool ready() const;
    InstrumentBusError lastError() const;
    uint8_t dataImage() const;
    uint8_t addressImage() const;
    const InstrumentBusTiming& timing() const;

private:
    bool initializeExpander();
    bool writeRegister(uint8_t registerAddress, uint8_t value);
    bool writeRepeatedRegister(uint8_t registerAddress,
                               const uint8_t* values,
                               uint8_t count);
    bool finishTransmission();
    void recordError(InstrumentBusError error);
    void recordWriteDuration(uint32_t startedUs, bool success);
    void bestEffortReleaseLoad(uint8_t inactiveControl);

    bool ready_ = false;
    uint8_t dataImage_ = 0u;
    uint8_t controlImage_ = 0u;
    InstrumentBusError lastError_ = InstrumentBusError::NotReady;
    InstrumentBusTiming timing_ = {};
};

extern InstrumentBus instrumentBus;

}  // namespace instrument_bus
}  // namespace adret
