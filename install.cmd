@echo off
setlocal
powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%~dp0install.ps1"
if errorlevel 1 (
  echo.
  echo Installation failed. The PowerShell window will stay open.
  pause
  exit /b 1
)
echo.
echo Installation finished. You can close this window.
pause
