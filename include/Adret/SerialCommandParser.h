#pragma once

#include <stdint.h>

#include "Adret/OperatingController.h"

namespace adret {
namespace serial_protocol {

enum class ErrorCode : uint8_t {
    None = 0xFFu,
    E00 = 0u,
    E21 = 21u,
    E22 = 22u,
    E41 = 41u,
    E42 = 42u,
    E61 = 61u,
    E62 = 62u,
    E64 = 64u,
    E71 = 71u,
    E72 = 72u,
    E74 = 74u,
    E77 = 77u,
    E89 = 89u,
    E91 = 91u,
};

enum class ExecutionMarker : uint8_t {
    LineEnding,
    QuestionMark,
};

enum class FrameEvent : uint8_t {
    None,
    Execute,
    Defer,
    Overflow,
};

struct FrameResult {
    FrameEvent event;
    ExecutionMarker marker;
    const char* text;
    uint8_t length;
};

class MessageFramer final {
public:
    static constexpr uint8_t kMaximumMessageLength = 128u;

    MessageFramer() = default;
    void reset();
    FrameResult consume(char value);

private:
    enum class TailState : uint8_t {
        None,
        IgnoreOptionalLf,
        IgnoreLineEnding,
    };

    FrameResult finish(FrameEvent event, ExecutionMarker marker);

    char message_[kMaximumMessageLength + 1u] = {};
    uint8_t length_ = 0u;
    bool overflow_ = false;
    TailState tailState_ = TailState::None;
};

enum class SequenceAction : uint8_t {
    None,
    Define,
    Clear,
};

struct RemoteState {
    bool remoteEnabled;
    bool localLockout;
};

struct Transaction {
    control::OutputConfiguration output;
    RemoteState remoteState;
    bool outputChanged;
    bool hasSettingCommand;
    bool storeMemory;
    uint8_t storeMemoryIndex;
    SequenceAction sequenceAction;
    uint8_t sequenceStart;
    uint8_t sequenceEnd;
};

using MemoryLoader = bool (*)(void* context,
                              uint8_t index,
                              control::OutputConfiguration* configuration);

struct ParseContext {
    MemoryLoader loadMemory;
    void* memoryContext;
};

struct ParseResult {
    ErrorCode error;
    bool statusQuery;
    int8_t memoryErrorIndex;
    Transaction transaction;
};

Transaction initialTransaction(const control::OutputConfiguration& output,
                               RemoteState state);

ParseResult parseCommand(const char* text,
                         uint8_t length,
                         ExecutionMarker marker,
                         const Transaction& base,
                         const ParseContext& context);

uint8_t makeStatusByte(RemoteState state,
                       bool serviceRequest,
                       bool errorLatched,
                       ErrorCode lastError);

}  // namespace serial_protocol
}  // namespace adret
