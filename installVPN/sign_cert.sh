#!/bin/bash
# Script bash per firmare certificati con easy-rsa
# Uso: ./sign_cert.sh <common-name>

if [ -z "$1" ]; then
    echo "Uso: $0 <common-name>"
    echo "Es: $0 tommi"
    exit 1
fi

COMMON_NAME="$1"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"

echo "==== Firma Certificato OpenVPN ===="
echo ""
echo "Nome certificato: $COMMON_NAME"
echo ""

# Verifica che sia nella directory giusta
if [ ! -d "easy-rsa-certs/pki" ]; then
    echo "[ERRORE] Directory easy-rsa-certs/pki non trovata!"
    exit 1
fi

if [ ! -f "easy-rsa-certs/pki/reqs/$COMMON_NAME.req" ]; then
    echo "[ERRORE] Certificate request non trovato: easy-rsa-certs/pki/reqs/$COMMON_NAME.req"
    exit 1
fi

cd "easy-rsa-certs"

# Esegui la firma con easy-rsa
echo ""
echo "[1/2] Firma del certificato..."
export EASYRSA_BATCH="true"
echo "yes" | ../easy-rsa/easyrsa3/easyrsa sign-req server "$COMMON_NAME" nopass

if [ $? -eq 0 ]; then
    echo ""
    echo "[OK] Certificato firmato con successo!"
    echo ""
    echo "[2/2] Upload su modem..."
    echo ""
    echo "Esegui questi comandi da PowerShell:"
    echo ""
    echo "  cd \"$SCRIPT_DIR\\easy-rsa-certs\\pki\""
    echo ""
    echo "  plink -batch -pw root -l root root@192.168.1.2 \"cat > /etc/openvpn/certs/ca.crt\" < ca.crt"
    echo "  plink -batch -pw root -l root root@192.168.1.2 \"cat > /etc/openvpn/certs/server.crt\" < issued/$COMMON_NAME.crt"
    echo "  plink -batch -pw root -l root root@192.168.1.2 \"cat > /etc/openvpn/keys/server.key\" < private/$COMMON_NAME.key"
    echo "  plink -batch -pw root -l root root@192.168.1.2 \"cat > /etc/openvpn/certs/dh.pem\" < dh.pem"
else
    echo ""
    echo "[ERRORE] Firma certificato fallita!"
    exit 1
fi
