# Setup OpenVPN su Modem Technicolor TG789

Questo progetto fornisce script automatici per configurare un server OpenVPN sul modem Technicolor TG789 (con OpenWrt).

## ⚡ Quick Start (3 comandi)

Se hai già OpenVPN installato sul modem:

```powershell
# 1. Genera certificati server (personalizza "server" con il nome che vuoi)
.\generate_certificates.ps1 -CommonName "server"

# 2. Firma il certificato con Python
.\.venv\Scripts\python.exe .\sign_cert_python.py server

# 3. Carica i certificati sul modem
cd .\easy-rsa-certs\pki
plink -batch -pw root -l root root@192.168.1.2 "cat > /etc/openvpn/certs/ca.crt" < ca.crt
plink -batch -pw root -l root root@192.168.1.2 "cat > /etc/openvpn/certs/server.crt" < issued/server.crt
plink -batch -pw root -l root root@192.168.1.2 "cat > /etc/openvpn/keys/server.key" < private/server.key
plink -batch -pw root -l root root@192.168.1.2 "cat > /etc/openvpn/certs/dh.pem" < dh.pem
```

---

### Script principali
- **`deploy_setup.ps1`** - ⭐ **CONSIGLIATO**: Deploy automatico da Windows PowerShell (installa OpenVPN su modem)
- **`generate_certificates.ps1`** - Genera certificati server con easy-rsa (personalizzabile con CommonName)
- **`sign_cert_python.py`** - Firma i certificati server usando Python (bypass bug easy-rsa su Windows)

### Script alternativi
- **`setup.ps1`** - Script PowerShell semplificato (alternativa a deploy_setup.ps1)
- **`setup_modem.sh`** - Script ash/sh da eseguire direttamente sul modem
- **`run_setup_remote.sh`** - Script bash per deploy da Linux/Mac
- **`sign_cert.sh`** - Script bash per firmare certificati (alternativa a Python)

## ⚙️ Configurazione iniziale (Una sola volta)

Se è la prima volta che usi questo progetto:

```powershell
# 1. Configura l'ambiente Python (virtualenv)
python -m venv .venv
.\.venv\Scripts\Activate.ps1

# 2. Installa le dipendenze Python
pip install cryptography

# 3. Scarica easy-rsa (se non presente)
git clone https://github.com/OpenVPN/easy-rsa.git
```

## 📋 Prerequisiti

