@echo off
REM =============================================
REM   Ingenico USB Driver Installer
REM   All-in-One Batch File with Embedded PowerShell
REM =============================================

title Ingenico USB Driver Installer

echo.
echo =============================================
echo   Ingenico USB Driver Installer
echo =============================================
echo.
echo This will install Ingenico USB drivers and
echo configure the COM port to COM21
echo.

cd /d "%~dp0"

REM Create temporary PowerShell script
set "PS_SCRIPT=%TEMP%\IngenicoInstall_%RANDOM%.ps1"

echo Creating temporary script...

(
echo # Ingenico USB Driver Installation Script
echo # Auto-generated from batch file
echo.
echo $isAdmin = ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent(^)^).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator^)
echo.
echo if (-not $isAdmin^) {
echo     Write-Host "Requesting Administrator privileges..." -ForegroundColor Yellow
echo     $scriptPath = $MyInvocation.MyCommand.Path
echo     Start-Process powershell.exe -ArgumentList "-NoProfile -ExecutionPolicy Bypass -File `"$scriptPath`"" -Verb RunAs -Wait
echo     exit
echo }
echo.
echo Set-Location "%~dp0"
echo.
echo Write-Host "=============================================" -ForegroundColor Cyan
echo Write-Host "  Ingenico USB Driver Installation" -ForegroundColor Cyan
echo Write-Host "=============================================" -ForegroundColor Cyan
echo Write-Host ""
echo Write-Host "Running as Administrator" -ForegroundColor Green
echo Write-Host ""
echo.
echo $CurrentDir = Get-Location
echo $LogDir = Join-Path $CurrentDir "Logs"
echo $LogFile = Join-Path $LogDir "CardReaderInstallLog.txt"
echo $InstallerName = "IngenicoUSBDrivers_2.80_setup.exe"
echo $InstallerPath = Join-Path $CurrentDir $InstallerName
echo $TargetCOMPort = 21
echo.
echo function Write-Log {
echo     param([string]$Message, [string]$Type = "Info"^)
echo     $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
echo     $logMessage = "[$timestamp] [$Type] $Message"
echo     if (Test-Path $LogDir^) {
echo         Add-Content -Path $LogFile -Value $logMessage -ErrorAction SilentlyContinue
echo     }
echo     switch ($Type^) {
echo         "Success" { Write-Host $Message -ForegroundColor Green }
echo         "Error" { Write-Host $Message -ForegroundColor Red }
echo         "Warning" { Write-Host $Message -ForegroundColor Yellow }
echo         default { Write-Host $Message -ForegroundColor White }
echo     }
echo }
echo.
echo Write-Host "[1/4] Setting up logging..." -ForegroundColor Cyan
echo if (-not (Test-Path $LogDir^)^) {
echo     try {
echo         New-Item -ItemType Directory -Path $LogDir -Force ^| Out-Null
echo         Write-Log "Log directory created" "Success"
echo     } catch {
echo         Write-Host "WARNING: Could not create log directory" -ForegroundColor Yellow
echo     }
echo } else {
echo     Write-Log "Log directory exists" "Info"
echo }
echo.
echo Write-Host ""
echo Write-Host "[2/4] Looking for installer..." -ForegroundColor Cyan
echo Write-Host "Current directory: $CurrentDir" -ForegroundColor Gray
echo.
echo if (-not (Test-Path $InstallerPath^)^) {
echo     Write-Log "ERROR: Installer not found at: $InstallerPath" "Error"
echo     Write-Host "ERROR: IngenicoUSBDrivers_2.80_setup.exe not found!" -ForegroundColor Red
echo     Write-Host "Place the installer in: $CurrentDir" -ForegroundColor Yellow
echo     pause
echo     exit 1
echo }
echo.
echo Write-Host "Found installer!" -ForegroundColor Green
echo Write-Host ""
echo Write-Host "[3/4] Installing drivers..." -ForegroundColor Cyan
echo Write-Log "Starting installation..." "Info"
echo.
echo try {
echo     $process = Start-Process -FilePath $InstallerPath -ArgumentList "/S /VCOM=$TargetCOMPort" -Wait -PassThru -NoNewWindow
echo     if ($process.ExitCode -eq 0^) {
echo         Write-Host "Installation completed successfully!" -ForegroundColor Green
echo         Write-Log "Installation successful" "Success"
echo     } else {
echo         Write-Host "Installation failed with exit code: $($process.ExitCode^)" -ForegroundColor Red
echo         Write-Log "Installation failed: $($process.ExitCode^)" "Error"
echo         pause
echo         exit 1
echo     }
echo } catch {
echo     Write-Host "Installation error: $_" -ForegroundColor Red
echo     pause
echo     exit 1
echo }
echo.
echo Start-Sleep -Seconds 3
echo.
echo Write-Host ""
echo Write-Host "[4/4] Configuring COM port..." -ForegroundColor Cyan
echo Write-Log "Searching for COM ports..." "Info"
echo.
echo $allComPorts = Get-WmiObject Win32_PnPEntity ^| Where-Object { $_.Name -match "COM\(\d+\^)" }
echo.
echo if ($allComPorts^) {
echo     $comPorts = @(^)
echo     Write-Host "Found COM ports:" -ForegroundColor Cyan
echo     foreach ($port in $allComPorts^) {
echo         if ($port.Name -match "COM\(\d+\^)"^) {
echo             $comNumber = [int]$matches[1]
echo             Write-Host "  - $($port.Name^)" -ForegroundColor Gray
echo             $comPorts += @{ Name = $port.Name; COMNumber = $comNumber; DeviceID = $port.DeviceID }
echo         }
echo     }
echo.
echo     $highestPort = $comPorts ^| Sort-Object -Property COMNumber -Descending ^| Select-Object -First 1
echo.
echo     if ($highestPort.COMNumber -ne $TargetCOMPort^) {
echo         Write-Host "Changing $($highestPort.Name^) to COM$TargetCOMPort..." -ForegroundColor Yellow
echo         $deviceID = $highestPort.DeviceID
echo         $regPath = "HKLM:\SYSTEM\CurrentControlSet\Enum\$deviceID\Device Parameters"
echo.
echo         if (Test-Path $regPath^) {
echo             Set-ItemProperty -Path $regPath -Name "PortName" -Value "COM$TargetCOMPort" -ErrorAction Stop
echo             Write-Host "Successfully changed to COM$TargetCOMPort!" -ForegroundColor Green
echo             Write-Log "Changed to COM$TargetCOMPort" "Success"
echo         } else {
echo             Write-Host "Could not change COM port automatically" -ForegroundColor Yellow
echo             Write-Log "Failed to change COM port" "Warning"
echo         }
echo     } else {
echo         Write-Host "Already configured as COM$TargetCOMPort" -ForegroundColor Green
echo         Write-Log "Already COM$TargetCOMPort" "Success"
echo     }
echo } else {
echo     Write-Host "No COM ports found" -ForegroundColor Yellow
echo     Write-Log "No COM ports detected" "Warning"
echo }
echo.
echo Write-Host ""
echo Write-Host "=============================================" -ForegroundColor Cyan
echo Write-Host "  Installation Complete!" -ForegroundColor Green
echo Write-Host "=============================================" -ForegroundColor Cyan
echo Write-Host ""
echo if (Test-Path $LogFile^) {
echo     Write-Host "Log file: $LogFile" -ForegroundColor Gray
echo }
echo Write-Host ""
echo pause
) > "%PS_SCRIPT%"

echo Running PowerShell script...
echo.

REM Execute the PowerShell script
PowerShell.exe -NoProfile -ExecutionPolicy Bypass -File "%PS_SCRIPT%"

REM Clean up temporary script
if exist "%PS_SCRIPT%" del /f /q "%PS_SCRIPT%"

echo.
echo Done.
exit /b 0
