@echo off
title RDP Ery-Leonardo - Cloudflare WARP Mode FIX
echo 🛠️ [1/5] Setting up User Accounts...
net user administrator %RDP_PASSWORD% /add >nul
net localgroup administrators administrator /add >nul
net user administrator /active:yes >nul

echo 🌐 [2/5] Optimizing DNS (Google)...
netsh interface ip set dns name="Ethernet" source=static address=8.8.8.8
netsh interface ip add dns name="Ethernet" addr=1.1.1.1 index=2
ipconfig /flushdns

echo ⏬ [3/5] Downloading Tools...
:: Pakai perintah echo manual buat ngegantiin 'WARP)...' yang error tadi
curl -L https://pkgs.tailscale.com/stable/tailscale-setup-latest.exe -o tailscale-setup.exe >nul
:: Pake winget buat install WARP
winget install --id Cloudflare.Warp --silent --accept-package-agreements --accept-source-agreements >nul

echo 🚀 [4/5] Installing Tailscale...
start /wait tailscale-setup.exe /quiet
taskkill /f /im tailscaled.exe >nul 2>&1
net stop tailscale /y >nul 2>&1
net start tailscale

echo 🌀 [5/5] Configuring Cloudflare WARP...
:: Ganti 'timeout' pake ping buat nunggu 20 detik (biar gak error Input Redirection)
ping 127.0.0.1 -n 20 >nul

set WARP_PATH="C:\Program Files\Cloudflare\Cloudflare WARP\warp-cli.exe"

:: Registrasi ulang biar bersih
%WARP_PATH% registration new
%WARP_PATH% mode warp

:: DAFTARKAN JALUR TAILSCALE (vnet)
:: Biar RDP gak putus pas WARP nyala
%WARP_PATH% vnet add 100.64.0.0/10

:: CONNECT!
%WARP_PATH% connect

echo ------------------------------------------------------------
echo 👉 KLIK LINK DI BAWAH INI UNTUK LOGIN TAILSCALE:
echo ------------------------------------------------------------
"C:\Program Files\Tailscale\tailscale.exe" up --hostname=RDP-Ery-Bogor --accept-routes --force-reauth --unattended
echo ------------------------------------------------------------

echo ✅ STATUS: WARP & TAILSCALE OPTIMIZED!
