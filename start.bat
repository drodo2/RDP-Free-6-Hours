@echo off
title RDP Ery-Leonardo - Tailscale + sing-box Trojan (Final)

:: ============================================================
:: [1/5] USER ACCOUNT + RDP
:: ============================================================
echo 🛠️  [1/5] Setting up User Account...
net user rdpuser %RDP_PASSWORD% /add
net localgroup administrators rdpuser /add
net user rdpuser /active:yes

reg add "HKLM\SYSTEM\CurrentControlSet\Control\Terminal Server" /v fDenyTSConnections /t REG_DWORD /d 0 /f >nul
reg add "HKLM\SYSTEM\CurrentControlSet\Control\Terminal Server\WinStations\RDP-Tcp" /v UserAuthentication /t REG_DWORD /d 0 /f >nul
netsh advfirewall firewall set rule group="remote desktop" new enable=Yes >nul
netsh advfirewall firewall add rule name="RDP-TCP-3389" protocol=TCP dir=in localport=3389 action=allow >nul
echo    ✅ RDP aktif.

:: ============================================================
:: [2/5] DNS
:: ============================================================
echo 🌐 [2/5] Optimizing DNS...
netsh interface ip set dns name="Ethernet" source=static address=8.8.8.8 >nul
netsh interface ip add dns name="Ethernet" addr=8.8.4.4 index=2 >nul
ipconfig /flushdns >nul
echo    ✅ DNS selesai.

:: ============================================================
:: [3/5] TAILSCALE
:: ============================================================
echo ⏬ [3/5] Downloading Tailscale...
curl -L https://pkgs.tailscale.com/stable/tailscale-setup-latest.exe -o tailscale-setup.exe >nul
echo 🔧 Installing Tailscale...
start /wait tailscale-setup.exe /quiet

taskkill /f /im tailscaled.exe /t >nul 2>&1
sc stop tailscale >nul 2>&1
timeout /t 3 /nobreak >nul
sc start tailscale >nul 2>&1
timeout /t 5 /nobreak >nul

echo 🔗 Connecting Tailscale...
"C:\Program Files\Tailscale\tailscale.exe" up ^
    --hostname=RDP-Ery-Bogor ^
    --accept-routes ^
    --force-reauth ^
    --unattended
echo    ✅ Tailscale connected.

:: ============================================================
:: [4/5] SING-BOX (Trojan VPN)
:: ============================================================
echo ⏬ [4/5] Downloading sing-box...
curl -L https://github.com/SagerNet/sing-box/releases/download/v1.8.0/sing-box-1.8.0-windows-amd64.zip -o sing-box.zip >nul
tar -xf sing-box.zip >nul 2>&1
move sing-box-1.8.0-windows-amd64\sing-box.exe sing-box.exe >nul

:: Buat config sing-box
echo 🔧 Writing sing-box config...
echo {> config.json
echo   "log": { "level": "warn" },>> config.json
echo   "inbounds": [>> config.json
echo     {>> config.json
echo       "type": "tun",>> config.json
echo       "tag": "tun-in",>> config.json
echo       "inet4_address": "172.19.0.1/30",>> config.json
echo       "auto_route": true,>> config.json
echo       "strict_route": false,>> config.json
echo       "stack": "system">> config.json
echo     }>> config.json
echo   ],>> config.json
echo   "outbounds": [>> config.json
echo     {>> config.json
echo       "type": "trojan",>> config.json
echo       "tag": "proxy",>> config.json
echo       "server": "sg6.servercepat.net",>> config.json
echo       "server_port": 443,>> config.json
echo       "password": "g4BYVqC5Xn9zvqs",>> config.json
echo       "tls": {>> config.json
echo         "enabled": true,>> config.json
echo         "insecure": true,>> config.json
echo         "server_name": "sg6.servercepat.net",>> config.json
echo         "alpn": ["http/1.1"],>> config.json
echo         "utls": { "enabled": true, "fingerprint": "chrome" }>> config.json
echo       },>> config.json
echo       "transport": {>> config.json
echo         "type": "ws",>> config.json
echo         "path": "/trojan-ws",>> config.json
echo         "headers": { "Host": "sg6.servercepat.net" }>> config.json
echo       }>> config.json
echo     },>> config.json
echo     { "type": "direct", "tag": "direct" }>> config.json
echo   ],>> config.json
echo   "route": {>> config.json
echo     "rules": [>> config.json
echo       {>> config.json
echo         "ip_cidr": [>> config.json
echo           "100.64.0.0/10",>> config.json
echo           "100.100.100.100/32",>> config.json
echo           "192.168.0.0/16",>> config.json
echo           "10.0.0.0/8",>> config.json
echo           "127.0.0.0/8">> config.json
echo         ],>> config.json
echo         "outbound": "direct">> config.json
echo       }>> config.json
echo     ],>> config.json
echo     "final": "proxy">> config.json
echo   }>> config.json
echo }>> config.json

:: Jalankan sing-box sebagai background
echo 🚀 Starting sing-box...
start /b sing-box.exe run -c config.json
timeout /t 5 /nobreak >nul
echo    ✅ sing-box running.

:: ============================================================
:: [5/5] STATUS AKHIR
:: ============================================================
echo.
echo ============================================================
echo ✅ STATUS: RDP READY!
echo.
echo    👤 Username  : rdpuser
echo    🔑 Password  : %RDP_PASSWORD%
echo    🔵 Tailscale : AKTIF  ^(routing via 100.x.x.x^)
echo    🟢 sing-box  : AKTIF  ^(Trojan WS TLS - sg6.servercepat.net^)
echo    🖥️  RDP       : AKTIF
echo.
echo    👉 CEK LINK LOGIN TAILSCALE DI LOG GITHUB SEKARANG.
echo ============================================================
```

---

### Cara Kerjanya
```
Traffic internet  → sing-box TUN → Trojan WS → sg6.servercepat.net
Tailscale 100.x   → DIRECT (bypass sing-box)
RDP / LAN         → DIRECT (bypass sing-box)
