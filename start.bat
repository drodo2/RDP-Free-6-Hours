@echo off
title Tailscale RDP Runner
echo 🛠️ Setting up User Accounts...
net user administrator @HarApito /add >nul
net localgroup administrators administrator /add >nul
net user administrator /active:yes >nul
net user installer /delete >nul

echo ⏬ Downloading Tailscale...
curl -L https://pkgs.tailscale.com/stable/tailscale-setup-latest.exe -o tailscale-setup.exe >nul

echo 🚀 Installing Tailscale (Please wait...)
start /wait tailscale-setup.exe /quiet

echo 🔗 Connecting to Tailscale Mesh Network...
:: Menggunakan Auth Key yang kamu berikan
"C:\Program Files\Tailscale\tailscale.exe" up --authkey=tskey-auth-kXk7us9Cx711CNTRL-uAjEChEYSsLWhjvoogbQsLnVknefJwPSA --hostname=RDP-Ery-Bogor --accept-routes

echo ----------------------------------
echo ✅ STATUS: TAILSCALE CONNECTED!
echo 🖥️  RDP CONNECTION DETAILS
echo ----------------------------------
echo Username: administrator
echo Password: @HarApito
echo Computer Name: RDP-Ery-Bogor
echo ----------------------------------
echo ⚠️  Jangan tutup jendela ini agar koneksi tetap aktif.

:: Mencegah Runner mati otomatis (Looping 6 Jam)
timeout /t 21600 /nobreak >nul
