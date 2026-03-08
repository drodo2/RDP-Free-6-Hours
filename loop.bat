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

tasklist | find /i "tailscaled.exe" >nul
if %errorlevel% equ 0 (
    echo [OK] Tailscale Active.
    echo [INFO] Hostname: RDP-Ery-Bogor
    echo [IP ADDRESS]:
    "C:\Program Files\Tailscale\tailscale.exe" ip -4
) else (
    echo [ERROR] Tailscale disconnected!
    exit /b 1
)

echo ------------------------------------------

tasklist | find /i "sing-box.exe" >nul
if %errorlevel% equ 0 (
    echo [OK] sing-box VPN Active.
) else (
    echo [WARN] sing-box mati, restart...
    schtasks /run /tn "singbox" >nul 2>&1
)

echo ------------------------------------------
echo Loop setiap 5 menit. Cancel workflow untuk stop.
echo ------------------------------------------

powershell -Command "Start-Sleep 300"
goto check
