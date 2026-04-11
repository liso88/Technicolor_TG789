#!/bin/bash

# Script di setup OpenVPN server su modem Technicolor TG789
# Uso: ./setup_openvpn.sh

set -e

echo "==== Setup OpenVPN Server ===="

# Colori per output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Directory di configurazione
OPENVPN_DIR="/etc/openvpn"
CONFIG_DIR="$OPENVPN_DIR/config"
KEYS_DIR="$OPENVPN_DIR/keys"
CERTS_DIR="$OPENVPN_DIR/certs"

# ===== Step 1: Carica modulo TUN =====
echo -e "${YELLOW}[1/5]${NC} Caricamento modulo TUN..."
if ! lsmod | grep -q tun; then
    if [ -f /root/tommaso/tun.ko ]; then
        insmod /root/tommaso/tun.ko
        echo -e "${GREEN}✓ Modulo TUN caricato${NC}"
    else
        echo -e "${RED}✗ File tun.ko non trovato${NC}"
        exit 1
    fi
else
    echo -e "${GREEN}✓ Modulo TUN già caricato${NC}"
fi

# ===== Step 2: Installa OpenVPN se necessario =====
echo -e "${YELLOW}[2/5]${NC} Verifica installazione OpenVPN..."
if ! which openvpn > /dev/null 2>&1; then
    echo "Installazione di OpenVPN..."
    opkg install --force-depends --nodeps /root/tommaso/openvpn-openssl_2.5.11-5_brcm63xx.ipk
    echo -e "${GREEN}✓ OpenVPN installato${NC}"
else
    echo -e "${GREEN}✓ OpenVPN già installato${NC}"
fi

# ===== Step 3: Crea directory di configurazione =====
echo -e "${YELLOW}[3/5]${NC} Setup directory di configurazione..."
mkdir -p $CERTS_DIR $KEYS_DIR $CONFIG_DIR
chmod 700 $KEYS_DIR

echo -e "${GREEN}✓ Directory create${NC}"

# ===== Step 4: Crea file di configurazione server =====
echo -e "${YELLOW}[4/5]${NC} Creazione file di configurazione..."

cat > $OPENVPN_DIR/openvpn_server.conf << 'EOF'
# Configurazione OpenVPN Server
port 1194
proto udp
dev tun

# Certificati e chiavi
ca certs/ca.crt
cert certs/server.crt
key keys/server.key
dh certs/dh.pem

# Rete VPN
server 10.8.0.0 255.255.255.0
ifconfig-pool-persist ipp.txt

# Compressione
compress lz4

# DHCP push
push "redirect-gateway def1 bypass-dhcp"
push "dhcp-option DNS 8.8.8.8"
push "dhcp-option DNS 8.8.4.4"

# Keep-alive
keepalive 10 120

# Cifratura
cipher AES-128-CBC
auth SHA256

# Log
log /var/log/openvpn.log
verb 3

# Utente e gruppo
user nobody
group nogroup

# Persistent
persist-key
persist-tun
EOF

echo -e "${GREEN}✓ File di configurazione creato${NC}"

# ===== Step 5: Info per generare certificati =====
echo -e "${YELLOW}[5/5]${NC} Istruzioni per generare certificati..."
echo ""
echo -e "${YELLOW}Per completare il setup, genera i certificati sul tuo PC con easy-rsa:${NC}"
echo ""
echo "1. Scarica easy-rsa:"
echo "   git clone https://github.com/OpenVPN/easy-rsa.git"
echo "   cd easy-rsa"
echo ""
echo "2. Inizializza PKI:"
echo "   ./easyrsa init-pki"
echo "   ./easyrsa build-ca nopass"
echo ""
echo "3. Genera certificati server:"
echo "   ./easyrsa gen-req server nopass"
echo "   ./easyrsa sign-req server server"
echo ""
echo "4. Genera parametri DH:"
echo "   ./easyrsa gen-dh"
echo ""
echo "5. Carica i file sul modem:"
echo "   scp pki/ca.crt root@192.168.1.2:$CERTS_DIR/"
echo "   scp pki/issued/server.crt root@192.168.1.2:$CERTS_DIR/"
echo "   scp pki/private/server.key root@192.168.1.2:$KEYS_DIR/"
echo "   scp pki/dh.pem root@192.168.1.2:$CERTS_DIR/"
echo ""
echo "6. Correggi i permessi sul modem:"
echo "   chmod 600 $KEYS_DIR/server.key"
echo "   chmod 644 $CERTS_DIR/*"
echo ""
echo "7. Avvia OpenVPN:"
echo "   /etc/init.d/openvpn start"
echo "   /etc/init.d/openvpn enable"
echo ""

echo -e "${GREEN}==== Setup completato! ====${NC}"
