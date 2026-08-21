#include "Adret/CalibrationStore.h"

#include <EEPROM.h>
#include <stddef.h>

#include "Adret/CalibrationEprom.h"
#include "Adret/EepromLayout.h"

namespace adret {
namespace calibration {
namespace {

constexpr uint32_t kBankMagic = 0x43414C31u;
// Differs from kBankMagic in its low byte only. During legacy-bank migration,
// this recoverable marker remains valid until the final single-byte commit.
constexpr uint32_t kMigrationMagic = 0x43414C30u;
constexpr uint16_t kLegacyBankVersion = 1u;
constexpr uint16_t kBankVersion = 2u;
constexpr uint8_t kCommittedState = 0xC3u;
constexpr uint8_t kWorkingState = 0x57u;
constexpr uint8_t kMigrationState = 0x4Du;
constexpr uint8_t kBankCount = 2u;
constexpr uint16_t kLegacyOverlayEntryCount =
    uint16_t(kBaseFrequencyRowCount) * kAttenuatorStepCount;
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
    uint8_t profile;
    uint16_t headerCrc;
};

constexpr int kBankSize = int(sizeof(BankHeader)) +
                          int(kCalibrationOverlayEntryCount);
constexpr int kLegacyBankSize = int(sizeof(BankHeader)) +
                                int(kLegacyOverlayEntryCount);
constexpr int kCalibrationEndAddress =
    eeprom_layout::kCalibrationBaseAddress + int(kBankCount) * kBankSize;

static_assert(sizeof(BankHeader) == 16u,
              "Unexpected calibration-bank header layout");
static_assert(kCalibrationEndAddress <= eeprom_layout::kEepromSize,
              "Calibration banks exceed Arduino Mega EEPROM capacity");

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

int legacyBankAddress(uint8_t bank)
{
    return eeprom_layout::kCalibrationBaseAddress + int(bank) * kLegacyBankSize;
}

int dataAddress(uint8_t bank, uint16_t overlayIndex)
{
    return bankAddress(bank) + int(sizeof(BankHeader)) + int(overlayIndex);
}

int legacyDataAddress(uint8_t bank, uint16_t overlayIndex)
{
    return legacyBankAddress(bank) + int(sizeof(BankHeader)) + int(overlayIndex);
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
    for (uint16_t i = 0u; i < kCalibrationOverlayEntryCount; ++i) {
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

uint16_t legacyBankDataCrc(uint8_t bank)
{
    uint16_t crc = 0xFFFFu;
    for (uint16_t i = 0u; i < kLegacyOverlayEntryCount; ++i) {
        const uint8_t value = EEPROM.read(legacyDataAddress(bank, i));
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
        header.profile > uint8_t(CalibrationProfile::Doubler) ||
        header.headerCrc != headerCrc(header) ||
        header.dataCrc != bankDataCrc(bank)) {
        return false;
    }
    if (result != nullptr) {
        *result = header;
    }
    return true;
}

bool validLegacyBank(uint8_t bank,
                     uint16_t expectedBaseCrc,
                     BankHeader* result)
{
    BankHeader header = {};
    EEPROM.get(legacyBankAddress(bank), header);
    if (header.magic != kBankMagic ||
        header.version != kLegacyBankVersion ||
        header.baseCrc != expectedBaseCrc ||
        header.state != kCommittedState ||
        header.headerCrc != headerCrc(header) ||
        header.dataCrc != legacyBankDataCrc(bank)) {
        return false;
    }
    if (result != nullptr) {
        *result = header;
    }
    return true;
}

bool resumePendingLegacyMigration(uint16_t expectedBaseCrc)
{
    BankHeader marker = {};
    EEPROM.get(bankAddress(0u), marker);
    if (marker.magic != kMigrationMagic ||
        marker.version != kBankVersion ||
        marker.baseCrc != expectedBaseCrc ||
        marker.profile > uint8_t(CalibrationProfile::Doubler)) {
        return false;
    }

    // Entries 0..839 were copied before the marker became visible. Only this
    // neutral tail can overlap and invalidate the old second legacy bank.
    for (uint16_t i = kLegacyOverlayEntryCount;
         i < kCalibrationOverlayEntryCount; ++i) {
        EEPROM.update(dataAddress(0u, i), 0xFFu);
    }

    BankHeader committed = marker;
    committed.magic = kBankMagic;
    committed.dataCrc = bankDataCrc(0u);
    committed.state = kCommittedState;
    committed.headerCrc = headerCrc(committed);

    // Keep the migration magic intact while refreshing every other field.
    // Since both magics differ only in byte zero, the last EEPROM byte write
    // is the transaction commit; after a power loss, either marker is usable.
    const uint8_t* bytes = reinterpret_cast<const uint8_t*>(&committed);
    updateBytes(bankAddress(0u) + int(sizeof(committed.magic)),
                bytes + sizeof(committed.magic),
                sizeof(committed) - sizeof(committed.magic));
    EEPROM.update(bankAddress(0u), uint8_t(kBankMagic & 0xFFu));
    return true;
}

}  // namespace

CalibrationStore calibrationStore;

void CalibrationStore::begin(
    const InstrumentCapabilities& capabilities)
{
    baseCrc_ = baseTableCrc16();
    profile_ = capabilities.doublerInstalled()
        ? CalibrationProfile::Doubler : CalibrationProfile::Base;
    sessionActive_ = false;
    hasCommittedBank_ = false;
    generation_ = 0u;

    // A marker can only exist while migrating legacy bank 1 into version-2
    // bank 0. Completing it first makes migration restartable after any reset.
    (void)resumePendingLegacyMigration(baseCrc_);

    BankHeader headers[kBankCount] = {};
    bool valid[kBankCount] = {};
    for (uint8_t bank = 0u; bank < kBankCount; ++bank) {
        valid[bank] = validBank(bank, baseCrc_, kCommittedState,
                                &headers[bank]);
    }
    if (valid[0] || valid[1]) {
        const uint8_t selected = valid[1] &&
                                 (!valid[0] || generationIsNewer(
                                      headers[1].generation,
                                      headers[0].generation))
            ? 1u : 0u;
        if (headers[selected].profile == uint8_t(profile_)) {
            committedBank_ = selected;
            generation_ = headers[selected].generation;
            hasCommittedBank_ = true;
            return;
        }
        constexpr uint16_t kSharedEntryCount =
            uint16_t(kBaseFrequencyRowCount - 1u) * kAttenuatorStepCount;
        (void)migrateBank(selected, false, headers[selected].generation,
                          kSharedEntryCount);
        return;
    }

    BankHeader legacyHeaders[kBankCount] = {};
    bool legacyValid[kBankCount] = {};
    for (uint8_t bank = 0u; bank < kBankCount; ++bank) {
        legacyValid[bank] = validLegacyBank(bank, baseCrc_,
                                            &legacyHeaders[bank]);
    }
    if (!legacyValid[0] && !legacyValid[1]) {
        return;
    }
    const uint8_t selected = legacyValid[1] &&
                             (!legacyValid[0] || generationIsNewer(
                                  legacyHeaders[1].generation,
                                  legacyHeaders[0].generation))
        ? 1u : 0u;
    const uint16_t preservedEntries = profile_ == CalibrationProfile::Base
        ? uint16_t(kBaseFrequencyRowCount) * kAttenuatorStepCount
        : uint16_t(kBaseFrequencyRowCount - 1u) * kAttenuatorStepCount;
    (void)migrateBank(selected, true, legacyHeaders[selected].generation,
                      preservedEntries);
}

bool CalibrationStore::migrateBank(uint8_t sourceBank,
                                   bool legacy,
                                   uint16_t sourceGeneration,
                                   uint16_t preservedEntries)
{
    const uint8_t destination = uint8_t(sourceBank ^ 1u);
    const uint32_t invalidMagic = 0u;
    updateBytes(bankAddress(destination), &invalidMagic, sizeof(invalidMagic));

    const uint16_t firstPassCount = legacy
        ? kLegacyOverlayEntryCount : kCalibrationOverlayEntryCount;
    for (uint16_t i = 0u; i < firstPassCount; ++i) {
        const uint8_t value = i < preservedEntries
            ? EEPROM.read(legacy ? legacyDataAddress(sourceBank, i)
                                 : dataAddress(sourceBank, i))
            : 0xFFu;
        EEPROM.update(dataAddress(destination, i), value);
    }

    if (legacy && sourceBank == 1u) {
        // New bank 0 overlaps the beginning of old bank 1 only in its neutral
        // extension. Publish a recovery marker before touching that overlap.
        BankHeader marker = {};
        marker.magic = kMigrationMagic;
        marker.version = kBankVersion;
        marker.generation = uint16_t(sourceGeneration + 1u);
        marker.baseCrc = baseCrc_;
        marker.state = kMigrationState;
        marker.profile = uint8_t(profile_);
        marker.headerCrc = headerCrc(marker);
        updateBytes(bankAddress(destination), &marker, sizeof(marker));
        if (!resumePendingLegacyMigration(baseCrc_)) {
            return false;
        }
    } else {
        for (uint16_t i = firstPassCount;
             i < kCalibrationOverlayEntryCount; ++i) {
            EEPROM.update(dataAddress(destination, i), 0xFFu);
        }

        BankHeader header = {};
        header.magic = kBankMagic;
        header.version = kBankVersion;
        header.generation = uint16_t(sourceGeneration + 1u);
        header.baseCrc = baseCrc_;
        header.dataCrc = bankDataCrc(destination);
        header.state = kCommittedState;
        header.profile = uint8_t(profile_);
        header.headerCrc = headerCrc(header);
        updateBytes(bankAddress(destination), &header, sizeof(header));
    }

    BankHeader verification = {};
    if (!validBank(destination, baseCrc_, kCommittedState, &verification) ||
        verification.profile != uint8_t(profile_)) {
        return false;
    }
    committedBank_ = destination;
    generation_ = verification.generation;
    hasCommittedBank_ = true;
    return true;
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
    for (uint16_t i = 0u; i < kCalibrationOverlayEntryCount; ++i) {
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
    header.profile = uint8_t(profile_);
    header.headerCrc = headerCrc(header);
    updateBytes(bankAddress(workingBank_), &header, sizeof(header));
    BankHeader verification = {};
    if (!validBank(workingBank_, baseCrc_, kWorkingState, &verification) ||
        verification.profile != uint8_t(profile_)) {
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
    header.profile = uint8_t(profile_);
    header.headerCrc = headerCrc(header);
    updateBytes(bankAddress(workingBank_), &header, sizeof(header));

    BankHeader verification = {};
    if (!validBank(workingBank_, baseCrc_, kCommittedState, &verification) ||
        verification.profile != uint8_t(profile_)) {
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
    const uint8_t profileRowCount = profile_ == CalibrationProfile::Doubler
        ? kCalibrationFrequencyRowCount : kBaseFrequencyRowCount;
    if (!sessionActive_ || row >= profileRowCount ||
        step >= kAttenuatorStepCount) {
        return false;
    }
    const uint16_t tableIndex =
        uint16_t(row) * kCorrectionColumnsPerRow + step;
    const uint16_t overlayIndex = uint16_t(row) * kAttenuatorStepCount + step;
    const CalibrationProfile permanentProfile = permanentTableProfile();
    const int8_t base = row < (kBaseFrequencyRowCount - 1u) ||
                        permanentProfile == profile_
        ? readCorrection(tableIndex) : 0;
    const int16_t effective =
        int16_t(base) + overlayTenthsDb;
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
    if (overlayIndex >= kCalibrationOverlayEntryCount) {
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

CalibrationProfile CalibrationStore::profile() const
{
    return profile_;
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
    const CalibrationProfile permanentProfile = permanentTableProfile();
    const int8_t base = row < (kBaseFrequencyRowCount - 1u) ||
                        permanentProfile == profile_
        ? readCorrection(tableIndex) : 0;
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
