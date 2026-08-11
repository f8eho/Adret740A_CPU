#include <assert.h>
#include <stdint.h>
#include <stdio.h>
#include <string.h>

#include <array>

#include "Adret/CalibrationEprom.h"
#include "Adret/CalibrationStore.h"
#include "Adret/EepromLayout.h"
#include "EEPROM.h"

EEPROMClass EEPROM;

namespace {

using adret::InstrumentCapabilities;
using adret::calibration::CalibrationProfile;
using adret::calibration::CalibrationStore;

constexpr int kBaseAddress = adret::eeprom_layout::kCalibrationBaseAddress;
constexpr uint32_t kMagic = 0x43414C31u;
constexpr uint16_t kLegacyVersion = 1u;
constexpr uint8_t kCommitted = 0xC3u;
constexpr uint16_t kLegacyEntries = 30u * 28u;

struct __attribute__((packed)) Header {
    uint32_t magic;
    uint16_t version;
    uint16_t generation;
    uint16_t baseCrc;
    uint16_t dataCrc;
    uint8_t state;
    uint8_t reserved;
    uint16_t headerCrc;
};

uint16_t crc16(const uint8_t* data, size_t length)
{
    uint16_t crc = 0xFFFFu;
    for (size_t i = 0u; i < length; ++i) {
        crc ^= uint16_t(data[i]) << 8u;
        for (uint8_t bit = 0u; bit < 8u; ++bit) {
            crc = (crc & 0x8000u) != 0u
                ? uint16_t((crc << 1u) ^ 0x1021u)
                : uint16_t(crc << 1u);
        }
    }
    return crc;
}

uint8_t encodedOverlay(int8_t value)
{
    return uint8_t(~uint8_t(value));
}

void installLegacyBank(uint8_t bank)
{
    memset(EEPROM.bytes, 0xFF, sizeof(EEPROM.bytes));
    const int bankSize = int(sizeof(Header)) + kLegacyEntries;
    const int address = kBaseAddress + int(bank) * bankSize;
    uint8_t* data = EEPROM.bytes + address + int(sizeof(Header));
    memset(data, 0xFF, kLegacyEntries);
    data[0u] = encodedOverlay(3);
    data[28u * 28u + 27u] = encodedOverlay(-2);
    data[29u * 28u] = encodedOverlay(4);

    Header header = {};
    header.magic = kMagic;
    header.version = kLegacyVersion;
    header.generation = 7u;
    header.baseCrc = adret::calibration::baseTableCrc16();
    header.dataCrc = crc16(data, kLegacyEntries);
    header.state = kCommitted;
    header.headerCrc = crc16(reinterpret_cast<const uint8_t*>(&header), 14u);
    memcpy(EEPROM.bytes + address, &header, sizeof(header));
}

void expectBaseMigrationValues(const CalibrationStore& store)
{
    assert(store.profile() == CalibrationProfile::Base);
    assert(store.overlayByCompactIndex(0u) == 3);
    assert(store.overlayByCompactIndex(28u * 28u + 27u) == -2);
    assert(store.overlayByCompactIndex(29u * 28u) == 4);
    assert(store.overlayByCompactIndex(30u * 28u) == 0);
    assert(store.overlayByCompactIndex(40u * 28u + 27u) == 0);
}

void testLegacyBankZeroAndProfileChange()
{
    installLegacyBank(0u);
    EEPROM.writesRemaining = -1;
    EEPROM.writesPerformed = 0;
    EEPROM.powerLost = false;
    CalibrationStore base;
    base.begin(InstrumentCapabilities{false});
    expectBaseMigrationValues(base);
    assert(base.generation() == 8u);

    CalibrationStore x2;
    x2.begin(InstrumentCapabilities{true});
    assert(x2.profile() == CalibrationProfile::Doubler);
    assert(x2.overlayByCompactIndex(0u) == 3);
    assert(x2.overlayByCompactIndex(28u * 28u + 27u) == -2);
    assert(x2.overlayByCompactIndex(29u * 28u) == 0);
    assert(x2.startSession());
    assert(x2.setWorkingOverlay(40u, 0u, 1, nullptr));
    x2.abortSession();

    CalibrationStore baseRows;
    baseRows.begin(InstrumentCapabilities{false});
    assert(baseRows.startSession());
    assert(!baseRows.setWorkingOverlay(30u, 0u, 1, nullptr));
    baseRows.abortSession();
}

void testLegacyBankOnePowerLossRecovery()
{
    installLegacyBank(1u);
    const std::array<uint8_t, 4096> pristine = [] {
        std::array<uint8_t, 4096> result = {};
        memcpy(result.data(), EEPROM.bytes, result.size());
        return result;
    }();

    EEPROM.writesRemaining = -1;
    EEPROM.writesPerformed = 0;
    EEPROM.powerLost = false;
    CalibrationStore measurement;
    measurement.begin(InstrumentCapabilities{false});
    const int migrationWrites = EEPROM.writesPerformed;
    assert(migrationWrites > 0);

    for (int cut = 0; cut <= migrationWrites; ++cut) {
        memcpy(EEPROM.bytes, pristine.data(), pristine.size());
        EEPROM.writesRemaining = cut;
        EEPROM.writesPerformed = 0;
        EEPROM.powerLost = false;
        CalibrationStore interrupted;
        interrupted.begin(InstrumentCapabilities{false});

        EEPROM.writesRemaining = -1;
        EEPROM.powerLost = false;
        CalibrationStore recovered;
        recovered.begin(InstrumentCapabilities{false});
        expectBaseMigrationValues(recovered);
    }
}

}  // namespace

int main()
{
    testLegacyBankZeroAndProfileChange();
    testLegacyBankOnePowerLossRecovery();
    puts("CalibrationStore migration vectors: OK");
    return 0;
}
