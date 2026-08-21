#include <Arduino.h>
#include <Wire.h>

#include "Adret/HardwareConfig.h"

#if ADRET_I2C_PROBE

namespace {

constexpr uint8_t kMcp23017FirstAddress = 0x20u;
constexpr uint8_t kMcp23017LastAddress = 0x27u;
constexpr uint8_t kIodirA = 0x00u;
constexpr uint8_t kIodirB = 0x01u;
constexpr uint8_t kIocon = 0x0Au;
constexpr uint8_t kOlatA = 0x14u;
constexpr uint8_t kOlatB = 0x15u;
constexpr uint32_t kProbeStandardClockHz = 100000UL;
constexpr uint32_t kProbeMaximumClockHz = 1000000UL;
constexpr uint16_t kReliabilityCyclesPerStep = 50u;
constexpr uint16_t kReliabilityFinalCycles = 1000u;
constexpr uint8_t kReliabilityClockCount = 13u;

// Exact ATmega1280/2560 TWI rates for F_CPU=16 MHz and prescaler=1, ordered from
// TWBR=12 (400 kHz) through TWBR=0 (1 MHz).
constexpr uint32_t kReliabilityClocksHz[kReliabilityClockCount] = {
    400000UL, 421052UL, 444444UL, 470588UL, 500000UL,
    533333UL, 571428UL, 615384UL, 666666UL, 727272UL,
    800000UL, 888888UL, 1000000UL
};

uint32_t probeClockHz = kProbeStandardClockHz;

void printHexByte(uint8_t value)
{
    if (value < 0x10u) {
        Serial.print('0');
    }
    Serial.print(value, HEX);
}

bool selectRegister(uint8_t deviceAddress, uint8_t registerAddress)
{
    Wire.clearWireTimeoutFlag();
    Wire.beginTransmission(deviceAddress);
    if (Wire.write(registerAddress) != 1u) {
        return false;
    }
    return Wire.endTransmission(false) == 0u && !Wire.getWireTimeoutFlag();
}

bool readRegister(uint8_t deviceAddress,
                  uint8_t registerAddress,
                  uint8_t* value)
{
    if (!selectRegister(deviceAddress, registerAddress)) {
        return false;
    }
    const uint8_t received = Wire.requestFrom(deviceAddress, uint8_t(1u),
                                              uint8_t(true));
    if (received != 1u || Wire.getWireTimeoutFlag() || Wire.available() != 1) {
        return false;
    }
    *value = uint8_t(Wire.read());
    return true;
}

bool writeRegister(uint8_t deviceAddress,
                   uint8_t registerAddress,
                   uint8_t value)
{
    Wire.clearWireTimeoutFlag();
    Wire.beginTransmission(deviceAddress);
    if (Wire.write(registerAddress) != 1u || Wire.write(value) != 1u) {
        return false;
    }
    return Wire.endTransmission(true) == 0u && !Wire.getWireTimeoutFlag();
}

uint8_t probeResult(uint8_t deviceAddress)
{
    Wire.clearWireTimeoutFlag();
    Wire.beginTransmission(deviceAddress);
    const uint8_t result = Wire.endTransmission(true);
    if (Wire.getWireTimeoutFlag()) {
        return 0xFFu;
    }
    return result;
}

bool probeAddress(uint8_t deviceAddress)
{
    return probeResult(deviceAddress) == 0u;
}

void printRegister(const __FlashStringHelper* name, uint8_t value)
{
    Serial.print(name);
    Serial.print(F("=0x"));
    printHexByte(value);
    Serial.print(' ');
}

void printI2cLineState()
{
    Serial.print(F("Etat cote Mega: SDA="));
    Serial.print(digitalRead(SDA) == HIGH ? F("HAUT") : F("BAS"));
    Serial.print(F(" SCL="));
    Serial.println(digitalRead(SCL) == HIGH ? F("HAUT") : F("BAS"));
}

void testMcp23017(uint8_t deviceAddress)
{
    uint8_t iodirA = 0u;
    uint8_t iodirB = 0u;
    uint8_t iocon = 0u;
    uint8_t olatA = 0u;
    uint8_t olatB = 0u;
    const bool registersRead =
        readRegister(deviceAddress, kIodirA, &iodirA) &&
        readRegister(deviceAddress, kIodirB, &iodirB) &&
        readRegister(deviceAddress, kIocon, &iocon) &&
        readRegister(deviceAddress, kOlatA, &olatA) &&
        readRegister(deviceAddress, kOlatB, &olatB);

    if (!registersRead) {
        Serial.println(F("  lecture des registres: ECHEC"));
        return;
    }

    Serial.print(F("  registres: "));
    printRegister(F("IODIRA"), iodirA);
    printRegister(F("IODIRB"), iodirB);
    printRegister(F("IOCON"), iocon);
    printRegister(F("OLATA"), olatA);
    printRegister(F("OLATB"), olatB);
    Serial.println();

    // Only exercise an output latch while every pin is confirmed as an input.
    // This proves both I2C directions without driving the future instrument bus.
    if (iodirA != 0xFFu || iodirB != 0xFFu) {
        Serial.println(F("  test ecriture ignore: certaines GPIO sont sorties"));
        return;
    }

    const uint8_t testValue = uint8_t(olatA ^ 0xA5u);
    uint8_t readBack = 0u;
    uint8_t restored = 0u;
    const bool testOk =
        writeRegister(deviceAddress, kOlatA, testValue) &&
        readRegister(deviceAddress, kOlatA, &readBack) &&
        readBack == testValue &&
        writeRegister(deviceAddress, kOlatA, olatA) &&
        readRegister(deviceAddress, kOlatA, &restored) &&
        restored == olatA;

    Serial.print(F("  lecture/ecriture OLATA, broches en entree: "));
    Serial.println(testOk ? F("OK") : F("ECHEC"));
}

bool testMcp23017Silently()
{
    if (probeResult(adret::hw::kInstrumentMcp23017Address) != 0u) {
        return false;
    }
    for (uint8_t address = uint8_t(kMcp23017FirstAddress + 1u);
         address <= kMcp23017LastAddress;
         ++address) {
        // A normal absent target produces an address NACK (Wire status 2).
        if (probeResult(address) != 2u) {
            return false;
        }
    }

    uint8_t iodirA = 0u;
    uint8_t iodirB = 0u;
    uint8_t olatA = 0u;
    if (!readRegister(adret::hw::kInstrumentMcp23017Address,
                      kIodirA, &iodirA) ||
        !readRegister(adret::hw::kInstrumentMcp23017Address,
                      kIodirB, &iodirB) ||
        !readRegister(adret::hw::kInstrumentMcp23017Address,
                      kOlatA, &olatA) ||
        iodirA != 0xFFu || iodirB != 0xFFu) {
        return false;
    }

    const uint8_t testValue = uint8_t(olatA ^ 0xA5u);
    uint8_t readBack = 0u;
    const bool writeOk =
        writeRegister(adret::hw::kInstrumentMcp23017Address,
                      kOlatA, testValue);
    const bool readOk = writeOk &&
        readRegister(adret::hw::kInstrumentMcp23017Address,
                     kOlatA, &readBack) &&
        readBack == testValue;

    // Restore the latch even when its readback failed. IODIRA remains 0xFF,
    // so no external pin is driven during this diagnostic.
    const bool restoreOk =
        writeRegister(adret::hw::kInstrumentMcp23017Address, kOlatA, olatA);
    uint8_t restored = 0u;
    const bool restoreReadOk = restoreOk &&
        readRegister(adret::hw::kInstrumentMcp23017Address,
                     kOlatA, &restored) &&
        restored == olatA;
    return readOk && restoreReadOk;
}

bool testClockReliability(uint32_t clockHz, uint16_t cycles)
{
    Wire.setClock(clockHz);
    for (uint16_t cycle = 0u; cycle < cycles; ++cycle) {
        if (!testMcp23017Silently()) {
            return false;
        }
    }
    return true;
}

void printClockResult(uint32_t clockHz, uint16_t cycles, bool passed)
{
    Serial.print(F("  "));
    Serial.print(clockHz);
    Serial.print(F(" Hz, "));
    Serial.print(cycles);
    Serial.print(F(" cycles: "));
    Serial.println(passed ? F("OK") : F("ECHEC"));
}

void runClockLimitSearch()
{
    Serial.println();
    Serial.println(F("Dichotomie I2C 400 kHz..1 MHz"));

    uint8_t goodIndex = 0u;
    uint8_t badIndex = uint8_t(kReliabilityClockCount - 1u);

    bool passed = testClockReliability(kReliabilityClocksHz[goodIndex],
                                       kReliabilityCyclesPerStep);
    printClockResult(kReliabilityClocksHz[goodIndex],
                     kReliabilityCyclesPerStep, passed);
    if (!passed) {
        Serial.println(F("ABANDON: 400 kHz n'est plus fiable."));
        Wire.setClock(adret::hw::kInstrumentI2cClockHz);
        probeClockHz = adret::hw::kInstrumentI2cClockHz;
        return;
    }

    passed = testClockReliability(kReliabilityClocksHz[badIndex],
                                  kReliabilityCyclesPerStep);
    printClockResult(kReliabilityClocksHz[badIndex],
                     kReliabilityCyclesPerStep, passed);
    if (passed) {
        goodIndex = badIndex;
    } else {
        while (uint8_t(badIndex - goodIndex) > 1u) {
            const uint8_t middle =
                uint8_t(goodIndex + uint8_t(badIndex - goodIndex) / 2u);
            passed = testClockReliability(kReliabilityClocksHz[middle],
                                          kReliabilityCyclesPerStep);
            printClockResult(kReliabilityClocksHz[middle],
                             kReliabilityCyclesPerStep, passed);
            if (passed) {
                goodIndex = middle;
            } else {
                badIndex = middle;
            }
        }
    }

    const bool finalPassed =
        testClockReliability(kReliabilityClocksHz[goodIndex],
                             kReliabilityFinalCycles);
    printClockResult(kReliabilityClocksHz[goodIndex],
                     kReliabilityFinalCycles, finalPassed);
    Serial.print(F("Limite fiable observee: "));
    Serial.print(kReliabilityClocksHz[goodIndex]);
    Serial.println(F(" Hz"));
    if (goodIndex + 1u < kReliabilityClockCount) {
        Serial.print(F("Premier palier en echec: "));
        Serial.print(kReliabilityClocksHz[uint8_t(goodIndex + 1u)]);
        Serial.println(F(" Hz"));
    }

    Wire.setClock(adret::hw::kInstrumentI2cClockHz);
    probeClockHz = adret::hw::kInstrumentI2cClockHz;
    Serial.println(F("Retour automatique a 400 kHz."));
}

void scanMcp23017Addresses()
{
    Serial.println();
    Serial.print(F("Recherche MCP23017 sur 0x20..0x27 (I2C "));
    Serial.print(probeClockHz / 1000UL);
    Serial.println(F(" kHz)"));
    printI2cLineState();
    uint8_t found = 0u;
    for (uint8_t address = kMcp23017FirstAddress;
         address <= kMcp23017LastAddress;
         ++address) {
        if (!probeAddress(address)) {
            continue;
        }
        ++found;
        Serial.print(F("Reponse a 0x"));
        printHexByte(address);
        if (address == adret::hw::kInstrumentMcp23017Address) {
            Serial.print(F(" (adresse firmware)"));
        }
        Serial.println();
        testMcp23017(address);
    }
    if (found == 0u) {
        Serial.println(F("Aucune reponse. Verifier alimentations, RESET et pull-up."));
        printI2cLineState();
    }
    Serial.println(F("Commandes: S=100 kHz, F=400 kHz, M=1 MHz, B=dichotomie."));
}

void runProbeAt(uint32_t clockHz)
{
    probeClockHz = clockHz;
    Wire.setClock(probeClockHz);
    scanMcp23017Addresses();
}

}  // namespace

void setup()
{
    Serial.begin(115200);
    Wire.begin();
    Wire.setClock(kProbeStandardClockHz);
    Wire.setWireTimeout(adret::hw::kInstrumentI2cTimeoutUs, true);
    delay(1000u);
    Serial.println(F("ADRET 740A - sonde ISO1540/MCP23017"));
    scanMcp23017Addresses();
}

void loop()
{
    if (Serial.available() <= 0) {
        return;
    }
    const char command = char(Serial.read());
    if (command == 's' || command == 'S') {
        runProbeAt(kProbeStandardClockHz);
    } else if (command == 'f' || command == 'F') {
        runProbeAt(adret::hw::kInstrumentI2cClockHz);
    } else if (command == 'm' || command == 'M') {
        runProbeAt(kProbeMaximumClockHz);
    } else if (command == 'b' || command == 'B') {
        runClockLimitSearch();
    }
}

#endif  // ADRET_I2C_PROBE