- **Windows PowerShell** (o PowerShell 7+)
- **Git** con Bash (scarica da https://git-scm.com/)
- **Python 3.7+** (scarica da https://www.python.org/)
- **PuTTY plink** (scarica da https://www.chiark.greenend.org.uk/~sgtatham/putty/)
- **Accesso SSH** al modem (root@192.168.1.2 con password root)

Assicurati che `plink` e `git` siano nel PATH:
```powershell
# Verifica che funzionano
git --version
plink -V
```

Il modo più semplice e veloce:

```powershell
cd C:\Users\tomma\Desktop\Technicolor_TG789\installVPN
.\deploy_setup.ps1
```

Questo farà automaticamente:
1. Carica il modulo TUN
2. Installa OpenVPN
3. Crea la struttura directory (`/etc/openvpn/certs`, `/etc/openvpn/keys`, etc.)
4. Crea il file di configurazione server

Con parametri personalizzati:
```powershell
.\deploy_setup.ps1 -ModemIP "192.168.1.2" -ModemUser "root" -ModemPass "root" -ScriptPath "setup_modem.sh"
```

## Metodo 2: Setup semplificato da PowerShell

Alternativa più leggera:

```powershell
.\setup.ps1
```

## Metodo 3: Esecuzione manuale su Linux/Mac

Se sei su Linux o Mac:

```bash
./run_setup_remote.sh
```

## Metodo 4: Upload manuale dello script

Se preferisci controllare ogni step:

```bash
# Carica lo script sul modem
plink -batch -pw root -l root root@192.168.1.2 "cat > /tmp/setup.sh" < setup_modem.sh

# Rendi eseguibile e lancaire
plink -batch -pw root -l root root@192.168.1.2 "ash /tmp/setup.sh"
```

---

## Step 2: Generare e firmare i certificati

### Procedura completa (CONSIGLIATO)

#### 1️⃣ Genera i certificati con PowerShell

```powershell
.\generate_certificates.ps1 -CommonName "server"
```

Puoi personalizzare il nome:
```powershell
.\generate_certificates.ps1 -CommonName "mio-vpn-server" -CountryCode "IT"
```

Se non specifichi CommonName:
```powershell
.\generate_certificates.ps1
```
Ti chiederà il nome.

**Output**: File creati in `.\easy-rsa-certs\pki\`
- CA certificato: `ca.crt`
- Richiesta server: `reqs/server.req`
- Chiave privata: `private/server.key`
- Parametri DH: `dh.pem`

#### 2️⃣ Firma il certificato con Python

```powershell
.\.venv\Scripts\python.exe .\sign_cert_python.py server
```

Sostituisci `server` con il nome che hai usato prima se diverso.

**Output**: Certificato firmato creato in `.\easy-rsa-certs\pki\issued\server.crt`

---

### Opzione alternativa: Usa facimente easy-rsa manualmente

Se preferisci usare easy-rsa direttamente:

```bash
# Da Git Bash, nella cartella easy-rsa-certs/
cd .\easy-rsa-certs
../easy-rsa/easyrsa3/easyrsa sign-req server server
```

⚠️ **Nota**: Potrebbe fallire su Windows a causa di un bug di easy-rsa. Se succede, usa il metodo Python (Step 2️⃣ sopra).

---

### Opzione legacy: Con script bash

Se preferisci bash:

```bash
./sign_cert.sh tommi
```

---

## Step 3: Caricare i certificati sul modem

Dopo aver generato e firmato i certificati, caricali sul modem con questi comandi.

**Sostituisci `server` con il nome che hai usato se diverso!**

### Da Windows PowerShell (CONSIGLIATO):

```powershell
# Posizionati nella cartella certificati
cd easy-rsa-certs\pki

# Carica i certificati
plink -batch -pw root -l root root@192.168.1.2 "cat > /etc/openvpn/certs/ca.crt" < ca.crt
plink -batch -pw root -l root root@192.168.1.2 "cat > /etc/openvpn/certs/server.crt" < issued/server.crt
plink -batch -pw root -l root root@192.168.1.2 "cat > /etc/openvpn/keys/server.key" < private/server.key
plink -batch -pw root -l root root@192.168.1.2 "cat > /etc/openvpn/certs/dh.pem" < dh.pem

# Correggi i permessi
plink -batch -pw root -l root root@192.168.1.2 "chmod 600 /etc/openvpn/keys/server.key && chmod 644 /etc/openvpn/certs/*"
```

Se hai usato un nome diverso, sostituisci `issued/server.crt` e `private/server.key` con il nome corretto.

Esempio con CommonName="mio-vpn-server":
```powershell
plink -batch -pw root -l root root@192.168.1.2 "cat > /etc/openvpn/certs/server.crt" < issued/mio-vpn-server.crt
plink -batch -pw root -l root root@192.168.1.2 "cat > /etc/openvpn/keys/server.key" < private/mio-vpn-server.key
```

### Da Linux/Mac:

```bash
# Posizionati nella cartella certificati
cd easy-rsa-certs/pki

# Carica i certificati
scp ca.crt root@192.168.1.2:/etc/openvpn/certs/
scp issued/server.crt root@192.168.1.2:/etc/openvpn/certs/
scp private/server.key root@192.168.1.2:/etc/openvpn/keys/
scp dh.pem root@192.168.1.2:/etc/openvpn/certs/

# Correggi i permessi
ssh root@192.168.1.2 "chmod 600 /etc/openvpn/keys/server.key && chmod 644 /etc/openvpn/certs/*"
```

### Verifica che i file siano stati caricati:

```bash
plink -batch -pw root -l root root@192.168.1.2 "ls -la /etc/openvpn/certs/ /etc/openvpn/keys/"
```

Dovresti vedere:
```
/etc/openvpn/certs/:
-rw-r--r--    1 root     root          1224 Apr 11 10:15 ca.crt
-rw-r--r--    1 root     root          4567 Apr 11 10:15 server.crt
-rw-r--r--    1 root     root          1234 Apr 11 10:15 dh.pem

/etc/openvpn/keys/:
-rw-------    1 root     root          1728 Apr 11 10:15 server.key
```

---

## Step 4: Avviare OpenVPN

Per ogni client che si deve connettere a VPN:

### Con Python/PowerShell (CONSIGLIATO)

```bash
cd easy-rsa-certs

# 1. Genera richiesta client
../easy-rsa/easyrsa3/easyrsa gen-req client1 nopass

# 2. Firma il certificato client con Python
python3 ../sign_cert_python.py client1

# Oppure da PowerShell:
.\.venv\Scripts\python.exe ..\sign_cert_python.py client1
```

Ora avrai:
- `pki/issued/client1.crt`
- `pki/private/client1.key`
- `pki/ca.crt` (copia anche questo)

### Manualmente con easy-rsa

```bash
cd easy-rsa/easyrsa3

# Genera richiesta
./easyrsa gen-req client1 nopass

# Firma certificato
./easyrsa sign-req client client1 nopass
```

### Avvio manuale:

```bash
plink -batch -pw root -l root root@192.168.1.2 "/etc/init.d/openvpn start"
```

### Abilitare autostart:

```bash
plink -batch -pw root -l root root@192.168.1.2 "/etc/init.d/openvpn enable"
```

### Verifica che sia in esecuzione:

```bash
plink -batch -pw root -l root root@192.168.1.2 "/etc/init.d/openvpn status"
```

---

## Step 5: Generare certificati client

Per ogni client che si deve connettere a VPN:

```bash
cd easy-rsa/easyrsa3

# Genera richiesta
./easyrsa gen-req client1 nopass

# Firma certificato
./easyrsa sign-req client client1

# Ora avrai:
# - pki/issued/client1.crt
# - pki/private/client1.key
# - pki/ca.crt (copialo anche)
```

Distribuisci questi file al client con le credenziali VPN.

---

## File di configurazione client

Esempio di `client.conf` per il client VPN:

```
client
dev tun
proto udp
remote 192.168.1.2 1194
resolv-retry infinite
nobind

persist-key
persist-tun

ca ca.crt
cert client1.crt
key client1.key

# Opzionale: se hai generato ta.key
tls-auth ta.key 1

cipher AES-128-CBC
auth SHA256
compress lz4

verb 3
```

Salva come `client.conf` e importalo nel client OpenVPN.

---

## 📝 Note importanti

- **CommonName**: Personnalizza il nome del certificato server (es: "server", "vpn-server", "mio-vpn") usando l'opzione `-CommonName` negli script
- **Python virtualenv**: I script Python usano `.venv\Scripts\python.exe` per eseguirsi in modo isolato. Non devi attivare manualmente il venv se esegui con questo percorso completo
- **Easy-RSA su Windows**: Easy-RSA ha un bug di accesso ai file su Windows. Per questo usiamo lo script Python `sign_cert_python.py` che non ha questo problema
- **Permessi**: Importante settare i permessi corretti con `chmod 600` sulla chiave privata

---

## ✅ Checklist di verifica

Dopo il setup completo, verifica che:

```bash
# 1. OpenVPN è in esecuzione
plink -batch -pw root -l root root@192.168.1.2 "ps | grep openvpn"

# 2. I certificati sono nella posizione giusta
plink -batch -pw root -l root root@192.168.1.2 "ls -la /etc/openvpn/certs/ /etc/openvpn/keys/"

# 3. Le porta è in ascolto
plink -batch -pw root -l root root@192.168.1.2 "netstat -ln | grep 1194"

# 4. Modulo TUN è caricato
plink -batch -pw root -l root root@192.168.1.2 "lsmod | grep tun"

# 5. I log sono puliti
plink -batch -pw root -l root root@192.168.1.2 "tail -20 /var/log/openvpn.log"
```

---

## 🐛 Troubleshooting Avanzato

### Errore: "bash: not found"
Il modem usa `ash` non `bash`. Lo script `setup_modem.sh` è già configurato per usare `ash`.

### Errore: "opkg install failed"
Usa le opzioni: `opkg install --force-depends --nodeps`

### OpenVPN non parte
1. Verifica che i certificati siano presenti:
   ```bash
   plink -batch -pw root -l root root@192.168.1.2 "ls -la /etc/openvpn/certs/ /etc/openvpn/keys/"
   ```

2. Verifica i log:
   ```bash
   plink -batch -pw root -l root root@192.168.1.2 "tail -50 /var/log/openvpn.log"
   ```

3. Verifica il modulo TUN:
   ```bash
   plink -batch -pw root -l root root@192.168.1.2 "lsmod | grep tun"
   ```

### Libreria mancante: "liblzo2.so.2"
OpenVPN funziona anche senza lzo. Se necessario:
```bash
plink -batch -pw root -l root root@192.168.1.2 "opkg install liblzo"
```

### Verifica che OpenVPN è in esecuzione

```bash
plink -batch -pw root -l root root@192.168.1.2 "ps | grep openvpn"
```

### Log di OpenVPN

```bash
plink -batch -pw root -l root root@192.168.1.2 "tail -100 /var/log/openvpn.log"
```

### Connessione client lenta/instabile
1. Aumenta il buffer:
   - Client: `sndbuf 524288` e `rcvbuf 524288`
   - Server: `sndbuf 524288` e `rcvbuf 524288`

2. Abilita keepalive:
   - In config: `keepalive 10 60`

---

## Configurazione firewall

Aggiungi queste regole a UCI (Web interface del modem):

```
- Apri la porta 1194 UDP (o quella usata da OpenVPN)
- Abilita forwarding per le subnet VPN
- Opzionale: limita accesso SSH
```

---

## Security - Consigli importanti

1. **Cambia password root** sul modem
2. **Usa chiavi SSH** invece di password
3. **Configurare firewall**:
   - Apri porta 1194 UDP (o la porta che configuri)
   - Abilita forwarding tra subnet VPN
   - Limita accesso SSH a IP specifici

4. **DH Parameters**:
   - Minimo 2048-bit (consigliato 4096)

5. **Certificati**:
   - Backup in luogo sicuro
   - Rinnova prima della scadenza

6. **Log**:
   - Monitora `/var/log/openvpn.log` per anomalie

---

## Riferimenti

- [OpenVPN Official Docs](https://openvpn.net/community-resources/)
- [easy-rsa GitHub](https://github.com/OpenVPN/easy-rsa)
- [OpenWrt Documentation](https://openwrt.org/docs/guide-user/services/vpn/openvpn/overview)
- [Technicolor TG789 - OpenWrt](https://openwrt.org/toh/technicolor/tg789)

---

## FAQ

**Q: Posso cambiate porta?**
A: Sì, modifica `port 1194` in `openvpn_server.conf` e assicurati di aprire la nuova porta nel firewall.

**Q: Come faccio a disabilitare la compressione?**
A: Rimuovi/commenta la riga `compress lz4` dal config.

**Q: Posso usare TCP invece di UDP?**
A: Sì, cambia `proto udp` a `proto tcp` in config. TCP è più lento ma più affidabile.

**Q: Come faccio a supportare IPv6?**
A: Aggiungi `server-ipv6 2001:db8:1234:1234::/64` al config server. Richiede configurazione firewall aggiuntiva.

**Q: I log dicono "Peer is unreachable"?**
A: Potrebbe essere firewall o configurazione NAT. Verifica le regole firewall sul modem.

**Q: Posso eseguire gli script da WSL?**
A: Sì, ma devi usare `plink` di PuTTY o configurare SSH normalmente. Lo script `run_setup_remote.sh` è fatto per questo.

**Q: Come personalizzare il nome del certificato server?**
A: Usa il parametro `-CommonName` nello script PowerShell:
```powershell
.\generate_certificates.ps1 -CommonName "mio-vpn-server"
.\.venv\Scripts\python.exe .\sign_cert_python.py mio-vpn-server
```

**Q: Cosa fare se `sign_req` fallisce con errore "index.txt"?**
A: È un bug noto di easy-rsa su Windows. Usa lo script Python `sign_cert_python.py` che non ha questo problema:
```powershell
.\.venv\Scripts\python.exe .\sign_cert_python.py server
```

**Q: Devo usare easy-rsa? Posso usare un'altra CA?**
A: Sì! Lo script `sign_cert_python.py` firma i certificati usando Python puro. Puoi usare altre CA, basta che la richiesta sia nel formato PEM corretto.

---

## Sommario file e cartelle

```
installVPN/
├── deploy_setup.ps1              # Deploy automatico (main script)
├── setup.ps1                     # Setup semplificato
├── setup_modem.sh                # Script ash da modem
├── run_setup_remote.sh           # Deploy da Linux/Mac
├── generate_certificates.ps1     # Genera certificati (1° step)
├── sign_cert_python.py           # Firma certificati con Python (2° step) ⭐
├── sign_cert.sh                  # Firma certificati con bash (alternativa)
├── sign_certificates.ps1         # Script PowerShell per firma (deprecato)
├── README.md                     # Questo file
├── easy-rsa/                     # Cartella easy-rsa (git clone)
├── easy-rsa-certs/               # Certificati generati
│   └── pki/
│       ├── ca.crt                # Certificate Authority
│       ├── issued/               # Certificati firmati
│       │   ├── server.crt
│       │   ├── client1.crt
│       │   └── ...
│       ├── private/              # Chiavi private
│       │   ├── ca.key
│       │   ├── server.key
│       │   └── ...
│       ├── reqs/                 # Richieste (non firmate)
│       │   ├── server.req
│       │   ├── client1.req
│       │   └── ...
│       └── dh.pem                # Diffie-Hellman parameters
└── .venv/                        # Python virtualenv
    └── Scripts/
        ├── python.exe
        └── ...
```

---
