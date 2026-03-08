@echo off
cls
echo ==========================================
echo    RDP TAILSCALE IS RUNNING!
echo ==========================================

:check
cls
echo ==========================================
echo    RDP TAILSCALE STATUS: ACTIVE
echo ==========================================

:: Cek Tailscale
tasklist | find /i "tailscaled.exe" >nul
if %errorlevel% equ 0 (
    echo [OK] Tailscale Service Active.
    echo [INFO] Hostname: RDP-Ery-Bogor
    echo [IP ADDRESS]:
    "C:\Program Files\Tailscale\tailscale.exe" ip -4
) else (
    echo [ERROR] Tailscale disconnected! Exiting...
    exit /b 1
)

echo ------------------------------------------

:: Cek sing-box
tasklist | find /i "sing-box.exe" >nul
if %errorlevel% equ 0 (
    echo [OK] sing-box VPN Active.
) else (
    echo [WARN] sing-box mati, restart...
    schtasks /run /tn "singbox" >nul 2>&1
)

echo ------------------------------------------
echo Session will stay alive. Loop setiap 5 menit.
echo To stop, cancel the GitHub Workflow.
echo ------------------------------------------

:: Tunggu 5 menit
timeout /t 300 /nobreak >nul
goto check
