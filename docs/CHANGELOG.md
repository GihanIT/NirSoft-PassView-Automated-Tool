# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [0.6.0-beta] - 2026-07-22

### Added

- `start.bat` now reads `scripts/version.txt` and prints the current version
  next to the startup banner: "Starting NirSoft Password Collector - vX.X.X-channel".
- Console window title is set to "NirSoft Password Collector v<version>".
- Fallback version label is now "N.N.N-UNKNOWN" when `version.txt` is missing.

## [0.5.0-beta] - 2026-07-22

### Added

- `report.bat` now uses colored output for headers, status messages, and the
  completion prompt via a `:ColorEcho` helper that delegates to PowerShell's
  `Write-Host`.

## [0.4.0-beta] - 2026-07-22

### Added

- `collector.ps1` now reads `scripts/version.txt` and prints the current version
  at startup (e.g. "NirSoft Password Collector v0.4.0-beta").

## [0.3.0-beta] - 2026-07-22

### Added

- Added an interactive confirmation prompt at the start of `collector.ps1`
  before closing browsers/email clients. The user can now save unsaved work
  before the collection proceeds.

## [0.2.0-beta] - 2026-07-22

### Added

- Integrated `WinLogOnView.exe` into `collector.ps1` to capture Windows logon/logoff
  history via the Event Log. Output saved as `win_logon.txt` using `/stext`.

## [0.1.0-beta] - 2026-07-22

### Added

- Initial beta release of the automated NirSoft password/diagnostic collector.
- `collector.ps1` runs NirSoft tools (`ChromePass`, `WebBrowserPassView`, `mailpv`,
  `OperaPassView`, `PasswordFox`, `BulletsPassView`, `ManageWirelessNetworks`,
  `UninstallView`, `UserProfilesView`, `SecuritySoftView`, `pspv`,
  `ProductKeyScanner`, `NetBScanner`, `WhoIsConnectedSniffer`) and saves outputs
  to a single timestamped folder.
- `start.bat` auto-elevates to Administrator, chains `collector.ps1` and
  `report.bat`, and pauses at the end with a clear completion message.
- `report.bat` collects diagnostic output (`ipconfig /all`, `systeminfo`,
  `netstat -ano`, `whoami /priv`, `route print`) into the same shared run folder
  when launched from `start.bat`; falls back to a standalone
  `IpConfigReport_<timestamp>` folder when run directly.
- `run.bat` convenience launcher in the project root.
- `scripts/version.txt` tracking the current beta version.
- Shared output folder naming: `<yyyyMMdd_HHmmss> <PCName> (<UserName>)`.
