@echo off
chcp 65001 >nul
setlocal

rem Decode every raw CSV trace. Decode.awk writes Out\Dec_<source name>.
for %%F in ("Data\*.csv") do (
    gawk -f "src\Decode.awk" "%%F"
    if errorlevel 1 exit /b 1
)

endlocal
