$ErrorActionPreference = 'Stop'
$Root = Split-Path -Parent $MyInvocation.MyCommand.Path
$Prefix = if ($env:BREW_PREFIX) { $env:BREW_PREFIX } else { Join-Path $HOME '.brew-with-makefile' }
$Bin = Join-Path $Prefix 'bin'
$FormulaTarget = Join-Path $Prefix 'Formula'

try {
    Write-Host 'Installing brew-with-makefile...'
    if (!(Test-Path (Join-Path $Root 'brew.ps1'))) { throw 'brew.ps1 was not found beside the installer.' }
    if (!(Test-Path (Join-Path $Root 'Formula'))) { throw 'Formula directory was not found beside the installer.' }

    New-Item -ItemType Directory -Force $Bin, $FormulaTarget | Out-Null
    Copy-Item (Join-Path $Root 'brew.ps1') (Join-Path $Bin 'brew-main.ps1') -Force
    Copy-Item (Join-Path $Root 'Formula\*') $FormulaTarget -Force
    $launcher = Join-Path $Bin 'brew.cmd'
    @('@echo off','powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%~dp0brew-main.ps1" %*') | Set-Content $launcher -Encoding ascii

    # Remove the old direct PowerShell launcher if a previous version installed it.
    $oldScript = Join-Path $Bin 'brew.ps1'
    if (Test-Path $oldScript) { Remove-Item $oldScript -Force }

    $userPath = [Environment]::GetEnvironmentVariable('Path','User')
    if ([string]::IsNullOrWhiteSpace($userPath)) { $parts = @() } else { $parts = @($userPath -split ';' | Where-Object { $_ }) }
    if ($parts -notcontains $Bin) {
        [Environment]::SetEnvironmentVariable('Path', (($parts + $Bin) -join ';'), 'User')
    }

    Write-Host ''
    Write-Host "Installed brew to: $Bin"
    Write-Host "Installed formulas to: $FormulaTarget"
    Write-Host 'Open a NEW PowerShell window, then run: brew search'
    Write-Host ''
    Write-Host 'Installation completed successfully.'
}
catch {
    Write-Host ''
    Write-Host 'INSTALLATION FAILED:' -ForegroundColor Red
    Write-Host $_.Exception.Message -ForegroundColor Red
    Write-Host ''
    Write-Host 'Press Enter to close this window...'
    Read-Host
    exit 1
}
