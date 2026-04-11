#!/bin/ash
# Setup OpenVPN Server su Modem Technicolor TG789
# Esecuzione: ash setup_modem.sh o sh setup_modem.sh

set -e

echo "===================================="
echo "  Setup OpenVPN Server - TG789"
echo "===================================="
echo ""

# Colori (non usare escape ANSI in ash)
# GREEN='\033[0;32m'
# YELLOW='\033[1;33m'
# RED='\033[0;31m'
# NC='\033[0m'

# ===== STEP 1: Modulo TUN =====
echo "[1/4] Caricamento modulo TUN..."
if lsmod | grep -q tun; then
    echo "✓ TUN già caricato"
else
    if [ -f /root/tommaso/tun.ko ]; then
        insmod /root/tommaso/tun.ko
        echo "✓ TUN caricato"
    else
        echo "✗ File tun.ko non trovato"
        exit 1
    fi
fi

# ===== STEP 2: OpenVPN Package =====
echo ""
echo "[2/4] Installazione OpenVPN..."
if which openvpn > /dev/null 2>&1; then
    echo "✓ OpenVPN già installato"
else
    if [ -f /root/tommaso/openvpn-openssl_2.5.11-5_brcm63xx.ipk ]; then
        opkg install --force-depends --nodeps /root/tommaso/openvpn-openssl_2.5.11-5_brcm63xx.ipk 2>&1 | tail -3
        echo "✓ OpenVPN installato"
    else
        echo "✗ Package OpenVPN non trovato"
        exit 1
    fi
fi

# ===== STEP 3: Directory Structure =====
echo ""
echo "[3/4] Creazione struttura directory..."
mkdir -p /etc/openvpn/certs
mkdir -p /etc/openvpn/keys
mkdir -p /etc/openvpn/config
chmod 700 /etc/openvpn/keys
chmod 755 /etc/openvpn/certs
chmod 755 /etc/openvpn/config
echo "✓ Directory create"

# ===== STEP 4: File di configurazione =====
echo ""
echo "[4/4] Creazione file di configurazione..."

# Config server
cat > /etc/openvpn/openvpn_server.conf << 'EOF'
# OpenVPN Server Configuration
port 1194
proto udp
dev tun

# Certificati e chiavi
ca certs/ca.crt
cert certs/server.crt
key keys/server.key
dh certs/dh.pem

# Network
server 10.8.0.0 255.255.255.0
ifconfig-pool-persist ipp.txt

# Compression
compress lz4

# DHCP Options
push "redirect-gateway def1 bypass-dhcp"
push "dhcp-option DNS 8.8.8.8"
push "dhcp-option DNS 8.8.4.4"

# Security
keepalive 10 120
cipher AES-128-CBC
auth SHA256

# Logging
status openvpn-status.log
log /var/log/openvpn.log
verb 3

# Performance
user nobody
group nogroup
persist-key
persist-tun
EOF

echo "✓ Configurazione creata"

echo ""
echo "===================================="
echo "  Setup completato!"
echo "===================================="
echo ""
echo "Prossimi step:"
echo ""
echo "1. GENERARE CERTIFICATI (su PC Windows/Linux):"
echo "   - Git clone: https://github.com/OpenVPN/easy-rsa.git"
echo "   - Seguire la documentazione easy-rsa"
echo ""
echo "2. CARICARE CERTIFICATI SUL MODEM:"
echo "   Dalla directory easy-rsa, eseguire:"
echo ""
echo "   # Linux/Mac:"
echo "   scp pki/ca.crt root@192.168.1.2:/etc/openvpn/certs/"
echo "   scp pki/issued/server.crt root@192.168.1.2:/etc/openvpn/certs/"
echo "   scp pki/private/server.key root@192.168.1.2:/etc/openvpn/keys/"
echo "   scp pki/dh.pem root@192.168.1.2:/etc/openvpn/certs/"
echo ""
echo "   # Windows (plink):"
echo "   plink -batch -pw root -l root root@192.168.1.2 \"cat > /etc/openvpn/certs/ca.crt\" < pki/ca.crt"
echo "   plink -batch -pw root -l root root@192.168.1.2 \"cat > /etc/openvpn/certs/server.crt\" < pki/issued/server.crt"
echo "   plink -batch -pw root -l root root@192.168.1.2 \"cat > /etc/openvpn/keys/server.key\" < pki/private/server.key"
echo "   plink -batch -pw root -l root root@192.168.1.2 \"cat > /etc/openvpn/certs/dh.pem\" < pki/dh.pem"
echo ""
echo "3. CORREGGERE PERMESSI:"
echo "   chmod 600 /etc/openvpn/keys/server.key"
echo "   chmod 644 /etc/openvpn/certs/*"
echo ""
echo "4. AVVIARE OPENVPN:"
echo "   /etc/init.d/openvpn start"
echo "   /etc/init.d/openvpn enable  (per autostart)"
echo ""
echo "5. VERIFICA:"
echo "   /etc/init.d/openvpn status"
echo "   ps | grep openvpn"
echo "   tail -20 /var/log/openvpn.log"
echo ""
echo "===================================="
