# Script PowerShell per generare certificati OpenVPN con easy-rsa
# Uso: .\generate_certificates.ps1

param(
    [string]$TargetDir = ".\easy-rsa-certs",
    [string]$CommonName = "",
    [string]$CountryCode = "IT"
)

# Se CommonName non è stato passato, chiedi all'utente
if ([string]::IsNullOrWhiteSpace($CommonName)) {
    $CommonName = Read-Host "Inserisci il nome del certificato (es: server, vpn-server)"
    if ([string]::IsNullOrWhiteSpace($CommonName)) {
        $CommonName = "server"
        Write-Host "Usando nome di default: $CommonName" -ForegroundColor Yellow
    }
}

Write-Host "==== Generazione Certificati OpenVPN ===" -ForegroundColor Cyan
Write-Host ""

# Controlla se git è disponibile
$gitAvailable = (Get-Command git -ErrorAction SilentlyContinue) -ne $null
if (-not $gitAvailable) {
    Write-Host "[ERRORE] git non trovato!" -ForegroundColor Red
    Write-Host "Installa git da: https://git-scm.com/" -ForegroundColor Yellow
    exit 1
}

# Verifica se easy-rsa esiste
$easyRsaExists = Test-Path "easy-rsa"
if (-not $easyRsaExists) {
    Write-Host "[1/5] Download easy-rsa..." -ForegroundColor Yellow
    git clone https://github.com/OpenVPN/easy-rsa.git
    Write-Host "[OK] easy-rsa scaricato" -ForegroundColor Green
} else {
    Write-Host "[OK] easy-rsa gia presente" -ForegroundColor Green
}

# Trova easyrsa script in diverse posizioni (priorità: shell script, poi .bat)
$easyRsaBin = $null
foreach ($path in @(".\easy-rsa\easyrsa3\easyrsa", ".\easy-rsa\distro\windows\EasyRSA-Start.bat", ".\easy-rsa\easyrsa")) {
    if (Test-Path $path) {
        $easyRsaBin = $path
        break
    }
}

if (-not $easyRsaBin) {
    Write-Host "[ERRORE] script easyrsa non trovato in:" -ForegroundColor Red
    Write-Host "  - .\easy-rsa\easyrsa3\easyrsa" -ForegroundColor Red
    Write-Host "  - .\easy-rsa\distro\windows\EasyRSA-Start.bat" -ForegroundColor Red
    Write-Host "  - .\easy-rsa\easyrsa" -ForegroundColor Red
    exit 1
}

# Usa sempre Git Bash direttamente (non bash da WSL se disponibile)
$gitBashPath = "C:\Program Files\Git\bin\bash.exe"
if (-not (Test-Path $gitBashPath)) {
    Write-Host "[ERRORE] Git Bash non trovato in: $gitBashPath" -ForegroundColor Red
    Write-Host "Scarica Git da: https://git-scm.com/" -ForegroundColor Yellow
    exit 1
}
$bashCmd = $gitBashPath

# Crea directory target
New-Item -ItemType Directory -Force -Path $TargetDir | Out-Null

# Converti percorsi a assoluti PRIMA di cambiare directory
$absoluteTargetDir = (Resolve-Path $TargetDir).Path
$absoluteEasyRsa = (Resolve-Path $easyRsaBin).Path

# Converti a formato Unix per bash (C:\ -> /c/)
$unixTargetDir = $absoluteTargetDir -replace '\\', '/' -replace '^(.):' , '/$1'
$unixEasyRsa = $absoluteEasyRsa -replace '\\', '/' -replace '^(.):' , '/$1'

# Adesso cambia directory
Push-Location $TargetDir

# Script bash per generare certificati automaticamente
$bashScript = @"
#!/bin/bash
set -e
cd "$unixTargetDir"
export EASYRSA_REQ_CN="$CommonName"
export EASYRSA_REQ_C="$CountryCode"
export EASYRSA_REQ_OU="OpenVPN"
export EASYRSA_REQ_ORG="Technicolor"
export EASYRSA_BATCH="true"

