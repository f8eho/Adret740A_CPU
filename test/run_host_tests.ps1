$ErrorActionPreference = 'Stop'

$compiler = (Get-Command g++ -ErrorAction Stop).Source
$output = Join-Path $PSScriptRoot '..\.pio\instrument_program_tests.exe'
$sources = @(
    (Join-Path $PSScriptRoot 'test_instrument_program.cpp'),
    (Join-Path $PSScriptRoot '..\src\CalibrationEprom.cpp'),
    (Join-Path $PSScriptRoot '..\src\InstrumentAmplitude.cpp'),
    (Join-Path $PSScriptRoot '..\src\InstrumentFrequencyPlan.cpp'),
    (Join-Path $PSScriptRoot '..\src\InstrumentModulation.cpp'),
    (Join-Path $PSScriptRoot '..\src\InstrumentProgram.cpp'),
    (Join-Path $PSScriptRoot '..\src\InstrumentPulse.cpp'),
    (Join-Path $PSScriptRoot '..\src\InstrumentSmallSteps.cpp')
)

& $compiler '-std=c++17' '-Wall' '-Wextra' '-Werror' `
    "-I$(Join-Path $PSScriptRoot 'host_stubs')" `
    "-I$(Join-Path $PSScriptRoot '..\include')" `
    @sources '-o' $output
if ($LASTEXITCODE -ne 0) {
    exit $LASTEXITCODE
}

& $output
if ($LASTEXITCODE -ne 0) {
    exit $LASTEXITCODE
}

$serialOutput = Join-Path $PSScriptRoot '..\.pio\serial_protocol_tests.exe'
$serialSources = @(
    (Join-Path $PSScriptRoot 'serial_protocol\test_main.cpp'),
    (Join-Path $PSScriptRoot '..\src\SerialCommandParser.cpp')
)

& $compiler '-std=c++17' '-Wall' '-Wextra' '-Werror' `
    "-I$(Join-Path $PSScriptRoot '..\include')" `
    @serialSources '-o' $serialOutput
if ($LASTEXITCODE -ne 0) {
    exit $LASTEXITCODE
}

& $serialOutput
if ($LASTEXITCODE -ne 0) {
    exit $LASTEXITCODE
}

& python -B (Join-Path $PSScriptRoot 'test_adret_calibration.py')
exit $LASTEXITCODE
