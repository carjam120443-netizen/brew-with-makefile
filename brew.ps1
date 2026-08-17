param(
    [Parameter(Position=0)] [string]$Command = 'help',
    [Parameter(Position=1, ValueFromRemainingArguments=$true)] [string[]]$Arguments
)

$ErrorActionPreference = 'Stop'
$Root = Split-Path -Parent $MyInvocation.MyCommand.Path
$Prefix = if ($env:BREW_PREFIX) { $env:BREW_PREFIX } else { Join-Path $HOME '.brew-with-makefile' }
$FormulaDir = if (Test-Path (Join-Path $Root 'Formula')) { Join-Path $Root 'Formula' } else { Join-Path $Prefix 'Formula' }
$Packages = Join-Path $Prefix 'packages'
$Bin = Join-Path $Prefix 'bin'
New-Item -ItemType Directory -Force $Packages, $Bin | Out-Null

function Show-Help {
    Write-Host 'brew-with-makefile - native Windows package manager'
    Write-Host ''
    Write-Host 'Commands:'
    Write-Host '  brew setup'
    Write-Host '  brew list'
    Write-Host '  brew search [name]'
    Write-Host '  brew install <name>'
    Write-Host '  brew uninstall <name>'
    Write-Host '  brew info <name>'
    Write-Host '  brew doctor'
    Write-Host '  brew prefix'
}

function Get-Formula($Name) {
    $path = Join-Path $FormulaDir ($Name + '.json')
    if (!(Test-Path $path)) { throw "No formula named '$Name'" }
    return Get-Content $path -Raw | ConvertFrom-Json
}

function Add-CommandShims($Formula, $InstallDir) {
    if (!$Formula.binaries) { return }
    foreach ($binary in $Formula.binaries) {
        $source = Join-Path $InstallDir $binary
        if (!(Test-Path $source)) {
            $leaf = Split-Path $binary -Leaf
            $found = Get-ChildItem $InstallDir -Recurse -File -Filter $leaf | Select-Object -First 1
            if ($found) { $source = $found.FullName }
        }
        if (!(Test-Path $source)) { throw "Formula '$($Formula.name)' listed binary '$binary', but it was not found after extraction." }
        $target = Join-Path $Bin ([IO.Path]::GetFileName($binary))
        Copy-Item $source $target -Force
    }
}

function Remove-CommandShims($Formula) {
    if (!$Formula.binaries) { return }
    foreach ($binary in $Formula.binaries) {
        $target = Join-Path $Bin ([IO.Path]::GetFileName($binary))
        if (Test-Path $target) { Remove-Item $target -Force }
    }
}

function Setup-Brew {
    New-Item -ItemType Directory -Force $Bin | Out-Null
    $launcher = Join-Path $Bin 'brew.cmd'
    @"
@echo off
powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%~dp0brew-main.ps1" %*
"@ | Set-Content $launcher -Encoding ascii
    Copy-Item $PSCommandPath (Join-Path $Bin 'brew-main.ps1') -Force
    $oldScript = Join-Path $Bin 'brew.ps1'
    if (Test-Path $oldScript) { Remove-Item $oldScript -Force }
    $userPath = [Environment]::GetEnvironmentVariable('Path', 'User')
    $parts = if ([string]::IsNullOrWhiteSpace($userPath)) { @() } else { @($userPath -split ';' | Where-Object { $_ }) }
    if ($parts -notcontains $Bin) { [Environment]::SetEnvironmentVariable('Path', (($parts + $Bin) -join ';'), 'User') }
    $env:Path = "$Bin;$env:Path"
    Write-Host 'Brew setup complete. Open a new PowerShell window, then use: brew search'
}

switch ($Command.ToLower()) {
    'help' { Show-Help }
    'setup' { Setup-Brew }
    'list' {
        $items = Get-ChildItem $Packages -Directory -ErrorAction SilentlyContinue
        if ($items) { $items | ForEach-Object { $_.Name } } else { Write-Host 'No packages installed.' }
    }
    'search' {
        $term = if ($Arguments.Count) { $Arguments[0] } else { '' }
        $items = Get-ChildItem $FormulaDir -Filter '*.json' | Where-Object { $_.BaseName -like "*$term*" }
        if ($items) { $items | ForEach-Object { $_.BaseName } } else { Write-Host 'No matching formulae.' }
    }
    'info' {
        if (!$Arguments.Count) { throw 'Usage: brew info <name>' }
        Get-Formula $Arguments[0] | ConvertTo-Json -Depth 10
    }
    'prefix' { Write-Host $Prefix }
    'doctor' {
        Write-Host "Prefix: $Prefix"
        Write-Host "Formulae: $FormulaDir"
        Write-Host "PowerShell: $($PSVersionTable.PSVersion)"
        if (Get-Command tar -ErrorAction SilentlyContinue) { Write-Host 'Archive extraction: available' } else { Write-Host 'Archive extraction: missing tar' }
        if (Test-Path $Bin) { Write-Host "Brew bin: $Bin" }
        Write-Host 'Doctor: OK'
    }
    'install' {
        if (!$Arguments.Count) { throw 'Usage: brew install <name>' }
        $f = Get-Formula $Arguments[0]
        $dest = Join-Path $Packages $f.name
        if (Test-Path $dest) { Write-Host "$($f.name) is already installed."; break }
        New-Item -ItemType Directory -Force $dest | Out-Null
        $archiveName = [IO.Path]::GetFileName(([Uri]$f.url).AbsolutePath)
        if ([string]::IsNullOrWhiteSpace($archiveName)) { $archiveName = "$($f.name).download" }
        $archive = Join-Path $dest $archiveName
        try {
            Write-Host "Downloading $($f.name) $($f.version)..."
            Invoke-WebRequest -Uri $f.url -OutFile $archive
            if (!$f.sha256) { throw "Formula '$($f.name)' has no SHA256 checksum." }
            $actual = (Get-FileHash $archive -Algorithm SHA256).Hash.ToLower()
            if ($actual -ne $f.sha256.ToLower()) { throw "SHA256 verification failed for $($f.name)." }
            Write-Host 'SHA256 verified.'
            $type = if ($f.type) { $f.type.ToLower() } else { 'zip' }
            if ($type -eq 'zip') { Expand-Archive -LiteralPath $archive -DestinationPath $dest -Force; Remove-Item $archive -Force }
            elseif ($type -eq 'tar' -or $type -eq 'tar.gz' -or $type -eq 'tgz') { tar -xf $archive -C $dest; Remove-Item $archive -Force }
            elseif ($type -ne 'file' -and $type -ne 'exe') { throw "Unsupported package type '$type'." }
            Add-CommandShims $f $dest
            Write-Host "Installed $($f.name) $($f.version)"
            Write-Host "Binary shims: $Bin"
        } catch {
            if (Test-Path $dest) { Remove-Item $dest -Recurse -Force -ErrorAction SilentlyContinue }
            throw
        }
    }
    'uninstall' {
        if (!$Arguments.Count) { throw 'Usage: brew uninstall <name>' }
        $f = Get-Formula $Arguments[0]
        $dest = Join-Path $Packages $f.name
        Remove-CommandShims $f
        if (Test-Path $dest) { Remove-Item $dest -Recurse -Force; Write-Host "Uninstalled $($f.name)" } else { Write-Host 'Package is not installed' }
    }
    default { Show-Help }
}
