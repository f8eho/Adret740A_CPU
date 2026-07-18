#include <stdint.h>
#include <stdio.h>
#include <string.h>

#include "Adret/SerialCommandParser.h"

namespace {

using adret::control::AmplitudeDisplayUnit;
using adret::control::ModulationMode;
using adret::control::ModulationSource;
using adret::control::OutputConfiguration;
using adret::serial_protocol::ErrorCode;
using adret::serial_protocol::ExecutionMarker;
using adret::serial_protocol::FrameEvent;
using adret::serial_protocol::FrameResult;
using adret::serial_protocol::MessageFramer;
using adret::serial_protocol::ParseContext;
using adret::serial_protocol::ParseResult;
using adret::serial_protocol::RemoteState;
using adret::serial_protocol::SequenceAction;
using adret::serial_protocol::Transaction;

uint16_t failures = 0u;

#define CHECK(condition)                                                       \
    do {                                                                       \
        if (!(condition)) {                                                    \
            printf("FAIL line %d: %s\n", __LINE__, #condition);               \
            ++failures;                                                        \
        }                                                                      \
    } while (false)

struct FakeMemories {
    OutputConfiguration values[40];
    bool valid[40];
};

OutputConfiguration defaultOutput()
{
    OutputConfiguration output = {};
    output.frequencyHz = 100000u;
    output.amplitudeTenthsDbm = -1299;
    output.modulationMode = ModulationMode::Am;
    output.modulationSource = ModulationSource::Cw;
    output.amplitudeDisplayUnit = AmplitudeDisplayUnit::DBm;
    output.rfOff = true;
    return output;
}

bool loadMemory(void* context,
                uint8_t index,
                OutputConfiguration* configuration)
{
    FakeMemories* memories = static_cast<FakeMemories*>(context);
    if (index >= 40u || !memories->valid[index] || configuration == nullptr) {
        return false;
    }
    *configuration = memories->values[index];
    return true;
}

ParseResult parse(const char* text,
                  const Transaction& base,
                  FakeMemories* memories,
                  ExecutionMarker marker = ExecutionMarker::LineEnding)
{
    const ParseContext context = {&loadMemory, memories};
    return adret::serial_protocol::parseCommand(
        text, uint8_t(strlen(text)), marker, base, context);
}

Transaction localBase()
{
    return adret::serial_protocol::initialTransaction(
        defaultOutput(), RemoteState{false, false});
}

Transaction remoteBase()
{
    return adret::serial_protocol::initialTransaction(
        defaultOutput(), RemoteState{true, false});
}

void testModeAndGroupedConfiguration(FakeMemories* memories)
{
    const ParseResult result = parse(
        "rEn1 f118e6A -117 RF1 aM2 %50.5", localBase(), memories);
    CHECK(result.error == ErrorCode::None);
    CHECK(result.transaction.remoteState.remoteEnabled);
    CHECK(result.transaction.output.frequencyHz == 118000000u);
    CHECK(result.transaction.output.amplitudeTenthsDbm == -1170);
    CHECK(!result.transaction.output.rfOff);
    CHECK(result.transaction.output.modulationMode == ModulationMode::Am);
    CHECK(result.transaction.output.modulationSource == ModulationSource::KHz1);
    CHECK(result.transaction.output.amTenthsPercent == 505u);
    CHECK(result.transaction.outputChanged);
    CHECK(result.transaction.hasSettingCommand);
}

void testScalingAndModes(FakeMemories* memories)
{
    ParseResult result = parse("F123456", remoteBase(), memories);
    CHECK(result.error == ErrorCode::None);
    CHECK(result.transaction.output.frequencyHz == 123450u);

    result = parse("FM3D19.999", remoteBase(), memories);
    CHECK(result.error == ErrorCode::None);
    CHECK(result.transaction.output.modulationMode == ModulationMode::Fm);
    CHECK(result.transaction.output.modulationSource == ModulationSource::Hz400);
    CHECK(result.transaction.output.fmHz == 19990u);

    result = parse("D20.099", remoteBase(), memories);
    CHECK(result.error == ErrorCode::None);
    CHECK(result.transaction.output.fmHz == 20000u);

    result = parse("PM1P3.14", remoteBase(), memories);
    CHECK(result.error == ErrorCode::None);
    CHECK(result.transaction.output.pmHundredthsRd == 314u);
    CHECK(result.transaction.output.modulationSource == ModulationSource::External);

    result = parse("AM0%99.9", remoteBase(), memories);
    CHECK(result.error == ErrorCode::None);
    CHECK(result.transaction.output.modulationSource == ModulationSource::Cw);
    CHECK(result.transaction.output.amTenthsPercent == 999u);
}

void testErrorsAndAtomicBase(FakeMemories* memories)
{
    const Transaction base = remoteBase();
    ParseResult result = parse("F600e6", base, memories);
    CHECK(result.error == ErrorCode::E21);
    CHECK(base.output.frequencyHz == 100000u);

    result = parse("F99999", base, memories);
    CHECK(result.error == ErrorCode::E22);
    result = parse("A13.1", base, memories);
    CHECK(result.error == ErrorCode::E41);
    result = parse("A10000", base, memories);
    CHECK(result.error == ErrorCode::E41);
    result = parse("A-130", base, memories);
    CHECK(result.error == ErrorCode::E42);
    result = parse("A-10000", base, memories);
    CHECK(result.error == ErrorCode::E42);
    result = parse("A-45.25", base, memories);
    CHECK(result.error == ErrorCode::E00);
    result = parse("A - 45.2", base, memories);
    CHECK(result.error == ErrorCode::None);
    CHECK(result.transaction.output.amplitudeTenthsDbm == -452);
    result = parse("%-0.1", base, memories);
    CHECK(result.error == ErrorCode::E62);
    result = parse("%100", base, memories);
    CHECK(result.error == ErrorCode::E61);
    result = parse("D-0.01", base, memories);
    CHECK(result.error == ErrorCode::E72);
    result = parse("D199.9", base, memories);
    CHECK(result.error == ErrorCode::None);
    CHECK(result.transaction.output.fmHz == 199900u);
    result = parse("D199.99", base, memories);
    CHECK(result.error == ErrorCode::None);
    CHECK(result.transaction.output.fmHz == 199900u);
    result = parse("D200", base, memories);
    CHECK(result.error == ErrorCode::E71);
    result = parse("D200.1", base, memories);
    CHECK(result.error == ErrorCode::E71);
    result = parse("P20", base, memories);
    CHECK(result.error == ErrorCode::E71);
    result = parse("P0.001", base, memories);
    CHECK(result.error == ErrorCode::E00);
    result = parse("SL64", base, memories);
    CHECK(result.error == ErrorCode::E64);
    result = parse("UNKNOWN", base, memories);
    CHECK(result.error == ErrorCode::E00);
    result = parse("F1e100", base, memories);
    CHECK(result.error == ErrorCode::E21);
    result = parse("F118e", base, memories);
    CHECK(result.error == ErrorCode::E00);

    result = parse("F118e6", localBase(), memories);
    CHECK(result.error == ErrorCode::E00);
}

void testMemoriesAndSequences(FakeMemories* memories)
{
    memories->values[5] = defaultOutput();
    memories->values[5].frequencyHz = 25000000u;
    memories->valid[5] = true;

    ParseResult result = parse("RM05 A-20 M06", remoteBase(), memories);
    CHECK(result.error == ErrorCode::None);
    CHECK(result.transaction.output.frequencyHz == 25000000u);
    CHECK(result.transaction.output.amplitudeTenthsDbm == -200);
    CHECK(result.transaction.storeMemory);
    CHECK(result.transaction.storeMemoryIndex == 6u);

    result = parse("RM04", remoteBase(), memories);
    CHECK(result.error == ErrorCode::E00);
    CHECK(result.memoryErrorIndex == 4);

    result = parse("M05 F1e6", remoteBase(), memories);
    CHECK(result.error == ErrorCode::E00);
    result = parse("M5", remoteBase(), memories);
    CHECK(result.error == ErrorCode::E00);

    result = parse("SQ0523", remoteBase(), memories);
    CHECK(result.error == ErrorCode::None);
    CHECK(result.transaction.sequenceAction == SequenceAction::Define);
    CHECK(result.transaction.sequenceStart == 5u);
    CHECK(result.transaction.sequenceEnd == 23u);
    result = parse("SQ0", remoteBase(), memories);
    CHECK(result.error == ErrorCode::None);
    CHECK(result.transaction.sequenceAction == SequenceAction::Clear);
    result = parse("SQ2305", remoteBase(), memories);
    CHECK(result.error == ErrorCode::E89);
}

void testStatusAndDeferredMerge(FakeMemories* memories)
{
    ParseResult result = parse("STB", remoteBase(), memories,
                               ExecutionMarker::QuestionMark);
    CHECK(result.error == ErrorCode::None);
    CHECK(result.statusQuery);

    result = parse("STB", remoteBase(), memories,
                   ExecutionMarker::LineEnding);
    CHECK(result.error == ErrorCode::E00);

    result = parse("REN1F1e6", localBase(), memories);
    CHECK(result.error == ErrorCode::None);
    const Transaction staged = result.transaction;
    result = parse("A-30", staged, memories);
    CHECK(result.error == ErrorCode::None);
    CHECK(result.transaction.output.frequencyHz == 1000000u);
    CHECK(result.transaction.output.amplitudeTenthsDbm == -300);

    result = parse("LLO1", result.transaction, memories);
    CHECK(result.error == ErrorCode::None);
    CHECK(result.transaction.remoteState.remoteEnabled);
    CHECK(result.transaction.remoteState.localLockout);
    result = parse("GTL", result.transaction, memories);
    CHECK(result.error == ErrorCode::None);
    CHECK(!result.transaction.remoteState.remoteEnabled);
    CHECK(result.transaction.remoteState.localLockout);
}

void testFraming()
{
    MessageFramer framer;
    framer.reset();
    FrameResult frame = {};
    const char first[] = "REN1\r\n";
    for (uint8_t i = 0u; i < sizeof(first) - 1u; ++i) {
        frame = framer.consume(first[i]);
        if (i == 4u) {
            CHECK(frame.event == FrameEvent::Execute);
            CHECK(frame.marker == ExecutionMarker::LineEnding);
            CHECK(frame.length == 4u);
            CHECK(strncmp(frame.text, "REN1", 4u) == 0);
        } else {
            CHECK(frame.event == FrameEvent::None);
        }
    }
    CHECK(frame.event == FrameEvent::None);

    const char question[] = "STB?\r\n";
    for (uint8_t i = 0u; i < sizeof(question) - 1u; ++i) {
        frame = framer.consume(question[i]);
        if (question[i] == '?') {
            CHECK(frame.event == FrameEvent::Execute);
            CHECK(frame.marker == ExecutionMarker::QuestionMark);
            CHECK(frame.length == 3u);
            CHECK(strncmp(frame.text, "STB", 3u) == 0);
        } else {
            CHECK(frame.event == FrameEvent::None);
        }
    }

    const char deferred[] = "F1!\r\n";
    for (uint8_t i = 0u; i < sizeof(deferred) - 1u; ++i) {
        frame = framer.consume(deferred[i]);
        if (deferred[i] == '!') {
            CHECK(frame.event == FrameEvent::Defer);
            CHECK(frame.length == 2u);
        } else {
            CHECK(frame.event == FrameEvent::None);
        }
    }
    frame = framer.consume('\r');
    CHECK(frame.event == FrameEvent::Execute);
    CHECK(frame.length == 0u);
    frame = framer.consume('\n');
    CHECK(frame.event == FrameEvent::None);

    for (uint16_t i = 0u; i < 129u; ++i) {
        frame = framer.consume('A');
        CHECK(frame.event == FrameEvent::None);
    }
    frame = framer.consume('\n');
    CHECK(frame.event == FrameEvent::Overflow);
    CHECK(frame.length == MessageFramer::kMaximumMessageLength);

    const char recovered[] = "REN1\n";
    for (uint8_t i = 0u; i < sizeof(recovered) - 1u; ++i) {
        frame = framer.consume(recovered[i]);
    }
    CHECK(frame.event == FrameEvent::Execute);
    CHECK(frame.length == 4u);
    CHECK(strncmp(frame.text, "REN1", 4u) == 0);
}

void testStatusBytes()
{
    const RemoteState remote = {true, false};
    CHECK(adret::serial_protocol::makeStatusByte(
              remote, false, false, ErrorCode::E00) == 16u);
    CHECK(adret::serial_protocol::makeStatusByte(
              remote, true, true, ErrorCode::E21) == 114u);
    CHECK(adret::serial_protocol::makeStatusByte(
              remote, false, true, ErrorCode::E21) == 50u);
    CHECK(adret::serial_protocol::makeStatusByte(
              RemoteState{false, false}, true, true, ErrorCode::E91) == 105u);
}

}  // namespace

int main()
{
    FakeMemories memories = {};
    testModeAndGroupedConfiguration(&memories);
    testScalingAndModes(&memories);
    testErrorsAndAtomicBase(&memories);
    testMemoriesAndSequences(&memories);
    testStatusAndDeferredMerge(&memories);
    testFraming();
    testStatusBytes();

    if (failures != 0u) {
        printf("%u serial protocol test(s) failed\n", failures);
        return 1;
    }
    printf("All serial protocol parser tests passed\n");
    return 0;
}
