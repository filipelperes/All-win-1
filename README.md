# :rocket: All-win-1 :rocket:
#### The last tweaker tool you'll ever need. Simplify your life with :rocket: All-win-1 :rocket:
:rocket: **All-win-1** :rocket: is a PowerShell-based tool designed to simplify your Windows experience.

- [Optional Prerequisites](#optional-prerequisites)
- [How to Get Started](#how-to-get-started)
- [How to Use](#how-to-use)
- [Extra](#extra)
- [Contribute & Support](#contribute-support)

---

## :wrench: Optional Prerequisites <a id="optional-prerequisites"></a>

##### :four_leaf_clover: Winrar: Run the command below in PowerShell to install (if you don't have it):
```powershell
winget install --id RARLab.WinRAR --accept-package-agreements
```

##### :desktop_computer: Git: Run the command below in PowerShell to install (if you don't have it):
```powershell
winget install --id Git.Git --accept-package-agreements
```

---

## :checkered_flag: How to Get Started <a id="how-to-get-started"></a>
#### :inbox_tray: **1. Download or clone:**
   * :pushpin: **Manual Download:**
      * Click the "Code" (green) button on the GitHub repository.
      * Select "Download ZIP".
      * Extract the contents of the ZIP file to a folder of your choice.
   * :pushpin: **Clone the repo:**
      ```powershell
      cd <PROJECT_LOCATION_FOLDER> ; git clone https://github.com/filipelperes/All-win-1.git ; cd All-win-1\
      ```

#### :desktop_computer: **2. Open PowerShell as Administrator:** *Press `Win + X` then `A`*

#### :open_file_folder: **3. Navigate to the Project Directory:**
   * Use the `cd` command to navigate to the folder where the `main.ps1` script is located.
      ```powershell
      cd <PROJECT_LOCATION_FOLDER>\All-win-1
      ```
      :small_blue_diamond: **Tip:** If you cloned the repository, the path will be the folder created by `git clone`.

#### :rocket: **4. Run the Script:**
   * Run the following command in PowerShell:
      ```powershell
      Set-ExecutionPolicy RemoteSigned -Scope Process -Force ; .\main.ps1
      ```

---

## :question: How to Use :question: <a id="how-to-use"></a>

**Once the script main.ps1 is executed, you should see a menu-driven interface (or a series of prompts) that allows you to select different tweaking options. Follow the on-screen instructions to explore the available features.**

**Most features have been tested and are working well, but if you encounter any issues, feel free to report them.**

**Check the `globals.ps1` file to adjust settings for import a file, or directly edit the data in the `data` directory as needed.**

---

### :hammer_and_wrench: Extra <a id="extra"></a>
**For Fish Shell With Starship on Windows Git Bash check out [this guide](https://gist.github.com/filipelperes/212abbfd422b4f3c77a04a26f4729c4c) or use the option in the 4devs menu.**

---

### :loudspeaker: Contribute & Support <a id="contribute-support"></a>
:busts_in_silhouette: **Contributions are welcome!**

   * **Submit a Pull Request to improve the code.**
   * **Report issues in the Issues section of the repository.**

:email: **Need help? contact us or open an Issue on GitHub.**