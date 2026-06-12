# All-win-1

PowerShell tool for Windows environment configuration, package management, system tweaks, and development environment setup.

## Features

- **Package Management**: Install, export, and restore packages via Winget, Chocolatey, and Scoop
- **Development Tools**: Install language runtimes, version managers (fnm, nvm, mise), package managers (npm, pip, pnpm), and dev tools
- **System Tweaks**: Explorer settings, power plans, theme toggles, time sync, computer rename, and more
- **Environment Variables**: Backup, compare, and restore environment variables per scope (User/Machine)
- **PowerShell Themes**: Apply community themes like Dracula to the console
- **Windows Themes**: Install Windhawk (Win 11) and SecureUxTheme
- **Settings Menu**: Quick access to Windows settings panels

## Prerequisites

| Requirement | Notes |
|---|---|
| Windows 10 1809+ | Winget support requires build 16299+ |
| PowerShell 3.0+ | Some features benefit from newer versions |
| Administrator rights | Required for system-level operations |

Optional tools may be installed from within the tool itself.

## Quick Start

```powershell
# 1. Open PowerShell as Administrator (Win+X, then A)

# 2. Navigate to the project directory
cd <path-to-all-win-1>

# 3. Run
Set-ExecutionPolicy RemoteSigned -Scope Process -Force; .\main.ps1
```

## Configuration

Edit `config.ps1` to adjust backup/export file paths.  
Edit files under `data/` to customize package lists and environment variable templates.

- `data/winget.json` / `data/winget.ps1` — Winget package catalog
- `data/chocolatey.json` / `data/chocolatey.ps1` — Chocolatey package list
- `data/scoop.json` / `data/scoop.ps1` — Scoop package list
- `data/packages.json` / `data/packages.ps1` — Node.js and Python global packages
- `data/environmentvariables.json` / `data/environmentvariables.ps1` — Environment variable reference profiles

## Project Structure

```
All-win-1/
├── main.ps1             # Entry point
├── config.ps1           # Global configuration
├── data/                # Data files (JSON + PowerShell objects)
│   ├── backup/          # Export/backup output directory
│   ├── winget.*
│   ├── chocolatey.*
│   ├── scoop.*
│   ├── packages.*
│   └── environmentvariables.*
├── modules/             # Feature modules
│   ├── menu.ps1         # Menu display system
│   ├── winget.ps1
│   ├── chocolatey.ps1
│   ├── scoop.ps1
│   ├── 4devs.ps1
│   ├── environmentVariables.ps1
│   ├── pwshThemes.ps1
│   ├── themes.ps1
│   ├── tweaks.ps1
│   ├── globals.ps1
│   ├── ps-menu/         # Interactive menu engine
│   └── utils/           # Shared utilities
│       ├── json.ps1
│       ├── arrays.ps1
│       ├── recursive.ps1
│       └── utils.ps1
├── .gitattributes
└── LICENSE
```

## Contributing

Contributions are welcome. Open an issue for bugs or feature requests, or submit a pull request.

## License

This project is licensed under the terms of the LICENSE file included in the repository.
