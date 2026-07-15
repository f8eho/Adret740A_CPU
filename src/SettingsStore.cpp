#include "Adret/SettingsStore.h"

#include <EEPROM.h>
#include <stddef.h>

namespace adret {

namespace {

constexpr uint32_t kSettingsMagic = 0x41523734u;
constexpr uint16_t kLegacySettingsVersion = 2u;
constexpr uint16_t kSettingsVersion = 3u;
constexpr uint8_t kSlotCount = 2u;
constexpr int kSettingsBaseAddress = 128;
constexpr int kSettingsSlotSize = 64;
constexpr int kMemoryBaseAddress = 256;
constexpr uint16_t kMemoryMagic = 0x4D34u;
constexpr uint8_t kMemoryVersion = 1u;

constexpr uint8_t kWheelInhibitedFlag = 1u << 0;
constexpr uint8_t kRfOffFlag = 1u << 0;

struct __attribute__((packed)) PersistentOutput {
    uint32_t frequencyHz;
    uint32_t fmHz;
    int16_t amplitudeTenthsDbm;
    uint16_t pmHundredthsRd;
    uint16_t amTenthsPercent;
    uint8_t modulationMode;
    uint8_t modulationSource;
    uint8_t amplitudeDisplayUnit;
    uint8_t flags;
};

struct __attribute__((packed)) PersistentPayloadV3 {
    PersistentOutput output;
    uint8_t target;
    uint8_t wheelTarget;
    uint8_t frequencyStepIndex;
    uint8_t amplitudeStepIndex;
    uint8_t fmStepIndex;
    uint8_t pmStepIndex;
    uint8_t amStepIndex;
    uint8_t flags;
};

struct __attribute__((packed)) PersistentRecordV3 {
    uint32_t magic;
    uint16_t version;
    uint16_t generation;
    PersistentPayloadV3 payload;
    uint16_t crc;
};

struct __attribute__((packed)) LegacyPayloadV2 {
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

struct __attribute__((packed)) LegacyRecordV2 {
    uint32_t magic;
    uint16_t version;
    uint16_t generation;
    LegacyPayloadV2 payload;
    uint16_t crc;
};

struct __attribute__((packed)) MemoryRecord {
    uint16_t magic;
    uint8_t version;
    uint8_t index;
    PersistentOutput output;
    uint16_t crc;
};

static_assert(sizeof(PersistentRecordV3) <= kSettingsSlotSize,
              "EEPROM settings slot too small");
static_assert(kMemoryBaseAddress +
                  int(SettingsStore::kMemoryCount) * int(sizeof(MemoryRecord)) <= 4096,
              "EEPROM memory bank exceeds ATmega2560 capacity");
static_assert(sizeof(LegacyRecordV2) <= 40u,
              "Legacy EEPROM layout changed unexpectedly");

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

template <typename Record>
uint16_t recordCrc(const Record& record)
{
    return crc16(reinterpret_cast<const uint8_t*>(&record),
                 sizeof(Record) - sizeof(record.crc));
}

bool generationIsNewer(uint16_t candidate, uint16_t reference)
{
    return int16_t(candidate - reference) > 0;
}

int settingsSlotAddress(uint8_t slot)
{
    return kSettingsBaseAddress + int(slot) * kSettingsSlotSize;
}

int legacySlotAddress(uint8_t slot)
{
    return int(slot) * int(sizeof(LegacyRecordV2));
}

int memoryAddress(uint8_t index)
{
    return kMemoryBaseAddress + int(index) * int(sizeof(MemoryRecord));
}

PersistentOutput encodeOutput(const control::OutputConfiguration& configuration)
{
    PersistentOutput result = {};
    result.frequencyHz = configuration.frequencyHz;
    result.fmHz = configuration.fmHz;
    result.amplitudeTenthsDbm = configuration.amplitudeTenthsDbm;
    result.pmHundredthsRd = configuration.pmHundredthsRd;
    result.amTenthsPercent = configuration.amTenthsPercent;
    result.modulationMode = uint8_t(configuration.modulationMode);
    result.modulationSource = uint8_t(configuration.modulationSource);
    result.amplitudeDisplayUnit = uint8_t(configuration.amplitudeDisplayUnit);
    result.flags = configuration.rfOff ? kRfOffFlag : 0u;
    return result;
}

control::OutputConfiguration decodeOutput(const PersistentOutput& payload)
{
    control::OutputConfiguration result = {};
    result.frequencyHz = payload.frequencyHz;
    result.fmHz = payload.fmHz;
    result.amplitudeTenthsDbm = payload.amplitudeTenthsDbm;
    result.pmHundredthsRd = payload.pmHundredthsRd;
    result.amTenthsPercent = payload.amTenthsPercent;
    result.modulationMode = control::ModulationMode(payload.modulationMode);
    result.modulationSource = control::ModulationSource(payload.modulationSource);
    result.amplitudeDisplayUnit =
        control::AmplitudeDisplayUnit(payload.amplitudeDisplayUnit);
    result.rfOff = (payload.flags & kRfOffFlag) != 0u;
    return result;
}

PersistentPayloadV3 encodeSettings(const control::Settings& settings)
{
    PersistentPayloadV3 result = {};
    result.output = encodeOutput(settings.output);
    result.target = uint8_t(settings.target);
    result.wheelTarget = uint8_t(settings.wheelTarget);
    result.frequencyStepIndex = settings.frequencyStepIndex;
    result.amplitudeStepIndex = settings.amplitudeStepIndex;
    result.fmStepIndex = settings.fmStepIndex;
    result.pmStepIndex = settings.pmStepIndex;
    result.amStepIndex = settings.amStepIndex;
    result.flags = settings.wheelInhibited ? kWheelInhibitedFlag : 0u;
    return result;
}

control::Settings decodeSettings(const PersistentPayloadV3& payload)
{
    control::Settings result = {};
    result.output = decodeOutput(payload.output);
    result.target = control::Target(payload.target);
    result.wheelTarget = control::Target(payload.wheelTarget);
    result.frequencyStepIndex = payload.frequencyStepIndex;
    result.amplitudeStepIndex = payload.amplitudeStepIndex;
    result.fmStepIndex = payload.fmStepIndex;
    result.pmStepIndex = payload.pmStepIndex;
    result.amStepIndex = payload.amStepIndex;
    result.wheelInhibited = (payload.flags & kWheelInhibitedFlag) != 0u;
    return result;
}

control::Settings decodeLegacy(const LegacyPayloadV2& payload)
{
    control::Settings result = {};
    result.output.frequencyHz = payload.frequencyHz;
    result.output.fmHz = payload.fmHz;
    result.output.amplitudeTenthsDbm = payload.amplitudeTenthsDbm;
    result.output.pmHundredthsRd = payload.pmHundredthsRd;
    result.output.amTenthsPercent = payload.amTenthsPercent;
    result.output.modulationMode = control::ModulationMode(payload.modulationMode);
    result.output.modulationSource =
        control::ModulationSource(payload.modulationSource);
    result.output.amplitudeDisplayUnit = control::AmplitudeDisplayUnit::DBm;
    result.output.rfOff = (payload.flags & (1u << 1)) != 0u;
    result.target = control::Target(payload.target);
    result.wheelTarget = control::Target(payload.wheelTarget);
    result.frequencyStepIndex = payload.frequencyStepIndex;
    result.amplitudeStepIndex = payload.amplitudeStepIndex;
    result.fmStepIndex = payload.fmStepIndex;
    result.pmStepIndex = payload.pmStepIndex;
    result.amStepIndex = payload.amStepIndex;
    result.wheelInhibited = (payload.flags & kWheelInhibitedFlag) != 0u;
    return result;
}

bool validV3(const PersistentRecordV3& record, control::Settings* decoded)
{
    if (record.magic != kSettingsMagic || record.version != kSettingsVersion ||
        record.crc != recordCrc(record)) {
        return false;
    }
    *decoded = decodeSettings(record.payload);
    return control::settingsAreValid(*decoded);
}

bool validLegacy(const LegacyRecordV2& record, control::Settings* decoded)
{
    if (record.magic != kSettingsMagic ||
        record.version != kLegacySettingsVersion ||
        record.crc != recordCrc(record)) {
        return false;
    }
    *decoded = decodeLegacy(record.payload);
    return control::settingsAreValid(*decoded);
}

template <typename Record>
void updateRecord(int address, const Record& record)
{
    const uint8_t* bytes = reinterpret_cast<const uint8_t*>(&record);
    for (size_t i = 0; i < sizeof(Record); ++i) {
        EEPROM.update(address + int(i), bytes[i]);
    }
}

}  // namespace

SettingsStore settingsStore;

bool SettingsStore::load(control::Settings* settings)
{
    if (settings == nullptr) {
        return false;
    }

    PersistentRecordV3 records[kSlotCount] = {};
    control::Settings decoded[kSlotCount] = {};
    bool valid[kSlotCount] = {};
    for (uint8_t slot = 0; slot < kSlotCount; ++slot) {
        EEPROM.get(settingsSlotAddress(slot), records[slot]);
        valid[slot] = validV3(records[slot], &decoded[slot]);
    }
    if (valid[0] || valid[1]) {
        activeSlot_ = valid[1] &&
                      (!valid[0] || generationIsNewer(records[1].generation,
                                                       records[0].generation))
            ? 1u
            : 0u;
        *settings = decoded[activeSlot_];
        generation_ = records[activeSlot_].generation;
        hasValidSlot_ = true;
        return true;
    }

    LegacyRecordV2 legacy[kSlotCount] = {};
    bool legacyValid[kSlotCount] = {};
    for (uint8_t slot = 0; slot < kSlotCount; ++slot) {
        EEPROM.get(legacySlotAddress(slot), legacy[slot]);
        legacyValid[slot] = validLegacy(legacy[slot], &decoded[slot]);
    }
    if (!legacyValid[0] && !legacyValid[1]) {
        return false;
    }
    const uint8_t selected = legacyValid[1] &&
                             (!legacyValid[0] ||
                              generationIsNewer(legacy[1].generation,
                                                legacy[0].generation))
        ? 1u
        : 0u;
    *settings = decoded[selected];
    generation_ = legacy[selected].generation;
    hasValidSlot_ = false;
    return true;
}

bool SettingsStore::saveNow(const control::Settings& settings)
{
    if (!control::settingsAreValid(settings)) {
        return false;
    }

    PersistentRecordV3 record = {};
    record.magic = kSettingsMagic;
    record.version = kSettingsVersion;
    record.generation = uint16_t(generation_ + 1u);
    record.payload = encodeSettings(settings);
    record.crc = recordCrc(record);

    const uint8_t destination = hasValidSlot_ ? uint8_t(activeSlot_ ^ 1u) : 0u;
    const int address = settingsSlotAddress(destination);
    updateRecord(address, record);

    PersistentRecordV3 verification = {};
    control::Settings decoded = {};
    EEPROM.get(address, verification);
    if (!validV3(verification, &decoded)) {
        return false;
    }
    generation_ = verification.generation;
    activeSlot_ = destination;
    hasValidSlot_ = true;
    return true;
}

bool SettingsStore::loadMemory(uint8_t index,
                               control::OutputConfiguration* configuration)
{
    if (index >= kMemoryCount || configuration == nullptr) {
        return false;
    }
    MemoryRecord record = {};
    EEPROM.get(memoryAddress(index), record);
    if (record.magic != kMemoryMagic || record.version != kMemoryVersion ||
        record.index != index || record.crc != recordCrc(record)) {
        return false;
    }
    const control::OutputConfiguration decoded = decodeOutput(record.output);
    if (!control::outputConfigurationIsValid(decoded)) {
        return false;
    }
    *configuration = decoded;
    return true;
}

bool SettingsStore::saveMemory(uint8_t index,
                               const control::OutputConfiguration& configuration)
{
    if (index >= kMemoryCount ||
        !control::outputConfigurationIsValid(configuration)) {
        return false;
    }
    MemoryRecord record = {};
    record.magic = kMemoryMagic;
    record.version = kMemoryVersion;
    record.index = index;
    record.output = encodeOutput(configuration);
    record.crc = recordCrc(record);
    const int address = memoryAddress(index);
    updateRecord(address, record);

    MemoryRecord verification = {};
    EEPROM.get(address, verification);
    return verification.magic == kMemoryMagic &&
           verification.version == kMemoryVersion &&
           verification.index == index &&
           verification.crc == recordCrc(verification);
}

}  // namespace adret
