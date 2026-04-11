#!/bin/bash
# Script per eseguire il setup OpenVPN remotamente sul modem

# Variabili
MODEM_IP="192.168.1.2"
MODEM_USER="root"
MODEM_PASS="root"
SCRIPT_FILE="setup_openvpn.sh"
REMOTE_SCRIPT="/tmp/setup_openvpn.sh"

echo "Caricamento script sul modem..."

# Carica lo script via SFTP o SCP
# Se nel workspace, carica il file
if [ -f "$SCRIPT_FILE" ]; then
    echo "Found local script: $SCRIPT_FILE"
    
    # Usa sshpass se disponibile
    if command -v sshpass &> /dev/null; then
        sshpass -p "$MODEM_PASS" scp -o StrictHostKeyChecking=no "$SCRIPT_FILE" "$MODEM_USER@$MODEM_IP:$REMOTE_SCRIPT"
        
        echo "Esecuzione dello script sul modem..."
        sshpass -p "$MODEM_PASS" ssh -o StrictHostKeyChecking=no "$MODEM_USER@$MODEM_IP" "chmod +x $REMOTE_SCRIPT && bash $REMOTE_SCRIPT"
    else
        echo "sshpass non installato. Usando plink..."
        # Nota: Windows con plink
        # Questa parte dovrebbe essere eseguita da Windows PowerShell
        echo "Eseguire da Windows:"
        echo "  plink -batch -pw root -l root root@$MODEM_IP \"bash $REMOTE_SCRIPT\""
    fi
else
    echo "Script $SCRIPT_FILE non trovato!"
    exit 1
fi