echo "1. Inizializzazione PKI..."
echo "yes" | "$unixEasyRsa" init-pki

echo ""
echo "2. Creazione CA..."
echo "" | "$unixEasyRsa" build-ca nopass

echo ""
echo "3. Generazione certificato server..."
EASYRSA_REQ_CN="$CommonName"
"$unixEasyRsa" gen-req "$CommonName" nopass

echo ""
echo "4. Generazione parametri DH (può impiegare minuti)..."
"$unixEasyRsa" gen-dh

echo "PKI inizializzato con successo!"
"@

# Salva lo script bash in un file temporaneo (senza BOM)
$bashScriptFile = Join-Path $env:TEMP "generate_certs_$(Get-Random).sh"
$utf8NoBom = New-Object System.Text.UTF8Encoding $false
[System.IO.File]::WriteAllText($bashScriptFile, $bashScript, $utf8NoBom)

# Esegui lo script bash
Write-Host ""
Write-Host "[Generazione certificati in corso...]" -ForegroundColor Yellow
& $bashCmd $bashScriptFile
$result = $LASTEXITCODE

# Cancella il file temporaneo
Remove-Item -Force $bashScriptFile -ErrorAction SilentlyContinue

if ($result -ne 0) { 
    Write-Host "[ERRORE] Generazione certificati fallita!" -ForegroundColor Red
    exit 1 
}

# Pop back to original directory
Pop-Location
Pop-Location

Write-Host ""
Write-Host "Verifica file generati..." -ForegroundColor Yellow

Write-Host ""
Write-Host "Verifica file generati..." -ForegroundColor Yellow
Write-Host ""

$requiredFiles = @(
    "pki/ca.crt",
    "pki/reqs/$CommonName.req",
    "pki/private/$CommonName.key",
    "pki/dh.pem"
)

$filesOk = $true
foreach ($file in $requiredFiles) {
    $fullPath = Join-Path $absoluteTargetDir $file
    if (Test-Path $fullPath) {
        Write-Host "[OK] $file" -ForegroundColor Green
    } else {
        Write-Host "[ERRORE] $file - MANCANTE!" -ForegroundColor Red
        $filesOk = $false
    }
}

Write-Host ""
if ($filesOk) {
    Write-Host "==== Certificati generati con successo! ====" -ForegroundColor Green
    Write-Host ""
    Write-Host "Nome certificato: $CommonName" -ForegroundColor Cyan
    Write-Host "Country: $CountryCode" -ForegroundColor Cyan
    Write-Host "File generati in: $TargetDir\pki\" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "STEP 1: Firmare il certificato server" -ForegroundColor Yellow
    Write-Host "  Apri Git Bash da qui e esegui:"
    Write-Host ""
    Write-Host "  cd $TargetDir"
    Write-Host "  ../easy-rsa/easyrsa3/easyrsa sign-req server $CommonName"
    Write-Host ""
   Write-Host "STEP 2: Caricare i certificati sul modem (dopo aver firmato)" -ForegroundColor Yellow
    Write-Host "  cd `"$TargetDir\pki`""
    Write-Host ""
    Write-Host "  plink -batch -pw root -l root root@192.168.1.2 `"cat > /etc/openvpn/certs/ca.crt`" < ca.crt"
    Write-Host "  plink -batch -pw root -l root root@192.168.1.2 `"cat > /etc/openvpn/certs/server.crt`" < issued/$CommonName.crt"
    Write-Host "  plink -batch -pw root -l root root@192.168.1.2 `"cat > /etc/openvpn/keys/server.key`" < private/$CommonName.key"
    Write-Host "  plink -batch -pw root -l root root@192.168.1.2 `"cat > /etc/openvpn/certs/dh.pem`" < dh.pem"
} else {
    Write-Host "==== Errore nella generazione! ====" -ForegroundColor Red
    exit 1
}
