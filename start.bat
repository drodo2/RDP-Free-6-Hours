@echo off
echo 🛠️ Setting up User Accounts...
:: Mengambil password dari GitHub Secret (RDP_PASSWORD)
net user administrator %RDP_PASSWORD% /add >nul
net localgroup administrators administrator /add >nul
net user administrator /active:yes >nul

echo ⏬ Downloading Tailscale...
curl -L https://pkgs.tailscale.com/stable/tailscale-setup-latest.exe -o tailscale-setup.exe >nul

echo 🚀 Installing Tailscale (Please wait...)
start /wait tailscale-setup.exe /quiet

echo 🔗 Connecting to Tailscale Mesh Network...
:: Menggunakan Auth Key dari GitHub Secret (TS_AUTHKEY)
"C:\Program Files\Tailscale\tailscale.exe" up --authkey=%TS_AUTHKEY% --hostname=RDP-Ery-Bogor --accept-routes

echo ----------------------------------
echo ✅ STATUS: TAILSCALE CONNECTED!
echo ----------------------------------
