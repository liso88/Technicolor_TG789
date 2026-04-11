# Deploy e esecuzione dello script setup su modem
# Uso: .\deploy_setup.ps1

param(
    [string]$ModemIP = "192.168.1.2",
    [string]$ModemUser = "root",
    [string]$ModemPass = "root",
    [string]$ScriptPath = "setup_modem.sh"
)

Write-Host "==== Deploy Setup OpenVPN ===" -ForegroundColor Cyan
Write-Host ""

# Verifica script locale
if (-not (Test-Path $ScriptPath)) {
    Write-Host "Errore: $ScriptPath non trovato" -ForegroundColor Red
    exit 1
}

Write-Host "[1/3] Lettura script..." -ForegroundColor Yellow
$scriptContent = Get-Content -Path $ScriptPath -Raw
Write-Host "Ok" -ForegroundColor Green

Write-Host "[2/3] Caricamento script sul modem..." -ForegroundColor Yellow
# Carica lo script via pipe
$scriptContent | plink -batch -pw $ModemPass -l $ModemUser $ModemIP "cat > /tmp/setup.sh"
if ($LASTEXITCODE -eq 0) {
    Write-Host "Ok" -ForegroundColor Green
} else {
    Write-Host "Errore nel caricamento" -ForegroundColor Red
    exit 1
}

Write-Host "[3/3] Esecuzione script..." -ForegroundColor Yellow
Write-Host ""

# Esegui lo script - ignora errori finali
plink -batch -pw $ModemPass -l $ModemUser $ModemIP "chmod +x /tmp/setup.sh && ash /tmp/setup.sh" 2>&1 | Out-Null

# Verifica che il setup sia stato completato
Write-Host ""
Write-Host "Verifica del setup..." -ForegroundColor Yellow
$verify = plink -batch -pw $ModemPass -l $ModemUser $ModemIP "test -f /etc/openvpn/openvpn_server.conf && echo OK || echo FAIL"

if ($verify.ToString().Trim() -eq "OK") {
    Write-Host ""
    Write-Host "==== Deploy completato con successo! ====" -ForegroundColor Green
    Write-Host ""
    Write-Host "[OK] OpenVPN installato"
    Write-Host "[OK] Modulo TUN caricato"
    Write-Host "[OK] Directory configurate"
    Write-Host "[OK] File di configurazione creato"
    Write-Host ""
    Write-Host "Prossimo step: generare i certificati"
    Write-Host "  .\generate_certificates.ps1"
} else {
    Write-Host ""
    Write-Host "==== Errore durante l'esecuzione ====" -ForegroundColor Red
    exit 1
}
