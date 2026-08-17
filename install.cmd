@echo off
setlocal
set "PREFIX=%USERPROFILE%\.brew-with-makefile"
if defined BREW_PREFIX set "PREFIX=%BREW_PREFIX%"
if exist "%PREFIX%\bin\brew.ps1" (
  echo Removing old unsigned brew.ps1 launcher...
  del /f /q "%PREFIX%\bin\brew.ps1"
)
powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%~dp0install.ps1"
if errorlevel 1 (
  echo.
  echo Installation failed. The PowerShell window will stay open.
  pause
  exit /b 1
)
echo.
echo Installation finished. Open a NEW PowerShell window before running brew.
echo.
pause
