@echo off
REM ============================================================================
REM report.bat - diagnostic command output collector (companion to collector.ps1)
REM
REM Auto-elevates to Administrator via UAC (matches start.bat), then runs a small
REM list of diagnostic commands. Each command's stdout + stderr is redirected to
REM ITS OWN .txt file, named after the command with "/" replaced by a space.
REM
REM Filename rule (per user request):
REM   <full command text with / replaced by space> + ".txt"
REM   Example:  ipconfig /all    ->  ipconfig all.txt
REM             netstat -ano     ->  netstat -ano.txt
REM             whoami /priv     ->  whoami priv.txt
REM             route print      ->  route print.txt
REM
REM Output goes to:
REM   <PROJECT_ROOT>\results\<yyyyMMdd_HHmmss> PCName (Username)\      (when chained from start.bat)
REM   or <PROJECT_ROOT>\results\IpConfigReport_<yyyyMMdd_HHmmss>\       (when run directly)
REM
REM Editing: add / remove / change commands in the "--- COMMANDS ---" section
REM below. Keep the redirect pattern:
REM   <command>  >  "<REPORTDIR>\<sanitized-name>.txt"  2>&1
REM ============================================================================

SETLOCAL

REM ----- Auto-elevate to Administrator if not already -----
net session >nul 2>&1
if %ERRORLEVEL% NEQ 0 (
    echo Requesting Administrator privileges...
    powershell.exe -NoProfile -Command "Start-Process -FilePath '%~f0' -Verb RunAs"
    exit /b
)
call :ColorEcho "Running with Administrator privileges - Good!" "Green"
echo.

REM ----- Project root (parent of scripts\) + report folder -----
SET SCRIPTDIR=%~dp0
for %%I in ("%SCRIPTDIR%..") do set PROJROOT=%%~fI

REM ----- Compute timestamp (used for header and fallback folder) -----
REM IMPORTANT: use `Get-Date -Format yyyyMMdd_HHmmss` (single STRING arg, no
REM nested quotes) rather than `(Get-Date).ToString('yyyyMMdd_HHmmss')`. The
REM .ToString version needs THREE levels of nested quotes around the single
REM quoted format string, which breaks CMD's `for /f` parser silently -- the
REM resulting TIMESTAMP ends up empty, REPORTDIR becomes "\results\IpConfigReport_",
REM and the .bat flashes + closes immediately when launched from double-click.
REM `--Format` avoids ALL of that with one clean arg.
REM
REM `%RANDOM%` fallback below protects against PowerShell being unavailable
REM (e.g. blocked by policy) -- in that case the script still completes with a
REM random-suffix folder instead of a malformed name.
for /f "delims=" %%T in ('powershell.exe -NoProfile -Command "Get-Date -Format yyyyMMdd_HHmmss"') do set TIMESTAMP=%%T
if "%TIMESTAMP%"=="" set TIMESTAMP=run_%RANDOM%

REM ----- Use shared output folder if start.bat provided it -----
REM start.bat sets NF_OUTPUT_DIR to <yyyyMMdd_HHmmss> PCName (Username) so that
REM report.bat writes into the SAME run folder as collector.ps1. If this script is
REM launched directly (no NF_OUTPUT_DIR), it falls back to its own legacy folder.
if not "%NF_OUTPUT_DIR%"=="" (
    set "REPORTDIR=%NF_OUTPUT_DIR%"
    if not exist "%REPORTDIR%" mkdir "%REPORTDIR%"
    goto :ReportDirReady
)

REM ----- Compute legacy fallback folder when run directly -----
SET REPORTDIR=%PROJROOT%\results\IpConfigReport_%TIMESTAMP%
if not exist "%REPORTDIR%" mkdir "%REPORTDIR%"

:ReportDirReady
call :ColorEcho "==================================================" "Cyan"
call :ColorEcho "  Diagnostic Report Collector (report.bat)" "Cyan"
call :ColorEcho "  Output: %REPORTDIR%" "Cyan"
call :ColorEcho "  Time:   %TIMESTAMP%" "Cyan"
call :ColorEcho "==================================================" "Cyan"
echo.

REM ============================================================================
REM --- COMMANDS BELOW THIS LINE -----------------------------------------------
REM Add / remove / edit freely. Each command's output goes to its OWN .txt file.
REM Naming rule: command text with / replaced by space (eg. "ipconfig /all" ->
REM "ipconfig all.txt"). Always keep the "2>&1" tail so stderr is captured too.
REM ============================================================================

ipconfig /all                                            >  "%REPORTDIR%\ipconfig all.txt"   2>&1
systeminfo                                               >  "%REPORTDIR%\systeminfo.txt"      2>&1
netstat -ano                                             >  "%REPORTDIR%\netstat -ano.txt"    2>&1
whoami /priv                                             >  "%REPORTDIR%\whoami priv.txt"     2>&1
route print                                              >  "%REPORTDIR%\route print.txt"     2>&1

REM ============================================================================
REM --- END COMMANDS -----------------------------------------------------------
REM ============================================================================

echo.
call :ColorEcho "==================================================" "Green"
call :ColorEcho "  Report collection complete." "Green"
call :ColorEcho "  Files written to: %REPORTDIR%" "Green"
call :ColorEcho "==================================================" "Green"
echo.
dir "%REPORTDIR%" /b
echo.

REM Conditional final pause:
REM   - Invoked directly from Explorer / start.bat? Pause so user can read.
REM   - Invoked via `call` from start.bat (chained after collector.ps1)?
REM     CHAINED_FROM_START=1 was set by start.bat before the call -> we just
REM     exit cleanly so control returns to start.bat for its single pause.
if "%CHAINED_FROM_START%"=="" (
    echo.
    call :ColorEcho "================================================" "Cyan"
    call :ColorEcho "  Report complete. Press any key to close this window." "Cyan"
    call :ColorEcho "================================================" "Cyan"
    echo.
    REM Native pause (NO > nul) so the standard "Press any key to continue . . ."
    REM message displays. Earlier `pause > nul` was SILENCING that native message,
    REM so the user saw only my echo above, then no visible feedback between echo and
    REM window close -- looked indistinguishable from "closes immediately". Now both
    REM the custom wrapper AND the native prompt are visible.
    pause
)

ENDLOCAL
REM Fall-through guard: keep the colored-output helper below from executing
REM as part of the main batch flow.
goto :eof

REM ----- Colored output helper -----
REM Usage: call :ColorEcho "text" "Color"
REM Available colors: Black, DarkBlue, DarkGreen, DarkCyan, DarkRed, DarkMagenta,
REM DarkYellow, Gray, DarkGray, Blue, Green, Cyan, Red, Magenta, Yellow, White.
:ColorEcho
setlocal
set "CE_TEXT=%~1"
set "CE_COLOR=%~2"
powershell.exe -NoProfile -Command "Write-Host $env:CE_TEXT -ForegroundColor $env:CE_COLOR"
endlocal
goto :eof
