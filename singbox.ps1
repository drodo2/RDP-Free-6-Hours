$WorkDir = Split-Path -Parent $MyInvocation.MyCommand.Path
Set-Location $WorkDir

Write-Host "[4/5] Downloading sing-box..."
Invoke-WebRequest -Uri "https://github.com/SagerNet/sing-box/releases/download/v1.8.0/sing-box-1.8.0-windows-amd64.zip" -OutFile "sing-box.zip"
Expand-Archive -Path "sing-box.zip" -DestinationPath "sing-box-extracted" -Force
Copy-Item "sing-box-extracted\sing-box-1.8.0-windows-amd64\sing-box.exe" ".\sing-box.exe" -Force
Write-Host "[4/5] sing-box downloaded OK"

Write-Host "[5/5] Writing config.json..."
$config = @{
    log = @{ level = "warn" }
    inbounds = @(
        @{
            type = "tun"
            tag = "tun-in"
            inet4_address = "172.19.0.1/30"
            auto_route = $true
            strict_route = $false
            stack = "system"
        }
    )
    outbounds = @(
        @{
            type = "trojan"
            tag = "proxy"
            server = "sg6.servercepat.net"
            server_port = 443
            password = "g4BYVqC5Xn9zvqs"
            tls = @{
                enabled = $true
                insecure = $true
                server_name = "sg6.servercepat.net"
                alpn = @("http/1.1")
                utls = @{
                    enabled = $true
                    fingerprint = "chrome"
                }
            }
            transport = @{
                type = "ws"
                path = "/trojan-ws"
                headers = @{ Host = "sg6.servercepat.net" }
            }
        },
        @{ type = "direct"; tag = "direct" }
    )
    route = @{
        rules = @(
            @{
                process_name = @(
                    "tailscaled.exe",
                    "tailscale.exe"
                )
                outbound = "direct"
            },
            @{
                ip_cidr = @(
                    "100.64.0.0/10",
                    "100.100.100.100/32",
                    "192.168.0.0/16",
                    "10.0.0.0/8",
                    "127.0.0.0/8"
                )
                outbound = "direct"
            }
        )
        final = "proxy"
    }
} | ConvertTo-Json -Depth 10

[System.IO.File]::WriteAllText("$WorkDir\config.json", $config, [System.Text.UTF8Encoding]::new($false))
Write-Host "[5/5] config.json OK (no BOM)"

Write-Host "[6/6] Starting sing-box via Task Scheduler (SYSTEM)..."
$exePath = "$WorkDir\sing-box.exe"
$cfgPath = "$WorkDir\config.json"

schtasks /create /tn "singbox" /tr "`"$exePath`" run -c `"$cfgPath`"" /sc onstart /ru SYSTEM /rl HIGHEST /f
schtasks /run /tn "singbox"
Start-Sleep -Seconds 8

$proc = Get-Process -Name "sing-box" -ErrorAction SilentlyContinue
if ($proc) {
    Write-Host "[6/6] sing-box RUNNING OK (PID: $($proc.Id))"
} else {
    Write-Host "[6/6] ERROR: sing-box masih gagal, cek log:"
    & "$exePath" run -c "$cfgPath" 2>&1 | Select-Object -First 20
}
```

---

### Kenapa Ini Fix-nya
```
tailscaled.exe  → DIRECT (bypass sing-box 100%)
tailscale.exe   → DIRECT (bypass sing-box 100%)
100.64.0.0/10   → DIRECT (mesh IP tetap direct)
Semua lainnya   → Trojan proxy
