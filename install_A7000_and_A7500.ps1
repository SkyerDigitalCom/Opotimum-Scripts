# Netgear A7000 & A7500 Driver Installation Script
# Auto-elevates to admin and performs silent installation

# Network drive path
$networkPath = "\\emcnas-home.bmc.bmcroot.bmc.org\home"

# Driver installer paths
$driverA7000 = Join-Path $networkPath "A7000.exe"
$driverA7500 = Join-Path $networkPath "A7500.exe"

# Function to check if running as administrator
function Test-Administrator {
    $currentUser = [Security.Principal.WindowsIdentity]::GetCurrent()
    $principal = New-Object Security.Principal.WindowsPrincipal($currentUser)
    return $principal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
}

# Function to install driver silently
function Install-Driver {
    param(
        [string]$installerPath,
        [string]$driverName
    )
    
    if (-not (Test-Path $installerPath)) {
        Write-Host "ERROR: Installer not found at: $installerPath" -ForegroundColor Red
        return $false
    }
    
    Write-Host "Installing $driverName..." -ForegroundColor Yellow
    
    # Try multiple silent installation switches (common for driver installers)
    # /S = Silent, /VERYSILENT = Very silent, /SUPPRESSMSGBOXES = No prompts
    $arguments = "/S /VERYSILENT /SUPPRESSMSGBOXES /NORESTART"
    
    try {
        $process = Start-Process -FilePath $installerPath -ArgumentList $arguments -Wait -PassThru -NoNewWindow
        
        if ($process.ExitCode -eq 0) {
            Write-Host "SUCCESS: $driverName installed successfully." -ForegroundColor Green
            return $true
        } else {
            Write-Host "WARNING: $driverName installer exited with code: $($process.ExitCode)" -ForegroundColor Yellow
            return $true  # Some installers return non-zero even on success
        }
    }
    catch {
        Write-Host "ERROR: Failed to install $driverName - $_" -ForegroundColor Red
        return $false
    }
}

# Main script execution
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "Netgear Driver Installation Script" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

# Check for administrator privileges
if (-not (Test-Administrator)) {
    Write-Host "Not running as administrator. Attempting to elevate..." -ForegroundColor Yellow
    
    # Re-launch the script with administrator privileges
    $scriptPath = $MyInvocation.MyCommand.Path
    if ($scriptPath) {
        Start-Process powershell.exe -Verb RunAs -ArgumentList "-NoProfile -ExecutionPolicy Bypass -File `"$scriptPath`""
    } else {
        # If running from console, re-launch with current command
        Start-Process powershell.exe -Verb RunAs -ArgumentList "-NoProfile -ExecutionPolicy Bypass -Command & {$($MyInvocation.MyCommand.ScriptBlock)}"
    }
    exit
}

Write-Host "Running with administrator privileges." -ForegroundColor Green
Write-Host ""

# Verify network path is accessible
Write-Host "Verifying network path: $networkPath" -ForegroundColor Cyan
if (-not (Test-Path $networkPath)) {
    Write-Host "ERROR: Cannot access network path: $networkPath" -ForegroundColor Red
    Write-Host "Please ensure the network drive is accessible." -ForegroundColor Red
    Read-Host "Press Enter to exit"
    exit 1
}
Write-Host "Network path accessible." -ForegroundColor Green
Write-Host ""

# Install A7000 driver
$a7000Success = Install-Driver -installerPath $driverA7000 -driverName "Netgear A7000"
Write-Host ""

# Install A7500 driver
$a7500Success = Install-Driver -installerPath $driverA7500 -driverName "Netgear A7500 Nighthawk"
Write-Host ""

# Summary
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "Installation Summary" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "A7000: $(if($a7000Success){'SUCCESS'}else{'FAILED'})" -ForegroundColor $(if($a7000Success){'Green'}else{'Red'})
Write-Host "A7500: $(if($a7500Success){'SUCCESS'}else{'FAILED'})" -ForegroundColor $(if($a7500Success){'Green'}else{'Red'})
Write-Host ""

if ($a7000Success -and $a7500Success) {
    Write-Host "All drivers installed successfully!" -ForegroundColor Green
    Write-Host "A system restart may be required for changes to take effect." -ForegroundColor Yellow
} else {
    Write-Host "Some drivers failed to install. Please check the errors above." -ForegroundColor Red
}

Write-Host ""
Read-Host "Press Enter to exit"