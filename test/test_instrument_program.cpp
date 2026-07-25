#include <assert.h>
#include <stdint.h>
#include <stdio.h>

#include "Adret/CalibrationEprom.h"
#include "Adret/InstrumentProgram.h"

namespace {

using namespace adret::instrument_bus;

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
    assert(makeInstrumentProgram(configuration, 0, registers, &program) ==
           InstrumentProgramResult::Ok);
    return program;
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
    assert(!frequencyRow(99999u, &row));
    assert(!frequencyRow(560000001u, &row));

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

    for (uint8_t expectedRow = 0u; expectedRow < 30u; ++expectedRow) {
        const uint32_t frequency = expectedRow < 9u
            ? uint32_t(expectedRow + 1u) * 100000u + 50000u
            : expectedRow < 18u
                ? uint32_t(expectedRow - 8u) * 1000000u + 500000u
                : expectedRow < 29u
                    ? 10000000u + uint32_t(expectedRow - 18u) * 50000000u +
                          25000000u
                    : 560000000u;
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
    test240MHzAmProgram();
    testRfOffClearsOnlyRelayBits();
    testFmAndPmFields();
    testFmDemonstratedEndpoint();
    testStandardFrequencyEndpoints();
    testCalibrationGrid();
    puts("InstrumentProgram host vectors: OK");
    return 0;
}
