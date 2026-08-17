.PHONY: build install uninstall clean test

SHELL := powershell.exe
.SHELLFLAGS := -NoProfile -ExecutionPolicy Bypass -Command

PREFIX ?= $(HOME)\.brew-with-makefile
BIN_DIR := $(PREFIX)\bin

build:
	Write-Host 'brew-with-makefile: nothing to compile; validating project...'; if (!(Test-Path .\brew.ps1)) { throw 'brew.ps1 is missing' }; Write-Host 'Build OK'

install:
	New-Item -ItemType Directory -Force '$(BIN_DIR)' | Out-Null; Copy-Item .\brew.ps1 '$(BIN_DIR)\brew.ps1' -Force; @'\n@echo off\npowershell.exe -NoProfile -ExecutionPolicy Bypass -File "%~dp0brew.ps1" %*\n'@ | Set-Content '$(BIN_DIR)\brew.cmd'; Write-Host "Installed to $(BIN_DIR)"

uninstall:
	if (Test-Path '$(PREFIX)') { Remove-Item '$(PREFIX)' -Recurse -Force }; Write-Host 'Uninstalled'

clean:
	if (Test-Path .\build) { Remove-Item .\build -Recurse -Force }; Write-Host 'Clean complete'

test:
	powershell.exe -NoProfile -ExecutionPolicy Bypass -File .\tests\smoke-test.ps1
