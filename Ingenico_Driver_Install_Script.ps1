# Ingenico USB Driver Installation Script - Network Drive Version with Auto-Elevation
# This script will automatically elevate to Administrator if needed

# Check if running as Administrator
$isAdmin = ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)

if (-not $isAdmin) {
    Write-Host "Not running as Administrator. Elevating..." -ForegroundColor Yellow
    
    # Create a temporary script file
    $scriptContent = $MyInvocation.MyCommand.ScriptBlock.ToString()
    $tempScript = [System.IO.Path]::GetTempFileName() + ".ps1"
    Set-Content -Path $tempScript -Value $scriptContent
    
    # Launch elevated PowerShell with the script
    try {
        Start-Process powershell.exe -ArgumentList "-NoProfile -ExecutionPolicy Bypass -File `"$tempScript`"" -Verb RunAs -Wait
        Remove-Item $tempScript -Force -ErrorAction SilentlyContinue
        exit
    } catch {
        Write-Host "Failed to elevate. Please run PowerShell as Administrator manually." -ForegroundColor Red
        pause
        exit 1
    }
}

# Set strict mode for better error handling
Set-StrictMode -Version Latest
$ErrorActionPreference = "Continue"

# Display banner
Write-Host "=============================================" -ForegroundColor Cyan
Write-Host "  Ingenico USB Driver Installation Script" -ForegroundColor Cyan
Write-Host "=============================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "✓ Running as Administrator" -ForegroundColor Green
Write-Host ""

# Define variables
$NetworkDrive = "H:"
$NetworkPath = "\\YourServer\YourShare"  # CHANGE THIS to your actual UNC path (e.g., \\server\share)
$LogDir = "H:\Logs"
$LogFile = "$LogDir\CardReaderInstallLog.txt"
$InstallerName = "IngenicoUSBDrivers_2.80_setup.exe"
$InstallerDir = "H:\Card_Reader_Driver"
$TargetCOMPort = 21

# Function to write to both console and log file
function Write-Log {
    param(
        [string]$Message,
        [string]$Type = "Info"
    )
    
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $logMessage = "[$timestamp] [$Type] $Message"
    
    # Write to log file
    Add-Content -Path $LogFile -Value $logMessage -ErrorAction SilentlyContinue
    
    # Write to console with color
    switch ($Type) {
        "Success" { Write-Host $Message -ForegroundColor Green }
        "Error" { Write-Host $Message -ForegroundColor Red }
        "Warning" { Write-Host $Message -ForegroundColor Yellow }
        default { Write-Host $Message -ForegroundColor White }
    }
}

# Check if H: drive is accessible
Write-Host "Checking network drive access..." -ForegroundColor Cyan
if (-not (Test-Path $NetworkDrive)) {
    Write-Host "WARNING: H: drive is not accessible in elevated context" -ForegroundColor Yellow
    Write-Host "Attempting to map network drive..." -ForegroundColor Cyan
    
    try {
        # Remove existing mapping if any
        if (Get-PSDrive -Name "H" -ErrorAction SilentlyContinue) {
            Remove-PSDrive -Name "H" -Force -ErrorAction SilentlyContinue
        }
        
        # Map the network drive
        Write-Host "Mapping $NetworkDrive to $NetworkPath" -ForegroundColor Gray
        New-PSDrive -Name "H" -PSProvider FileSystem -Root $NetworkPath -Persist -Scope Global -ErrorAction Stop | Out-Null
        Write-Host "✓ Network drive mapped successfully!" -ForegroundColor Green
        Start-Sleep -Seconds 2
    } catch {
        Write-Host "✗ Failed to map network drive: $_" -ForegroundColor Red
        Write-Host ""
        Write-Host "SOLUTIONS:" -ForegroundColor Yellow
        Write-Host "1. Update the `$NetworkPath variable at the top of this script with your UNC path" -ForegroundColor Yellow
        Write-Host "   (e.g., \\server\share instead of \\YourServer\YourShare)" -ForegroundColor Yellow
        Write-Host "2. Or manually map H: drive before running this script" -ForegroundColor Yellow
        Write-Host "3. Or modify script to use UNC paths directly" -ForegroundColor Yellow
        pause
        exit 1
    }
}

# Verify access to the drive
if (-not (Test-Path $NetworkDrive)) {
    Write-Host "ERROR: Still cannot access H: drive" -ForegroundColor Red
    Write-Host "Please check your network connection and permissions" -ForegroundColor Yellow
    pause
    exit 1
}

Write-Host "✓ Network drive accessible" -ForegroundColor Green
Write-Host ""

# Step 1: Create log directory if it doesn't exist
Write-Host "[1/4] Checking log directory..." -ForegroundColor Cyan
if (-not (Test-Path $LogDir)) {
    try {
        New-Item -ItemType Directory -Path $LogDir -Force | Out-Null
        Write-Log "Log directory created: $LogDir" "Success"
    } catch {
        Write-Host "ERROR: Could not create log directory: $_" -ForegroundColor Red
        pause
        exit 1
    }
} else {
    Write-Log "Log directory already exists: $LogDir" "Info"
}

# Step 2: Check if installer exists
Write-Host ""
Write-Host "[2/4] Checking for installer..." -ForegroundColor Cyan
$InstallerPath = Join-Path $InstallerDir $InstallerName
if (-not (Test-Path $InstallerPath)) {
    Write-Log "ERROR: Installer not found at: $InstallerPath" "Error"
    Write-Host "Please ensure $InstallerName is in H:\Card_Reader_Driver folder." -ForegroundColor Yellow
    pause
    exit 1
}
Write-Log "Installer found: $InstallerPath" "Success"

