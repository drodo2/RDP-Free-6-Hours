$WorkDir = Split-Path -Parent $MyInvocation.MyCommand.Path
Set-Location $WorkDir

Write-Host "[sing-box 1/3] Downloading..."
Invoke-WebRequest -Uri "https://github.com/SagerNet/sing-box/releases/download/v1.8.0/sing-box-1.8.0-windows-amd64.zip" -OutFile "sing-box.zip"
Expand-Archive -Path "sing-box.zip" -DestinationPath "sing-box-extracted" -Force
Copy-Item "sing-box-extracted\sing-box-1.8.0-windows-amd64\sing-box.exe" ".\sing-box.exe" -Force
Write-Host "[sing-box 1/3] Downloaded OK"

Write-Host "[sing-box 2/3] Writing config.json..."
$config = @{
    log = @{ level = "warn" }
    inbounds = @(
        @{
            type = "mixed"
            tag = "mixed-in"
            listen = "127.0.0.1"
            listen_port = 2080
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
        final = "proxy"
    }
} | ConvertTo-Json -Depth 10

[System.IO.File]::WriteAllText("$WorkDir\config.json", $config, [System.Text.UTF8Encoding]::new($false))
Write-Host "[sing-box 2/3] config.json OK"

Write-Host "[sing-box 3/3] Starting..."
$exePath = "$WorkDir\sing-box.exe"
$cfgPath = "$WorkDir\config.json"

schtasks /delete /tn "singbox" /f 2>$null
schtasks /create /tn "singbox" /tr "`"$exePath`" run -c `"$cfgPath`"" /sc onstart /ru SYSTEM /rl HIGHEST /f
schtasks /run /tn "singbox"
Start-Sleep -Seconds 8

$proc = Get-Process -Name "sing-box" -ErrorAction SilentlyContinue
if ($proc) {
    Write-Host "[sing-box 3/3] RUNNING OK (PID: $($proc.Id))"

    Write-Host "[sing-box +] Setting system proxy 127.0.0.1:2080..."
    Set-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Internet Settings" -Name ProxyEnable -Value 1
    Set-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Internet Settings" -Name ProxyServer -Value "127.0.0.1:2080"
    Set-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Internet Settings" -Name ProxyOverride -Value "100.*;10.*;192.168.*;127.*;localhost;<local>"
    Write-Host "[sing-box +] System proxy OK"
} else {
    Write-Host "[sing-box 3/3] ERROR: gagal start, output:"
    & "$exePath" run -c "$cfgPath" 2>&1 | Select-Object -First 30
}
