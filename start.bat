@echo off
title RDP Ery-Leonardo - Tailscale + sing-box

net user rdpuser %RDP_PASSWORD% /add
net localgroup administrators rdpuser /add
net user rdpuser /active:yes
reg add "HKLM\SYSTEM\CurrentControlSet\Control\Terminal Server" /v fDenyTSConnections /t REG_DWORD /d 0 /f >nul
reg add "HKLM\SYSTEM\CurrentControlSet\Control\Terminal Server\WinStations\RDP-Tcp" /v UserAuthentication /t REG_DWORD /d 0 /f >nul
netsh advfirewall firewall set rule group="remote desktop" new enable=Yes >nul
netsh advfirewall firewall add rule name="RDP-TCP-3389" protocol=TCP dir=in localport=3389 action=allow >nul
echo [1/4] RDP OK

netsh interface ip set dns name="Ethernet" source=static address=8.8.8.8 >nul
netsh interface ip add dns name="Ethernet" addr=8.8.4.4 index=2 >nul
ipconfig /flushdns >nul
echo [2/4] DNS OK

curl -L https://pkgs.tailscale.com/stable/tailscale-setup-latest.exe -o tailscale-setup.exe >nul
start /wait tailscale-setup.exe /quiet
taskkill /f /im tailscaled.exe /t >nul 2>&1
sc stop tailscale >nul 2>&1
timeout /t 3 /nobreak >nul
sc start tailscale >nul 2>&1
timeout /t 5 /nobreak >nul
"C:\Program Files\Tailscale\tailscale.exe" up --hostname=RDP-Ery-Bogor --accept-routes --force-reauth --unattended
echo [3/4] Tailscale OK

powershell -ExecutionPolicy Bypass -File "%~dp0singbox.ps1"
echo [4/4] sing-box OK

echo ============================================================
echo RDP READY!
echo Username : rdpuser
echo Password : %RDP_PASSWORD%
echo Tailscale: AKTIF
echo sing-box : AKTIF - SOCKS5 di 127.0.0.1:2080
echo CEK LINK LOGIN TAILSCALE DI LOG GITHUB SEKARANG.
echo ============================================================
