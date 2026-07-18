#pragma once

#include <stdint.h>

#define PROGMEM

inline uint8_t pgm_read_byte(const void* address)
{
    return *static_cast<const uint8_t*>(address);
}
