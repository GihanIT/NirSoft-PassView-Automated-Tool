# test-tools-cli.ps1
# Dry-run probe: for each NirSoft .exe in tools\, try /scomma and /stext and
# report whether the CLI save actually works (process exits by itself and the
# output file is created). This is the diagnostic the README promised
# ("test-tools.bat"). Safe to re-run; writes to results\_dryrun_cli_test\.
# Probe runs non-elevated; tools that need admin (Credential Manager / DPAPI /
# registry hives) will typically not save here even if they work fine when
# invoked from an elevated session.

$ErrorActionPreference = 'Continue'

$scriptFolder = Split-Path -Parent $MyInvocation.MyCommand.Definition
$usbRoot      = (Get-Item "$scriptFolder\..").FullName
$toolsDir     = Join-Path $usbRoot 'tools'
$testRoot     = Join-Path $usbRoot 'results\_dryrun_cli_test'

if (-not (Test-Path $testRoot)) {
    New-Item -ItemType Directory -Path $testRoot -Force | Out-Null
}

# Tools NOT yet wired into collector.ps1 (validated once; expand as needed).
$missing = @(
    'BulletsPassView.exe',
    'CredentialsFileView.exe',
    'DataProtectionDecryptor.exe',
    'ManageWirelessNetworks.exe',
    'ProductKeyScanner.exe',
    'UninstallView.exe',
    'UserProfilesView.exe',
    'pspv.exe'
)

function Probe-CLI {
    param(
        [string]$Exe,
        [string]$Switch,
        [string]$OutName,
        [int]$TimeoutMs = 10000
    )

    $exePath = Join-Path $toolsDir $Exe
    $outPath = Join-Path $testRoot $OutName

    if (-not (Test-Path $exePath)) {
        return [PSCustomObject]@{
            Exe        = $Exe
            SwitchUsed = $Switch
            Found      = $false
            Exited     = 'N/A'
            ExitCode   = $null
            FileExists = $false
            FileBytes  = 0
            Note       = 'EXE not found in tools\'
        }
    }

    # Clean previous probe output
    if (Test-Path $outPath) {
        Remove-Item -Path $outPath -Force -ErrorAction SilentlyContinue
    }

    $psi = New-Object System.Diagnostics.ProcessStartInfo
    $psi.FileName        = $exePath
    $psi.Arguments       = "$Switch `"$outPath`""
    $psi.UseShellExecute = $false
    $psi.CreateNoWindow  = $true
    $psi.WindowStyle     = [System.Diagnostics.ProcessWindowStyle]::Hidden

    $exited = 'no'
    $ec     = $null
    $note   = ''

    try {
        $proc      = [System.Diagnostics.Process]::Start($psi)
        $completed = $proc.WaitForExit($TimeoutMs)
        if ($completed) {
            $exited = 'yes'
            $ec     = $proc.ExitCode
        } else {
            $note = 'killed after timeout'
            $proc.Kill()
            $proc.WaitForExit(2000)
        }
    } catch {
        $note = "start error: $($_.Exception.Message)"
    }

    Start-Sleep -Milliseconds 500

    $exists = Test-Path $outPath
    $bytes  = 0
    if ($exists) { $bytes = (Get-Item $outPath).Length }

    return [PSCustomObject]@{
        Exe        = $Exe
        SwitchUsed = $Switch
        Found      = $true
        Exited     = $exited
        ExitCode   = $ec
        FileExists = $exists
        FileBytes  = $bytes
        Note       = $note
    }
}

# foreach-with-yield pattern (one allocation, no +=)
$results = foreach ($t in $missing) {
    $stem = [IO.Path]::GetFileNameWithoutExtension($t)

    $r1 = Probe-CLI -Exe $t -Switch '/scomma' -OutName ("$stem-comma.csv")
    Write-Host ("[{0}] /scomma -> exited={1} file={2} ({3}B) exitCode={4} {5}" -f `
        $r1.Exe, $r1.Exited, $r1.FileExists, $r1.FileBytes, $r1.ExitCode, $r1.Note)

    $r2 = Probe-CLI -Exe $t -Switch '/stext'  -OutName ("$stem-text.txt")
    Write-Host ("[{0}] /stext  -> exited={1} file={2} ({3}B) exitCode={4} {5}" -f `
        $r2.Exe, $r2.Exited, $r2.FileExists, $r2.FileBytes, $r2.ExitCode, $r2.Note)

    ,$r1, ,$r2
}

# Summary table
Write-Host ""
Write-Host "==================== SUMMARY ====================" -ForegroundColor Cyan
$usable = $results | Where-Object { $_.FileExists -and $_.Exited -eq 'yes' }
Write-Host ("CLI-save tools that WORKED: {0}" -f $usable.Count) -ForegroundColor Green
foreach ($u in $usable) {
    Write-Host ("  - {0,-30} {1,-8} -> {2}B" -f $u.Exe, $u.SwitchUsed, $u.FileBytes) -ForegroundColor Green
}

$broken = $results | Where-Object { -not ($_.FileExists -and $_.Exited -eq 'yes') }
if ($broken.Count -gt 0) {
    Write-Host ""
    Write-Host ("CLI-save tools that DID NOT WORK: {0}" -f $broken.Count) -ForegroundColor Red
    foreach ($b in $broken) {
        Write-Host ("  - {0,-30} {1,-8} exited={2,-3} file={3,-5} bytes={4,-4} {5}" -f `
            $b.Exe, $b.SwitchUsed, $b.Exited, $b.FileExists, $b.FileBytes, $b.Note) -ForegroundColor Red
    }
}

# Save machine-readable report
$reportCsv = Join-Path $testRoot 'report.csv'
$results | Export-Csv -Path $reportCsv -NoTypeInformation -Encoding utf8
Write-Host ""
Write-Host "Detailed report: $reportCsv"
Write-Host "Probe outputs : $testRoot"
