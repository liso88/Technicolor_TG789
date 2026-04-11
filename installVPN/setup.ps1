# Script PowerShell per setup OpenVPN su modem
# Uso: .\setup.ps1

param(
    [string]$IP = "192.168.1.2",
    [string]$User = "root",
    [string]$Pass = "root"
)

Write-Host "==== Setup OpenVPN ===" -ForegroundColor Cyan
Write-Host ""

# Step 1: TUN
Write-Host "[1/3] TUN..." -ForegroundColor Yellow
plink -batch -pw $Pass -l $User $IP 'lsmod | grep -q tun || insmod /root/tommaso/tun.ko'
Write-Host "OK" -ForegroundColor Green

# Step 2: OpenVPN
Write-Host "[2/3] OpenVPN..." -ForegroundColor Yellow
plink -batch -pw $Pass -l $User $IP 'which openvpn || opkg install --force-depends --nodeps /root/tommaso/openvpn-openssl_2.5.11-5_brcm63xx.ipk'
Write-Host "OK" -ForegroundColor Green

# Step 3: Directories
Write-Host "[3/3] Directory..." -ForegroundColor Yellow
plink -batch -pw $Pass -l $User $IP 'mkdir -p /etc/openvpn/certs /etc/openvpn/keys; chmod 700 /etc/openvpn/keys'
Write-Host "OK" -ForegroundColor Green

Write-Host ""
Write-Host "==== Completato! ====" -ForegroundColor Green
Write-Host ""
Write-Host "Prossimi step:"
Write-Host "1. Genera certificati: .\generate_certificates.ps1"
Write-Host "2. Carica i certificati sul modem"
Write-Host "3. Avvia OpenVPN: plink -batch -pw root -l root root@$IP '/etc/init.d/openvpn start'"
