#include <assert.h>
#include <stdint.h>
#include <stdio.h>

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

}  // namespace

int main()
{
    test240MHzAmProgram();
    testRfOffClearsOnlyRelayBits();
    testFmAndPmFields();
    testStandardFrequencyEndpoints();
    puts("InstrumentProgram host vectors: OK");
    return 0;
}
