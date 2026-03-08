@echo off
title RDP Ery-Leonardo - Pure Tailscale Mode
echo 🛠️ [1/4] Setting up User Accounts...
net user administrator %RDP_PASSWORD% /add >nul
net localgroup administrators administrator /add >nul
net user administrator /active:yes >nul

echo 🌐 [2/4] Optimizing DNS (Google)...
netsh interface ip set dns name="Ethernet" source=static address=8.8.8.8
netsh interface ip add dns name="Ethernet" addr=8.8.4.4 index=2
ipconfig /flushdns

echo ⏬ [3/4] Downloading Tailscale...
curl -L https://pkgs.tailscale.com/stable/tailscale-setup-latest.exe -o tailscale-setup.exe >nul

echo 🚀 [4/4] Installing Tailscale...
:: Install secara silent
start /wait tailscale-setup.exe /quiet

:: --- BAGIAN PENTING: REBUT KENDALI DARI RUNNERADMIN ---
echo 🛡️ Cleaning up Background Processes...
taskkill /f /im tailscaled.exe /t >nul 2>&1
taskkill /f /im tailscale.exe /t >nul 2>&1
net stop tailscale /y >nul 2>&1
net start tailscale

echo 🔗 [CONNECT] Minta Link Login Baru...
:: Munculkan link login di log GitHub Actions
"C:\Program Files\Tailscale\tailscale.exe" up --hostname=RDP-Ery-Bogor --accept-routes --force-reauth --unattended

echo ------------------------------------------------------------
echo ✅ STATUS: RDP READY!
echo 👉 Cari link "To authenticate, visit:" di log GitHub.
echo ------------------------------------------------------------
