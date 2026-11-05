@echo off
powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%~dp0CopyAsPath.ps1" -Uninstall
echo.
pause
