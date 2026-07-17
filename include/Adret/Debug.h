#pragma once

#ifndef ADRET_DEBUG_SERIAL
#define ADRET_DEBUG_SERIAL 0
#endif

#ifndef ADRET_REMOTE_SERIAL
#define ADRET_REMOTE_SERIAL 0
#endif

#if ADRET_DEBUG_SERIAL != 0 && ADRET_DEBUG_SERIAL != 1
#error "ADRET_DEBUG_SERIAL must be 0 or 1"
#endif

#if ADRET_REMOTE_SERIAL != 0 && ADRET_REMOTE_SERIAL != 1
#error "ADRET_REMOTE_SERIAL must be 0 or 1"
#endif

#if ADRET_DEBUG_SERIAL && ADRET_REMOTE_SERIAL
#error "Serial0 diagnostics and remote protocol are mutually exclusive"
#endif
