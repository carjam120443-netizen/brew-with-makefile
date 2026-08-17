$ErrorActionPreference = 'Stop'
if (!(Test-Path .\brew.ps1)) { throw 'brew.ps1 missing' }
if (!(Test-Path .\Makefile)) { throw 'Makefile missing' }
$help = powershell.exe -NoProfile -ExecutionPolicy Bypass -File .\brew.ps1 help | Out-String
if ($help -notmatch 'brew-with-makefile') { throw 'CLI help test failed' }
Write-Host 'Smoke tests passed.'
