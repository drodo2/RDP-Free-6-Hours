@echo off
cls
echo ==========================================
echo    RDP TAILSCALE IS RUNNING!
echo ==========================================

:check
:: Cek apakah service Tailscale masih jalan
tasklist | find /i "tailscaled.exe" >Nul
if %errorlevel% equ 0 (
    echo [OK] Tailscale Service Active.
    echo [INFO] Connect via: RDP-Ery-Bogor
    
    :: Menampilkan IP Tailscale agar kamu tidak perlu buka dashboard
    echo [IP ADDRESS]:
    "C:\Program Files\Tailscale\tailscale.exe" ip -4
) else (
    echo [ERROR] Tailscale disconnected! Rebuilding...
    exit
)

echo ------------------------------------------
echo ⏰ Session will stay alive for 6 hours.
echo 🛑 To stop, cancel the GitHub Workflow.
echo ------------------------------------------

:: Loop setiap 5 menit untuk mengecek status
ping 127.0.0.1 -n 300 > nul
cls
echo RDP TAILSCALE STATUS: ACTIVE
goto check
