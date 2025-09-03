Get-NetAdapter -Name "vEthernet (WSL)","vEthernet (Default Switch)" `
  | Set-NetConnectionProfile -NetworkCategory Private

# http://77.222.181.11:8080/mjpg/video.mjpg
New-NetFirewallRule -DisplayName "Allow Docker Backend Out" -Direction Outbound `
  -Program "C:\Program Files\Docker\Docker\com.docker.backend.exe" -Action Allow -Profile Any -ErrorAction SilentlyContinue
