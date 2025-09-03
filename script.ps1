Get-NetAdapter -Name "vEthernet (WSL)","vEthernet (Default Switch)" `
  | Set-NetConnectionProfile -NetworkCategory Private

# Разрешим исходящий трафик для Docker Desktop backend (на всякий случай)
New-NetFirewallRule -DisplayName "Allow Docker Backend Out" -Direction Outbound `
  -Program "C:\Program Files\Docker\Docker\com.docker.backend.exe" -Action Allow -Profile Any -ErrorAction SilentlyContinue
