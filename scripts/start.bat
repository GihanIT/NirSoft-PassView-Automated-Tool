@echo off
REM start.bat - double-click to run collector.ps1 from USB scripts folder

SETLOCAL

REM Check for administrator privileges
net session >nul 2>&1
if %errorLevel% == 0 (
    echo Running with Administrator privileges - Good!
    echo.
) else (
    echo ================================================
    echo WARNING: NOT running as Administrator!
    echo ================================================
    echo.
    echo Many NirSoft tools require admin rights to work.
    echo Please RIGHT-CLICK this file and select "Run as administrator"
    echo.
    echo Press any key to continue anyway ^(some tools may fail^)...
    pause >nul
    echo.
)

SET SCRIPTDIR=%~dp0

echo ================================================
echo Starting NirSoft Password Collector
echo ================================================
echo.

REM Run PowerShell script with visible window
powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%SCRIPTDIR%collector.ps1"

echo.
echo ================================================
echo Script execution completed
echo ================================================
echo.
echo Press any key to close this window...
pause >nul

ENDLOCAL