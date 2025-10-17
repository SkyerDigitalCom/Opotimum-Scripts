@echo off
REM Runs YourScript.ps1 from the same folder as this .bat
powershell -NoProfile -ExecutionPolicy Bypass -File "Ingenico_Driver_Install_Script.ps1" %*
exit /b %ERRORLEVEL%
