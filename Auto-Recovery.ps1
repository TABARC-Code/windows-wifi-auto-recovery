# TABARC-Code
# Diagnose gateway, upstream and DNS separately. Adapter resets are explicit and bounded.
[CmdletBinding()]
param(
  [string]$Target = '1.1.1.1',
  [string]$DnsHost = 'example.com',
  [string]$AdapterName = 'Wi-Fi',
  [ValidateRange(1,20)][int]$FailCount = 3,
  [ValidateRange(1,300)][int]$IntervalSeconds = 10,
  [ValidateRange(1,3600)][int]$CooldownSeconds = 120,
  [ValidateRange(1,20)][int]$MaxResets = 3,
  [switch]$EnableReset,
  [switch]$Once,
  [switch]$SkipDnsProbe
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

function Assert-Admin {
  $identity = [Security.Principal.WindowsIdentity]::GetCurrent()
  $principal = New-Object Security.Principal.WindowsPrincipal($identity)
  if (-not $principal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    throw 'Administrator rights are required to reset a network adapter.'
  }
}

function Probe-Network {
  $adapter = Get-NetAdapter -Name $AdapterName -ErrorAction Stop
  $config = $null
  try {
    $config = Get-NetIPConfiguration -InterfaceIndex $adapter.ifIndex -ErrorAction Stop
  } catch {
    # An adapter can exist before the TCP/IP interface is configured.
    Write-Warning "No TCP/IP configuration available for $AdapterName; gateway probe skipped."
  }
  $gateway = ''
  if ($config -and $config.IPv4DefaultGateway) {
    $gateway = [string]$config.IPv4DefaultGateway.NextHop
  }
  $adapterUp = ($adapter.Status -eq 'Up')
  $gatewayReachable = $false
  $upstreamReachable = $false
  $dnsReachable = $null

  if ($adapterUp -and $gateway) {
    $gatewayReachable = [bool](Test-Connection -ComputerName $gateway -Count 1 -Quiet -ErrorAction SilentlyContinue)
  }
  if ($adapterUp) {
    $upstreamReachable = [bool](Test-Connection -ComputerName $Target -Count 1 -Quiet -ErrorAction SilentlyContinue)
    if (-not $SkipDnsProbe) {
      try {
        Resolve-DnsName -Name $DnsHost -Type A -ErrorAction Stop | Out-Null
        $dnsReachable = $true
      } catch { $dnsReachable = $false }
    }
  }
  [pscustomobject]@{
    adapter = $AdapterName
    adapterStatus = [string]$adapter.Status
    gateway = $gateway
    gatewayReachable = $gatewayReachable
    upstreamReachable = $upstreamReachable
    dnsReachable = $dnsReachable
  }
}

$failures = 0
$resets = 0
while ($true) {
  $status = Probe-Network
  $localFailure = ($status.adapterStatus -ne 'Up' -or ($status.gateway -and -not $status.gatewayReachable))
  $connectivityFailure = -not $status.upstreamReachable

  $label = if ($status.adapterStatus -ne 'Up') {
    'Adapter is not up'
  } elseif ($status.gateway -and -not $status.gatewayReachable) {
    'Local gateway does not answer ICMP'
  } elseif ($connectivityFailure) {
    'Gateway reachable but upstream IP does not answer ICMP'
  } elseif ($status.dnsReachable -eq $false) {
    'Upstream IP reachable but DNS lookup failed'
  } else {
    'Network probes passed'
  }
  Write-Host ("{0} {1} | gateway={2} upstream={3} dns={4}" -f (Get-Date -Format 's'),$label,$status.gatewayReachable,$status.upstreamReachable,$status.dnsReachable)

  if (-not $localFailure -or -not $connectivityFailure) {
    $failures = 0
  } else {
    $failures++
  }

  if ($EnableReset -and $failures -ge $FailCount) {
    if ($resets -ge $MaxResets) {
      throw "Stopped after $MaxResets adapter reset(s). Manual diagnosis required."
    }
    Assert-Admin
    Write-Warning "Resetting $AdapterName after $failures consecutive local connectivity failures."
    Disable-NetAdapter -Name $AdapterName -Confirm:$false -ErrorAction Stop
    Start-Sleep -Seconds 3
    Enable-NetAdapter -Name $AdapterName -Confirm:$false -ErrorAction Stop
    $resets++
    $failures = 0
    if (-not $Once) { Start-Sleep -Seconds $CooldownSeconds }
  }

  if ($Once) { break }
  Start-Sleep -Seconds $IntervalSeconds
}
