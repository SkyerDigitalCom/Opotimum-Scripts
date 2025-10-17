@echo off
REM =============================================
REM   Ingenico Driver Installer - Batch Launcher
REM   Double-click this file to run the installer
REM =============================================

title Ingenico USB Driver Installer

echo.
echo =============================================
echo   Ingenico USB Driver Installer
echo =============================================
echo.
echo Double-click Install.bat to run the installer
echo The script will automatically request admin rights
echo.
echo Starting installation...
echo.

REM Change to the directory where this batch file is located
cd /d "%~dp0"

REM Run the PowerShell script with auto-elevation
PowerShell.exe -NoProfile -ExecutionPolicy Bypass -File "%~dp0Ingenico_Driver_Install_Script.ps1"

echo.
echo Installation script completed.
echo.
pause
