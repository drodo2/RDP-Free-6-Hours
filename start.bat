@echo off
title RDP Ery-Leonardo - Tailscale Only (Fixed)

:: ============================================================
:: [DIAGNOSA] Cek identitas runner
:: ============================================================
echo 🔍 [DIAGNOSA] Username aktif:
whoami
echo.
echo 🔍 Semua user tersedia:
net user
echo.

:: ============================================================
:: [1/4] USER ACCOUNT + RDP
:: ============================================================
echo 🛠️  [1/4] Setting up User Account...

:: Buat user baru "rdpuser" (lebih aman dari pakai administrator)
net user rdpuser %RDP_PASSWORD% /add
net localgroup administrators rdpuser /add
net user rdpuser /active:yes

:: Nonaktifkan NLA (wajib!)
reg add "HKLM\SYSTEM\CurrentControlSet\Control\Terminal Server" /v fDenyTSConnections /t REG_DWORD /d 0 /f >nul
reg add "HKLM\SYSTEM\CurrentControlSet\Control\Terminal Server\WinStations\RDP-Tcp" /v UserAuthentication /t REG_DWORD /d 0 /f >nul

:: Buka firewall RDP
netsh advfirewall firewall set rule group="remote desktop" new enable=Yes >nul
netsh advfirewall firewall add rule name="RDP-TCP-3389" protocol=TCP dir=in localport=3389 action=allow >nul
echo    ✅ RDP aktif. Login: rdpuser / %RDP_PASSWORD%

:: ============================================================
:: [2/4] DNS
:: ============================================================
echo 🌐 [2/4] Optimizing DNS...
netsh interface ip set dns name="Ethernet" source=static address=8.8.8.8 >nul
netsh interface ip add dns name="Ethernet" addr=8.8.4.4 index=2 >nul
ipconfig /flushdns >nul
echo    ✅ DNS selesai.

:: ============================================================
:: [3/4] TAILSCALE
:: ============================================================
echo ⏬ [3/4] Downloading Tailscale...
curl -L https://pkgs.tailscale.com/stable/tailscale-setup-latest.exe -o tailscale-setup.exe >nul
start /wait tailscale-setup.exe /quiet

:: Fix anti-401 tanpa /y
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
:: [4/4] STATUS
:: ============================================================
echo.
echo ============================================================
echo ✅ STATUS: RDP READY!
echo.
echo    👤 Username : rdpuser
echo    🔑 Password : %RDP_PASSWORD%
echo    🖥️  RDP      : Pakai IP Tailscale (100.x.x.x)
echo.
echo    👉 CEK LINK LOGIN TAILSCALE DI LOG GITHUB SEKARANG.
echo ============================================================
