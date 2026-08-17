param(
    [Parameter(Position=0)] [string]$Command = 'help',
    [Parameter(Position=1, ValueFromRemainingArguments=$true)] [string[]]$Arguments
)

$ErrorActionPreference = 'Stop'
$Root = Split-Path -Parent $MyInvocation.MyCommand.Path
$FormulaDir = Join-Path $Root 'Formula'
$Prefix = if ($env:BREW_PREFIX) { $env:BREW_PREFIX } else { Join-Path $HOME '.brew-with-makefile' }
$Packages = Join-Path $Prefix 'packages'
New-Item -ItemType Directory -Force $Packages | Out-Null

function Show-Help {
    Write-Host 'brew-with-makefile - a tiny native Windows brew-style package manager'
    Write-Host ''
    Write-Host 'Commands:'
    Write-Host '  brew list'
    Write-Host '  brew search <name>'
    Write-Host '  brew install <name>'
    Write-Host '  brew uninstall <name>'
    Write-Host '  brew info <name>'
}

function Get-Formula($Name) {
    $path = Join-Path $FormulaDir ($Name + '.json')
    if (!(Test-Path $path)) { throw "No formula named '$Name'" }
    return Get-Content $path -Raw | ConvertFrom-Json
}

switch ($Command.ToLower()) {
    'help' { Show-Help }
    'list' {
        if (!(Test-Path $Packages)) { return }
        Get-ChildItem $Packages -Directory | ForEach-Object { $_.Name }
    }
    'search' {
        $term = $Arguments[0]
        Get-ChildItem $FormulaDir -Filter '*.json' | Where-Object { $_.BaseName -like "*$term*" } | ForEach-Object { $_.BaseName }
    }
    'info' {
        $f = Get-Formula $Arguments[0]
        $f | ConvertTo-Json -Depth 5
    }
    'install' {
        $f = Get-Formula $Arguments[0]
        $dest = Join-Path $Packages $f.name
        New-Item -ItemType Directory -Force $dest | Out-Null
        $archive = Join-Path $dest ([IO.Path]::GetFileName($f.url))
        Write-Host "Downloading $($f.name) $($f.version)..."
        Invoke-WebRequest -Uri $f.url -OutFile $archive
        Write-Host "Downloaded to $archive"
        if ($f.sha256) {
            $actual = (Get-FileHash $archive -Algorithm SHA256).Hash.ToLower()
            if ($actual -ne $f.sha256.ToLower()) { Remove-Item $archive -Force; throw 'SHA256 verification failed' }
        }
        Write-Host "Installed $($f.name)"
    }
    'uninstall' {
        $dest = Join-Path $Packages $Arguments[0]
        if (Test-Path $dest) { Remove-Item $dest -Recurse -Force; Write-Host "Uninstalled $($Arguments[0])" } else { Write-Host 'Package is not installed' }
    }
    default { Show-Help }
}
