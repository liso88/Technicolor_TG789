# Script PowerShell per eseguire setup OpenVPN sul modem
# Uso: .\run_setup_openvpn.ps1

param(
    [string]$ModemIP = "192.168.1.2",
    [string]$ModemUser = "root",
    [string]$ModemPass = "root"
)

$ErrorActionPreference = "Stop"

Write-Host "==== Setup OpenVPN SU MODEM ===" -ForegroundColor Cyan

# Step 1: Caricamento modulo TUN
Write-Host "[1/3] Caricamento modulo TUN..." -ForegroundColor Yellow
$result = & plink -batch -pw $ModemPass -l $ModemUser $ModemIP 'lsmod | grep -q tun || insmod /root/tommaso/tun.ko; echo OK'
if ($LASTEXITCODE -eq 0) {
    Write-Host "✓ Modulo TUN caricato" -ForegroundColor Green
} else {
    Write-Host "✗ Errore nel caricamento di TUN" -ForegroundColor Red
    exit 1
}

# Step 2: Installazione OpenVPN
Write-Host "[2/3] Verifica e installazione OpenVPN..." -ForegroundColor Yellow
$result = & plink -batch -pw $ModemPass -l $ModemUser $ModemIP 'which openvpn >/dev/null 2>&1 && echo EXISTS || opkg install --force-depends --nodeps /root/tommaso/openvpn-openssl_2.5.11-5_brcm63xx.ipk 2>&1'

if ($LASTEXITCODE -eq 0) {
    Write-Host "✓ OpenVPN disponibile" -ForegroundColor Green
} else {
    Write-Host "⚠ OpenVPN: possibile errore (exit code: $LASTEXITCODE))" -ForegroundColor Yellow
}

# Step 3: Creazione directory di configurazione
Write-Host "[3/3] Setup directory di configurazione..." -ForegroundColor Yellow
& plink -batch -pw $ModemPass -l $ModemUser $ModemIP 'mkdir -p /etc/openvpn/certs /etc/openvpn/keys /etc/openvpn/config; chmod 700 /etc/openvpn/keys' | Out-Null

if ($LASTEXITCODE -eq 0) {
    Write-Host "✓ Directory create" -ForegroundColor Green
} else {
    Write-Host "✗ Errore nella creazione directory" -ForegroundColor Red
    exit 1
}

Write-Host ""
Write-Host "==== Prossimi step (da eseguire su PC Windows) ====" -ForegroundColor Cyan
Write-Host ""
Write-Host "1. Scarica easy-rsa:"
Write-Host "   git clone https://github.com/OpenVPN/easy-rsa.git"
Write-Host ""
Write-Host "2. Genera certificati con: .\generate_certificates.ps1"
Write-Host ""
Write-Host "3. Avvia OpenVPN sul modem:"
Write-Host "   plink -batch -pw root -l root root@$ModemIP '/etc/init.d/openvpn start'"
Write-Host ""
Write-Host "==== Setup completato! ====" -ForegroundColor Green
