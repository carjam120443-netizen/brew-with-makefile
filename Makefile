.PHONY: build install uninstall clean test

SHELL := powershell.exe
.SHELLFLAGS := -NoProfile -ExecutionPolicy Bypass -Command

PREFIX ?= $(HOME)\.brew-with-makefile
BIN_DIR := $(PREFIX)\bin

build:
	Write-Host 'brew-with-makefile: validating project...'; if (!(Test-Path .\brew.ps1)) { throw 'brew.ps1 is missing' }; if (!(Test-Path .\Formula)) { throw 'Formula directory is missing' }; Write-Host 'Build OK'

install:
	New-Item -ItemType Directory -Force '$(BIN_DIR)' | Out-Null; Copy-Item .\brew.ps1 '$(BIN_DIR)\brew.ps1' -Force; Set-Content '$(BIN_DIR)\brew.cmd' '@echo off','powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%~dp0brew.ps1" %*' -Encoding ascii; $p=[Environment]::GetEnvironmentVariable('Path','User'); $parts=@($p -split ';' | Where-Object { $_ }); if ($parts -notcontains '$(BIN_DIR)') { [Environment]::SetEnvironmentVariable('Path', (($parts + '$(BIN_DIR)') -join ';'), 'User') }; Write-Host "Installed brew to $(BIN_DIR). Open a new terminal and type: brew search"

uninstall:
	if (Test-Path '$(PREFIX)') { Remove-Item '$(PREFIX)' -Recurse -Force }; Write-Host 'Uninstalled'

clean:
	if (Test-Path .\build) { Remove-Item .\build -Recurse -Force }; Write-Host 'Clean complete'

test:
	powershell.exe -NoProfile -ExecutionPolicy Bypass -File .\tests\smoke-test.ps1
