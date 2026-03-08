@echo off
git init
:: Menghapus remote lama jika ada, lalu tambah yang baru agar tidak error "remote origin already exists"
git remote remove origin >nul 2>&1
git remote add origin https://github.com/harapito15/RDP-FREE-6-JAM.git
git branch -m main

:: Menarik perubahan terbaru dari GitHub (mencegah error push)
git pull origin main --rebase

git add .
:: Jika kamu lupa kasih pesan commit saat jalanin: push.bat "update tailscale"
if "%~1"=="" (
    git commit -m "Update RDP Script %date% %time%"
) else (
    git commit -m "%~1"
)

git push origin main
echo ✅ Sukses terupdate ke GitHub!
pause
