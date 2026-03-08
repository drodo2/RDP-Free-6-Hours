@echo off
title RDP Ery-Leonardo - Tailscale + WARP (Final Fixed)

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

:: Anti-401: rebut kontrol dari runneradmin
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
:: [4/5] CLOUDFLARE WARP
:: ============================================================
echo ⏬ [4/5] Downloading Cloudflare WARP (MSI)...
curl -L https://1111-releases.cloudflareclient.com/win/Cloudflare_WARP_2023.7.160.0.msi -o warp.msi >nul
echo 🔧 Installing WARP...
start /wait msiexec /i warp.msi /quiet /norestart
timeout /t 15 /nobreak >nul

set WARP="C:\Program Files\Cloudflare\Cloudflare WARP\warp-cli.exe"

:: Register WARP
echo 🔧 Registering WARP...
%WARP% register new
timeout /t 10 /nobreak >nul

:: Split Tunnel — Tailscale bypass WARP
echo 🔧 Setting Split Tunnel...
%WARP% add-excluded-route 100.64.0.0/10
%WARP% add-excluded-route 100.100.100.100/32
%WARP% add-excluded-route 127.0.0.0/8
%WARP% add-excluded-route 192.168.0.0/16
%WARP% add-excluded-route 10.0.0.0/8
echo    ✅ Split tunnel selesai.

:: Konek WARP
echo 🔗 Connecting WARP...
%WARP% connect
timeout /t 10 /nobreak >nul

:: Verifikasi status
echo 📊 Status WARP:
%WARP% status
echo    ✅ WARP connected.

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
echo    🟠 WARP      : AKTIF  ^(bypass Tailscale otomatis^)
echo    🖥️  RDP       : AKTIF
echo.
echo    👉 CEK LINK LOGIN TAILSCALE DI LOG GITHUB SEKARANG.
echo ============================================================
