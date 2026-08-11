#include <assert.h>
#include <stdint.h>
#include <stdio.h>

#include "Adret/CalibrationEprom.h"
#include "Adret/InstrumentCapabilities.h"
#include "Adret/InstrumentAmplitude.h"
#include "Adret/InstrumentProgram.h"

namespace {

using namespace adret::instrument_bus;

void testDoublerCapabilitySnapshot()
{
    bool simulatedInputIsHigh = true;
    const adret::InstrumentCapabilities startup =
        adret::capabilitiesFromDoublerJumperLevel(simulatedInputIsHigh);
    simulatedInputIsHigh = false;
    assert(!startup.doublerInstalled());
    assert(startup.maximumFrequencyHz() == adret::kBaseMaximumFrequencyHz);

    const adret::InstrumentCapabilities afterRestart =
        adret::capabilitiesFromDoublerJumperLevel(simulatedInputIsHigh);
    assert(afterRestart.doublerInstalled());
    assert(afterRestart.maximumFrequencyHz() ==
           adret::kDoublerMaximumFrequencyHz);
}

InstrumentConfiguration baseConfiguration()
{
    return {
        240000000u,
        -351,
        5000u,
        123u,
        600u,
        ModulationKind::Am,
        ModulationSource::Internal1kHz,
        false,
        false,
        false,
        false,
    };
}

void expectWrite(const InstrumentProgram& program,
                 uint8_t index,
                 uint8_t address,
                 uint8_t value)
{
    assert(index < program.writeCount);
    assert(program.writes[index].address == address);
    assert(program.writes[index].value == value);
}

InstrumentProgram makeProgram(const InstrumentConfiguration& configuration)
{
    uint8_t registers[kInstrumentRegisterCount] = {};
    makeInitialInstrumentRegisters(registers);
    InstrumentProgram program = {};
    const InstrumentProgramResult result =
        makeInstrumentProgram(configuration, 0, registers, &program);
    if (result != InstrumentProgramResult::Ok) {
        fprintf(stderr, "program failed frequency=%lu result=%u\n",
                static_cast<unsigned long>(configuration.frequencyHz),
                unsigned(result));
    }
    assert(result == InstrumentProgramResult::Ok);
    return program;
}

InstrumentProgram makeProgramForSections(
    const InstrumentConfiguration& configuration,
    const uint8_t registers[kInstrumentRegisterCount],
    InstrumentProgramSections sections,
    int8_t calibrationTenthsDb = 0)
{
    InstrumentProgram program = {};
    assert(makeInstrumentProgramForSections(configuration,
                                            calibrationTenthsDb,
                                            registers,
                                            sections,
                                            &program) ==
           InstrumentProgramResult::Ok);
    return program;
}

void copyRegisters(const InstrumentProgram& program,
                   uint8_t registers[kInstrumentRegisterCount])
{
    for (uint8_t address = 0u; address < kInstrumentRegisterCount; ++address) {
        registers[address] = program.finalRegisters[address];
    }
}

void test240MHzAmProgram()
{
    const InstrumentProgram program = makeProgram(baseConfiguration());
    assert(program.writeCount == 20u);

    const InstrumentWrite expected[] = {
        {12u, 0x61u}, {15u, 0x1Fu}, {5u, 0x05u}, {11u, 0xB9u},
        {4u, 0xAAu}, {13u, 0x2Au}, {0u, 0x00u}, {1u, 0x00u},
        {2u, 0x00u}, {3u, 0x9Eu}, {6u, 0x2Du}, {8u, 0xA9u},
        {6u, 0x2Du}, {6u, 0x2Du}, {9u, 0x00u}, {10u, 0xF6u},
        {12u, 0x61u}, {13u, 0x2Au}, {11u, 0x39u}, {6u, 0x2Du},
    };
    static_assert(sizeof(expected) / sizeof(expected[0]) == 20u,
                  "Unexpected reference vector length");
    for (uint8_t i = 0u; i < program.writeCount; ++i) {
        expectWrite(program, i, expected[i].address, expected[i].value);
    }
}

void testRfOffClearsOnlyRelayBits()
{
    InstrumentConfiguration configuration = baseConfiguration();
    configuration.rfOff = true;
    const InstrumentProgram program = makeProgram(configuration);
    assert(program.writeCount == 21u);
    expectWrite(program, 20u, 6u, 0x00u);
    assert(program.finalRegisters[6] == 0x00u);
}

void testDifferentialSections()
{
    const InstrumentProgramSections frequency =
        instrumentProgramSection(InstrumentProgramSection::Frequency);
    const InstrumentProgramSections amplitude =
        instrumentProgramSection(InstrumentProgramSection::Amplitude);
    const InstrumentProgramSections modulation =
        instrumentProgramSection(InstrumentProgramSection::Modulation);
    const InstrumentProgramSections inhibit =
        instrumentProgramSection(InstrumentProgramSection::RfInhibit);

    assert(requiredInstrumentProgramSections(
               nullptr, 0, baseConfiguration(), 0) ==
           kAllInstrumentProgramSections);

    uint8_t registers[kInstrumentRegisterCount] = {};
    makeInitialInstrumentRegisters(registers);
    InstrumentConfiguration applied = baseConfiguration();
    InstrumentProgram program = makeProgramForSections(
        applied, registers, kAllInstrumentProgramSections);
    assert(program.writeCount == 20u);
    copyRegisters(program, registers);

    InstrumentProgramSections sections = requiredInstrumentProgramSections(
        &applied, 0, applied, 0);
    assert(sections == kNoInstrumentProgramSections);
    program = makeProgramForSections(applied, registers, sections);
    assert(program.writeCount == 0u);

    InstrumentConfiguration requested = applied;
    requested.amTenthsPercent = 500u;
    sections = requiredInstrumentProgramSections(&applied, 0, requested, 0);
    assert(sections == modulation);
    program = makeProgramForSections(requested, registers, sections);
    assert(program.writeCount == 7u);
    copyRegisters(program, registers);
    applied = requested;

    requested.amplitudeTenthsDbm = -401;
    sections = requiredInstrumentProgramSections(&applied, 0, requested, 0);
    assert(sections == amplitude);
    program = makeProgramForSections(requested, registers, sections);
    assert(program.writeCount == 3u);
    assert(program.writes[0].address == 6u);
    assert(program.writes[1].address == 8u);
    assert(program.writes[2].address == 6u);
    copyRegisters(program, registers);
    applied = requested;

    requested.rfOff = true;
    sections = requiredInstrumentProgramSections(&applied, 0, requested, 0);
    assert(sections == inhibit);
    program = makeProgramForSections(requested, registers, sections);
    assert(program.writeCount == 1u);
    expectWrite(program, 0u, 6u, uint8_t(registers[6] & 0xC0u));
    copyRegisters(program, registers);
    applied = requested;

    requested.amTenthsPercent = 400u;
    sections = requiredInstrumentProgramSections(&applied, 0, requested, 0);
    assert(sections == InstrumentProgramSections(modulation | inhibit));
    program = makeProgramForSections(requested, registers, sections);
    assert(program.writeCount == 8u);
    assert(program.writes[program.writeCount - 1u].address == 6u);
    assert(program.finalRegisters[6] ==
           uint8_t(program.writes[program.writeCount - 1u].value));
    copyRegisters(program, registers);
    applied = requested;

    requested.rfOff = false;
    sections = requiredInstrumentProgramSections(&applied, 0, requested, 0);
    assert(sections == amplitude);
    program = makeProgramForSections(requested, registers, sections);
    assert(program.writeCount == 3u);
    copyRegisters(program, registers);
    applied = requested;

    requested.frequencyHz = 241000000u;
    sections = requiredInstrumentProgramSections(&applied, 0, requested, 0);
    assert(sections ==
           InstrumentProgramSections(frequency | amplitude | modulation));
    program = makeProgramForSections(requested, registers, sections);
    assert(program.writeCount == 20u);
}

void testInactiveModulationValueDoesNotWriteBus()
{
    InstrumentConfiguration applied = baseConfiguration();
    InstrumentConfiguration requested = applied;
    requested.fmDeviationHz += 100u;
    assert(requiredInstrumentProgramSections(&applied, 0, requested, 0) ==
           kNoInstrumentProgramSections);

    requested = applied;
    assert(requiredInstrumentProgramSections(&applied, 0, requested, 1) ==
           instrumentProgramSection(InstrumentProgramSection::Amplitude));

    requested = applied;
    requested.amplitudeTenthsDbm -= 1;
    requested.amTenthsPercent += 1u;
    assert(requiredInstrumentProgramSections(&applied, 0, requested, 0) ==
           InstrumentProgramSections(
               instrumentProgramSection(InstrumentProgramSection::Amplitude) |
               instrumentProgramSection(InstrumentProgramSection::Modulation)));
}

void testFullReplayFromPartialImage()
{
    InstrumentConfiguration configuration = baseConfiguration();
    uint8_t registers[kInstrumentRegisterCount] = {};
    makeInitialInstrumentRegisters(registers);
    const InstrumentProgram initial = makeProgramForSections(
        configuration, registers, kAllInstrumentProgramSections);

    for (uint8_t i = 0u; i < 5u; ++i) {
        registers[initial.writes[i].address] = initial.writes[i].value;
    }
    const InstrumentProgram replay = makeProgramForSections(
        configuration, registers, kAllInstrumentProgramSections);
    assert(replay.writeCount == 20u);
    for (uint8_t address = 0u; address < kInstrumentRegisterCount; ++address) {
        assert(replay.finalRegisters[address] ==
               initial.finalRegisters[address]);
    }
}

void testFmAndPmFields()
{
    InstrumentConfiguration configuration = baseConfiguration();
    configuration.modulationKind = ModulationKind::Fm;
    configuration.modulationSource = ModulationSource::External;
    InstrumentProgram program = makeProgram(configuration);
    assert(program.writeCount == 19u);
    expectWrite(program, 14u, 10u, 0x95u);
    expectWrite(program, 15u, 12u, 0x10u);
    expectWrite(program, 16u, 13u, 0xAAu);

    configuration.modulationKind = ModulationKind::Pm;
    program = makeProgram(configuration);
    expectWrite(program, 13u, 9u, 0x23u);
    expectWrite(program, 14u, 10u, 0x91u);
    expectWrite(program, 15u, 12u, 0x18u);
    expectWrite(program, 16u, 13u, 0xAAu);
}

void testFmDemonstratedEndpoint()
{
    InstrumentConfiguration configuration = baseConfiguration();
    configuration.modulationKind = ModulationKind::Fm;
    configuration.fmDeviationHz = kFmMaximumExactlyEncodedHz;
    InstrumentProgram program = makeProgram(configuration);
    assert(program.writeCount == 19u);

    configuration.fmDeviationHz = 200000u;
    uint8_t registers[kInstrumentRegisterCount] = {};
    makeInitialInstrumentRegisters(registers);
    assert(makeInstrumentProgram(configuration, 0, registers, &program) ==
           InstrumentProgramResult::InvalidModulation);
}

void testStandardFrequencyEndpoints()
{
    InstrumentConfiguration configuration = baseConfiguration();
    configuration.frequencyHz = 100000u;
    InstrumentProgram program = makeProgram(configuration);
    expectWrite(program, 2u, 5u, 0x23u);
    expectWrite(program, 4u, 4u, 0xBAu);
    expectWrite(program, 9u, 3u, 0x9Fu);

    configuration.frequencyHz = 560000000u;
    program = makeProgram(configuration);
    expectWrite(program, 2u, 5u, 0x09u);
    expectWrite(program, 4u, 4u, 0x9Au);
    expectWrite(program, 9u, 3u, 0x9Eu);
}

void testDoublerFrequencyEndpoints()
{
    InstrumentConfiguration configuration = baseConfiguration();
    configuration.doublerInstalled = true;

    configuration.frequencyHz = 559999990u;
    InstrumentProgram program = makeProgram(configuration);
    expectWrite(program, 2u, 5u, 0x09u);

    configuration.frequencyHz = 560000000u;
    program = makeProgram(configuration);
    expectWrite(program, 2u, 5u, 0x10u);
    assert((program.finalRegisters[12] & kAddress12RangeMask) == 0x02u);

    configuration.frequencyHz = 735999990u;
    program = makeProgram(configuration);
    expectWrite(program, 2u, 5u, 0x10u);

    configuration.frequencyHz = 736000000u;
    program = makeProgram(configuration);
    expectWrite(program, 2u, 5u, 0x11u);

    configuration.frequencyHz = 1119999990u;
    program = makeProgram(configuration);
    expectWrite(program, 2u, 5u, 0x11u);

    configuration.pulseOptionInstalled = true;
    configuration.pulseEnabled = true;
    program = makeProgram(configuration);
    expectWrite(program, 2u, 5u, 0x31u);

    configuration.frequencyHz = 1120000000u;
    uint8_t registers[kInstrumentRegisterCount] = {};
    makeInitialInstrumentRegisters(registers);
    assert(makeInstrumentProgram(configuration, 0, registers, &program) ==
           InstrumentProgramResult::InvalidFrequency);

    configuration = baseConfiguration();
    configuration.frequencyHz = 560000010u;
    assert(makeInstrumentProgram(configuration, 0, registers, &program) ==
           InstrumentProgramResult::InvalidFrequency);
}

void testDoublerModulationAndLevelDomains()
{
    InstrumentConfiguration configuration = baseConfiguration();
    configuration.doublerInstalled = true;
    configuration.frequencyHz = 800000010u;

    configuration.modulationKind = ModulationKind::Am;
    configuration.amplitudeTenthsDbm = -1299;
    (void)makeProgram(configuration);
    configuration.amplitudeTenthsDbm = 130;
    (void)makeProgram(configuration);

    configuration.modulationKind = ModulationKind::Fm;
    (void)makeProgram(configuration);
    configuration.modulationKind = ModulationKind::Pm;
    (void)makeProgram(configuration);

    configuration.modulationKind = ModulationKind::Am;
    configuration.pulseOptionInstalled = true;
    configuration.pulseEnabled = true;
    (void)makeProgram(configuration);

    configuration.modulationKind = ModulationKind::Fm;
    uint8_t registers[kInstrumentRegisterCount] = {};
    makeInitialInstrumentRegisters(registers);
    InstrumentProgram program = {};
    assert(makeInstrumentProgram(configuration, 0, registers, &program) ==
           InstrumentProgramResult::InvalidPulseState);
}

void testOriginalPlus5DbControlPolarity()
{
    constexpr uint8_t kNoRelays = 0x3Fu;
    constexpr uint8_t kHeterodyneAddress5 = 0x23u;
    constexpr uint8_t kDivideBy2Address5 = 0x05u;

    assert(makeAmplitudeControlAddress6(
               kNoRelays, kHeterodyneAddress5, false, false) == 0x3Fu);
    assert(makeAmplitudeControlAddress6(
               kNoRelays, kHeterodyneAddress5, true, false) == 0xBFu);
    assert(makeAmplitudeControlAddress6(
               kNoRelays, kHeterodyneAddress5, true, true) == 0xBFu);
    assert(makeAmplitudeControlAddress6(
               kNoRelays, kDivideBy2Address5, false, false) == 0x3Fu);
    assert(makeAmplitudeControlAddress6(
               kNoRelays, kDivideBy2Address5, true, false) == 0x3Fu);
}

void testHighLevelFineControlRemainsContinuous()
{
    constexpr uint8_t kHeterodyneAddress5 = 0x23u;
    AmplitudeProgram program = {};

    assert(makeAmplitudeProgram(
        69, 0, 0x3Fu, kHeterodyneAddress5, false, &program));
    assert(program.nominalFineTenthsDb == 69);
    assert(program.address8 == 0x89u);
    assert(program.address6AfterAddress8 == 0x3Fu);

    assert(makeAmplitudeProgram(
        70, 0, 0xBFu, kHeterodyneAddress5, false, &program));
    assert(program.nominalFineTenthsDb == 68);
    assert(program.address8 == 0x88u);
    assert(program.address6AfterAddress8 == 0xBFu);

    assert(makeAmplitudeProgram(
        130, 0, 0x3Fu, kHeterodyneAddress5, false, &program));
    assert(program.nominalFineTenthsDb == 8);
    assert(program.address8 == 0x08u);

    assert(makeAmplitudeProgram(
        69, 0, 0x3Fu, kHeterodyneAddress5, true, &program));
    assert(program.address6BeforeAddress8 == 0x3Fu);
    assert(program.address6AfterAddress8 == 0xBFu);
}

void testCalibrationGrid()
{
    using namespace adret::calibration;
    uint8_t row = 0u;
    assert(frequencyRow(100000u, &row) && row == 0u);
    assert(frequencyRow(999999u, &row) && row == 8u);
    assert(frequencyRow(1000000u, &row) && row == 9u);
    assert(frequencyRow(9999999u, &row) && row == 17u);
    assert(frequencyRow(10000000u, &row) && row == 18u);
    assert(frequencyRow(59999999u, &row) && row == 18u);
    assert(frequencyRow(60000000u, &row) && row == 19u);
    assert(frequencyRow(559999999u, &row) && row == 28u);
    assert(frequencyRow(560000000u, &row) && row == 29u);
    assert(frequencyRow(609999999u, &row) && row == 29u);
    assert(frequencyRow(610000000u, &row) && row == 30u);
    assert(frequencyRow(1109999999u, &row) && row == 39u);
    assert(frequencyRow(1110000000u, &row) && row == 40u);
    assert(frequencyRow(1119999990u, &row) && row == 40u);
    assert(!frequencyRow(99999u, &row));
    assert(!frequencyRow(1120000000u, &row));

    uint8_t step = 0u;
    assert(attenuatorStep(130, &step) && step == 0u);
    assert(attenuatorStep(70, &step) && step == 0u);
    assert(attenuatorStep(69, &step) && step == 0u);
    assert(attenuatorStep(20, &step) && step == 0u);
    assert(attenuatorStep(19, &step) && step == 1u);
    assert(attenuatorStep(-30, &step) && step == 1u);
    assert(attenuatorStep(-31, &step) && step == 2u);
    assert(attenuatorStep(-1299, &step) && step == 27u);

    uint16_t tableIndex = 0u;
    uint16_t overlayIndex = 0u;
    assert(correctionIndex(100000u, -1299, &tableIndex, &overlayIndex,
                           &row, &step));
    assert(row == 0u && step == 27u);
    assert(tableIndex == 27u && overlayIndex == 27u);
    assert(correctionIndex(560000000u, 100, &tableIndex, &overlayIndex,
                           &row, &step));
    assert(row == 29u && step == 0u);
    assert(tableIndex == 29u * 32u);
    assert(overlayIndex == 29u * 28u);
    assert(baseTableCrc16() == 0xC584u);

    for (uint8_t expectedRow = 0u;
         expectedRow < kCalibrationFrequencyRowCount; ++expectedRow) {
        const uint32_t frequency = expectedRow < 9u
            ? uint32_t(expectedRow + 1u) * 100000u + 50000u
            : expectedRow < 18u
                ? uint32_t(expectedRow - 8u) * 1000000u + 500000u
                : expectedRow < 29u
                    ? 10000000u + uint32_t(expectedRow - 18u) * 50000000u +
                          25000000u
                    : expectedRow == 29u
                        ? 585000000u
                        : expectedRow < 40u
                            ? 610000000u +
                                  uint32_t(expectedRow - 30u) * 50000000u +
                                  25000000u
                            : 1115000000u;
        for (uint8_t expectedStep = 0u; expectedStep < 28u; ++expectedStep) {
            const int16_t amplitude = expectedStep == 0u
                ? 100
                : expectedStep == 27u
                    ? -1290
                    : int16_t(45 - int16_t(expectedStep) * 50);
            assert(correctionIndex(frequency, amplitude, &tableIndex,
                                   &overlayIndex, &row, &step));
            assert(row == expectedRow);
            assert(step == expectedStep);
        }
    }
}

}  // namespace

int main()
{
    testDoublerCapabilitySnapshot();
    test240MHzAmProgram();
    testRfOffClearsOnlyRelayBits();
    testDifferentialSections();
    testInactiveModulationValueDoesNotWriteBus();
    testFullReplayFromPartialImage();
    testFmAndPmFields();
    testFmDemonstratedEndpoint();
    testStandardFrequencyEndpoints();
    testDoublerFrequencyEndpoints();
    testDoublerModulationAndLevelDomains();
    testOriginalPlus5DbControlPolarity();
    testHighLevelFineControlRemainsContinuous();
    testCalibrationGrid();
    puts("InstrumentProgram host vectors: OK");
    return 0;
}
