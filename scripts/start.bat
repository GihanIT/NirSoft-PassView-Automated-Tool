@echo off
REM start.bat - NirSoft Password Collector launcher (auto-elevates to Administrator)
REM
REM Portable: copy the project folder to any USB drive, any path on any PC.
REM A double-click shows one UAC prompt, then runs as Administrator.
REM
REM How auto-elevation works:
REM   1. `net session` detects whether we are already admin.
REM   2. If NOT admin, we use PowerShell's Start-Process -Verb RunAs to
REM      re-launch this very same batch file (%~f0) as Administrator, then
REM      `exit /b` the non-elevated instance so the user sees ONE console,
REM      not two.
REM   3. The re-launched instance passes the `net session` check and proceeds
REM      to invoke collector.ps1 normally.
REM
REM Edge cases handled:
REM   - Path with spaces: %~f0 contains the full quoted path; PowerShell uses
REM     single-quoted -Command so the path is passed through literally.
REM   - Infinite loop: avoided because the elevated instance succeeds the
REM     `net session` check on its first run.
REM   - No system installation: nothing added to registry, no scheduled task.

SETLOCAL

REM ----- Gihan IT Logo -----
echo.
echo  ===================================================
echo   ####   ##  ##   ##     ##     ##   ##     ##  ######
echo  ##      ##  ##   ##    ####    ###  ##     ##    ##
echo  ## ###  ##  #######   ##  ##   #######     ##    ##
echo  ##  ##  ##  ##   ##  ########  ##  ###     ##    ##
echo   ####   ##  ##   ##  ##    ##  ##   ##     ##    ##
echo.
echo  Powered by NirSoft
echo.
echo  ===================================================
echo                      Gihan IT
echo       Copyright (C) 2025 - All Rights Reserved
echo  ===================================================
echo.

REM ----- Auto-elevate to Administrator if not already -----
net session >nul 2>&1
if %ERRORLEVEL% NEQ 0 (
    echo Requesting Administrator privileges...
    echo A new window will open with Administrator rights in a moment.
    echo Click YES on the UAC prompt.
    REM Start an elevated copy of this same batch file in a new console.
    REM The non-elevated launcher exits right away so the user has ONE window:
    REM the elevated one, which runs the collection and then pauses at the end.
    powershell.exe -NoProfile -Command "Start-Process -FilePath '%~f0' -Verb RunAs"
    timeout /t 2 >nul
    exit /b
)

echo Running with Administrator privileges - Good!
echo.

REM ----- Launch collector.ps1 -----
SET SCRIPTDIR=%~dp0

REM Read current version from version.txt (sibling of this batch file).
REM Defaults to "N.N.N-UNKNOWN" if the file is missing for any reason.
set "PROJECT_VERSION=N.N.N-UNKNOWN"
for /f "delims=" %%V in ('type "%SCRIPTDIR%version.txt" 2^>nul') do set "PROJECT_VERSION=%%V"

REM Set the console window title so the user can identify the running version
REM even when multiple windows are open.
title NirSoft Password Collector v%PROJECT_VERSION%

REM Compute the shared output folder name once: <yyyyMMdd_HHmmss> PCName (Username).
REM This folder will hold BOTH the NirSoft tool outputs and the diagnostic report.
for /f "delims=" %%F in ('powershell.exe -NoProfile -ExecutionPolicy Bypass -Command "$ts = Get-Date -Format 'yyyyMMdd_HHmmss'; $pc = $env:COMPUTERNAME -replace '[^a-zA-Z0-9_-]','_'; $user = $env:USERNAME -replace '[^a-zA-Z0-9_-]','_'; Write-Output ('{0} {1} ({2})' -f $ts,$pc,$user)"') do set "RUN_FOLDER_NAME=%%F"
for %%I in ("%SCRIPTDIR%..") do set "PROJROOT=%%~fI"
set "NF_OUTPUT_DIR=%PROJROOT%\results\%RUN_FOLDER_NAME%"
if not exist "%NF_OUTPUT_DIR%" mkdir "%NF_OUTPUT_DIR%"

echo ================================================
echo Starting NirSoft Password Collector - v%PROJECT_VERSION%
echo Output folder: %NF_OUTPUT_DIR%
echo ================================================
echo.

powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%SCRIPTDIR%collector.ps1" -OutputDir "%NF_OUTPUT_DIR%"

echo.
echo ================================================
echo Running diagnostic report collector (report.bat)
echo ================================================
echo.
REM Chain report.bat AFTER collector.ps1 so opening run.bat / start.bat
REM runs the full flow (collect + diagnostic snapshot) in a single user action.
REM The CHAINED_FROM_START=1 flag lets report.bat SKIP its own final pause
REM so we end up with ONE single "Press any key" at the bottom of this
REM script instead of two pauses.
REM (report.bat's auto-elevation check also detects we're already admin via
REM inherited token, so NO extra UAC prompt when chained.)
set "CHAINED_FROM_START=1"
set "NF_OUTPUT_DIR=%NF_OUTPUT_DIR%"
call "%SCRIPTDIR%report.bat"
set "CHAINED_FROM_START="
set "NF_OUTPUT_DIR="
echo.
echo ================================================
echo   SCRIPT COMPLETE
echo   Press any key to close this window.
echo ================================================
echo.
REM Final pause: NO > nul so the native "Press any key to continue . . ."
REM message is shown to the user. This window stays open until a key is pressed.
pause

ENDLOCAL