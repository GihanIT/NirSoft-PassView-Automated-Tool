@echo off
REM run.bat - project-root convenience launcher that calls scripts\start.bat
REM (which auto-elevates to Administrator via UAC and runs collector.ps1).
REM Uses %~dp0 so the path resolves correctly regardless of cwd and is
REM safe when the project lives in a path that contains spaces.
call "%~dp0scripts\start.bat" %*
