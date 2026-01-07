# TABARC-Code
param(
  [string]$Target = "8.8.8.8",
  [int]$FailCount = 3,
  [string]$AdapterName = "Wi-Fi"
)

function Assert-Admin {
  $id = [Security.Principal.WindowsIdentity]::GetCurrent()
  $p = New-Object Security.Principal.WindowsPrincipal($id)
  if (-not $p.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    throw "Run as Administrator."
  }
}

Assert-Admin

$fail = 0
while ($true) {
  $ok = Test-Connection -ComputerName $Target -Count 1 -Quiet -ErrorAction SilentlyContinue
  if ($ok) {
    $fail = 0
    Start-Sleep -Seconds 10
    continue
  }

  $fail++
  Write-Host "Ping failed ($fail/$FailCount) to $Target"

  if ($fail -ge $FailCount) {
    Write-Host "Restarting adapter '$AdapterName'"
    Disable-NetAdapter -Name $AdapterName -Confirm:$false -ErrorAction SilentlyContinue
    Start-Sleep -Seconds 3
    Enable-NetAdapter -Name $AdapterName -Confirm:$false -ErrorAction SilentlyContinue
    Start-Sleep -Seconds 10
    $fail = 0
  } else {
    Start-Sleep -Seconds 5
  }
}
