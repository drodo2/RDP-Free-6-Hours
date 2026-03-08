$WorkDir = Split-Path -Parent $MyInvocation.MyCommand.Path
Set-Location $WorkDir

Write-Host "[sing-box 1/3] Downloading..."
Invoke-WebRequest -Uri "https://github.com/SagerNet/sing-box/releases/download/v1.8.0/sing-box-1.8.0-windows-amd64.zip" -OutFile "sing-box.zip"
Expand-Archive -Path "sing-box.zip" -DestinationPath "sing-box-extracted" -Force
Copy-Item "sing-box-extracted\sing-box-1.8.0-windows-amd64\sing-box.exe" ".\sing-box.exe" -Force
Write-Host "[sing-box 1/3] Downloaded OK"

Write-Host "[sing-box 2/3] Writing config.json..."
$config = [ordered]@{
    log = [ordered]@{ level = "warn" }
    inbounds = @(
        [ordered]@{
            type = "mixed"
            tag = "mixed-in"
            listen = "127.0.0.1"
            listen_port = 2080
        }
    )
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
        final = "proxy"
    }
} | ConvertTo-Json -Depth 10

[System.IO.File]::WriteAllText("$WorkDir\config.json", $config, [System.Text.UTF8Encoding]::new($false))
Write-Host "[sing-box 2/3] config.json OK"

Write-Host "[sing-box 3/3] Starting sing-box..."
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
    exit 1
}

Write-Host "[Proxifier 1/2] Downloading Proxifier..."
Invoke-WebRequest -Uri "https://www.proxifier.com/download/ProxifierSetup.exe" -OutFile "ProxifierSetup.exe"
Start-Process -FilePath "ProxifierSetup.exe" -ArgumentList "/VERYSILENT","/NORESTART" -Wait
Start-Sleep -Seconds 10
Write-Host "[Proxifier 1/2] Installed OK"

Write-Host "[Proxifier 2/2] Writing Proxifier config..."
$proxifierConfig = @'
<?xml version="1.0" encoding="UTF-8" standalone="yes"?>
<ProxifierProfile version="101" platform="Win" product_id="1">
  <ProxyList>
    <Proxy id="1" type="SOCKS5">
      <Address>127.0.0.1</Address>
      <Port>2080</Port>
    </Proxy>
  </ProxyList>
  <RuleList>
    <Rule>
      <n>Tailscale Direct</n>
      <Applications>tailscaled.exe;tailscale.exe</Applications>
      <Action type="Direct"/>
    </Rule>
    <Rule>
      <n>RDP Direct</n>
      <Applications>rdpclip.exe;svchost.exe;mstsc.exe</Applications>
      <Action type="Direct"/>
    </Rule>
    <Rule>
      <n>RGSStore via Proxy</n>
      <Applications>RGSStorePro.exe</Applications>
      <Targets>rgsstoregamming.com;*.rgsstoregamming.com</Targets>
      <Action type="Proxy" id="1"/>
    </Rule>
    <Rule>
      <n>Default Direct</n>
      <Action type="Direct"/>
    </Rule>
  </RuleList>
</ProxifierProfile>
'@

$proxifierConfigPath = "$WorkDir\proxifier.ppx"
[System.IO.File]::WriteAllText($proxifierConfigPath, $proxifierConfig, [System.Text.UTF8Encoding]::new($false))

$proxifierExe = "C:\Program Files\Proxifier\Proxifier.exe"
if (Test-Path $proxifierExe) {
    Start-Process -FilePath $proxifierExe -ArgumentList "`"$proxifierConfigPath`"" -WindowStyle Hidden
    Start-Sleep -Seconds 5
    Write-Host "[Proxifier 2/2] RUNNING OK"
} else {
    Write-Host "[Proxifier 2/2] ERROR: Proxifier tidak ditemukan"
}

Write-Host "[RGSStore 1/2] Downloading RGSStorePro..."
$rgsUrl = "https://dl.rgsstoregamming.com/RGSSTORE%20APP/RGSStorePro_with_net.exe"
$rgsPath = "$WorkDir\RGSStorePro_setup.exe"
Invoke-WebRequest -Uri $rgsUrl -OutFile $rgsPath
Write-Host "[RGSStore 1/2] Downloaded OK"

Write-Host "[RGSStore 2/2] Installing RGSStorePro..."
Start-Process -FilePath $rgsPath -ArgumentList "/VERYSILENT","/NORESTART" -Wait
Start-Sleep -Seconds 10

$rgsExe = Get-ChildItem "C:\Program Files*\*RGS*\*.exe" -Recurse -ErrorAction SilentlyContinue | Select-Object -First 1
if ($rgsExe) {
    Write-Host "[RGSStore 2/2] Installed OK: $($rgsExe.FullName)"
} else {
    Write-Host "[RGSStore 2/2] WARNING: exe tidak ditemukan, mungkin install di lokasi lain"
    Write-Host "[RGSStore 2/2] Coba jalankan manual dari Desktop atau Start Menu"
}
