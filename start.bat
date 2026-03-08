@echo off
title RDP Ery-Leonardo - Exit Node Mode (via Drodo-Ubuntu)
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

:: FIX: Reset servis agar user administrator punya kontrol penuh (Anti-401)
taskkill /f /im tailscaled.exe >nul 2>&1
net stop tailscale /y >nul 2>&1
net start tailscale

echo 🔗 [CONNECT] Minta Link Login & Aktifkan Exit Node...
:: Perintah 'up' untuk memunculkan link login di log GitHub
"C:\Program Files\Tailscale\tailscale.exe" up --hostname=RDP-Ery-Bogor --accept-routes --force-reauth --unattended

echo ------------------------------------------------------------
echo 👉 LANGKAH WAJIB:
echo 1. Klik link login di atas (jika muncul).
echo 2. Login ke akun Tailscale lo.
echo 3. Setelah login, RDP akan OTOMATIS diarahkan ke Ubuntu lo.
echo ------------------------------------------------------------

:: OTOMATIS PAKAI EXIT NODE UBUNTU (100.110.10.98)
echo 🌀 Mengarahkan trafik via drodo-ubuntu...
"C:\Program Files\Tailscale\tailscale.exe" set --exit-node=100.110.10.98

echo ✅ STATUS: RDP READY! Jalur aman via Ubuntu aktif.
