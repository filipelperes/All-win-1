# All‑win‑1

> PowerShell toolkit for Windows environment configuration, package management, system tweaks, and development environment setup.

[![PowerShell](https://img.shields.io/badge/PowerShell-3.0%2B-5391FE?logo=powershell&logoColor=white)](https://github.com/PowerShell/PowerShell)
[![Windows](https://img.shields.io/badge/Windows-10%201809%2B%20%7C%2011-0078D6?logo=windows&logoColor=white)](https://www.microsoft.com/windows)
[![License](https://img.shields.io/badge/license-MIT-green)](LICENSE)
[![PRs Welcome](https://img.shields.io/badge/PRs-welcome-brightgreen)](https://github.com/filipelperes/all-win-1/pulls)

---

## Features

| Category | Capabilities |
|---|---|
| **Package Management** | Install, export, and restore packages via Winget, Chocolatey, and Scoop |
| **Development Tools** | Language runtimes, version managers (fnm, nvm, mise), package managers (npm, pip, pnpm), and dev tooling |
| **System Tweaks** | Explorer settings, power plans, theme toggles, time sync, computer rename, and more |
| **Environment Variables** | Backup, compare, and restore environment variables per scope (User / Machine) |
| **Console Themes** | Apply community themes like Dracula to the PowerShell console |
| **Windows Themes** | Install Windhawk (Windows 11) and SecureUxTheme |
| **Settings Launcher** | Quick-access menu to Windows settings panels |

---

## Prerequisites

| Requirement | Details |
|---|---|
| **Windows 10 1809+** | Winget support requires build 16299+ |
| **PowerShell 3.0+** | Some features benefit from newer versions; Windows 10 ships with 5.1 |
| **Administrator rights** | Required for system-level operations |

Optional tools (e.g., Chocolatey, Scoop) can be installed from within the tool itself.

---

## Quick Start

```powershell
# 1. Open PowerShell as Administrator (Win+X, then A)

# 2. Navigate to the project directory
cd <path-to-all-win-1>

# 3. Bypass execution policy for the session and launch
Set-ExecutionPolicy RemoteSigned -Scope Process -Force; .\main.ps1
```

> **Tip:** If you run the tool frequently, add an alias to your `$PROFILE`:
> ```powershell
> Set-Alias allwin C:\path\to\all-win-1\main.ps1
> ```

---

## Configuration

Edit **`config.ps1`** to customize backup / export file paths:

| Variable | Default Path | Purpose |
|---|---|---|
| `$wingetJSONFileBkp` | `data\backup\winget.json` | Winget export/import |
| `$chocoConfigFileBkp` | `data\backup\chocolatey.config` | Chocolatey export/import |
| `$scoopJSONFileBkp` | `data\backup\scoop.json` | Scoop export/import |

Edit files under **`data/`** to customize package lists and environment variable reference profiles:

| File(s) | Purpose |
|---|---|
| `data/winget.json` / `data/winget.ps1` | Winget package catalog |
| `data/chocolatey.json` / `data/chocolatey.ps1` | Chocolatey package list |
| `data/scoop.json` / `data/scoop.ps1` | Scoop package list |
| `data/packages.json` / `data/packages.ps1` | Node.js and Python global packages |
| `data/environmentvariables.json` / `data/environmentvariables.ps1` | Environment variable reference profiles |

Both `.json` and `.ps1` variants contain the same data; the `.ps1` files are loaded first for better performance.

---

## Project Structure

```
All-win-1/
├── main.ps1                  # Entry point
├── config.ps1                # Global configuration
│
├── data/                     # Data files (JSON + pre-built PowerShell objects)
│   ├── backup/               # Export/backup output directory
│   ├── winget.*
│   ├── chocolatey.*
│   ├── scoop.*
│   ├── packages.*
│   └── environmentvariables.*
│
├── modules/                  # Feature modules
│   ├── menu.ps1              # Menu display system
│   ├── winget.ps1            # Winget package management
│   ├── chocolatey.ps1        # Chocolatey package management
│   ├── scoop.ps1             # Scoop package management
│   ├── 4devs.ps1             # Developer tools
│   ├── environmentVariables.ps1
│   ├── pwshThemes.ps1        # PowerShell console themes
│   ├── themes.ps1            # Windows themes
│   ├── tweaks.ps1            # System tweaks
│   ├── settings.ps1          # Settings shortcuts
│   ├── globals.ps1           # Shared global variables
│   ├── ps-menu/              # Interactive menu engine (module)
│   └── utils/                # Shared utilities
│       ├── json.ps1
│       ├── arrays.ps1
│       ├── recursive.ps1
│       ├── utils.ps1
│       ├── clear.ps1
│       └── generateProjectStructure.ps1
│
├── .gitattributes
├── .gitignore
└── LICENSE
```

---

## Menu Shortcuts

| Key | Action |
|---|---|
| `↑` / `↓` or `K` / `J` | Navigate |
| `Home` | First option |
| `End` | Last option |
| `Enter` or `→` | Select current option |
| `B` or `←` | Go back (submenus) |
| `Escape`, `E`, `Q`, `X` | Exit / Quit |
| `V` | Display all shortcuts |

---

## Contributing

Contributions of all sizes are welcome. Please follow these steps:

1. **Open an issue** to discuss bugs, feature requests, or architecture changes.
2. **Fork the repository** and create a feature branch.
3. **Submit a pull request** with a clear description of the change.

Before submitting, ensure your changes:
- Follow the existing coding style (Verb-Noun function names, comment blocks)
- Maintain backward compatibility
- Include any necessary updates to data files

---

## License

This project is licensed under the terms of the [LICENSE](LICENSE) file included in the repository.
