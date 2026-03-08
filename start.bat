@echo off
title RDP Ery-Leonardo - Tailscale + sing-box

net user rdpuser %RDP_PASSWORD% /add
net localgroup administrators rdpuser /add
net user rdpuser /active:yes
reg add "HKLM\SYSTEM\CurrentControlSet\Control\Terminal Server" /v fDenyTSConnections /t REG_DWORD /d 0 /f >nul
reg add "HKLM\SYSTEM\CurrentControlSet\Control\Terminal Server\WinStations\RDP-Tcp" /v UserAuthentication /t REG_DWORD /d 0 /f >nul
netsh advfirewall firewall set rule group="remote desktop" new enable=Yes >nul
netsh advfirewall firewall add rule name="RDP-TCP-3389" protocol=TCP dir=in localport=3389 action=allow >nul
echo [1/5] RDP OK

netsh interface ip set dns name="Ethernet" source=static address=8.8.8.8 >nul
netsh interface ip add dns name="Ethernet" addr=8.8.4.4 index=2 >nul
ipconfig /flushdns >nul
echo [2/5] DNS OK

curl -L https://pkgs.tailscale.com/stable/tailscale-setup-latest.exe -o tailscale-setup.exe >nul
start /wait tailscale-setup.exe /quiet
taskkill /f /im tailscaled.exe /t >nul 2>&1
sc stop tailscale >nul 2>&1
timeout /t 3 /nobreak >nul
sc start tailscale >nul 2>&1
timeout /t 5 /nobreak >nul
"C:\Program Files\Tailscale\tailscale.exe" up --hostname=RDP-Ery-Bogor --accept-routes --force-reauth --unattended
echo [3/5] Tailscale OK

curl -L https://github.com/SagerNet/sing-box/releases/download/v1.8.0/sing-box-1.8.0-windows-amd64.zip -o sing-box.zip >nul
tar -xf sing-box.zip >nul 2>&1
move sing-box-1.8.0-windows-amd64\sing-box.exe sing-box.exe >nul
echo [4/5] sing-box downloaded

(
echo {
echo   "log": { "level": "warn" },
echo   "inbounds": [{
echo     "type": "tun",
echo     "tag": "tun-in",
echo     "inet4_address": "172.19.0.1/30",
echo     "auto_route": true,
echo     "strict_route": false,
echo     "stack": "system"
echo   }],
echo   "outbounds": [
echo     {
echo       "type": "trojan",
echo       "tag": "proxy",
echo       "server": "sg6.servercepat.net",
echo       "server_port": 443,
echo       "password": "g4BYVqC5Xn9zvqs",
echo       "tls": {
echo         "enabled": true,
echo         "insecure": true,
echo         "server_name": "sg6.servercepat.net",
echo         "alpn": ["http/1.1"],
echo         "utls": { "enabled": true, "fingerprint": "chrome" }
echo       },
echo       "transport": {
echo         "type": "ws",
echo         "path": "/trojan-ws",
echo         "headers": { "Host": "sg6.servercepat.net" }
echo       }
echo     },
echo     { "type": "direct", "tag": "direct" }
echo   ],
echo   "route": {
echo     "rules": [{
echo       "ip_cidr": [
echo         "100.64.0.0/10",
echo         "100.100.100.100/32",
echo         "192.168.0.0/16",
echo         "10.0.0.0/8",
echo         "127.0.0.0/8"
echo       ],
echo       "outbound": "direct"
echo     }],
echo     "final": "proxy"
echo   }
echo }
) > config.json

schtasks /create /tn "singbox" /tr "%CD%\sing-box.exe run -c %CD%\config.json" /sc onstart /ru SYSTEM /f >nul
schtasks /run /tn "singbox" >nul
timeout /t 5 /nobreak >nul
echo [5/5] sing-box started via Task Scheduler

echo ============================================================
echo RDP READY!
echo Username : rdpuser
echo Password : %RDP_PASSWORD%
echo Tailscale: AKTIF
echo sing-box : AKTIF
echo CEK LINK LOGIN TAILSCALE DI LOG GITHUB SEKARANG.
echo ============================================================
