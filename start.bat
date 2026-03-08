@echo off
echo 🛠️ Setting up User Accounts...
net user administrator %RDP_PASSWORD% /add >nul
net localgroup administrators administrator /add >nul
net user administrator /active:yes >nul

echo 🌐 Mengganti DNS ke Google (Bypass rgsstoregamming.com)...
netsh interface ip set dns name="Ethernet" source=static address=8.8.8.8
netsh interface ip add dns name="Ethernet" addr=8.8.4.4 index=2
ipconfig /flushdns

echo ⏬ Downloading Tailscale...
curl -L https://pkgs.tailscale.com/stable/tailscale-setup-latest.exe -o tailscale-setup.exe >nul

echo 🚀 Installing Tailscale...
start /wait tailscale-setup.exe /quiet

echo 🔗 Connecting to Tailscale (Bogor Exit Node Ready)...
:: Menambahkan --operator agar user administrator punya izin penuh
:: Menambahkan --unattended agar tetap jalan saat ganti user
"C:\Program Files\Tailscale\tailscale.exe" up --authkey=%TS_AUTHKEY% --hostname=RDP-Ery-Bogor --accept-routes --operator=administrator --unattended

echo ----------------------------------
echo ✅ STATUS: RDP READY & OPTIMIZED!
echo ----------------------------------
