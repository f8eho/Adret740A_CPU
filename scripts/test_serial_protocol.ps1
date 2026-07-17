$ErrorActionPreference = "Stop"

$projectRoot = (Resolve-Path (Join-Path $PSScriptRoot "..")).Path
$outputDirectory = Join-Path $projectRoot ".pio\host-tests"
$executable = Join-Path $outputDirectory "serial_protocol_tests.exe"

New-Item -ItemType Directory -Force -Path $outputDirectory | Out-Null

& g++ `
    -std=c++17 `
    -Wall `
    -Wextra `
    -Werror `
    -I (Join-Path $projectRoot "include") `
    (Join-Path $projectRoot "src\SerialCommandParser.cpp") `
    (Join-Path $projectRoot "test\serial_protocol\test_main.cpp") `
    -o $executable

if ($LASTEXITCODE -ne 0) {
    throw "Serial protocol test compilation failed with exit code $LASTEXITCODE"
}

& $executable
if ($LASTEXITCODE -ne 0) {
    throw "Serial protocol tests failed with exit code $LASTEXITCODE"
}
