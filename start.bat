@echo off
title RDP Ery-Leonardo - Tailscale + Cloudflare WARP

:: ============================================================
:: [1/5] USER ACCOUNT + RDP
:: ============================================================
echo 🛠️  [1/5] Setting up User Account and RDP...
net user administrator %RDP_PASSWORD%
net user administrator /active:yes
net localgroup administrators administrator /add >nul 2>&1

:: Aktifkan RDP
reg add "HKLM\SYSTEM\CurrentControlSet\Control\Terminal Server" /v fDenyTSConnections /t REG_DWORD /d 0 /f >nul
netsh advfirewall firewall set rule group="remote desktop" new enable=Yes >nul
echo    ✅ RDP aktif.

:: ============================================================
:: [2/5] DNS
:: ============================================================
echo 🌐 [2/5] Optimizing DNS (Google)...
netsh interface ip set dns name="Ethernet" source=static address=8.8.8.8 >nul
netsh interface ip add dns name="Ethernet" addr=8.8.4.4 index=2 >nul
ipconfig /flushdns >nul
echo    ✅ DNS selesai.

:: ============================================================
:: [3/5] TAILSCALE (harus duluan sebelum WARP)
:: ============================================================
echo ⏬ [3/5] Downloading and Installing Tailscale...
curl -L https://pkgs.tailscale.com/stable/tailscale-setup-latest.exe -o tailscale-setup.exe >nul
start /wait tailscale-setup.exe /quiet

:: Anti-401: rebut kontrol dari runneradmin
taskkill /f /im tailscaled.exe /t >nul 2>&1
net stop tailscale /y >nul 2>&1
net start tailscale
timeout /t 5 /nobreak >nul

:: Konek Tailscale
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
echo ⏬ [4/5] Downloading and Installing Cloudflare WARP...
curl -L https://1111-releases.cloudflareclient.com/win/latest -o warp-setup.exe >nul
start /wait warp-setup.exe /quiet
timeout /t 10 /nobreak >nul

set WARP="C:\Program Files\Cloudflare\Cloudflare WARP\warp-cli.exe"

:: Register WARP (tanpa akun = mode consumer biasa)
echo 🔧 Configuring Cloudflare WARP...
%WARP% registration new >nul 2>&1
timeout /t 5 /nobreak >nul

:: ============================================================
:: KUNCI UTAMA: Split Tunnel — Tailscale BYPASS WARP
:: ============================================================
:: Exclude range IP Tailscale (CGNAT 100.64.0.0/10)
%WARP% tunnel exclude 100.64.0.0/10 >nul
:: Exclude MagicDNS Tailscale
%WARP% tunnel exclude 100.100.100.100/32 >nul
:: Exclude loopback & LAN supaya RDP tidak terganggu
%WARP% tunnel exclude 127.0.0.0/8 >nul
%WARP% tunnel exclude 192.168.0.0/16 >nul
%WARP% tunnel exclude 10.0.0.0/8 >nul

:: Konek WARP
%WARP% connect
timeout /t 8 /nobreak >nul
echo    ✅ WARP connected.

:: ============================================================
:: [5/5] STATUS AKHIR
:: ============================================================
echo.
echo ============================================================
echo ✅ STATUS: RDP READY!
echo.
echo    🔵 Tailscale : AKTIF  (routing via 100.64.x.x)
echo    🟠 WARP      : AKTIF  (bypass Tailscale otomatis)
echo    🖥️  RDP       : AKTIF
echo.
echo    👉 CEK LINK LOGIN TAILSCALE DI LOG GITHUB SEKARANG.
echo ============================================================
