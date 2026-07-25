@echo off
setlocal
pushd "%~dp0.."
python scripts\adret_calibration.py
if errorlevel 1 (
    echo.
    echo L'application s'est terminee avec une erreur.
    pause
)
popd
endlocal
