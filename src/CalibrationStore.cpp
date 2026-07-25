#include "Adret/CalibrationStore.h"

#include <EEPROM.h>
#include <stddef.h>

#include "Adret/CalibrationEprom.h"
#include "Adret/EepromLayout.h"

namespace adret {
namespace calibration {
namespace {

constexpr uint32_t kBankMagic = 0x43414C31u;
constexpr uint16_t kBankVersion = 1u;
constexpr uint8_t kCommittedState = 0xC3u;
constexpr uint8_t kWorkingState = 0x57u;
constexpr uint8_t kBankCount = 2u;
// Across the complete level range, nominal fine attenuation spans 5.8..11.8
// dB. These conservative limits keep every corrected code inside 0..13.9 dB,
// including the edges of all mechanical cells.
constexpr int16_t kMinimumEffectiveTenthsDb = -50;
constexpr int16_t kMaximumEffectiveTenthsDb = 20;

struct __attribute__((packed)) BankHeader {
    uint32_t magic;
    uint16_t version;
    uint16_t generation;
    uint16_t baseCrc;
    uint16_t dataCrc;
    uint8_t state;
    uint8_t reserved;
    uint16_t headerCrc;
};

constexpr int kBankSize = int(sizeof(BankHeader)) +
                          int(kStandardOverlayEntryCount);
constexpr int kCalibrationEndAddress =
    eeprom_layout::kCalibrationBaseAddress + int(kBankCount) * kBankSize;

static_assert(sizeof(BankHeader) == 16u,
              "Unexpected calibration-bank header layout");
static_assert(kCalibrationEndAddress <= eeprom_layout::kEepromSize,
              "Calibration banks exceed ATmega2560 EEPROM capacity");

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

uint16_t headerCrc(const BankHeader& header)
{
    return crc16(reinterpret_cast<const uint8_t*>(&header),
                 offsetof(BankHeader, headerCrc));
}

int bankAddress(uint8_t bank)
{
    return eeprom_layout::kCalibrationBaseAddress + int(bank) * kBankSize;
}

int dataAddress(uint8_t bank, uint16_t overlayIndex)
{
    return bankAddress(bank) + int(sizeof(BankHeader)) + int(overlayIndex);
}

uint8_t encodeOverlay(int8_t value)
{
    return uint8_t(~uint8_t(value));
}

int8_t decodeOverlay(uint8_t value)
{
    return int8_t(uint8_t(~value));
}

void updateBytes(int address, const void* value, size_t length)
{
    const uint8_t* bytes = static_cast<const uint8_t*>(value);
    for (size_t i = 0u; i < length; ++i) {
        EEPROM.update(address + int(i), bytes[i]);
    }
}

uint16_t bankDataCrc(uint8_t bank)
{
    uint16_t crc = 0xFFFFu;
    for (uint16_t i = 0u; i < kStandardOverlayEntryCount; ++i) {
        const uint8_t value = EEPROM.read(dataAddress(bank, i));
        crc ^= uint16_t(value) << 8u;
        for (uint8_t bit = 0u; bit < 8u; ++bit) {
            crc = (crc & 0x8000u) != 0u
                ? uint16_t((crc << 1u) ^ 0x1021u)
                : uint16_t(crc << 1u);
        }
    }
    return crc;
}

bool generationIsNewer(uint16_t candidate, uint16_t reference)
{
    return int16_t(candidate - reference) > 0;
}

bool validBank(uint8_t bank,
               uint16_t expectedBaseCrc,
               uint8_t expectedState,
               BankHeader* result)
{
    BankHeader header = {};
    EEPROM.get(bankAddress(bank), header);
    if (header.magic != kBankMagic || header.version != kBankVersion ||
        header.baseCrc != expectedBaseCrc ||
        header.state != expectedState ||
        header.headerCrc != headerCrc(header) ||
        header.dataCrc != bankDataCrc(bank)) {
        return false;
    }
    if (result != nullptr) {
        *result = header;
    }
    return true;
}

}  // namespace

CalibrationStore calibrationStore;

void CalibrationStore::begin()
{
    baseCrc_ = baseTableCrc16();
    sessionActive_ = false;
    hasCommittedBank_ = false;
    generation_ = 0u;

    BankHeader headers[kBankCount] = {};
    bool valid[kBankCount] = {};
    for (uint8_t bank = 0u; bank < kBankCount; ++bank) {
        valid[bank] = validBank(bank, baseCrc_, kCommittedState,
                                &headers[bank]);
    }
    if (!valid[0] && !valid[1]) {
        return;
    }
    committedBank_ = valid[1] &&
                     (!valid[0] || generationIsNewer(headers[1].generation,
                                                      headers[0].generation))
        ? 1u
        : 0u;
    generation_ = headers[committedBank_].generation;
    hasCommittedBank_ = true;
}

bool CalibrationStore::startSession()
{
    if (sessionActive_) {
        return false;
    }
    workingBank_ = hasCommittedBank_ ? uint8_t(committedBank_ ^ 1u) : 0u;

    // Invalidate the destination before changing any data. The previously
    // committed bank remains untouched until the new bank is fully verified.
    const uint32_t invalidMagic = 0u;
    updateBytes(bankAddress(workingBank_), &invalidMagic, sizeof(invalidMagic));
    for (uint16_t i = 0u; i < kStandardOverlayEntryCount; ++i) {
        const uint8_t value = hasCommittedBank_
            ? EEPROM.read(dataAddress(committedBank_, i))
            : 0xFFu;
        EEPROM.update(dataAddress(workingBank_, i), value);
    }

    BankHeader header = {};
    header.magic = kBankMagic;
    header.version = kBankVersion;
    header.generation = uint16_t(generation_ + 1u);
    header.baseCrc = baseCrc_;
    header.dataCrc = bankDataCrc(workingBank_);
    header.state = kWorkingState;
    header.headerCrc = headerCrc(header);
    updateBytes(bankAddress(workingBank_), &header, sizeof(header));
    BankHeader verification = {};
    if (!validBank(workingBank_, baseCrc_, kWorkingState, &verification)) {
        return false;
    }
    sessionActive_ = true;
    return true;
}

bool CalibrationStore::commitSession()
{
    if (!sessionActive_) {
        return false;
    }
    BankHeader header = {};
    header.magic = kBankMagic;
    header.version = kBankVersion;
    header.generation = uint16_t(generation_ + 1u);
    header.baseCrc = baseCrc_;
    header.dataCrc = bankDataCrc(workingBank_);
    header.state = kCommittedState;
    header.headerCrc = headerCrc(header);
    updateBytes(bankAddress(workingBank_), &header, sizeof(header));

    BankHeader verification = {};
    if (!validBank(workingBank_, baseCrc_, kCommittedState, &verification)) {
        return false;
    }
    committedBank_ = workingBank_;
    generation_ = verification.generation;
    hasCommittedBank_ = true;
    sessionActive_ = false;
    return true;
}

void CalibrationStore::abortSession()
{
    sessionActive_ = false;
}

bool CalibrationStore::sessionActive() const
{
    return sessionActive_;
}

bool CalibrationStore::point(uint32_t frequencyHz,
                             int16_t amplitudeTenthsDbm,
                             CalibrationPoint* result) const
{
    uint16_t tableIndex = 0u;
    uint16_t overlayIndex = 0u;
    uint8_t row = 0u;
    uint8_t step = 0u;
    return result != nullptr &&
           correctionIndex(frequencyHz, amplitudeTenthsDbm, &tableIndex,
                           &overlayIndex, &row, &step) &&
           fillPoint(tableIndex, overlayIndex, row, step, result);
}

bool CalibrationStore::effectiveCorrection(
    uint32_t frequencyHz,
    int16_t amplitudeTenthsDbm,
    int8_t* correctionTenthsDb) const
{
    CalibrationPoint selected = {};
    if (correctionTenthsDb == nullptr ||
        !point(frequencyHz, amplitudeTenthsDbm, &selected)) {
        return false;
    }
    *correctionTenthsDb = selected.effectiveTenthsDb;
    return true;
}

bool CalibrationStore::addWorkingCorrection(
    uint32_t frequencyHz,
    int16_t amplitudeTenthsDbm,
    int16_t addedTenthsDb,
    CalibrationPoint* result)
{
    CalibrationPoint selected = {};
    if (!sessionActive_ ||
        !point(frequencyHz, amplitudeTenthsDbm, &selected)) {
        return false;
    }
    const int16_t updatedOverlay =
        int16_t(selected.overlayTenthsDb) + addedTenthsDb;
    const int16_t updatedEffective =
        int16_t(selected.baseTenthsDb) + updatedOverlay;
    if (updatedOverlay < INT8_MIN || updatedOverlay > INT8_MAX ||
        updatedEffective < kMinimumEffectiveTenthsDb ||
        updatedEffective > kMaximumEffectiveTenthsDb) {
        return false;
    }
    EEPROM.update(dataAddress(workingBank_, selected.overlayIndex),
                  encodeOverlay(int8_t(updatedOverlay)));
    return fillPoint(selected.tableIndex, selected.overlayIndex,
                     selected.row, selected.step, result);
}

bool CalibrationStore::setWorkingOverlay(uint8_t row,
                                         uint8_t step,
                                         int8_t overlayTenthsDb,
                                         CalibrationPoint* result)
{
    if (!sessionActive_ || row >= kStandardFrequencyRowCount ||
        step >= kAttenuatorStepCount) {
        return false;
    }
    const uint16_t tableIndex =
        uint16_t(row) * kCorrectionColumnsPerRow + step;
    const uint16_t overlayIndex = uint16_t(row) * kAttenuatorStepCount + step;
    const int16_t effective =
        int16_t(readCorrection(tableIndex)) + overlayTenthsDb;
    if (effective < kMinimumEffectiveTenthsDb ||
        effective > kMaximumEffectiveTenthsDb) {
        return false;
    }
    EEPROM.update(dataAddress(workingBank_, overlayIndex),
                  encodeOverlay(overlayTenthsDb));
    return result == nullptr ||
           fillPoint(tableIndex, overlayIndex, row, step, result);
}

int8_t CalibrationStore::overlayByCompactIndex(uint16_t overlayIndex) const
{
    if (overlayIndex >= kStandardOverlayEntryCount) {
        return 0;
    }
    if (sessionActive_) {
        return overlayFromBank(workingBank_, overlayIndex);
    }
    return hasCommittedBank_
        ? overlayFromBank(committedBank_, overlayIndex)
        : 0;
}

uint16_t CalibrationStore::baseCrc() const
{
    return baseCrc_;
}

uint16_t CalibrationStore::generation() const
{
    return generation_;
}

int8_t CalibrationStore::overlayFromBank(uint8_t bank,
                                         uint16_t overlayIndex) const
{
    return decodeOverlay(EEPROM.read(dataAddress(bank, overlayIndex)));
}

bool CalibrationStore::fillPoint(uint16_t tableIndex,
                                 uint16_t overlayIndex,
                                 uint8_t row,
                                 uint8_t step,
                                 CalibrationPoint* result) const
{
    if (result == nullptr) {
        return false;
    }
    const int8_t base = readCorrection(tableIndex);
    const int8_t overlay = overlayByCompactIndex(overlayIndex);
    const int16_t effective = int16_t(base) + overlay;
    if (effective < kMinimumEffectiveTenthsDb ||
        effective > kMaximumEffectiveTenthsDb) {
        return false;
    }
    result->tableIndex = tableIndex;
    result->overlayIndex = overlayIndex;
    result->row = row;
    result->step = step;
    result->baseTenthsDb = base;
    result->overlayTenthsDb = overlay;
    result->effectiveTenthsDb = int8_t(effective);
    return true;
}

}  // namespace calibration
}  // namespace adret
