# Ingenico USB Driver Installer

Automated PowerShell scripts for installing Ingenico USB drivers and configuring COM ports on Windows systems.

## 🚀 Features

- **Automatic Administrator Elevation** - Scripts automatically request admin privileges if needed
- **Intelligent COM Port Detection** - Finds and configures any COM port device
- **Dual Installation Methods** - Choose between simple local installation or network drive installation
- **Automatic COM Port Reconfiguration** - Changes the highest numbered COM port to COM21
- **Comprehensive Logging** - Detailed logs for troubleshooting
- **Visual Progress Indicators** - Color-coded status messages throughout installation
- **Error Handling** - Graceful error handling with helpful messages

## 📋 Prerequisites

- Windows 10 or later
- PowerShell 5.1 or later
- Administrator privileges (scripts will auto-elevate)
- Ingenico USB Driver installer (`IngenicoUSBDrivers_2.80_setup.exe`)

## 📦 Installation

### Method 1: Simple Version (Recommended)

**Best for:** Most users, local installations, copy-paste into PowerShell

1. Download or navigate to the folder containing `IngenicoUSBDrivers_2.80_setup.exe`
2. Open PowerShell (no need to run as Administrator - script will auto-elevate)
3. Navigate to the installer folder:
   ```powershell
   cd H:\Card_Reader_Driver
   ```
4. Copy and paste the **Simple Version** script
5. Press Enter
6. Click "Yes" on the UAC prompt
7. Wait for installation to complete

### Method 2: Network Drive Version (Advanced)

**Best for:** Enterprise deployments, network drive installations

1. Edit the script and update the network path:
   ```powershell
   $NetworkPath = "\\YourServer\YourShare"  # Change to your UNC path
   ```
2. Open PowerShell (script will auto-elevate)
3. Copy and paste the **Network Drive Version** script
4. Press Enter
5. Click "Yes" on the UAC prompt
6. Wait for installation to complete

## 🛠️ How It Works

### Installation Process

1. **Elevation Check** - Verifies Administrator privileges, auto-elevates if needed
2. **Environment Setup** - Creates log directory, verifies installer exists
3. **Driver Installation** - Installs Ingenico USB drivers with `/S /VCOM=21` parameters
4. **Device Detection** - Scans for all COM port devices
5. **Port Configuration** - Identifies the highest numbered COM port
6. **Registry Modification** - Changes COM port to COM21 via registry
7. **Completion** - Displays summary and log file location

### COM Port Configuration

The script automatically:
- Detects **all COM port devices** (not just specific device names)
- Identifies the **highest numbered COM port**
- Changes it to **COM21** via registry modification
- Provides feedback on success or failure

## 📊 Script Comparison

| Feature | Simple Version | Network Drive Version |
|---------|---------------|----------------------|
| Auto-Elevation | ✅ Yes | ✅ Yes |
| Network Drive Mapping | ❌ No | ✅ Yes |
| Configuration Required | ❌ None | ✅ UNC Path |
| Best Use Case | Local installations | Enterprise deployments |
| Complexity | Simple | Advanced |

## 🔍 Troubleshooting

### "No COM ports found"

**Cause:** Device not connected or drivers not loaded

**Solutions:**
- Ensure the Ingenico device is plugged in via USB
- Wait 15-20 seconds after driver installation
- Unplug and replug the device
- Check Device Manager for COM ports

### "Installer not found"

**Cause:** Script cannot locate the installer file

**Solutions:**
- Verify `IngenicoUSBDrivers_2.80_setup.exe` is in the correct folder
- Ensure you navigated to the correct directory before running the script
- Check file name matches exactly (case-sensitive)

### "Failed to map network drive"

**Cause:** Invalid UNC path or insufficient permissions (Network version only)

**Solutions:**
- Verify the `$NetworkPath` variable is set correctly
- Test the UNC path manually: `net use H: \\server\share`
- Check network permissions
- Ensure the network drive is accessible

### "Could not automatically change COM port"

**Cause:** Registry path not found or insufficient permissions

**Solutions:**
- Manually change COM port in Device Manager:
  1. Open Device Manager
  2. Expand "Ports (COM & LPT)"
  3. Right-click the device → Properties
  4. Port Settings → Advanced → COM Port Number → Select COM21
- Restart the computer after driver installation
- Run script again after device is detected

## 📝 Logging

Logs are automatically created at:
- **Simple Version:** `.\Logs\CardReaderInstallLog.txt` (current directory)
- **Network Version:** `H:\Logs\CardReaderInstallLog.txt`

Log files include:
- Timestamps for all operations
- Installation exit codes
- COM port detection results
- Configuration changes
- Error messages and warnings

## 🔧 Configuration Options

### Change Target COM Port

Edit this line in either script:
```powershell
$TargetCOMPort = 21  # Change to desired COM port number
```

### Change Installer Name

Edit this line in either script:
```powershell
$InstallerName = "IngenicoUSBDrivers_2.80_setup.exe"  # Change to your installer filename
```

### Network Drive Path (Network Version Only)

Edit this line:
```powershell
$NetworkPath = "\\YourServer\YourShare"  # Change to your UNC path
```

## 🖥️ System Requirements

- **Operating System:** Windows 10, Windows 11, Windows Server 2016+
- **PowerShell:** Version 5.1 or later
- **Permissions:** Administrator rights (auto-elevation enabled)
- **Disk Space:** Minimal (< 50 MB for drivers)
- **Network:** Required for Network Drive version only

## 📄 License

This project is provided as-is for use with Ingenico card reader devices. Modify and distribute freely.

## 🤝 Contributing

Contributions are welcome! Please feel free to submit issues or pull requests.

### Areas for Improvement
- Support for additional driver versions
- GUI interface option
- Silent installation mode (no pause prompts)
- Multi-device COM port configuration
- Uninstallation script

## 📞 Support

For issues or questions:
1. Check the [Troubleshooting](#-troubleshooting) section
2. Review the log files
3. Open an issue on GitHub
4. Consult Ingenico's official documentation

## ⚠️ Disclaimer

This script modifies system settings and registry values. Always test in a non-production environment first. The authors are not responsible for any system issues that may arise from using these scripts.

## 🔗 Related Links

- [Ingenico Official Website](https://www.ingenico.com)
- [PowerShell Documentation](https://docs.microsoft.com/en-us/powershell/)
- [Windows Device Manager Guide](https://support.microsoft.com/en-us/windows/device-manager)

## 📅 Version History

### Version 1.0 (Current)
- Initial release
- Auto-elevation support
- Dual installation methods
- Comprehensive COM port detection
- Automatic COM port reconfiguration
- Full logging support

---

**Made with ❤️ for easier Ingenico driver deployments**
