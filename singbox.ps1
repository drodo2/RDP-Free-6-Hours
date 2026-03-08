$WorkDir = Split-Path -Parent $MyInvocation.MyCommand.Path
Set-Location $WorkDir

Write-Host "[sing-box 1/3] Downloading..."
Invoke-WebRequest -Uri "https://github.com/SagerNet/sing-box/releases/download/v1.8.0/sing-box-1.8.0-windows-amd64.zip" -OutFile "sing-box.zip"
Expand-Archive -Path "sing-box.zip" -DestinationPath "sing-box-extracted" -Force
Copy-Item "sing-box-extracted\sing-box-1.8.0-windows-amd64\sing-box.exe" ".\sing-box.exe" -Force
Write-Host "[sing-box 1/3] Downloaded OK"

Write-Host "[sing-box 2/3] Detecting Tailscale interface..."
$tsInterface = Get-NetAdapter | Where-Object {
    $_.Description -match "tailscale|tsun|wintun" -or
    $_.Name -match "tailscale|tsun"
} | Select-Object -First 1 -ExpandProperty Name

if ($tsInterface) {
    Write-Host "[sing-box 2/3] Tailscale interface: $tsInterface"
} else {
    Write-Host "[sing-box 2/3] WARNING: interface tidak ditemukan, pakai IP rules saja"
}

Write-Host "[sing-box 2/3] Writing config.json..."

$inbound = [ordered]@{
    type = "tun"
    tag = "tun-in"
    inet4_address = "172.19.0.1/30"
    auto_route = $true
    strict_route = $false
    stack = "system"
}

if ($tsInterface) {
    $inbound["exclude_interface"] = @($tsInterface)
}

$config = [ordered]@{
    log = [ordered]@{ level = "warn" }
    inbounds = @($inbound)
    outbounds = @(
        [ordered]@{
            type = "trojan"
            tag = "proxy"
            server = "sg6.servercepat.net"
            server_port = 443
            password = "g4BYVqC5Xn9zvqs"
            tls = [ordered]@{
                enabled = $true
                insecure = $true
                server_name = "sg6.servercepat.net"
                alpn = @("http/1.1")
                utls = [ordered]@{
                    enabled = $true
                    fingerprint = "chrome"
                }
            }
            transport = [ordered]@{
                type = "ws"
                path = "/trojan-ws"
                headers = [ordered]@{
                    Host = "sg6.servercepat.net"
                }
            }
        },
        [ordered]@{ type = "direct"; tag = "direct" }
    )
    route = [ordered]@{
        rules = @(
            [ordered]@{
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
Write-Host "[sing-box 2/3] config.json OK"

Write-Host "[sing-box 3/3] Starting via Task Scheduler..."
$exePath = "$WorkDir\sing-box.exe"
$cfgPath = "$WorkDir\config.json"

schtasks /delete /tn "singbox" /f 2>$null
schtasks /create /tn "singbox" /tr "`"$exePath`" run -c `"$cfgPath`"" /sc onstart /ru SYSTEM /rl HIGHEST /f
schtasks /run /tn "singbox"
Start-Sleep -Seconds 8

$proc = Get-Process -Name "sing-box" -ErrorAction SilentlyContinue
if ($proc) {
    Write-Host "[sing-box 3/3] RUNNING OK (PID: $($proc.Id))"
} else {
    Write-Host "[sing-box 3/3] ERROR: gagal start, output:"
    & "$exePath" run -c "$cfgPath" 2>&1 | Select-Object -First 30
}
