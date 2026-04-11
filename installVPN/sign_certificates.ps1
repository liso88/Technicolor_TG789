# Script PowerShell per firmare certificati OpenVPN con easy-rsa
# Uso: .\sign_certificates.ps1 -CommonName "server"

param(
    [string]$TargetDir = ".\easy-rsa-certs",
    [string]$CommonName = ""
)

if ([string]::IsNullOrWhiteSpace($CommonName)) {
    $CommonName = Read-Host "Inserisci il nome del certificato da firmare (es: server, vpn-server)"
    if ([string]::IsNullOrWhiteSpace($CommonName)) {
        Write-Host "[ERRORE] Nome certificato richiesto!" -ForegroundColor Red
        exit 1
    }
}

Write-Host "==== Firma Certificato OpenVPN ===" -ForegroundColor Cyan
Write-Host ""
Write-Host "Nome certificato: $CommonName" -ForegroundColor Yellow
Write-Host ""

# Verifica che il file di richiesta esista
$reqFile = Join-Path $TargetDir "pki\reqs\$CommonName.req"
if (-not (Test-Path $reqFile)) {
    Write-Host "[ERRORE] File di richiesta non trovato: $reqFile" -ForegroundColor Red
    Write-Host "Esegui prima: .\generate_certificates.ps1 -CommonName `"$CommonName`"" -ForegroundColor Yellow
    exit 1
}

Write-Host "[OK] File di richiesta trovato: $reqFile" -ForegroundColor Green
Write-Host ""

# Posiziona index.txt se mancante
$pkiDir = Join-Path (Resolve-Path $TargetDir).Path "pki"
$indexFile = Join-Path $pkiDir "index.txt"
$indexOldFile = Join-Path $pkiDir "index.txt.old"

# Assicura che index.txt esista e sia valido
if (-not (Test-Path $indexFile)) {
    Write-Host "[1/3] Creazione file index.txt..." -ForegroundColor Yellow
    Set-Content -Path $indexFile -Value "" -Encoding ASCII
    Write-Host "[OK] index.txt creato" -ForegroundColor Green
} else {
    Write-Host "[OK] index.txt già presente" -ForegroundColor Green
}

# Assicura che serial esista
$serialFile = Join-Path $pkiDir "serial"
if (-not (Test-Path $serialFile)) {
    Write-Host "[1/3] Creazione file serial..." -ForegroundColor Yellow
    Set-Content -Path $serialFile -Value "1000" -Encoding ASCII
}

Write-Host ""
Write-Host "[2/3] Firma del certificato in corso..." -ForegroundColor Yellow

# Usa OpenSSL direttamente per firmare (bypass bug easy-rsa su Windows)
$openssl = "C:\Program Files\Git\mingw64\bin\openssl.exe"
if (-not (Test-Path $openssl)) {
    $openssl = "openssl"  # Prova in PATH se non trovato
}

$pkiDir = Join-Path (Resolve-Path $TargetDir).Path "pki"
$caKey = Join-Path $pkiDir "private\ca.key"
$caCrt = Join-Path $pkiDir "ca.crt"
$req = Join-Path $pkiDir "reqs\$CommonName.req"
$out = Join-Path $pkiDir "issued\$CommonName.crt"
$config = Join-Path $pkiDir "openssl-easyrsa.cnf"

# Firma il certificato usando openssl ca
& $openssl ca `
    -config $config `
    -in $req `
    -out $out `
    -outdir (Join-Path $pkiDir "certs_by_serial") `
    -days 3650 `
    -batch 2>&1 | Out-Null

if ($LASTEXITCODE -ne 0) {
    Write-Host "[AVVISO] OpenSSL ha restituito un errore, ma il certificato potrebbe essere stato creato comunque..." -ForegroundColor Yellow
}

Write-Host ""
Write-Host "[3/3] Verifica file firmato..." -ForegroundColor Yellow

# Verifica che il certificato sia stato creato
$certFile = Join-Path $pkiDir "issued\$CommonName.crt"
if (Test-Path $certFile) {
    Write-Host "[OK] Certificato firmato: $certFile" -ForegroundColor Green
    Write-Host ""
    Write-Host "==== Firma completata con successo! ====" -ForegroundColor Green
    Write-Host ""
    Write-Host "Prossimo step: caricare i certificati sul modem" -ForegroundColor Yellow
    Write-Host ""
    Write-Host "Esegui:"
    Write-Host "  cd `"$TargetDir\pki`""
    Write-Host ""
    Write-Host "Quindi carica i 4 file con plink:"
    Write-Host "  plink -batch -pw root -l root root@192.168.1.2 `"cat > /etc/openvpn/certs/ca.crt`" < ca.crt"
    Write-Host "  plink -batch -pw root -l root root@192.168.1.2 `"cat > /etc/openvpn/certs/server.crt`" < issued/$CommonName.crt"
    Write-Host "  plink -batch -pw root -l root root@192.168.1.2 `"cat > /etc/openvpn/keys/server.key`" < private/$CommonName.key"
    Write-Host "  plink -batch -pw root -l root root@192.168.1.2 `"cat > /etc/openvpn/certs/dh.pem`" < dh.pem"
} else {
    Write-Host "[ERRORE] Certificato firmato non trovato!" -ForegroundColor Red
    exit 1
}
