# GIANBEST Audio Latency Optimizer 🚀

A simple and effective script designed to reduce audio latency in Windows 10 and 11. Ideal for gamers, streamers, music producers and any user looking for faster and more accurate sound response.

This project automates the installation of a lightweight service in the system that is responsible for optimizing audio processing, minimizing the annoying delay between action and sound.

---

## ✨ Main features

* **One-command installation:** Paste a line into PowerShell and the script takes care of everything. You can also run the `.ps1` file with right click.
* **All in one:** A single script with menu to **install**, **uninstall** and **view the status** of the service.
* **Lightweight Service:**The installed service consumes minimal resources and runs discreetly in the background.
* **Easy to Use:** No technical knowledge required. The interface on the console guides you through each step.
* **Clean uninstall:**Reverses all changes, deleting the service and files.
* **Compatible:** Designed for Windows 10 and 11. Use PowerShell 7; If you don't have it, the script offers you to install it with `winget`.

---

## 🤔 How does it work?

The script (`AudioLatency.ps1`) performs the following actions:

1.  **Relaunches in PowerShell 7 as Administrator** (Windows will ask you to confirm permission).
2.  **Create a folder** in `C:\AudioLatencyReducer`.
3.  **Download and check the necessary components** (`nssm.exe` to manage services and `REAL.exe`, the optimizer).
4.  **Install, configure, and start a new service** in Windows called `GIANBEST Audio Latency Reducer Service` to run automatically.

---

## 🔧 Installation

### Option 1: a single command (recommended)

Open **PowerShell** (or Terminal), paste this line and press Enter:

```powershell
& ([scriptblock]::Create((irm "https://raw.githubusercontent.com/GIANBEST/AudioLatency/main/AudioLatency.ps1").TrimStart([char]0xFEFF)))
```

## 🗑 ️ Uninstall

If you want to delete the service and all files:

* **From the menu:** run the script as in the installation and choose the **2** option.
* **With a command:** paste this line into PowerShell:

```powershell
& ([scriptblock]::Create((irm "https://raw.githubusercontent.com/GIANBEST/AudioLatency/main/AudioLatency.ps1").TrimStart([char]0xFEFF))) -Action Uninstall
```

The script will stop and delete the service, and delete the installation folder.

---

## ⚠️ Disclaimer

This is a personal and unofficial project. The downloaded tools (`nssm.exe`, `REAL.exe`) belong to their respective creators. Use this script at your own risk. I am not responsible for possible problems with your system, although it has been designed to be as secure and reversible as possible.
