[Download Powershell](https://aka.ms/powershell-release?tag=lts) | [Download Winget](https://www.microsoft.com/p/app-installer/9nblggh4nns1)

1. Open PowerShell as an administrator (Win + X + A)
2. Run the command line below to install winrar
```
 winget install --id RARLab.WinRAR --accept-package-agreements
```

### (COULD NOT WORK) Online Installing

```powershell
iex (New-Object System.Net.WebClient).DownloadString('https://raw.githubusercontent.com/filipelperes/windows-sync/main/<FILE-NAME>.ps1')
```

### (RECOMMENDED) Manual Installing

1. Download the repository as `.zip` in desktop
2. Extract the files in the windows-sync folder
3. Open PowerShell as an administrator (Win + X + A)
4. Run the command line below to run the Script in PowerShell

```powershell
Set-ExecutionPolicy RemoteSigned -Scope Process -Force ; $Set-Location $HOME\Desktop\windows-sync ; .\<FILE-NAME>.ps1
```

### For Basic Users
Replace `<FILE-NAME>` for essentials

### 4Devs (Package devs include essentials)
Replace `<FILE-NAME>` for devs

If you want versions manager for node and/or python see
* "pyenv.ps1"
* "fnm.ps1"

For fish shell + starship on windows git bash without WSL click [here](https://gist.github.com/filipelperes/212abbfd422b4f3c77a04a26f4729c4c)