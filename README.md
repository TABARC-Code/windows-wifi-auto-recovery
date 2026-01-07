# windows-wifi-auto-recovery
Pings a target and restarts a Wi-Fi adapter if connectivity fails repeatedly

# Wi-Fi Auto Recovery (PowerShell)

Pings a target and restarts a Wi-Fi adapter if connectivity fails repeatedly.

This is for the classic situation where Windows insists you are connected, yet nothing resolves.

## Requirements

- Windows
- PowerShell 5.1 or PowerShell 7+
- Administrator privileges (adapter toggling)
- `Disable-NetAdapter` and `Enable-NetAdapter` available

## Usage

Run PowerShell as Administrator:

```powershell
Set-ExecutionPolicy -Scope Process -ExecutionPolicy Bypass
.\WiFi-Auto-Recovery.ps1
Example:

powershell
Copy code
.\WiFi-Auto-Recovery.ps1 -Target 1.1.1.1 -FailCount 3 -AdapterName "Wi-Fi"
Notes
Choose a target you trust in your environment.
