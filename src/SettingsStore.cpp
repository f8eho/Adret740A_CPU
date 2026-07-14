#include "Adret/SettingsStore.h"

#include <EEPROM.h>
#include <stddef.h>

namespace adret {

namespace {

constexpr uint32_t kSettingsMagic = 0x41523734u;
constexpr uint16_t kSettingsVersion = 2u;
constexpr uint8_t kSlotCount = 2u;

struct __attribute__((packed)) PersistentPayload {
    uint32_t frequencyHz;
    uint32_t fmHz;
    int16_t amplitudeTenthsDbm;
    uint16_t pmHundredthsRd;
    uint16_t amTenthsPercent;
    uint8_t target;
    uint8_t wheelTarget;
    uint8_t modulationMode;
    uint8_t modulationSource;
    uint8_t frequencyStepIndex;
    uint8_t amplitudeStepIndex;
    uint8_t fmStepIndex;
    uint8_t pmStepIndex;
    uint8_t amStepIndex;
    uint8_t flags;
};

struct __attribute__((packed)) PersistentRecord {
    uint32_t magic;
    uint16_t version;
    uint16_t generation;
    PersistentPayload payload;
    uint16_t crc;
};

constexpr uint8_t kWheelInhibitedFlag = 1u << 0;
constexpr uint8_t kRfOffFlag = 1u << 1;

static_assert(sizeof(PersistentRecord) <= 40u,
              "EEPROM settings record unexpectedly large");

uint16_t crc16(const uint8_t* data, size_t length)
{
    uint16_t crc = 0xFFFFu;
    for (size_t i = 0; i < length; ++i) {
        crc ^= uint16_t(data[i]) << 8;
        for (uint8_t bit = 0; bit < 8u; ++bit) {
            crc = (crc & 0x8000u) != 0u
                ? uint16_t((crc << 1) ^ 0x1021u)
                : uint16_t(crc << 1);
        }
    }
    return crc;
}

uint16_t recordCrc(const PersistentRecord& record)
{
    return crc16(reinterpret_cast<const uint8_t*>(&record),
                 offsetof(PersistentRecord, crc));
}

bool recordIsValid(const PersistentRecord& record)
{
    return record.magic == kSettingsMagic &&
           record.version == kSettingsVersion &&
           record.crc == recordCrc(record);
}

bool generationIsNewer(uint16_t candidate, uint16_t reference)
{
    return int16_t(candidate - reference) > 0;
}

int slotAddress(uint8_t slot)
{
    return int(slot) * int(sizeof(PersistentRecord));
}

control::Settings decode(const PersistentPayload& payload)
{
    control::Settings result = {};
    result.frequencyHz = payload.frequencyHz;
    result.fmHz = payload.fmHz;
    result.amplitudeTenthsDbm = payload.amplitudeTenthsDbm;
    result.pmHundredthsRd = payload.pmHundredthsRd;
    result.amTenthsPercent = payload.amTenthsPercent;
    result.target = control::Target(payload.target);
    result.wheelTarget = control::Target(payload.wheelTarget);
    result.modulationMode = control::ModulationMode(payload.modulationMode);
    result.modulationSource = control::ModulationSource(payload.modulationSource);
    result.frequencyStepIndex = payload.frequencyStepIndex;
    result.amplitudeStepIndex = payload.amplitudeStepIndex;
    result.fmStepIndex = payload.fmStepIndex;
    result.pmStepIndex = payload.pmStepIndex;
    result.amStepIndex = payload.amStepIndex;
    result.wheelInhibited = (payload.flags & kWheelInhibitedFlag) != 0u;
    result.rfOff = (payload.flags & kRfOffFlag) != 0u;
    return result;
}

PersistentPayload encode(const control::Settings& settings)
{
    PersistentPayload result = {};
    result.frequencyHz = settings.frequencyHz;
    result.fmHz = settings.fmHz;
    result.amplitudeTenthsDbm = settings.amplitudeTenthsDbm;
    result.pmHundredthsRd = settings.pmHundredthsRd;
    result.amTenthsPercent = settings.amTenthsPercent;
    result.target = uint8_t(settings.target);
    result.wheelTarget = uint8_t(settings.wheelTarget);
    result.modulationMode = uint8_t(settings.modulationMode);
    result.modulationSource = uint8_t(settings.modulationSource);
    result.frequencyStepIndex = settings.frequencyStepIndex;
    result.amplitudeStepIndex = settings.amplitudeStepIndex;
    result.fmStepIndex = settings.fmStepIndex;
    result.pmStepIndex = settings.pmStepIndex;
    result.amStepIndex = settings.amStepIndex;
    result.flags = uint8_t((settings.wheelInhibited ? kWheelInhibitedFlag : 0u) |
                           (settings.rfOff ? kRfOffFlag : 0u));
    return result;
}

}  // namespace

SettingsStore settingsStore;

bool SettingsStore::load(control::Settings* settings)
{
    if (settings == nullptr) {
        return false;
    }

    PersistentRecord records[kSlotCount] = {};
    for (uint8_t slot = 0; slot < kSlotCount; ++slot) {
        EEPROM.get(slotAddress(slot), records[slot]);
    }

    const control::Settings decoded0 = decode(records[0].payload);
    const control::Settings decoded1 = decode(records[1].payload);
    const bool valid0 = recordIsValid(records[0]) &&
                        control::settingsAreValid(decoded0);
    const bool valid1 = recordIsValid(records[1]) &&
                        control::settingsAreValid(decoded1);
    if (!valid0 && !valid1) {
        return false;
    }

    activeSlot_ = valid1 && (!valid0 || generationIsNewer(records[1].generation,
                                                           records[0].generation))
        ? 1u
        : 0u;
    *settings = activeSlot_ == 0u ? decoded0 : decoded1;
    generation_ = records[activeSlot_].generation;
    hasValidSlot_ = true;
    return true;
}

bool SettingsStore::saveNow(const control::Settings& settings)
{
    if (!control::settingsAreValid(settings)) {
        return false;
    }

    PersistentRecord record = {};
    record.magic = kSettingsMagic;
    record.version = kSettingsVersion;
    record.generation = uint16_t(generation_ + 1u);
    record.payload = encode(settings);
    record.crc = recordCrc(record);

    const uint8_t destination = hasValidSlot_ ? uint8_t(activeSlot_ ^ 1u) : 0u;
    const int address = slotAddress(destination);
    const uint8_t* bytes = reinterpret_cast<const uint8_t*>(&record);
    for (size_t i = 0; i < sizeof(record); ++i) {
        EEPROM.update(address + int(i), bytes[i]);
    }

    PersistentRecord verification = {};
    EEPROM.get(address, verification);
    if (!recordIsValid(verification)) {
        return false;
    }
    generation_ = verification.generation;
    activeSlot_ = destination;
    hasValidSlot_ = true;
    return true;
}

}  // namespace adret
