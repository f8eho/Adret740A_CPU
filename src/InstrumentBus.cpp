#include "Adret/InstrumentBus.h"

#include <Arduino.h>
#include <Wire.h>

#include "Adret/HardwareConfig.h"

namespace adret {
namespace instrument_bus {
namespace {

constexpr uint8_t kIodirA = 0x00u;
constexpr uint8_t kIodirB = 0x01u;
constexpr uint8_t kIocon = 0x0Au;
constexpr uint8_t kOlatA = 0x14u;
constexpr uint8_t kOlatB = 0x15u;

// BANK=0 retains the standard register map. SEQOP=1 keeps the register pointer
// fixed, allowing two consecutive bytes to pulse the same OLATB register.
constexpr uint8_t kIoconDisableSequentialAddress = 0x20u;
constexpr uint8_t kPortBReservedInputMask = 0xE0u;
constexpr uint8_t kInstrumentAddressMask = 0x0Fu;
constexpr uint8_t kLoadMask = uint8_t(1u << hw::kInstrumentLoadBit);

static_assert(hw::kInstrumentLoadActiveLow,
              "The captured instrument bus latches on falling Chargt");
static_assert(hw::kInstrumentLoadBit < 8u,
              "Invalid MCP23017 Chargt bit");

uint8_t inactiveControl(uint8_t address)
{
    return uint8_t(uint8_t(address & kInstrumentAddressMask) | kLoadMask);
}

uint8_t activeControl(uint8_t address)
{
    return uint8_t(address & kInstrumentAddressMask);
}

InstrumentBusError wireError(uint8_t error, bool timedOut)
{
    if (timedOut || error == 5u) {
        return InstrumentBusError::I2cTimeout;
    }
    switch (error) {
        case 0u: return InstrumentBusError::None;
        case 1u: return InstrumentBusError::I2cBufferOverflow;
        case 2u: return InstrumentBusError::I2cAddressNack;
        case 3u: return InstrumentBusError::I2cDataNack;
        default: return InstrumentBusError::I2cOther;
    }
}

}  // namespace

InstrumentBus instrumentBus;

bool InstrumentBus::begin()
{
    ready_ = false;
    Wire.begin();
    Wire.setClock(hw::kInstrumentI2cClockHz);
    Wire.setWireTimeout(hw::kInstrumentI2cTimeoutUs, true);
    Wire.clearWireTimeoutFlag();
    return initializeExpander();
}

bool InstrumentBus::recover()
{
    return begin();
}

bool InstrumentBus::initializeExpander()
{
    dataImage_ = 0u;
    controlImage_ = inactiveControl(0u);

    // All pins power up as inputs. Preload both output latches before changing
    // IODIR so Chargt cannot make a falling edge during CPU initialization.
    if (!writeRegister(kIocon, kIoconDisableSequentialAddress) ||
        !writeRegister(kOlatA, dataImage_) ||
        !writeRegister(kOlatB, controlImage_) ||
        !writeRegister(kIodirA, 0x00u) ||
        !writeRegister(kIodirB, kPortBReservedInputMask)) {
        ready_ = false;
        return false;
    }

    ready_ = true;
    lastError_ = InstrumentBusError::None;
    return true;
}

bool InstrumentBus::write(uint8_t address, uint8_t value)
{
    const uint32_t startedUs = micros();
    if (!ready_) {
        recordError(InstrumentBusError::NotReady);
        recordWriteDuration(startedUs, false);
        return false;
    }
    if ((address & uint8_t(~kInstrumentAddressMask)) != 0u) {
        recordError(InstrumentBusError::InvalidAddress);
        recordWriteDuration(startedUs, false);
        return false;
    }

    const uint8_t inactive = inactiveControl(address);
    if (value != dataImage_) {
        if (!writeRegister(kOlatA, value)) {
            ready_ = false;
            recordWriteDuration(startedUs, false);
            return false;
        }
        dataImage_ = value;
    }
    if (inactive != controlImage_) {
        if (!writeRegister(kOlatB, inactive)) {
            ready_ = false;
            recordWriteDuration(startedUs, false);
            return false;
        }
        controlImage_ = inactive;
    }

    const uint8_t pulse[2] = {activeControl(address), inactive};
    if (!writeRepeatedRegister(kOlatB, pulse, 2u)) {
        const InstrumentBusError pulseError = lastError_;
        bestEffortReleaseLoad(inactive);
        lastError_ = pulseError;
        ready_ = false;
        recordWriteDuration(startedUs, false);
        return false;
    }

    controlImage_ = inactive;
    lastError_ = InstrumentBusError::None;
    recordWriteDuration(startedUs, true);
    return true;
}

bool InstrumentBus::writeRegister(uint8_t registerAddress, uint8_t value)
{
    return writeRepeatedRegister(registerAddress, &value, 1u);
}

bool InstrumentBus::writeRepeatedRegister(uint8_t registerAddress,
                                          const uint8_t* values,
                                          uint8_t count)
{
    Wire.clearWireTimeoutFlag();
    Wire.beginTransmission(hw::kInstrumentMcp23017Address);
    if (Wire.write(registerAddress) != 1u) {
        recordError(InstrumentBusError::I2cBufferOverflow);
        return false;
    }
    for (uint8_t i = 0u; i < count; ++i) {
        if (Wire.write(values[i]) != 1u) {
            recordError(InstrumentBusError::I2cBufferOverflow);
            return false;
        }
    }
    return finishTransmission();
}

bool InstrumentBus::finishTransmission()
{
    const uint8_t error = Wire.endTransmission(true);
    const InstrumentBusError mapped =
        wireError(error, Wire.getWireTimeoutFlag());
    Wire.clearWireTimeoutFlag();
    if (mapped != InstrumentBusError::None) {
        recordError(mapped);
        return false;
    }
    return true;
}

void InstrumentBus::recordError(InstrumentBusError error)
{
    lastError_ = error;
}

void InstrumentBus::recordWriteDuration(uint32_t startedUs, bool success)
{
    const uint32_t durationUs = micros() - startedUs;
    timing_.lastWriteUs = durationUs;
    if (durationUs > timing_.maximumWriteUs) {
        timing_.maximumWriteUs = durationUs;
    }
    if (success) {
        ++timing_.completedWrites;
    } else {
        ++timing_.failedWrites;
    }
}

void InstrumentBus::bestEffortReleaseLoad(uint8_t inactiveControl)
{
    const InstrumentBusError savedError = lastError_;
    if (writeRegister(kOlatB, inactiveControl)) {
        controlImage_ = inactiveControl;
    }
    lastError_ = savedError;
}

bool InstrumentBus::ready() const
{
    return ready_;
}

InstrumentBusError InstrumentBus::lastError() const
{
    return lastError_;
}

uint8_t InstrumentBus::dataImage() const
{
    return dataImage_;
}

uint8_t InstrumentBus::addressImage() const
{
    return uint8_t(controlImage_ & kInstrumentAddressMask);
}

const InstrumentBusTiming& InstrumentBus::timing() const
{
    return timing_;
}

}  // namespace instrument_bus
}  // namespace adret
