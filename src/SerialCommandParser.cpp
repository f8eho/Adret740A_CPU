#include "Adret/SerialCommandParser.h"

#include <limits.h>

namespace adret {
namespace serial_protocol {

namespace {

struct Cursor {
    const char* text;
    uint8_t length;
    uint8_t position;
};

struct DecimalNumber {
    uint64_t mantissa;
    int16_t exponent;
    bool negative;
    bool overflow;
};

enum class ScaleResult : uint8_t {
    Ok,
    Negative,
    TooLarge,
    Inexact,
};

bool asciiSpace(char value)
{
    return value == ' ' || value == '\t';
}

char asciiUpper(char value)
{
    return value >= 'a' && value <= 'z' ? char(value - ('a' - 'A')) : value;
}

void skipSpaces(Cursor* cursor)
{
    while (cursor->position < cursor->length &&
           asciiSpace(cursor->text[cursor->position])) {
        ++cursor->position;
    }
}

bool atEnd(Cursor* cursor)
{
    skipSpaces(cursor);
    return cursor->position == cursor->length;
}

bool matchMnemonic(Cursor* cursor, const char* mnemonic)
{
    uint8_t size = 0u;
    while (mnemonic[size] != '\0') {
        ++size;
    }
    if (uint16_t(cursor->position) + size > cursor->length) {
        return false;
    }
    for (uint8_t i = 0u; i < size; ++i) {
        if (asciiUpper(cursor->text[uint8_t(cursor->position + i)]) !=
            mnemonic[i]) {
            return false;
        }
    }
    cursor->position = uint8_t(cursor->position + size);
    return true;
}

bool exactQueryMatches(const FrameResult& frame,
                       const char* mnemonic,
                       uint8_t mnemonicLength)
{
    if (frame.marker != ExecutionMarker::QuestionMark) {
        return false;
    }
    uint8_t position = 0u;
    while (position < frame.length && asciiSpace(frame.text[position])) {
        ++position;
    }
    for (uint8_t i = 0u; i < mnemonicLength; ++i) {
        if (position >= frame.length ||
            asciiUpper(frame.text[position++]) != mnemonic[i]) {
            return false;
        }
    }
    while (position < frame.length && asciiSpace(frame.text[position])) {
        ++position;
    }
    return position == frame.length;
}

bool parseDecimal(Cursor* cursor, DecimalNumber* result)
{
    skipSpaces(cursor);
    DecimalNumber value = {};
    if (cursor->position < cursor->length &&
        (cursor->text[cursor->position] == '+' ||
         cursor->text[cursor->position] == '-')) {
        value.negative = cursor->text[cursor->position] == '-';
        ++cursor->position;
        skipSpaces(cursor);
    }

    bool haveDigit = false;
    bool havePoint = false;
    int16_t fractionalDigits = 0;
    while (cursor->position < cursor->length) {
        const char current = cursor->text[cursor->position];
        if (current >= '0' && current <= '9') {
            haveDigit = true;
            const uint8_t digit = uint8_t(current - '0');
            if (value.mantissa > (UINT64_MAX - digit) / 10u) {
                value.overflow = true;
            } else if (!value.overflow) {
                value.mantissa = value.mantissa * 10u + digit;
            }
            if (havePoint && fractionalDigits < INT16_MAX) {
                ++fractionalDigits;
            }
            ++cursor->position;
            continue;
        }
        if (current == '.' && !havePoint) {
            havePoint = true;
            ++cursor->position;
            continue;
        }
        break;
    }
    if (!haveDigit) {
        return false;
    }

    int16_t explicitExponent = 0;
    if (cursor->position < cursor->length &&
        asciiUpper(cursor->text[cursor->position]) == 'E') {
        ++cursor->position;
        bool exponentNegative = false;
        if (cursor->position < cursor->length &&
            (cursor->text[cursor->position] == '+' ||
             cursor->text[cursor->position] == '-')) {
            exponentNegative = cursor->text[cursor->position] == '-';
            ++cursor->position;
        }
        bool haveExponentDigit = false;
        int16_t exponentMagnitude = 0;
        while (cursor->position < cursor->length) {
            const char current = cursor->text[cursor->position];
            if (current < '0' || current > '9') {
                break;
            }
            haveExponentDigit = true;
            if (exponentMagnitude < 1000) {
                exponentMagnitude = int16_t(exponentMagnitude * 10 +
                                            (current - '0'));
            }
            ++cursor->position;
        }
        if (!haveExponentDigit) {
            return false;
        } else {
            explicitExponent = exponentNegative
                ? int16_t(-exponentMagnitude) : exponentMagnitude;
        }
    }

    const int32_t combined = int32_t(explicitExponent) - fractionalDigits;
    if (combined > INT16_MAX) {
        value.exponent = INT16_MAX;
        value.overflow = true;
    } else if (combined < INT16_MIN) {
        value.exponent = INT16_MIN;
    } else {
        value.exponent = int16_t(combined);
    }
    *result = value;
    return true;
}

ScaleResult scaledUnsigned(const DecimalNumber& number,
                           uint32_t multiplier,
                           bool exact,
                           uint32_t* result)
{
    if (number.negative && number.mantissa != 0u) {
        return ScaleResult::Negative;
    }
    if (number.overflow) {
        return ScaleResult::TooLarge;
    }
    uint64_t value = number.mantissa;
    if (value > UINT64_MAX / multiplier) {
        return ScaleResult::TooLarge;
    }
    value *= multiplier;
    if (value == 0u) {
        *result = 0u;
        return ScaleResult::Ok;
    }
    if (number.exponent >= 0) {
        if (number.exponent > 19) {
            return ScaleResult::TooLarge;
        }
        for (int16_t i = 0; i < number.exponent; ++i) {
            if (value > UINT64_MAX / 10u) {
                return ScaleResult::TooLarge;
            }
            value *= 10u;
        }
    } else {
        int32_t divisorDigits = -int32_t(number.exponent);
        while (divisorDigits > 0) {
            if (exact && (value % 10u) != 0u) {
                return ScaleResult::Inexact;
            }
            value /= 10u;
            --divisorDigits;
            if (value == 0u && divisorDigits > 0) {
                break;
            }
        }
    }
    if (value > UINT32_MAX) {
        return ScaleResult::TooLarge;
    }
    *result = uint32_t(value);
    return ScaleResult::Ok;
}

bool parseMode(Cursor* cursor, uint8_t* mode)
{
    DecimalNumber number = {};
    uint32_t value = 0u;
    return parseDecimal(cursor, &number) &&
           scaledUnsigned(number, 1u, true, &value) == ScaleResult::Ok &&
           value <= 3u && ((*mode = uint8_t(value)), true);
}

bool parseBinary(Cursor* cursor, bool* enabled)
{
    DecimalNumber number = {};
    uint32_t value = 0u;
    return parseDecimal(cursor, &number) &&
           scaledUnsigned(number, 1u, true, &value) == ScaleResult::Ok &&
           value <= 1u && ((*enabled = value != 0u), true);
}

bool parseTwoDigits(Cursor* cursor, uint8_t* value)
{
    skipSpaces(cursor);
    if (uint16_t(cursor->position) + 2u > cursor->length) {
        return false;
    }
    const char first = cursor->text[cursor->position];
    const char second = cursor->text[uint8_t(cursor->position + 1u)];
    if (first < '0' || first > '9' || second < '0' || second > '9') {
        return false;
    }
    cursor->position = uint8_t(cursor->position + 2u);
    *value = uint8_t((first - '0') * 10 + (second - '0'));
    return true;
}

control::ModulationSource sourceForMode(uint8_t mode)
{
    return mode == 0u ? control::ModulationSource::Cw
        : mode == 1u ? control::ModulationSource::External
        : mode == 2u ? control::ModulationSource::KHz1
                     : control::ModulationSource::Hz400;
}

ErrorCode parseFrequency(Cursor* cursor,
                         uint32_t maximumFrequencyHz,
                         Transaction* transaction)
{
    DecimalNumber number = {};
    uint32_t value = 0u;
    if (!parseDecimal(cursor, &number)) {
        return ErrorCode::E00;
    }
    const ScaleResult scaled = scaledUnsigned(number, 1u, false, &value);
    if (scaled == ScaleResult::Negative) {
        return ErrorCode::E22;
    }
    if (scaled != ScaleResult::Ok || value > maximumFrequencyHz) {
        return ErrorCode::E21;
    }
    value -= value % 10u;
    if (value < control::kFrequencyMinimumHz) {
        return ErrorCode::E22;
    }
    transaction->output.frequencyHz = value;
    transaction->outputChanged = true;
    transaction->hasSettingCommand = true;
    return ErrorCode::None;
}

ErrorCode parseAmplitude(Cursor* cursor, Transaction* transaction)
{
    DecimalNumber number = {};
    uint32_t magnitude = 0u;
    if (!parseDecimal(cursor, &number)) {
        return ErrorCode::E00;
    }
    const ScaleResult scaled = scaledUnsigned(
        DecimalNumber{number.mantissa, number.exponent, false, number.overflow},
        10u, true, &magnitude);
    if (scaled == ScaleResult::TooLarge) {
        return number.negative ? ErrorCode::E42 : ErrorCode::E41;
    }
    if (scaled != ScaleResult::Ok) {
        return ErrorCode::E00;
    }
    if (number.negative) {
        const uint32_t maximumMagnitude =
            uint32_t(-int32_t(control::kAmplitudeMinimumTenthsDbm));
        if (magnitude > maximumMagnitude) {
            return ErrorCode::E42;
        }
    } else if (magnitude >
               uint32_t(control::kAmplitudeMaximumTenthsDbm)) {
        return ErrorCode::E41;
    }
    const int32_t signedValue = number.negative ? -int32_t(magnitude)
                                                : int32_t(magnitude);
    transaction->output.amplitudeTenthsDbm = int16_t(signedValue);
    transaction->output.amplitudeDisplayUnit = control::AmplitudeDisplayUnit::DBm;
    transaction->outputChanged = true;
    transaction->hasSettingCommand = true;
    return ErrorCode::None;
}

ErrorCode parseFmDeviation(Cursor* cursor, Transaction* transaction)
{
    DecimalNumber number = {};
    uint32_t value = 0u;
    if (!parseDecimal(cursor, &number)) {
        return ErrorCode::E00;
    }
    const ScaleResult scaled = scaledUnsigned(number, 1000u, false, &value);
    if (scaled == ScaleResult::Negative) {
        return ErrorCode::E72;
    }
    if (scaled != ScaleResult::Ok) {
        return ErrorCode::E71;
    }
    const uint32_t resolution = value < control::kFmFineRangeMaximumHz
        ? 10u : 100u;
    value -= value % resolution;
    if (value > control::kFmMaximumHz) {
        return ErrorCode::E71;
    }
    transaction->output.fmHz = value;
    transaction->outputChanged = true;
    transaction->hasSettingCommand = true;
    return ErrorCode::None;
}

ErrorCode parsePmDeviation(Cursor* cursor, Transaction* transaction)
{
    DecimalNumber number = {};
    uint32_t value = 0u;
    if (!parseDecimal(cursor, &number)) {
        return ErrorCode::E00;
    }
    const ScaleResult scaled = scaledUnsigned(number, 100u, true, &value);
    if (scaled == ScaleResult::Negative) {
        return ErrorCode::E72;
    }
    if (scaled == ScaleResult::TooLarge ||
        value > control::kPmMaximumHundredthsRd) {
        return ErrorCode::E71;
    }
    if (scaled != ScaleResult::Ok) {
        return ErrorCode::E00;
    }
    transaction->output.pmHundredthsRd = uint16_t(value);
    transaction->outputChanged = true;
    transaction->hasSettingCommand = true;
    return ErrorCode::None;
}

ErrorCode parseAmRate(Cursor* cursor, Transaction* transaction)
{
    DecimalNumber number = {};
    uint32_t value = 0u;
    if (!parseDecimal(cursor, &number)) {
        return ErrorCode::E00;
    }
    const ScaleResult scaled = scaledUnsigned(number, 10u, true, &value);
    if (scaled == ScaleResult::Negative) {
        return ErrorCode::E62;
    }
    if (scaled == ScaleResult::TooLarge ||
        value > control::kAmMaximumTenthsPercent) {
        return ErrorCode::E61;
    }
    if (scaled != ScaleResult::Ok) {
        return ErrorCode::E00;
    }
    transaction->output.amTenthsPercent = uint16_t(value);
    transaction->outputChanged = true;
    transaction->hasSettingCommand = true;
    return ErrorCode::None;
}

bool requireRemote(const Transaction& transaction)
{
    return transaction.remoteState.remoteEnabled;
}

}  // namespace

ReadOnlyQuery readOnlyQuery(const FrameResult& frame)
{
    if (exactQueryMatches(frame, "STB", 3u)) {
        return ReadOnlyQuery::Status;
    }
    if (exactQueryMatches(frame, "IB", 2u)) {
        return ReadOnlyQuery::InstrumentBus;
    }
    if (exactQueryMatches(frame, "BUILD", 5u)) {
        return ReadOnlyQuery::Build;
    }
    if (exactQueryMatches(frame, "OPT", 3u)) {
        return ReadOnlyQuery::Options;
    }
    return ReadOnlyQuery::None;
}

void MessageFramer::reset()
{
    length_ = 0u;
    message_[0] = '\0';
    overflow_ = false;
    tailState_ = TailState::None;
}

FrameResult MessageFramer::consume(char value)
{
    if (tailState_ == TailState::IgnoreOptionalLf) {
        tailState_ = TailState::None;
        if (value == '\n') {
            return {FrameEvent::None, ExecutionMarker::LineEnding, nullptr, 0u};
        }
    } else if (tailState_ == TailState::IgnoreLineEnding) {
        tailState_ = TailState::None;
        if (value == '\r') {
            tailState_ = TailState::IgnoreOptionalLf;
            return {FrameEvent::None, ExecutionMarker::LineEnding, nullptr, 0u};
        }
        if (value == '\n') {
            return {FrameEvent::None, ExecutionMarker::LineEnding, nullptr, 0u};
        }
    }

    if (value == '\r') {
        const FrameResult result = finish(FrameEvent::Execute,
                                          ExecutionMarker::LineEnding);
        tailState_ = TailState::IgnoreOptionalLf;
        return result;
    }
    if (value == '\n') {
        return finish(FrameEvent::Execute, ExecutionMarker::LineEnding);
    }
    if (value == '?') {
        const FrameResult result = finish(FrameEvent::Execute,
                                          ExecutionMarker::QuestionMark);
        tailState_ = TailState::IgnoreLineEnding;
        return result;
    }
    if (value == '!') {
        const FrameResult result = finish(FrameEvent::Defer,
                                          ExecutionMarker::LineEnding);
        tailState_ = TailState::IgnoreLineEnding;
        return result;
    }

    if (length_ < kMaximumMessageLength) {
        message_[length_++] = value;
        message_[length_] = '\0';
    } else {
        overflow_ = true;
    }
    return {FrameEvent::None, ExecutionMarker::LineEnding, nullptr, 0u};
}

FrameResult MessageFramer::finish(FrameEvent event, ExecutionMarker marker)
{
    const FrameResult result = {
        overflow_ ? FrameEvent::Overflow : event,
        marker,
        message_,
        length_};
    length_ = 0u;
    overflow_ = false;
    return result;
}

Transaction initialTransaction(const control::OutputConfiguration& output,
                               RemoteState state)
{
    Transaction result = {};
    result.output = output;
    result.remoteState = state;
    result.sequenceAction = SequenceAction::None;
    return result;
}

ParseResult parseCommand(const char* text,
                         uint8_t length,
                         ExecutionMarker marker,
                         const Transaction& base,
                         const ParseContext& context)
{
    ParseResult result = {};
    result.error = ErrorCode::None;
    result.memoryErrorIndex = -1;
    result.transaction = base;
    Cursor cursor = {text, length, 0u};
    bool haveCommand = false;

    while (!atEnd(&cursor)) {
        if (result.transaction.storeMemory) {
            result.error = ErrorCode::E00;
            return result;
        }
        haveCommand = true;

        if (matchMnemonic(&cursor, "STB")) {
            if (marker != ExecutionMarker::QuestionMark ||
                !atEnd(&cursor) || result.transaction.outputChanged ||
                result.transaction.hasSettingCommand ||
                result.transaction.storeMemory ||
                result.transaction.sequenceAction != SequenceAction::None ||
                result.transaction.remoteState.remoteEnabled !=
                    base.remoteState.remoteEnabled ||
                result.transaction.remoteState.localLockout !=
                    base.remoteState.localLockout) {
                result.error = ErrorCode::E00;
                return result;
            }
            result.statusQuery = true;
            return result;
        }
        if (matchMnemonic(&cursor, "REN")) {
            bool enabled = false;
            if (!parseBinary(&cursor, &enabled)) {
                result.error = ErrorCode::E00;
                return result;
            }
            result.transaction.remoteState.remoteEnabled = enabled;
            continue;
        }
        if (matchMnemonic(&cursor, "LLO")) {
            bool enabled = false;
            if (!parseBinary(&cursor, &enabled)) {
                result.error = ErrorCode::E00;
                return result;
            }
            result.transaction.remoteState.localLockout = enabled;
            continue;
        }
        if (matchMnemonic(&cursor, "GTL")) {
            result.transaction.remoteState.remoteEnabled = false;
            continue;
        }

        if (!requireRemote(result.transaction)) {
            result.error = ErrorCode::E00;
            return result;
        }

        if (matchMnemonic(&cursor, "RF")) {
            bool enabled = false;
            if (!parseBinary(&cursor, &enabled)) {
                result.error = ErrorCode::E00;
                return result;
            }
            result.transaction.output.rfOff = !enabled;
            result.transaction.outputChanged = true;
            result.transaction.hasSettingCommand = true;
            continue;
        }
        if (matchMnemonic(&cursor, "RM")) {
            uint8_t index = 0u;
            if (!parseTwoDigits(&cursor, &index) || index >= 40u ||
                context.loadMemory == nullptr ||
                !context.loadMemory(context.memoryContext, index,
                                    &result.transaction.output)) {
                result.error = ErrorCode::E00;
                result.memoryErrorIndex = int8_t(index);
                return result;
            }
            if (result.transaction.output.frequencyHz >
                context.maximumFrequencyHz) {
                result.error = ErrorCode::E21;
                result.memoryErrorIndex = int8_t(index);
                return result;
            }
            result.transaction.outputChanged = true;
            result.transaction.hasSettingCommand = true;
            continue;
        }
        if (matchMnemonic(&cursor, "AM")) {
            uint8_t mode = 0u;
            if (!parseMode(&cursor, &mode)) {
                result.error = ErrorCode::E00;
                return result;
            }
            result.transaction.output.modulationMode = control::ModulationMode::Am;
            result.transaction.output.modulationSource = sourceForMode(mode);
            result.transaction.outputChanged = true;
            result.transaction.hasSettingCommand = true;
            continue;
        }
        if (matchMnemonic(&cursor, "FM")) {
            uint8_t mode = 0u;
            if (!parseMode(&cursor, &mode)) {
                result.error = ErrorCode::E00;
                return result;
            }
            result.transaction.output.modulationMode = control::ModulationMode::Fm;
            result.transaction.output.modulationSource = sourceForMode(mode);
            result.transaction.outputChanged = true;
            result.transaction.hasSettingCommand = true;
            continue;
        }
        if (matchMnemonic(&cursor, "PM")) {
            uint8_t mode = 0u;
            if (!parseMode(&cursor, &mode)) {
                result.error = ErrorCode::E00;
                return result;
            }
            result.transaction.output.modulationMode = control::ModulationMode::Pm;
            result.transaction.output.modulationSource = sourceForMode(mode);
            result.transaction.outputChanged = true;
            result.transaction.hasSettingCommand = true;
            continue;
        }
        if (matchMnemonic(&cursor, "SL")) {
            DecimalNumber number = {};
            uint32_t value = 0u;
            if (!parseDecimal(&cursor, &number) ||
                scaledUnsigned(number, 1u, true, &value) != ScaleResult::Ok) {
                result.error = ErrorCode::E00;
                return result;
            }
            if (value == 64u) {
                result.error = ErrorCode::E64;
                return result;
            }
            if (value != 60u) {
                result.error = ErrorCode::E00;
                return result;
            }
            result.transaction.hasSettingCommand = true;
            continue;
        }
        if (matchMnemonic(&cursor, "SQ")) {
            skipSpaces(&cursor);
            if (cursor.position < cursor.length &&
                cursor.text[cursor.position] == '0') {
                const uint8_t saved = cursor.position;
                ++cursor.position;
                if (atEnd(&cursor)) {
                    result.transaction.sequenceAction = SequenceAction::Clear;
                    result.transaction.hasSettingCommand = true;
                    continue;
                }
                cursor.position = saved;
            }
            uint8_t start = 0u;
            uint8_t end = 0u;
            if (!parseTwoDigits(&cursor, &start) ||
                !parseTwoDigits(&cursor, &end) || start >= 40u ||
                end >= 40u || start > end) {
                result.error = ErrorCode::E89;
                return result;
            }
            result.transaction.sequenceAction = SequenceAction::Define;
            result.transaction.sequenceStart = start;
            result.transaction.sequenceEnd = end;
            result.transaction.hasSettingCommand = true;
            continue;
        }
        if (matchMnemonic(&cursor, "F")) {
            result.error = parseFrequency(&cursor,
                                          context.maximumFrequencyHz,
                                          &result.transaction);
        } else if (matchMnemonic(&cursor, "A")) {
            result.error = parseAmplitude(&cursor, &result.transaction);
        } else if (matchMnemonic(&cursor, "D")) {
            result.error = parseFmDeviation(&cursor, &result.transaction);
        } else if (matchMnemonic(&cursor, "P")) {
            result.error = parsePmDeviation(&cursor, &result.transaction);
        } else if (matchMnemonic(&cursor, "M")) {
            uint8_t index = 0u;
            if (!parseTwoDigits(&cursor, &index) || index >= 40u ||
                !atEnd(&cursor)) {
                result.error = ErrorCode::E00;
            } else {
                result.transaction.storeMemory = true;
                result.transaction.storeMemoryIndex = index;
                result.transaction.hasSettingCommand = true;
            }
        } else if (cursor.text[cursor.position] == '%') {
            ++cursor.position;
            result.error = parseAmRate(&cursor, &result.transaction);
        } else {
            result.error = ErrorCode::E00;
        }
        if (result.error != ErrorCode::None) {
            return result;
        }
    }

    if (!haveCommand) {
        result.error = ErrorCode::E00;
    }
    return result;
}

uint8_t makeStatusByte(RemoteState state,
                       bool serviceRequest,
                       bool errorLatched,
                       ErrorCode lastError)
{
    uint8_t result = 0u;
    if (serviceRequest) {
        result |= 64u;
    }
    if (errorLatched) {
        result |= 32u;
        result |= uint8_t(uint8_t(lastError) / 10u) & 0x0Fu;
    }
    if (state.remoteEnabled) {
        result |= 16u;
    }
    return result;
}

}  // namespace serial_protocol
}  // namespace adret
