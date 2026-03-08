@echo off
title RDP Ery-Leonardo - Cloudflare WARP Mode
echo 🛠️ [1/5] Setting up User Accounts...
net user administrator %RDP_PASSWORD% /add >nul
net localgroup administrators administrator /add >nul
net user administrator /active:yes >nul

echo 🌐 [2/5] Optimizing DNS (Google)...
netsh interface ip set dns name="Ethernet" source=static address=8.8.8.8
netsh interface ip add dns name="Ethernet" addr=8.8.4.4 index=2
ipconfig /flushdns

echo ⏬ [3/5] Downloading Tools (Tailscale & WARP)...
:: Download Tailscale
curl -L https://pkgs.tailscale.com/stable/tailscale-setup-latest.exe -o tailscale-setup.exe >nul
:: Install WARP via Winget (Paling stabil untuk CLI)
winget install --id Cloudflare.Warp --silent --accept-package-agreements --accept-source-agreements >nul

echo 🚀 [4/5] Installing Tailscale...
start /wait tailscale-setup.exe /quiet
taskkill /f /im tailscaled.exe >nul 2>&1
net stop tailscale >nul 2>&1
net start tailscale

echo 🌀 [5/5] Configuring Cloudflare WARP...
:: Kasih waktu sebentar biar instalasi WARP beres di background
timeout /t 15 >nul

:: Eksekusi perintah WARP (PENTING: Jangan asal connect biar gak DC)
set WARP_PATH="C:\Program Files\Cloudflare\Cloudflare WARP\warp-cli.exe"

%WARP_PATH% registration register --accept-tos
%WARP_PATH% mode warp

:: DAFTARKAN JALUR TAILSCALE (100.64.0.0/10) BIAR GAK LEWAT WARP
:: Ini kunci biar RDP lo gak freeze/macet pas WARP ON
%WARP_PATH% networks route add 100.64.0.0/10 "Tailscale Bypass"

:: CONNECT WARP!
%WARP_PATH% connect

echo ------------------------------------------------------------
echo 👉 KLIK LINK DI BAWAH INI UNTUK LOGIN TAILSCALE:
echo ------------------------------------------------------------
"C:\Program Files\Tailscale\tailscale.exe" up --hostname=RDP-Ery-Bogor --accept-routes --force-reauth --unattended
echo ------------------------------------------------------------

echo ✅ STATUS: WARP IS ACTIVE! IP Microsoft sudah disamarkan.
echo ✅ Coba akses rgsstoregamming.com/json sekarang.
