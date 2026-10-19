# Windows Wi-Fi / Network Recovery

Monitor an adapter, a local gateway, an upstream IP target and DNS separately. This distinguishes an upstream outage from a likely local connectivity failure.

Designed for Windows PowerShell 5.1 or PowerShell 7+.

## Use

One read-only diagnostic pass:


```powershell
.\Auto-Recovery.ps1 -AdapterName 'Wi-Fi' -Once
```

Continual diagnostics without resets:


```powershell
.\Auto-Recovery.ps1 -AdapterName 'Wi-Fi' -Target '1.1.1.1'
```

Allow adapter resets after three consecutive local failures (requires Administrator rights):


```powershell
.\Auto-Recovery.ps1 -AdapterName 'Wi-Fi' -EnableReset -FailCount 3 -MaxResets 3 -CooldownSeconds 120
```

Optional parameters: `-SkipDnsProbe`, `-DnsHost`, `-IntervalSeconds` and `-Once`.

**Changed default:** Running the script no longer resets a network adapter automatically. You must opt in using `-EnableReset`. Resets are capped per run, with a cooldown between attempts.

## Limitations

ICMP replies can be blocked by otherwise healthy routers or upstream services. Failure to ping a host does not prove the connection is broken. The script only requests a reset when local and upstream probes fail consecutively; this is a heuristic, not a complete network diagnosis.

Restarting an adapter can interrupt remote access, downloads, calls or active services. Do not use reset mode over an unattended remote session without a recovery path.
