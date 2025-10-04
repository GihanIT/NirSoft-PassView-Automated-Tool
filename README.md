# NirSoft PassView Automated Tool

A portable USB-based automation tool for collecting saved passwords and credentials using NirSoft utilities. This tool automates the execution of multiple NirSoft password recovery tools and saves all results to timestamped folders.

## ⚠️ Legal Disclaimer

**IMPORTANT:** This tool is intended for:
- Personal use on your own computers
- Authorized security auditing with proper permission
- Educational and research purposes
- IT administrators managing systems they own

**Unauthorized use on computers you don't own is illegal.** Always ensure you have explicit permission before running password recovery tools on any system.

---

## 📁 Project Structure

```
USB_ROOT\
├── tools\                      # Place all NirSoft EXE files here
│   ├── ChromePass.exe
│   ├── WirelessKeyView.exe
│   ├── WebBrowserPassView.exe
│   ├── mailpv.exe
│   ├── OperaPassView.exe
│   ├── PasswordFox.exe
│   └── [other NirSoft tools]
│
├── scripts\                    # Automation scripts
│   ├── collector.ps1          # Main PowerShell script (CSV output)
│   ├── start.bat              # Batch file launcher
│
├── results\                    # Auto-created output folder
│   └── YYYYMMDD_HHMMSS\       # Timestamped results folders
│       ├── collector.log
│       ├── ChromePass.csv
│       ├── wifi_keys.csv
│       └── [other outputs]
│
└── README.md                   # This file
```

---

## 🚀 Quick Start Guide

### Step 1: Setup the USB Drive

1. Copy the entire project structure to your USB drive
2. Verify the folder structure matches the layout above
3. Ensure all scripts are in the `scripts\` folder

### Step 3: Run the Collector

**Important:** Right-click `start.bat` → **"Run as administrator"**

- Some tools (especially WirelessKeyView) require administrator privileges
- Running without admin rights will cause some tools to fail

---

## 🔧 Troubleshooting

### Issue: "No output files created"

**Possible causes:**
1. **No data to extract** - If you don't have passwords saved in that browser/application, no file will be created
2. **Antivirus blocking** - Most antivirus software blocks password recovery tools
3. **Not running as admin** - WirelessKeyView and some other tools require administrator rights
4. **Application not installed** - If Firefox isn't installed, PasswordFox won't find anything

**Solutions:**
- ✅ Verify you have passwords saved in the browser (check browser settings)
- ✅ Temporarily disable antivirus or add `tools\` folder to exclusions
- ✅ Always run as administrator
- ✅ Run the diagnostic test (see below)

### Issue: "Antivirus keeps blocking the tools"

**Solution:**
1. Open Windows Security (or your antivirus)
2. Go to Virus & threat protection settings
3. Turn it off temporary
4. Try running again

### Issue: "GUI windows keep appearing"

Some NirSoft tools may still show their GUI interface briefly. This is normal behavior for certain tools that require user interaction to save output.

**What to do:**
- Let the GUI window open
- Click the Save button or close the window
- The tool will save the file automatically

**Note:** WirelessKeyView and OperaPassView auto-save when closed. Other tools may need manual saving.

---

## 📊 Understanding Results

### Result Files

Each run creates a new timestamped folder:
```
results\20251004_103942\
├── collector.log           # Detailed execution log
├── ChromePass.txt         # Chrome passwords
├── wifi_keys.txt          # WiFi passwords
├── browser_passwords.txt  # Multi-browser passwords
├── MailPass.txt           # Email passwords
├── OperaPass.txt          # Opera passwords
└── PasswordFox.txt        # Firefox passwords
```

### Log File

The `collector.log` file contains:
- Timestamp for each operation
- Success/failure status for each tool
- File sizes and locations
- Error messages if any issues occurred

---

## ⚙️ Advanced Configuration

### Adding More NirSoft Tools

To add additional NirSoft tools:

1. Download the tool from NirSoft
2. Place the `.exe` in the `tools\` folder
3. Edit `collector.ps1` and add a new line:
   ```powershell
   Run-Tool -exe 'ToolName.exe' -outfile 'output.csv' -saveParam '/scomma'
   ```

### Changing Output Format

If you prefer text files instead of CSV:

Edit the tool execution lines in `collector.ps1`:
```powershell
# Change from:
Run-Tool -exe 'ChromePass.exe' -outfile 'ChromePass.csv' -saveParam '/scomma'

