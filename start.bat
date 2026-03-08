@echo off
title RDP Ery-Leonardo - Tailscale + sing-box

net user rdpuser %RDP_PASSWORD% /add
net localgroup administrators rdpuser /add
net user rdpuser /active:yes
reg add "HKLM\SYSTEM\CurrentControlSet\Control\Terminal Server" /v fDenyTSConnections /t REG_DWORD /d 0 /f >nul
reg add "HKLM\SYSTEM\CurrentControlSet\Control\Terminal Server\WinStations\RDP-Tcp" /v UserAuthentication /t REG_DWORD /d 0 /f >nul
netsh advfirewall firewall set rule group="remote desktop" new enable=Yes >nul
netsh advfirewall firewall add rule name="RDP-TCP-3389" protocol=TCP dir=in localport=3389 action=allow >nul
echo [1/5] RDP OK

netsh interface ip set dns name="Ethernet" source=static address=8.8.8.8 >nul
netsh interface ip add dns name="Ethernet" addr=8.8.4.4 index=2 >nul
ipconfig /flushdns >nul
echo [2/5] DNS OK

curl -L https://pkgs.tailscale.com/stable/tailscale-setup-latest.exe -o tailscale-setup.exe >nul
start /wait tailscale-setup.exe /quiet
taskkill /f /im tailscaled.exe /t >nul 2>&1
sc stop tailscale >nul 2>&1
timeout /t 3 /nobreak >nul
sc start tailscale >nul 2>&1
timeout /t 5 /nobreak >nul
"C:\Program Files\Tailscale\tailscale.exe" up --hostname=RDP-Ery-Bogor --accept-routes --force-reauth --unattended
echo [3/5] Tailscale OK

curl -L https://github.com/SagerNet/sing-box/releases/download/v1.8.0/sing-box-1.8.0-windows-amd64.zip -o sing-box.zip >nul
tar -xf sing-box.zip >nul 2>&1
move sing-box-1.8.0-windows-amd64\sing-box.exe sing-box.exe >nul
echo [4/5] sing-box downloaded

python -c "import json; cfg={'log':{'level':'warn'},'inbounds':[{'type':'tun','tag':'tun-in','inet4_address':'172.19.0.1/30','auto_route':True,'strict_route':False,'stack':'system'}],'outbounds':[{'type':'trojan','tag':'proxy','server':'sg6.servercepat.net','server_port':443,'password':'g4BYVqC5Xn9zvqs','tls':{'enabled':True,'insecure':True,'server_name':'sg6.servercepat.net','alpn':['http/1.1'],'utls':{'enabled':True,'fingerprint':'chrome'}},'transport':{'type':'ws','path':'/trojan-ws','headers':{'Host':'sg6.servercepat.net'}}},{'type':'direct','tag':'direct'}],'route':{'rules':[{'ip_cidr':['100.64.0.0/10','100.100.100.100/32','192.168.0.0/16','10.0.0.0/8','127.0.0.0/8'],'outbound':'direct'}],'final':'proxy'}}; open('config.json','w').write(json.dumps(cfg,indent=2))"
echo [5/5] Config JSON OK

schtasks /create /tn "singbox" /tr "%CD%\sing-box.exe run -c %CD%\config.json" /sc onstart /ru SYSTEM /f >nul
schtasks /run /tn "singbox" >nul
timeout /t 5 /nobreak >nul
echo [6/6] sing-box started

echo ============================================================
echo RDP READY!
echo Username : rdpuser
echo Password : %RDP_PASSWORD%
echo Tailscale: AKTIF
echo sing-box : AKTIF
echo CEK LINK LOGIN TAILSCALE DI LOG GITHUB SEKARANG.
echo ============================================================
