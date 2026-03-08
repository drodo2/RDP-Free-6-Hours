@echo off
title RDP Ery-Leonardo - Tailscale Stable Mode
echo 🛠️ [1/4] Setting up User Accounts...
net user administrator %RDP_PASSWORD% /add >nul
net localgroup administrators administrator /add >nul
net user administrator /active:yes >nul

echo 🌐 [2/4] Optimizing DNS (Google & Cloudflare)...
:: Ganti DNS biar rgsstoregamming.com gak nyangkut di DNS Microsoft
netsh interface ip set dns name="Ethernet" source=static address=8.8.8.8
netsh interface ip add dns name="Ethernet" addr=1.1.1.1 index=2
ipconfig /flushdns

echo ⏬ [3/4] Downloading Tailscale...
curl -L https://pkgs.tailscale.com/stable/tailscale-setup-latest.exe -o tailscale-setup.exe >nul

echo 🚀 [4/4] Installing Tailscale...
:: Install secara silent dan tunggu sampai selesai
start /wait tailscale-setup.exe /quiet

:: FIX: Matikan servis bawaan runneradmin agar user administrator bisa kontrol penuh
taskkill /f /im tailscaled.exe >nul 2>&1
net stop tailscale /y >nul 2>&1
net start tailscale

echo ------------------------------------------------------------
echo 👉 KLIK LINK DI BAWAH INI UNTUK LOGIN TAILSCALE:
echo ------------------------------------------------------------
:: Paksa link muncul di log GitHub
"C:\Program Files\Tailscale\tailscale.exe" up --hostname=RDP-Ery-Bogor --accept-routes --force-reauth --unattended
echo ------------------------------------------------------------

echo ✅ STATUS: RDP READY! Silahkan login.
