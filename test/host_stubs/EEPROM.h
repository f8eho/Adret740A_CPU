#pragma once

#include <stddef.h>
#include <stdint.h>
#include <string.h>

class EEPROMClass final {
public:
    uint8_t bytes[4096] = {};
    int writesRemaining = -1;
    int writesPerformed = 0;
    bool powerLost = false;

    uint8_t read(int address) const
    {
        return bytes[address];
    }

    void update(int address, uint8_t value)
    {
        if (powerLost || bytes[address] == value) {
            return;
        }
        if (writesRemaining == 0) {
            powerLost = true;
            return;
        }
        if (writesRemaining > 0) {
            --writesRemaining;
        }
        bytes[address] = value;
        ++writesPerformed;
    }

    template <typename T>
    T& get(int address, T& value) const
    {
        memcpy(&value, bytes + address, sizeof(T));
        return value;
    }
};

extern EEPROMClass EEPROM;