# Step 3: Install the driver
Write-Host ""
Write-Host "[3/4] Installing Ingenico USB Drivers..." -ForegroundColor Cyan
Write-Log "Starting driver installation..." "Info"

try {
    # Note: The /VCOM parameter sets the Virtual COM Port (green arrow box)
    # If this doesn't work, you may need to use /PORT or check Ingenico documentation
    $arguments = "/S /VCOM=$TargetCOMPort"
    
    Write-Host "Running: $InstallerName $arguments" -ForegroundColor Gray
    Write-Log "Executing: $InstallerPath $arguments" "Info"
    
    $process = Start-Process -FilePath $InstallerPath -ArgumentList $arguments -Wait -PassThru -NoNewWindow
    
    $exitCode = $process.ExitCode
    Write-Log "Installer exit code: $exitCode" "Info"
    
    if ($exitCode -eq 0) {
        Write-Log "Driver installation completed successfully!" "Success"
        Write-Host "✓ Installation completed successfully!" -ForegroundColor Green
    } else {
        Write-Log "Driver installation failed with exit code: $exitCode" "Error"
        Write-Host "✗ Installation failed with exit code: $exitCode" -ForegroundColor Red
        Write-Host "Check the log file for details: $LogFile" -ForegroundColor Yellow
        pause
        exit $exitCode
    }
} catch {
    Write-Log "Exception during installation: $_" "Error"
    Write-Host "✗ Installation failed: $_" -ForegroundColor Red
    pause
    exit 1
}

# Wait a moment for device enumeration
Write-Host "Waiting for device enumeration..." -ForegroundColor Gray
Start-Sleep -Seconds 3

# Step 4: Find and configure the highest numbered USB Serial Device
Write-Host ""
Write-Host "[4/4] Configuring USB Serial Device COM Port..." -ForegroundColor Cyan
Write-Log "Searching for USB Serial Device COM ports..." "Info"

try {
    # Get ALL COM ports (not just "USB Serial Device")
    $allComPorts = Get-WmiObject Win32_PnPEntity | Where-Object {
        $_.Name -match "COM(\d+)"
    }
    
    if ($allComPorts) {
        # Extract COM port numbers and find the highest
        $comPorts = @()
        Write-Host "Found the following COM ports:" -ForegroundColor Cyan
        foreach ($port in $allComPorts) {
            if ($port.Name -match "COM(\d+)") {
                $comNumber = [int]$matches[1]
                Write-Host "  - $($port.Name)" -ForegroundColor Gray
                $comPorts += @{
                    Name = $port.Name
                    COMNumber = $comNumber
                    DeviceID = $port.DeviceID
                }
            }
        }
        
        # Sort and get the highest numbered port
        $highestPort = $comPorts | Sort-Object -Property COMNumber -Descending | Select-Object -First 1
        
        Write-Log "Found COM ports: $($comPorts.Count)" "Info"
        Write-Log "Highest numbered port: $($highestPort.Name)" "Info"
        
        if ($highestPort.COMNumber -ne $TargetCOMPort) {
            Write-Host "Found: $($highestPort.Name)" -ForegroundColor Yellow
            Write-Host "Changing COM port to COM$TargetCOMPort..." -ForegroundColor Cyan
            
            # Change COM port using devcon or registry
            # Registry path for COM port configuration
            $deviceID = $highestPort.DeviceID
            $regPath = "HKLM:\SYSTEM\CurrentControlSet\Enum\$deviceID\Device Parameters"
            
            if (Test-Path $regPath) {
                Set-ItemProperty -Path $regPath -Name "PortName" -Value "COM$TargetCOMPort" -ErrorAction Stop
                Write-Log "Successfully changed $($highestPort.Name) to COM$TargetCOMPort" "Success"
                Write-Host "✓ Successfully changed to COM$TargetCOMPort" -ForegroundColor Green
                Write-Host "NOTE: You may need to restart the device or computer for changes to take effect." -ForegroundColor Yellow
            } else {
                Write-Log "Could not find registry path for device: $regPath" "Warning"
                Write-Host "⚠ Could not automatically change COM port" -ForegroundColor Yellow
                Write-Host "Please change it manually in Device Manager to COM$TargetCOMPort" -ForegroundColor Yellow
            }
        } else {
            Write-Log "Device is already configured as COM$TargetCOMPort" "Success"
            Write-Host "✓ Device is already configured as COM$TargetCOMPort" -ForegroundColor Green
        }
    } else {
        Write-Log "No COM ports found" "Warning"
        Write-Host "⚠ No COM ports found" -ForegroundColor Yellow
        Write-Host "The device may not be connected or drivers may need time to load" -ForegroundColor Yellow
    }
} catch {
    Write-Log "Error configuring COM port: $_" "Error"
    Write-Host "⚠ Could not automatically configure COM port: $_" -ForegroundColor Yellow
    Write-Host "Please configure COM$TargetCOMPort manually in Device Manager" -ForegroundColor Yellow
}

# Final summary
Write-Host ""
Write-Host "=============================================" -ForegroundColor Cyan
Write-Host "  Installation Complete!" -ForegroundColor Green
Write-Host "=============================================" -ForegroundColor Cyan
Write-Host "Log file: $LogFile" -ForegroundColor Gray
Write-Host ""

Write-Log "Script execution completed" "Success"
pause
exit 0