# To:
Run-Tool -exe 'ChromePass.exe' -outfile 'ChromePass.txt' -saveParam '/stext'
```

**Note:** `/stext` format may require manual GUI interaction for some tools.

### Enabling Auto-Compression

To automatically compress results into a ZIP file:

Run the collector with the `-ZipResults` parameter:
```powershell
powershell.exe -NoProfile -ExecutionPolicy Bypass -File "collector.ps1" -ZipResults
```

Or edit `start.bat` and modify the PowerShell line to include `-ZipResults`

---

## 🔒 Security Considerations

### Protecting Collected Data

**The collected password files contain sensitive information!**

Best practices:
- ✅ Keep the USB drive encrypted (use BitLocker or VeraCrypt)
- ✅ Delete results after analysis
- ✅ Never store on shared computers
- ✅ Use strong password protection on the drive
- ✅ Don't leave USB drive unattended

### False Positive Warnings

NirSoft password recovery tools are legitimate utilities but are often flagged by antivirus software as "potentially unwanted programs" (PUP) or "hacking tools."

**This is normal behavior.** These tools are safe when downloaded from the official NirSoft website.

---

## 🛠️ System Requirements

- **Operating System:** Windows 7 or later (Windows 10/11 recommended)
- **Privileges:** Administrator rights required for full functionality
- **PowerShell:** Version 5.0 or later (included in Windows 10/11)
- **Disk Space:** Minimal (results are usually a few KB to few MB)
- **USB Drive:** Any size (FAT32, NTFS, or exFAT formatted)

---

## 📝 Common Use Cases

### 1. Personal Password Recovery
Recover your own forgotten passwords from browsers and applications.

### 2. System Migration
Export passwords before migrating to a new computer or reinstalling Windows.

### 3. Security Auditing
Check which passwords are stored in plain text or easily recoverable on managed systems.

### 4. IT Administration
Recover credentials for decommissioned systems or assist users who lost access.

---

## 🐛 Known Issues

### Issue: Empty Files Created

**Cause:** The tool ran successfully but found no data to extract.

**Meaning:** 
- No passwords saved in that application
- Application not installed
- Browser profile empty or new

**Solution:** This is expected behavior. Not every tool will find data on every system.

### Issue: Script Execution Policy Error

If you see: `cannot be loaded because running scripts is disabled`

**Solution:**
1. Open PowerShell as Administrator
2. Run: `Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser`
3. Try running the script again

Or use the provided `start.bat` which bypasses this automatically.

---

## 📚 Additional Resources

- **NirSoft Password Recovery Tools:** https://www.nirsoft.net/password_recovery_tools.html
- **NirSoft FAQ:** https://www.nirsoft.net/faq.html
- **Command-Line Options:** Most tools support `/help` parameter for details

---

## 📜 Version History

### Version 1.0 (Current)
- Initial release
- Automated NirSoft tool execution
- CSV output format
- Timestamped result folders
- Comprehensive logging
- Diagnostic testing utility
- Administrator privilege checking

---

## 📄 License & Credits

This automation tool is provided as-is for legitimate use cases only.

**NirSoft Utilities:** Created by Nir Sofer - https://www.nirsoft.net/
- NirSoft utilities are freeware for personal and commercial use
- Please review NirSoft's license terms on their website

**Automation Scripts:** Open for personal and educational use.

---

## ⚖️ Legal Notice

**USE THIS TOOL RESPONSIBLY**

Unauthorized access to computer systems and data is illegal. This tool should only be used:
- On systems you own
- With explicit written authorization
- For legitimate security research
- For personal password recovery

The creators of this tool are not responsible for misuse or illegal activities performed with this software.

**If in doubt about legality, consult with legal counsel before use.**