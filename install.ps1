$ErrorActionPreference = 'Stop'
$Root = Split-Path -Parent $MyInvocation.MyCommand.Path
$Prefix = if ($env:BREW_PREFIX) { $env:BREW_PREFIX } else { Join-Path $HOME '.brew-with-makefile' }
$Bin = Join-Path $Prefix 'bin'
New-Item -ItemType Directory -Force $Bin | Out-Null
Copy-Item (Join-Path $Root 'brew.ps1') (Join-Path $Bin 'brew.ps1') -Force
Set-Content (Join-Path $Bin 'brew.cmd') '@echo off','powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%~dp0brew.ps1" %*' -Encoding ascii
$userPath = [Environment]::GetEnvironmentVariable('Path','User')
$parts = @($userPath -split ';' | Where-Object { $_ })
if ($parts -notcontains $Bin) { [Environment]::SetEnvironmentVariable('Path', (($parts + $Bin) -join ';'), 'User') }
Write-Host "Installed brew to $Bin"
Write-Host 'Open a new PowerShell window and run: brew search'
