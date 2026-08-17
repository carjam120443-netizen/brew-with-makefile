# brew-with-makefile 🍺🪟

A small Homebrew-inspired package manager for native Windows, implemented with PowerShell and built/tested with GNU Make.

## Features

- `brew search <name>` — search local formulae
- `brew info <name>` — inspect a formula
- `brew install <name>` — download, verify SHA-256, extract ZIP/TAR archives, and install binary shims
- `brew uninstall <name>` — remove an installed package and its shims
- `brew list` — list installed packages
- `brew prefix` — show the installation prefix
- `brew doctor` — basic environment checks
- Formulae live in `Formula/*.json`
- Portable Windows ZIP is built automatically by GitHub Actions

## Build locally

Install GNU Make with Scoop, then run:

    make build
    make test
    make install

The default prefix is `%USERPROFILE%\.brew-with-makefile`. Set `BREW_PREFIX` to customize it.

## Download

Every push to `main` that changes the project runs the **Build Windows Download** workflow. The workflow creates `brew-with-makefile-windows.zip` and uploads it as the `brew-with-makefile-windows` Actions artifact.

Download the artifact from the workflow run's **Artifacts** section, extract it, and run `brew.cmd` from the extracted directory.

## Formula format

Example:

    {
      "name": "example",
      "version": "1.0.0",
      "description": "Example package",
      "url": "https://example.com/example.zip",
      "sha256": "...",
      "type": "zip",
      "binaries": ["example.exe"]
    }

`binaries` contains paths inside the extracted package. Matching files are copied into the brew prefix `bin` directory as command shims.

This is a Windows-native experimental project inspired by Homebrew; it is not the official Homebrew project.
