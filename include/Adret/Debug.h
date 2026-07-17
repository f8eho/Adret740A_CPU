#pragma once

#ifndef ADRET_DEBUG_SERIAL
#define ADRET_DEBUG_SERIAL 0
#endif

#if ADRET_DEBUG_SERIAL != 0 && ADRET_DEBUG_SERIAL != 1
#error "ADRET_DEBUG_SERIAL must be 0 or 1"
#endif
